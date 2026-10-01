param([switch]$SkipDatabasePrepare)
. "$PSScriptRoot/environment.ps1"
foreach ($required in @((Join-Path $PgBin 'initdb.exe'), (Join-Path $VipsBin 'libvips-42.dll'), (Join-Path $YamlRoot 'include/yaml.h'))) {
  if (-not (Test-Path -LiteralPath $required)) { throw "Falta $required. Ejecuta install-dependencies.ps1 primero." }
}
& $RubyExe -S bundle install --retry 2
if ($LASTEXITCODE -ne 0) { throw 'No se pudieron instalar las gemas' }
if (-not (Test-Path -LiteralPath (Join-Path $PgData 'PG_VERSION'))) {
  if (-not $env:DB_PASSWORD) {
    $random = New-Object byte[] 32
    $rng = [Security.Cryptography.RandomNumberGenerator]::Create()
    $rng.GetBytes($random)
    $rng.Dispose()
    $env:DB_PASSWORD = [Convert]::ToBase64String($random)
    [IO.File]::WriteAllText($LocalConfig, '$env:DB_PASSWORD = ' + "'" + $env:DB_PASSWORD + "'`n")
  }
  $passwordFile = Join-Path $ProjectRoot 'tmp/windows-initdb-password'
  try {
    [IO.File]::WriteAllText($passwordFile, $env:DB_PASSWORD)
    & (Join-Path $PgBin 'initdb.exe') -D $PgData -U resilios --auth=scram-sha-256 --encoding=UTF8 --locale=C --pwfile=$passwordFile
    if ($LASTEXITCODE -ne 0) { throw 'No se pudo inicializar PostgreSQL' }
  } finally { if (Test-Path -LiteralPath $passwordFile) { Remove-Item -LiteralPath $passwordFile } }
}
if (-not $env:DB_PASSWORD) { throw 'Falta DB_PASSWORD en config/windows.local.ps1' }
Start-Database
if (-not $SkipDatabasePrepare) {
  Ensure-Database 'resilios_pos_development'
  Ensure-Database 'resilios_pos_test'
  Invoke-Rails db:prepare
}
Invoke-Rails tailwindcss:build
Write-Host 'Preparacion completa. Ejecuta script/windows/start.ps1'
