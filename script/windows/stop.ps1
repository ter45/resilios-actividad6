. "$PSScriptRoot/environment.ps1"
$pidFile = Join-Path $ProjectRoot 'tmp/pids/windows-server.pid'
if (Test-Path -LiteralPath $pidFile) {
  $serverId = [int]([IO.File]::ReadAllText($pidFile).Trim())
  $server = Get-CimInstance Win32_Process -Filter "ProcessId=$serverId"
  if ($server -and $server.ExecutablePath -eq $RubyExe -and $server.CommandLine -match 'tmp/pids/windows-server.pid') {
    Stop-Process -Id $serverId
    Remove-Item -LiteralPath $pidFile -ErrorAction SilentlyContinue
  } elseif ($server) { throw 'El PID pertenece a otro proceso; no se detuvo' }
}
& (Join-Path $PgBin 'pg_ctl.exe') -D $PgData -m fast -w stop
if ($LASTEXITCODE -ne 0) { Write-Warning 'PostgreSQL no estaba activo o no pudo detenerse' }
