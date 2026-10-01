$ErrorActionPreference = 'Stop'
$ProjectRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
Set-Location -LiteralPath $ProjectRoot
$RubyExe = (Get-Command ruby.exe -ErrorAction Stop).Source
$PgBin = Join-Path $ProjectRoot 'vendor/windows/postgresql/pgsql/bin'
$VipsBin = Join-Path $ProjectRoot 'vendor/windows/vips-static/vips-dev-8.18/bin'
$YamlRoot = Join-Path $ProjectRoot 'vendor/windows/libyaml/ucrt64'
$LocalConfig = Join-Path $ProjectRoot 'config/windows.local.ps1'
if (Test-Path -LiteralPath $LocalConfig) { . $LocalConfig }
$env:RUBY_DLL_PATH = "$VipsBin;$(Join-Path $YamlRoot 'bin')"
$env:Path = "$VipsBin;$(Join-Path $YamlRoot 'bin');$PgBin;$env:Path"
$env:BUNDLE_BUILD__PSYCH = '--with-libyaml-dir="' + $YamlRoot.Replace('\', '/') + '"'
$env:DB_HOST = '127.0.0.1'
$env:DB_PORT = '55433'
$env:DB_USERNAME = 'resilios'
$env:RAILS_ENV = 'development'
$PgData = Join-Path $ProjectRoot 'storage/windows-postgres'
function Invoke-Rails {
  & $RubyExe bin/rails @args
  if ($LASTEXITCODE -ne 0) { throw "Rails termino con codigo $LASTEXITCODE" }
}
function Start-Database {
  & (Join-Path $PgBin 'pg_ctl.exe') -D $PgData status *> $null
  if ($LASTEXITCODE -ne 0) {
    & (Join-Path $PgBin 'pg_ctl.exe') -D $PgData -l (Join-Path $ProjectRoot 'log/windows-postgres.log') -o '-h 127.0.0.1 -p 55433' -w start
    if ($LASTEXITCODE -ne 0) { throw 'No se pudo iniciar PostgreSQL local' }
  }
}

function Ensure-Database {
  param([ValidateSet('resilios_pos_development','resilios_pos_test')][string]$Name)
  $env:PGPASSWORD = $env:DB_PASSWORD
  $exists = & (Join-Path $PgBin 'psql.exe') -h 127.0.0.1 -p 55433 -U resilios -d postgres -tAc "SELECT 1 FROM pg_database WHERE datname='$Name'"
  if ($LASTEXITCODE -ne 0) { throw 'No se pudo comprobar la base local' }
  if ($exists -ne '1') {
    & (Join-Path $PgBin 'createdb.exe') -h 127.0.0.1 -p 55433 -U resilios $Name
    if ($LASTEXITCODE -ne 0) { throw "No se pudo crear $Name" }
  }
}