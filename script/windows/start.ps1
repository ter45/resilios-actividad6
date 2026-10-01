param([int]$Port = 3021)
. "$PSScriptRoot/environment.ps1"
if (-not $env:DB_PASSWORD) { throw 'Ejecuta setup.ps1 antes de iniciar' }
Start-Database
Invoke-Rails db:migrate
Invoke-Rails tailwindcss:build
if (Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue) { throw "El puerto $Port esta ocupado" }
$process = Start-Process -FilePath $RubyExe -ArgumentList @('bin/rails','server','-b','127.0.0.1','-p',"$Port",'-P','tmp/pids/windows-server.pid') -WorkingDirectory $ProjectRoot -WindowStyle Hidden -PassThru -RedirectStandardOutput 'log/windows-server.out.log' -RedirectStandardError 'log/windows-server.err.log'
$ready = $false
for ($attempt = 0; $attempt -lt 40; $attempt++) {
  if ($process.HasExited) { throw 'Rails se detuvo. Revisa log/windows-server.err.log' }
  try {
    $response = Invoke-WebRequest -UseBasicParsing "http://127.0.0.1:$Port/up" -TimeoutSec 2
    if ($response.StatusCode -eq 200) { $ready = $true; break }
  } catch { Start-Sleep -Seconds 1 }
}
if (-not $ready) { throw 'Rails aun no responde. Revisa log/windows-server.err.log' }
Write-Host "ResiliOS Windows: http://localhost:$Port"
