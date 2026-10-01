#Requires -Version 7.2
[CmdletBinding()]
param(
    [string] $EngineRoot = $env:UE_ENGINE_ROOT,
    [ValidateRange(1, 2)] [int] $MaxParallelActions = 2,
    [ValidateRange(1, 7200)] [int] $BuildTimeoutSeconds = 1200,
    [ValidateRange(1, 1800)] [int] $TestTimeoutSeconds = 600
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'Validation.psm1') -Force

try {
    if (-not $IsWindows) { throw 'This UE 5.8.3 verification entrypoint requires Windows.' }
    if ([string]::IsNullOrWhiteSpace($EngineRoot)) { throw 'Specify -EngineRoot or UE_ENGINE_ROOT.' }
    $engine = (Resolve-Path -LiteralPath $EngineRoot).Path
    $repository = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
    $project = Join-Path $repository 'client/DraconicClient.uproject'
    $build = Join-Path $engine 'Engine/Build/BatchFiles/Build.bat'
    $editor = Join-Path $engine 'Engine/Binaries/Win64/UnrealEditor-Cmd.exe'
    # Build.bat itself expands arguments with cmd and delayed expansion. Fail before invoking it on unsafe paths.
    foreach ($path in @($engine, $repository)) {
        if ($path -match '[%!?^&|<>"\r\n]') { throw 'Build.bat paths may not contain shell metacharacters.' }
    }
    $version = Get-Content -LiteralPath (Join-Path $engine 'Engine/Build/Build.version') -Raw | ConvertFrom-Json
    if ($version.MajorVersion -ne 5 -or $version.MinorVersion -ne 8 -or $version.PatchVersion -ne 3) {
        throw 'This verification is pinned to UE 5.8.3; review APIs and evidence before changing the pin.'
    }
    foreach ($file in @($project, $build, $editor)) {
        if (-not (Test-Path -LiteralPath $file -PathType Leaf)) { throw "Required file missing: $file" }
    }
    $runId = [datetime]::UtcNow.ToString('yyyyMMddTHHmmssZ') + '-' + [guid]::NewGuid().ToString('N')
    $runDirectory = Join-Path $repository ".build/unreal/$runId"
    $reportDirectory = Join-Path $runDirectory 'report'
    # Never reuse, clean, or resume a previous report directory.
    New-Item -ItemType Directory -Path $reportDirectory -ErrorAction Stop | Out-Null
    Write-Host "UE 5.8.3, changelist $($version.Changelist). Evidence: $runDirectory"
    Write-Host 'Building DraconicClientEditor Win64 Development...'
    $buildArguments = '/d /s /c ""' + $build + '" DraconicClientEditor Win64 Development "-Project=' +
        $project + '" -WaitMutex -NoHotReloadFromIDE -MaxParallelActions=' + $MaxParallelActions + '"'
    $buildExit = Invoke-BoundedProcess -FilePath (Join-Path $env:SystemRoot 'System32\cmd.exe') -RawArguments $buildArguments `
        -WorkingDirectory $repository -LogPrefix (Join-Path $runDirectory 'build') -TimeoutSeconds $BuildTimeoutSeconds
    if ($buildExit -ne 0) { throw "UBT failed with code $buildExit. Evidence: $runDirectory" }

    $log = Join-Path $runDirectory 'automation.log'
    $startedUtc = [datetime]::UtcNow
    Write-Host 'Running the exact client module smoke test headlessly...'
    $editorArguments = @($project, '-unattended', '-nullrhi', '-nosplash', '-nosound', '-nowrite', '-culture=en',
        '-LogCmds=LogAutomationTest Log', '-ExecCmds=Automation RunTest Draconic.Foundation.ClientModuleLoaded;Quit',
        "-ReportExportPath=$reportDirectory", "-abslog=$log")
    $editorExit = Invoke-BoundedProcess -FilePath $editor -Arguments $editorArguments -WorkingDirectory $repository `
        -LogPrefix (Join-Path $runDirectory 'editor') -TimeoutSeconds $TestTimeoutSeconds
    $finishedUtc = [datetime]::UtcNow
    $result = Assert-UnrealAutomationResult -ReportDirectory $reportDirectory -LogPath $log `
        -StartedUtc $startedUtc -FinishedUtc $finishedUtc -EditorExitCode $editorExit
    [ordered]@{
        engineVersion = '5.8.3'; engineChangelist = $version.Changelist
        buildExitCode = $buildExit; editorExitCode = $editorExit
        startedUtc = $startedUtc.ToString('o'); finishedUtc = $finishedUtc.ToString('o')
        test = $result.Test; state = $result.State; report = $result.Report
        scope = 'editor_build_and_module_load_only'
    } | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $runDirectory 'verification.json') -Encoding utf8
    Write-Host "VERIFIED: $($result.Test) = Success. No rendering, packaging, networking or gameplay is tested."
    exit 0
} catch {
    Write-Error -Message $_.Exception.Message -ErrorAction Continue
    exit 1
}
