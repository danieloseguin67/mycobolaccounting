param(
    [string]$Image = 'myaccounting-cobol:local',
    [switch]$NoTty,
    [switch]$Local,
    [string]$SqlServer = 'lpc:localhost',
    [string]$Database = 'myaccounting',
    [string]$CompanyName = 'My Demo Consulting Services'
)
$ErrorActionPreference = 'Stop'
# Keep native exit codes available for the diagnostic below in PowerShell 7.
$PSNativeCommandUseErrorActionPreference = $false
$projectRoot = Split-Path -Parent $PSScriptRoot
$sqlDirectory = $null
& "$PSScriptRoot\build.ps1" -Image $Image
$useTty = -not $NoTty
if ($useTty) {
    try {
        $useTty = -not ([Console]::IsInputRedirected -or [Console]::IsOutputRedirected)
    } catch {
        # IDE runners may not attach a console at all.
        $useTty = $false
    }
}
$dockerArguments = @('run', '--rm', '-i')
if ($useTty) { $dockerArguments += '-t' }
$dockerArguments += @(
    '--entrypoint', '/workspace/build/myaccounting',
    '--mount', "type=bind,source=$projectRoot,target=/workspace",
    '--workdir', '/workspace', $Image
)
try {
    if (-not $Local) {
        $sessionName = 'sqlserver-' + [Guid]::NewGuid().ToString('N')
        $sqlDirectory = Join-Path $projectRoot "data\$sessionName"
        & "$PSScriptRoot\read-sqlserver.ps1" -SqlServer $SqlServer -Database $Database `
            -CompanyName $CompanyName -OutputDirectory $sqlDirectory
        # Insert Docker options before the image argument.
        $dockerArguments = $dockerArguments[0..($dockerArguments.Count - 2)] + @(
            '--env', "MYACCOUNT_SQL_DIR=/workspace/data/$sessionName",
            '--mount', "type=bind,source=$sqlDirectory,target=/workspace/data/$sessionName,readonly",
            $Image)
    }
    docker @dockerArguments
    $applicationExitCode = $LASTEXITCODE
} finally {
    if ($null -ne $sqlDirectory -and (Test-Path -LiteralPath $sqlDirectory)) {
        # Delete only this invocation's flat display snapshot, never the ledger.
        $expectedParent = [IO.Path]::GetFullPath((Join-Path $projectRoot 'data'))
        $actualParent = Split-Path -Parent ([IO.Path]::GetFullPath($sqlDirectory))
        if ($actualParent -ne $expectedParent -or (Split-Path -Leaf $sqlDirectory) -notmatch '^sqlserver-[0-9a-f]{32}$') {
            throw 'Unexpected SQL snapshot cleanup path.'
        }
        Get-ChildItem -LiteralPath $sqlDirectory -File | ForEach-Object {
            Remove-Item -LiteralPath $_.FullName -Force
        }
        [IO.Directory]::Delete($sqlDirectory, $false)
    }
}
if ($applicationExitCode -ne 0) {
    [Console]::Error.WriteLine("MyAccounting/Docker exited with code $applicationExitCode. The error immediately above explains the failure.")
    if ($applicationExitCode -eq 125) {
        [Console]::Error.WriteLine('Docker could not start the container. If it reported a TTY problem, run .\scripts\run.cmd -NoTty.')
    }
    exit $applicationExitCode
}
