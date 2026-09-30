[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

function Wait-HttpOk {
    param(
        [Parameter(Mandatory)] [string] $Uri,
        [int] $TimeoutSeconds = 120
    )

    $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
    do {
        try {
            Invoke-RestMethod -Uri $Uri -TimeoutSec 5 | Out-Null
            return
        } catch {
            Start-Sleep -Seconds 2
        }
    } while ((Get-Date) -lt $deadline)

    throw "Serviço não ficou disponível: $Uri"
}

function New-LocalApiKey {
    $bytes = New-Object byte[] 32
    $rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
    try {
        $rng.GetBytes($bytes)
    } finally {
        $rng.Dispose()
    }
    return [Convert]::ToBase64String($bytes)
}

$projectRoot = $PSScriptRoot
$composeFile = Join-Path $projectRoot 'openjarvis-compose.local.yml'
$envFile = Join-Path $projectRoot '.env'
$sourceDir = Join-Path $projectRoot 'OpenJarvis'

if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    throw 'Docker Desktop CLI não foi encontrado. Instale/inicie o Docker Desktop e execute novamente.'
}

try {
    docker info | Out-Null
} catch {
    $dockerDesktop = Join-Path $env:ProgramFiles 'Docker\Docker\Docker Desktop.exe'
    if (-not (Test-Path -LiteralPath $dockerDesktop)) {
        throw 'Docker Desktop não está em execução e o executável não foi encontrado.'
    }
    Start-Process -FilePath $dockerDesktop
    $deadline = (Get-Date).AddSeconds(120)
    do {
        Start-Sleep -Seconds 3
        try {
            docker info | Out-Null
            break
        } catch {
            if ((Get-Date) -ge $deadline) { throw 'Docker Desktop não ficou pronto em 120 segundos.' }
        }
    } while ($true)
}

try {
    Invoke-RestMethod -Uri 'http://127.0.0.1:11434/api/tags' -TimeoutSec 5 | Out-Null
} catch {
    throw 'O Ollama local não está disponível em http://127.0.0.1:11434. Este inicializador não inicia nem altera o serviço WSL automaticamente.'
}

if (-not (Test-Path -LiteralPath $sourceDir)) {
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        throw 'Git não foi encontrado para baixar o código-fonte oficial do OpenJarvis.'
    }
    git clone --depth 1 https://github.com/open-jarvis/OpenJarvis.git $sourceDir
    if ($LASTEXITCODE -ne 0) { throw 'Não foi possível baixar o código-fonte oficial do OpenJarvis.' }
}

if (-not (Test-Path -LiteralPath $envFile)) {
    Set-Content -LiteralPath $envFile -Value "OPENJARVIS_API_KEY=$(New-LocalApiKey)" -Encoding ascii -NoNewline
}

$env:JARVIS_PROJECT_ROOT = $projectRoot.Replace('\', '/')
$env:OPENJARVIS_SOURCE_DIR = $sourceDir.Replace('\', '/')

docker compose --env-file $envFile -f $composeFile up -d --build
if ($LASTEXITCODE -ne 0) { throw 'Falha ao iniciar o OpenJarvis.' }

Wait-HttpOk -Uri 'http://127.0.0.1:18444/v1/speech/health'
Wait-HttpOk -Uri 'http://127.0.0.1:18444/v1/speech/tts/health' -TimeoutSeconds 180

Start-Process 'http://127.0.0.1:18444/'
Write-Host 'Jarvis pronto em http://127.0.0.1:18444/' -ForegroundColor Green
