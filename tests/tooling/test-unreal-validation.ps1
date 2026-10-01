#Requires -Version 7.2
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$repository = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
Import-Module (Join-Path $repository 'tools/unreal/Validation.psm1') -Force
$fixture = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'fixtures/automation-success.json') -Raw
$runDirectory = Join-Path $repository ('.build/tooling-tests/' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $runDirectory | Out-Null
$script:passed = 0

function Invoke-ReportCase {
    param([string] $Name, [scriptblock] $Mutate, [bool] $Accept = $false)
    $directory = Join-Path $runDirectory $Name
    New-Item -ItemType Directory -Path $directory | Out-Null
    $path = Join-Path $directory 'index.json'
    $log = Join-Path $directory 'automation.log'
    $start = [datetime]::UtcNow.AddSeconds(-2)
    $document = $fixture | ConvertFrom-Json -AsHashtable
    $document.reportCreatedOn = [datetime]::UtcNow.ToString('yyyy.MM.dd-HH.mm.ss')
    $document | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $path -Encoding utf8
    'LogAutomationCommandLine: Display: **** TEST COMPLETE. EXIT CODE: 0 ****' |
        Set-Content -LiteralPath $log -Encoding utf8
    $context = @{ Directory = $directory; Path = $path; Log = $log; ExitCode = 0; Document = $document }
    if ($Mutate) { & $Mutate $context }
    $accepted = $false
    try {
        $result = Assert-UnrealAutomationResult -ReportDirectory $directory -LogPath $log `
            -StartedUtc $start -FinishedUtc ([datetime]::UtcNow.AddSeconds(1)) -EditorExitCode $context.ExitCode
        $accepted = $true
        if ($result.State -cne 'Success') { throw 'Validator did not return its promised success result.' }
    } catch {
        if ($Accept) { throw "Case $Name unexpectedly rejected: $($_.Exception.Message)" }
    }
    if ($accepted -ne $Accept) { throw "Case $Name was falsely accepted." }
    $script:passed++
    Write-Host "PASS $Name"
}

function Save-CaseDocument {
    param($Context)
    $Context.Document | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $Context.Path -Encoding utf8
}

# Start from the observed 5.8 report shape, without host identifiers. Failures simulate real false-green routes.
Invoke-ReportCase 'one-exact-success' -Accept $true
Invoke-ReportCase 'informational-event' {
    param($c)
    $c.Document.tests[0].entries = @(@{ event = @{ type = 'Info'; message = 'Module loaded.' } })
    Save-CaseDocument $c
} -Accept $true
Invoke-ReportCase 'exit-failure-with-good-report' { param($c) $c.ExitCode = 7 }
Invoke-ReportCase 'missing-report-exit-zero' { param($c) Remove-Item -LiteralPath $c.Path }
Invoke-ReportCase 'malformed-json-exit-zero' { param($c) '{"succeeded":1' | Set-Content -LiteralPath $c.Path }
Invoke-ReportCase 'empty-report' { param($c) '' | Set-Content -LiteralPath $c.Path }
Invoke-ReportCase 'missing-log' { param($c) Remove-Item -LiteralPath $c.Log }
Invoke-ReportCase 'stale-file' { param($c) (Get-Item -LiteralPath $c.Path).LastWriteTimeUtc = [datetime]::UtcNow.AddDays(-1) }
Invoke-ReportCase 'stale-report-copied-today' {
    param($c) $c.Document.reportCreatedOn = '2020.01.01-00.00.00'; Save-CaseDocument $c
}
Invoke-ReportCase 'multiple-reports' {
    param($c)
    $nested = Join-Path $c.Directory 'previous'
    New-Item -ItemType Directory -Path $nested | Out-Null
    Copy-Item -LiteralPath $c.Path -Destination (Join-Path $nested 'index.json')
}
Invoke-ReportCase 'missing-test' { param($c) $c.Document.tests = @(); Save-CaseDocument $c }
Invoke-ReportCase 'duplicate-test' {
    param($c) $c.Document.tests = @($c.Document.tests[0], $c.Document.tests[0]); Save-CaseDocument $c
}
Invoke-ReportCase 'similar-test-name' {
    param($c) $c.Document.tests[0].fullTestPath += '.Other'; Save-CaseDocument $c
}
Invoke-ReportCase 'failed-test-with-success-summary' { param($c) $c.Document.tests[0].state = 'Fail'; Save-CaseDocument $c }
Invoke-ReportCase 'not-run-test-with-success-summary' { param($c) $c.Document.tests[0].state = 'NotRun'; Save-CaseDocument $c }
Invoke-ReportCase 'wrong-state-case' { param($c) $c.Document.tests[0].state = 'success'; Save-CaseDocument $c }
foreach ($counter in @('succeededWithWarnings', 'failed', 'notRun', 'inProcess')) {
    $field = $counter
    # Cases run synchronously. A module closure would hide script-local helpers under -Command (CI).
    Invoke-ReportCase "aggregate-$field" { param($c) $c.Document[$field] = 1; Save-CaseDocument $c }
}
Invoke-ReportCase 'inconsistent-success-count' { param($c) $c.Document.succeeded = 2; Save-CaseDocument $c }
Invoke-ReportCase 'missing-aggregate-count' { param($c) $c.Document.Remove('notRun'); Save-CaseDocument $c }
Invoke-ReportCase 'string-count' { param($c) $c.Document.succeeded = '1'; Save-CaseDocument $c }
Invoke-ReportCase 'null-count' { param($c) $c.Document.notRun = $null; Save-CaseDocument $c }
Invoke-ReportCase 'test-warnings' { param($c) $c.Document.tests[0].warnings = 1; Save-CaseDocument $c }
Invoke-ReportCase 'test-errors' { param($c) $c.Document.tests[0].errors = 1; Save-CaseDocument $c }
Invoke-ReportCase 'event-error-with-clean-counters' {
    param($c)
    $c.Document.tests[0].entries = @(@{ event = @{ type = 'Error'; message = 'An assertion failed.' } })
    Save-CaseDocument $c
}
Invoke-ReportCase 'duplicate-json-key' {
    param($c)
    $text = Get-Content -LiteralPath $c.Path -Raw
    $text.Replace('"succeeded": 1', '"succeeded": 0, "succeeded": 1') | Set-Content -LiteralPath $c.Path
}
Invoke-ReportCase 'startup-error-before-test-success' {
    param($c) 'LogAutomationTest: Error: Condition failed' | Add-Content -LiteralPath $c.Log
}
Invoke-ReportCase 'startup-automation-warning' {
    param($c) 'LogAutomationTest: Warning: incomplete startup test' | Add-Content -LiteralPath $c.Log
}
Invoke-ReportCase 'no-completion-marker' { param($c) 'Editor exited normally.' | Set-Content -LiteralPath $c.Log }
Invoke-ReportCase 'duplicate-completion-marker' {
    param($c) '**** TEST COMPLETE. EXIT CODE: 0 ****' | Add-Content -LiteralPath $c.Log
}

# Exercise actual OS process execution and timeout; these processes are tests, not fake Unreal executables.
$shell = (Get-Process -Id $PID).Path
$exitCode = Invoke-BoundedProcess -FilePath $shell -Arguments @('-NoProfile', '-NonInteractive', '-Command', 'exit 17') `
    -WorkingDirectory $runDirectory -LogPrefix (Join-Path $runDirectory 'nonzero') -TimeoutSeconds 15
if ($exitCode -ne 17) { throw 'Process exit code was lost.' }
$script:passed++
Write-Host 'PASS process-exit-code'
$timedOut = $false
try {
    Invoke-BoundedProcess -FilePath $shell `
        -Arguments @('-NoProfile', '-NonInteractive', '-Command', '[Console]::WriteLine($PID); Start-Sleep -Seconds 60') `
        -WorkingDirectory $runDirectory -LogPrefix (Join-Path $runDirectory 'timeout') -TimeoutSeconds 10 | Out-Null
} catch {
    if ($_.Exception.Message -notlike 'Process timed out*') { throw }
    $timedOut = $true
}
if (-not $timedOut) { throw 'Timeout was not enforced.' }
$ownedPid = [int](Get-Content -LiteralPath (Join-Path $runDirectory 'timeout.stdout.log') -Raw).Trim()
if (Get-Process -Id $ownedPid -ErrorAction SilentlyContinue) { throw 'Timed-out owned process is still running.' }
$script:passed++
Write-Host 'PASS owned-process-timeout-cleanup'

if ($IsWindows) {
    $wrongEngine = Join-Path $runDirectory 'wrong-engine'
    New-Item -ItemType Directory -Path (Join-Path $wrongEngine 'Engine/Build') | Out-Null
    '{"MajorVersion":5,"MinorVersion":8,"PatchVersion":2,"Changelist":1}' |
        Set-Content -LiteralPath (Join-Path $wrongEngine 'Engine/Build/Build.version')
    $wrongExit = Invoke-BoundedProcess -FilePath $shell -Arguments @('-NoProfile', '-NonInteractive', '-File',
        (Join-Path $repository 'tools/unreal/verify.ps1'), '-EngineRoot', $wrongEngine) `
        -WorkingDirectory $runDirectory -LogPrefix (Join-Path $runDirectory 'wrong-engine') -TimeoutSeconds 15
    $errorText = Get-Content -LiteralPath (Join-Path $runDirectory 'wrong-engine.stderr.log') -Raw
    if ($wrongExit -eq 0 -or $errorText -notmatch 'pinned to UE 5\.8\.3') { throw 'Engine version pin did not fail correctly.' }
    $script:passed++
    Write-Host 'PASS wrong-engine-version'
}
Write-Host "$script:passed tooling checks passed. No Unreal installation is required. Evidence: $runDirectory"
