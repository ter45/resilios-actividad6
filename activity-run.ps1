param([Parameter(ValueFromRemainingArguments=$true)][string[]]$RailsArgs)
$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot
$dependencyRoot = 'D:\MiniMercado-\resilios-pos-minimercado-1\vendor\windows'
$env:RUBY_DLL_PATH = "$dependencyRoot\vips-static\vips-dev-8.18\bin;$dependencyRoot\libyaml\ucrt64\bin"
$env:Path = "$env:RUBY_DLL_PATH;C:\Ruby34-x64\bin;$env:Path"
$env:RAILS_ENV = 'test'
$env:DB_HOST = '127.0.0.1'
$env:DB_PORT = '55436'
$env:DB_USERNAME = 'resilios'
$env:DB_PASSWORD = 'activity-local-only'
& ruby bin/rails @RailsArgs
exit $LASTEXITCODE
