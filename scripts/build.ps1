param([string]$Image = 'myaccounting-cobol:local')
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
Push-Location $projectRoot
try {
    $toolchainId = docker image ls --quiet --filter "reference=$Image"
    if ($LASTEXITCODE -ne 0) { throw 'Cannot reach Docker. Start Docker Desktop in Linux-container mode.' }
    if (-not $toolchainId) {
        docker build -t $Image .
        if ($LASTEXITCODE -ne 0) { throw 'Docker toolchain build failed.' }
    }
    New-Item -ItemType Directory -Force build, data, exports | Out-Null
    docker run --rm --entrypoint /bin/sh `
        --mount "type=bind,source=$projectRoot,target=/workspace" `
        --workdir /workspace $Image -c `
        'cobc -x -free -Wall -Werror -debug -I copybooks -o build/myaccounting src/myaccounting.cob'
    if ($LASTEXITCODE -ne 0) { throw 'COBOL compilation failed.' }
    Write-Host 'Built build/myaccounting. Start it with .\scripts\run.cmd'
} finally {
    Pop-Location
}
