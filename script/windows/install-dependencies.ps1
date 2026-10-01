$ErrorActionPreference = 'Stop'
$root = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
Set-Location -LiteralPath $root
Get-Command ruby.exe -ErrorAction Stop | Out-Null
[IO.Directory]::CreateDirectory((Join-Path $root 'vendor/windows')) | Out-Null
function Get-Archive($url, $archive, $destination, $marker) {
  if (Test-Path -LiteralPath $marker) { return }
  & curl.exe -fL --retry 2 --connect-timeout 15 --speed-limit 10000 --speed-time 30 $url -o $archive
  if ($LASTEXITCODE -ne 0) { throw "No se pudo descargar $url" }
  Expand-Archive -LiteralPath $archive -DestinationPath $destination -Force
}
Get-Archive 'https://sbp.enterprisedb.com/getfile.jsp?fileid=1260569' 'vendor/windows/postgresql.zip' 'vendor/windows/postgresql' 'vendor/windows/postgresql/pgsql/bin/initdb.exe'
Get-Archive 'https://github.com/libvips/build-win64-mxe/releases/download/v8.18.6/vips-dev-x64-web-8.18.6-static-ffi.zip' 'vendor/windows/vips-static.zip' 'vendor/windows/vips-static' 'vendor/windows/vips-static/vips-dev-8.18/bin/libvips-42.dll'
if (-not (Test-Path 'vendor/windows/libyaml/ucrt64/include/yaml.h')) {
  & curl.exe -fL --retry 2 'https://mirror.msys2.org/mingw/ucrt64/mingw-w64-ucrt-x86_64-libyaml-0.2.5-2-any.pkg.tar.zst' -o vendor/windows/libyaml.tar.zst
  if ($LASTEXITCODE -ne 0) { throw 'No se pudo descargar libyaml' }
  if ((Get-FileHash vendor/windows/libyaml.tar.zst -Algorithm SHA256).Hash -ne 'BF4C28A3A92A46DB3C809B0789AEF731AE9A0C4283DB368C7E8624550FED07F3') { throw 'Checksum de libyaml incorrecto' }
  [IO.Directory]::CreateDirectory((Join-Path $root 'vendor/windows/libyaml')) | Out-Null
  & tar.exe -xf vendor/windows/libyaml.tar.zst -C vendor/windows/libyaml
  if ($LASTEXITCODE -ne 0) { throw 'No se pudo extraer libyaml' }
}
Write-Host 'Dependencias listas. Ejecuta script/windows/setup.ps1'
