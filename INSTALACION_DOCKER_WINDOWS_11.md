# Instalación de ResiliOS con Docker en Windows 11

Instalar Docker Desktop con WSL 2 y contenedores Linux. Abrir Docker Desktop antes de ejecutar los comandos. Instalar Git o descargar el proyecto como ZIP. Ruby y PostgreSQL se ejecutan en contenedores.

## Descargar (después de publicar el commit)
    git clone https://github.com/ter45/resilios-pos-minimercado.git C:\ResiliOS
    cd C:\ResiliOS

## Crear claves una sola vez
Ejecutar en PowerShell dentro del proyecto. Conservar el archivo .env en las actualizaciones; no subirlo a GitHub.

    if (Test-Path .env) { throw 'Ya existe .env; conservarlo.' }
    $rng = [Security.Cryptography.RandomNumberGenerator]::Create()
    $dbBytes = New-Object byte[] 32
    $keyBytes = New-Object byte[] 64
    $rng.GetBytes($dbBytes)
    $rng.GetBytes($keyBytes)
    $rng.Dispose()
    $dbKey = [Convert]::ToBase64String($dbBytes)
    $appKey = [BitConverter]::ToString($keyBytes).Replace('-', '')
    @("DB_PASSWORD=$dbKey", "SECRET_KEY_BASE=$appKey", "APP_PORT=3021") | Set-Content .env -Encoding ASCII

## Construir y arrancar
    docker compose -f compose.windows.yml config --quiet
    docker compose -f compose.windows.yml up -d --build
    docker compose -f compose.windows.yml logs --tail 100 app

Esperar a que Rails termine de preparar las bases y anuncie que escucha en el puerto 3000. Abrir http://localhost:3021 en Edge o Chrome. Comprobar http://localhost:3021/up. Si el puerto local está ocupado, cambiar APP_PORT en .env.

Usar siempre -f compose.windows.yml para evitar el override de desarrollo. Los volúmenes conservan la base de datos y los logos. La instalación nueva no importa ventas de otro equipo.

## Configuración inicial
Ingresar con admin@resilios.local y clave admin123456. Crear un administrador propio desde Sistema > Usuarios, entrar con él y desactivar las cuentas de demostración. Crear cajeros y asignarles terminal. Configurar el negocio y el logo. Sustituir los precios y existencias sintéticos del catálogo por los reales.

## Impresoras
Instalar los controladores en Windows. Probar una página desde Windows. Desde el ticket seleccionar EPSON / hoja A4 para L3110 o térmica 58/80 mm según el papel. Imprimir desde Edge o Chrome con escala 100 % y sin encabezados ni pies. No se necesita pasar USB al contenedor. El usuario validó la impresión de esta versión; repetir la prueba en el equipo nuevo.

## Uso diario
    docker compose -f compose.windows.yml stop
    docker compose -f compose.windows.yml up -d
    docker compose -f compose.windows.yml ps

Configurar Docker Desktop para abrir al iniciar sesión. Los contenedores se recuperan si estaban en marcha; tras una parada manual usar up -d. Nunca ejecutar down -v: elimina los datos.

## Respaldo antes de actualizar
Detener las ventas y la aplicación. Ejecutar cada comando solo si el anterior terminó correctamente. El respaldo incluye las bases principal, caché y cola, los roles, los adjuntos y las claves.

    $backup = Join-Path $PWD ('backups/' + (Get-Date -Format 'yyyyMMdd-HHmmss'))
    New-Item -ItemType Directory -Path $backup -Force | Out-Null
    docker compose -f compose.windows.yml stop app
    docker compose -f compose.windows.yml exec -T db sh -c 'pg_dumpall -U resilios > /tmp/resilios.sql'
    docker compose -f compose.windows.yml cp db:/tmp/resilios.sql "$backup/database.sql"
    docker compose -f compose.windows.yml run --name resilios-backup-files --no-deps --entrypoint tar app -czf /tmp/storage.tar.gz -C /rails/storage .
    docker cp resilios-backup-files:/tmp/storage.tar.gz "$backup/storage.tar.gz"
    docker rm resilios-backup-files
    Copy-Item .env "$backup/.env"
    docker compose -f compose.windows.yml up -d

Guardar la carpeta completa en otro dispositivo protegido. No copiar directamente los archivos internos de PostgreSQL como respaldo.

## Restauración en un equipo nuevo
Usar el mismo código y PostgreSQL 17. Copiar el .env respaldado al proyecto. Restaurar sobre volúmenes nuevos y vacíos, antes del primer arranque de Rails. Reemplazar RUTA_RESPALDO por la carpeta real.

    docker compose -f compose.windows.yml build app
    docker compose -f compose.windows.yml up -d --wait db
    docker compose -f compose.windows.yml cp "RUTA_RESPALDO/database.sql" db:/tmp/resilios.sql
    docker compose -f compose.windows.yml exec -T db psql -U resilios -d postgres -f /tmp/resilios.sql
    docker compose -f compose.windows.yml create app
    docker compose -f compose.windows.yml cp "RUTA_RESPALDO/storage.tar.gz" app:/rails/storage/restore.tar.gz
    docker compose -f compose.windows.yml run --rm --no-deps --entrypoint tar app -xzf /rails/storage/restore.tar.gz -C /rails/storage
    docker compose -f compose.windows.yml up -d

El rol resilios puede reportar que ya existe por la inicialización de PostgreSQL; revisar cualquier otro error antes de seguir. Comprobar usuarios, ventas, inventario y logo. Ensayar la restauración en una instalación aparte antes de depender del respaldo.

## Actualizar
Crear el respaldo primero y conservar .env y volúmenes.

    docker compose -f compose.windows.yml stop app
    git pull --ff-only
    docker compose -f compose.windows.yml up -d --build

Las migraciones se ejecutan al arrancar. Restaurar una imagen anterior no revierte cambios de base.