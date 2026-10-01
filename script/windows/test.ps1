. "$PSScriptRoot/environment.ps1"
Start-Database
Ensure-Database 'resilios_pos_test'
$env:RAILS_ENV = 'test'
Invoke-Rails db:prepare
Invoke-Rails test
Invoke-Rails zeitwerk:check
& node test/javascript/scale_controller_test.cjs
if ($LASTEXITCODE -ne 0) { throw 'Fallaron las pruebas JavaScript' }
