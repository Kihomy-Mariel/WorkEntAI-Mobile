# Lee el .env y lanza flutter con --dart-define por cada variable
# Uso:
#   .\scripts\run_with_env.ps1 run
#   .\scripts\run_with_env.ps1 build apk --release
#   .\scripts\run_with_env.ps1 build apk --release --split-per-abi

$envFile = Join-Path $PSScriptRoot ".." ".env"

if (-not (Test-Path $envFile)) {
    Write-Error "❌ No se encontró .env. Copia .env.example como .env y configura tus valores."
    exit 1
}

$dartDefines = @()
Get-Content $envFile | ForEach-Object {
    $line = $_.Trim()
    if ($line -and -not $line.StartsWith("#")) {
        $dartDefines += "--dart-define=$line"
    }
}

$flutterArgs = $args + $dartDefines
Write-Host "🚀 Ejecutando: flutter $flutterArgs"
& flutter @flutterArgs
