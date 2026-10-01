param([ValidateSet('Install','Start','Stop','Backup','Update','Check')][string]$Action='Install',[switch]$NoBrowser)
$ErrorActionPreference='Stop'
Set-Location -LiteralPath ([IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..')))
$script:compose=@('compose','--env-file',"$PWD/.env",'-f',"$PWD/compose.windows.yml")
function DC {
  & docker @script:compose @args | Out-Host
  if($LASTEXITCODE -ne 0){throw "Docker fallo: $LASTEXITCODE"}
}
function Ready {
  $port=3021
  foreach($line in Get-Content .env){if($line -match '^APP_PORT=(\d+)$'){$port=[int]$Matches[1]}}
  $url="http://localhost:$port"
  for($i=0;$i -lt 90;$i++){
    try {
      if((Invoke-WebRequest -UseBasicParsing "$url/up" -TimeoutSec 2).StatusCode -eq 200){
        Write-Host "ResiliOS listo: $url"
        if(-not $NoBrowser){Start-Process $url}
        return
      }
    }catch{}
    Start-Sleep -Seconds 2
  }
  DC logs --tail 60 app
  throw 'La aplicacion no responde. Revisa los registros.'
}
function Backup {
  $running=@(& docker @script:compose ps --status running --services)
  if($LASTEXITCODE -ne 0){throw 'No se pudo consultar Docker.'}
  $resume=$running -contains 'app'
  $id=[guid]::NewGuid().ToString('N')
  $folder=Join-Path $PWD ('backups/'+(Get-Date -Format yyyyMMdd-HHmmss)+'-'+$id.Substring(0,6))
  $container='resilios-backup-'+$id
  New-Item -ItemType Directory $folder | Out-Null
  try {
    if($resume){DC stop app}
    DC up -d --wait db
    DC exec -T db sh -c 'pg_dumpall -U resilios > /tmp/resilios.sql'
    DC cp db:/tmp/resilios.sql "$folder/database.sql"
    DC run --name $container --no-deps --entrypoint tar app -czf /tmp/storage.tar.gz -C /rails/storage .
    & docker cp ($container+':/tmp/storage.tar.gz') "$folder/storage.tar.gz"
    if($LASTEXITCODE -ne 0){throw 'Fallo al copiar adjuntos.'}
    Copy-Item .env "$folder/.env"
    foreach($file in @('database.sql','storage.tar.gz','.env')){
      if((Get-Item "$folder/$file").Length -eq 0){throw "Archivo vacio: $file"}
    }
    Get-FileHash "$folder/database.sql","$folder/storage.tar.gz" | Select-Object Hash,Path |
      ConvertTo-Json | Set-Content "$folder/checksums.json"
    Set-Content "$folder/COMPLETO.txt" 'Respaldo completo. Conservar toda la carpeta y verificar su restauracion.'
    Write-Host "Respaldo: $folder"
  }finally{
    try { & docker rm $container 2>$null | Out-Host } catch { Write-Warning "No se pudo retirar el contenedor temporal $container" }
    if($resume){DC up -d app}
  }
}
try {
  Get-Command docker -ErrorAction Stop | Out-Null
  $os=& docker info --format '{{.OSType}}'
  if($LASTEXITCODE -ne 0){throw 'Abre Docker Desktop y espera a que este listo.'}
  if($os -ne 'linux'){throw 'Selecciona contenedores Linux en Docker Desktop.'}
  foreach($name in @('DB_PASSWORD','SECRET_KEY_BASE','APP_PORT','COMPOSE_FILE','COMPOSE_PROJECT_NAME')){
    Remove-Item "Env:$name" -ErrorAction SilentlyContinue
  }
  if(-not(Test-Path .env)){
    if($Action -ne 'Install'){throw 'Ejecuta Instalar.cmd primero.'}
    $rng=[Security.Cryptography.RandomNumberGenerator]::Create()
    $values=@()
    try {
      foreach($name in @('DB_PASSWORD','SECRET_KEY_BASE')){
        $bytes=New-Object byte[] 48
        $rng.GetBytes($bytes)
        $values+=($name+'='+[BitConverter]::ToString($bytes).Replace('-',''))
      }
    }finally{$rng.Dispose()}
    $values+='APP_PORT=3021'
    $stream=[IO.File]::Open("$PWD/.env",[IO.FileMode]::CreateNew,[IO.FileAccess]::Write)
    $writer=New-Object IO.StreamWriter($stream)
    try{$writer.WriteLine(($values -join [Environment]::NewLine))}finally{$writer.Dispose()}
  }
  DC config --quiet
  switch($Action){
    Install{DC up -d --build; Ready}
    Start{DC up -d; Ready}
    Stop{DC stop; Write-Host 'Sistema detenido. Datos conservados.'}
    Backup{Backup}
    Update{
      Get-Command git -ErrorAction Stop | Out-Null
      $changes=& git status --porcelain
      if($LASTEXITCODE -ne 0){throw 'Actualizar requiere una copia clonada con Git.'}
      if($changes){throw 'Hay cambios locales. Guardalos en Git antes de actualizar.'}
      Backup
      & git pull --ff-only
      if($LASTEXITCODE -ne 0){throw 'Git no pudo actualizar; no se reconstruyo la aplicacion.'}
      DC up -d --build
      Ready
    }
    Check{Write-Host 'Docker y configuracion correctos.'}
  }
}catch{
  Write-Host ('ERROR: '+$_.Exception.Message) -ForegroundColor Red
  exit 1
}