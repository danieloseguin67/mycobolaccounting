param([string]$Image = 'myaccounting-cobol:local')
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
& "$PSScriptRoot\build.ps1" -Image $Image
python "$projectRoot\tests\test_accounting.py" --docker-image $Image
if ($LASTEXITCODE -ne 0) { throw 'Accounting integration tests failed.' }
