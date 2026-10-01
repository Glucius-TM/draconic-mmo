#Requires -Version 7.2
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Assert-UniqueJsonProperties {
    param([System.Text.Json.JsonElement] $Value)
    if ($Value.ValueKind -eq [System.Text.Json.JsonValueKind]::Object) {
        $names = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
        foreach ($property in $Value.EnumerateObject()) {
            if (-not $names.Add($property.Name)) { throw "Duplicate JSON property: $($property.Name)" }
            Assert-UniqueJsonProperties $property.Value
        }
    } elseif ($Value.ValueKind -eq [System.Text.Json.JsonValueKind]::Array) {
        foreach ($item in $Value.EnumerateArray()) { Assert-UniqueJsonProperties $item }
    }
}

function Get-JsonProperty {
    param([System.Text.Json.JsonElement] $Object, [string] $Name,
        [System.Text.Json.JsonValueKind] $Kind)
    $value = $Object.GetProperty($Name)
    if ($value.ValueKind -ne $Kind) { throw "Invalid JSON type for $Name; expected $Kind." }
    return $value
}

function Assert-JsonCount {
    param([System.Text.Json.JsonElement] $Object, [string] $Name, [int] $Expected)
    $value = Get-JsonProperty $Object $Name Number
    $count = 0
    if (-not $value.TryGetInt32([ref] $count) -or $count -ne $Expected) {
        throw "Unexpected count for $Name; expected $Expected."
    }
}

function Assert-UnrealAutomationResult {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [string] $ReportDirectory,
        [Parameter(Mandatory)] [string] $LogPath,
        [Parameter(Mandatory)] [datetime] $StartedUtc,
        [Parameter(Mandatory)] [datetime] $FinishedUtc,
        [Parameter(Mandatory)] [int] $EditorExitCode
    )
    if ($EditorExitCode -ne 0) { throw "Editor exited with code $EditorExitCode." }
    if ($StartedUtc.Kind -ne 'Utc' -or $FinishedUtc.Kind -ne 'Utc' -or $FinishedUtc -lt $StartedUtc) {
        throw 'Invalid UTC execution interval.'
    }
    $reports = @(Get-ChildItem -LiteralPath $ReportDirectory -Filter index.json -File -Recurse)
    $expectedPath = [IO.Path]::GetFullPath((Join-Path $ReportDirectory 'index.json'))
    if ($reports.Count -ne 1 -or $reports[0].FullName -cne $expectedPath) {
        throw 'Expected exactly one index.json at the root of the fresh report directory.'
    }
    $report = $reports[0]
    if ($report.Length -eq 0 -or $report.Length -gt 4MB) { throw 'Report is empty or exceeds 4 MiB.' }
    foreach ($file in @($report, (Get-Item -LiteralPath $LogPath))) {
        if ($file.LastWriteTimeUtc -lt $StartedUtc -or $file.LastWriteTimeUtc -gt $FinishedUtc) {
            throw "Stale or future evidence file: $($file.Name)"
        }
    }
    $options = [System.Text.Json.JsonDocumentOptions]::new()
    $options.MaxDepth = 32
    $json = [System.Text.Json.JsonDocument]::Parse([IO.File]::ReadAllText($report.FullName), $options)
    try {
        $root = $json.RootElement
        Assert-UniqueJsonProperties $root
        Assert-JsonCount $root succeeded 1
        foreach ($name in @('succeededWithWarnings', 'failed', 'notRun', 'inProcess')) {
            Assert-JsonCount $root $name 0
        }
        $created = (Get-JsonProperty $root reportCreatedOn String).GetString()
        $createdUtc = [datetime]::ParseExact($created, 'yyyy.MM.dd-HH.mm.ss',
            [Globalization.CultureInfo]::InvariantCulture,
            [Globalization.DateTimeStyles]::AssumeUniversal -bor [Globalization.DateTimeStyles]::AdjustToUniversal)
        # Unreal serializes UTC without subsecond precision. Only this field gets a one-second allowance.
        if ($createdUtc -lt $StartedUtc.AddSeconds(-1) -or $createdUtc -gt $FinishedUtc) {
            throw 'Report creation timestamp is outside this execution.'
        }
        $tests = Get-JsonProperty $root tests Array
        if ($tests.GetArrayLength() -ne 1) { throw 'Expected exactly one test result; duplicates/extras are rejected.' }
        $test = $tests[0]
        if ((Get-JsonProperty $test fullTestPath String).GetString() -cne 'Draconic.Foundation.ClientModuleLoaded') {
            throw 'The exact required client smoke test did not run.'
        }
        if ((Get-JsonProperty $test state String).GetString() -cne 'Success') { throw 'Smoke test did not succeed.' }
        Assert-JsonCount $test warnings 0
        Assert-JsonCount $test errors 0
        foreach ($entry in (Get-JsonProperty $test entries Array).EnumerateArray()) {
            $event = Get-JsonProperty $entry event Object
            $type = (Get-JsonProperty $event type String).GetString()
            if ($type -cne 'Info') { throw "Unexpected test event type: $type" }
        }
    } finally { $json.Dispose() }

    # Engine startup smoke failures can precede the selected test and be absent from its JSON report.
    $completed = 0
    foreach ($line in [IO.File]::ReadLines($LogPath)) {
        if ($line -match ':\s*(Error|Fatal):|Condition failed|LogAutomationTest:\s*Warning:|Result=\{Fail(?:ure)?\}') {
            throw 'Engine log contains an error or automation warning; inspect the preserved log.'
        }
        if ($line -match '\*{4} TEST COMPLETE\. EXIT CODE: 0 \*{4}') { $completed++ }
    }
    if ($completed -ne 1) { throw 'Expected exactly one successful automation completion marker.' }
    return [pscustomobject]@{ Test = 'Draconic.Foundation.ClientModuleLoaded'; State = 'Success'; Report = $report.FullName }
}

function Invoke-BoundedProcess {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [string] $FilePath,
        [string[]] $Arguments = @(),
        [string] $RawArguments,
        [Parameter(Mandatory)] [string] $WorkingDirectory,
        [Parameter(Mandatory)] [string] $LogPrefix,
        [ValidateRange(1, 7200)] [int] $TimeoutSeconds = 600
    )
    $info = [Diagnostics.ProcessStartInfo]::new()
    $info.FileName = $FilePath
    $info.WorkingDirectory = $WorkingDirectory
    $info.UseShellExecute = $false
    $info.CreateNoWindow = $true
    $info.WindowStyle = [Diagnostics.ProcessWindowStyle]::Hidden
    $info.RedirectStandardOutput = $true
    $info.RedirectStandardError = $true
    if ($RawArguments) {
        if ($Arguments.Count -ne 0) { throw 'Provide either raw or individual arguments.' }
        $info.Arguments = $RawArguments
    } else {
        foreach ($argument in $Arguments) { $info.ArgumentList.Add($argument) }
    }
    $process = [Diagnostics.Process]::new()
    $process.StartInfo = $info
    $stdout = [IO.File]::Create("$LogPrefix.stdout.log")
    $stderr = [IO.File]::Create("$LogPrefix.stderr.log")
    $started = $false
    $outCopy = $null
    $errCopy = $null
    try {
        $started = $process.Start()
        if (-not $started) { throw "Could not start $FilePath" }
        $outCopy = $process.StandardOutput.BaseStream.CopyToAsync($stdout)
        $errCopy = $process.StandardError.BaseStream.CopyToAsync($stderr)
        if (-not $process.WaitForExit($TimeoutSeconds * 1000)) {
            throw "Process timed out after $TimeoutSeconds seconds: $FilePath"
        }
        if (-not [Threading.Tasks.Task]::WaitAll(@($outCopy, $errCopy), 10000)) {
            throw 'Timed out draining process logs.'
        }
        return $process.ExitCode
    } finally {
        # Use the owned process handle/tree, never a name-based kill of editors or build tools.
        if ($started -and -not $process.HasExited) {
            $process.Kill($true)
            if (-not $process.WaitForExit(10000)) { Write-Warning 'Owned process did not exit after termination.' }
        }
        if ($null -ne $outCopy -and $null -ne $errCopy) {
            try {
                if (-not [Threading.Tasks.Task]::WaitAll(@($outCopy, $errCopy), 10000)) {
                    Write-Warning 'Some owned process output did not finish draining.'
                }
            } catch { Write-Warning "Process output could not be fully preserved: $($_.Exception.Message)" }
        }
        $stdout.Dispose()
        $stderr.Dispose()
        $process.Dispose()
    }
}

Export-ModuleMember -Function Assert-UnrealAutomationResult, Invoke-BoundedProcess
