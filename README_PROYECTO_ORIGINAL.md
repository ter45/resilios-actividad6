# ResiliOS POS Minimercado

Aplicacion Rails 8.1 con PostgreSQL para productos, clientes, ventas en efectivo y a credito, inventario, abonos, cierres de caja y tickets. Incluye captura de peso manual, Web Serial y un bridge HTTP opcional en el puerto 8088. El bridge y el hardware requieren validacion independiente.

## Desarrollo local en Ubuntu / WSL

Requiere Ruby 3.3 o superior compatible con Rails 8.1, Bundler, compilador, cabeceras de PostgreSQL y libyaml, Docker y Node.js para las pruebas JavaScript. `.ruby-version` y Docker fijan Ruby 3.3.6; el entorno local de esta revision usa Ruby 3.3.8.

Desde la carpeta del repositorio en Ubuntu:

```sh
export BUNDLE_PATH="$HOME/.local/share/resilios-bundle"
export DB_HOST=127.0.0.1 DB_PORT=55432
export DB_USERNAME=resilios DB_PASSWORD=resilios_dev
bundle install
```

En Ubuntu con Ruby empaquetado por la distribucion, el ejecutable puede llamarse `bundle3.3`. Evitar el ejecutable de Ruby de Windows que WSL puede heredar en PATH.

Crear la base local una sola vez (credenciales exclusivas de desarrollo):

```sh
docker run -d --name resilios-dev-db \
  -e POSTGRES_USER=resilios -e POSTGRES_PASSWORD=resilios_dev \
  -e POSTGRES_DB=resilios_pos_development \
  -p 127.0.0.1:55432:5432 \
  -v resilios_dev_pgdata:/var/lib/postgresql/data postgres:17-alpine
```

Si ya existe el contenedor, usar `docker start resilios-dev-db`. El volumen conserva sus datos.

```sh
bundle exec rails db:prepare
bundle exec rails tailwindcss:build
bundle exec rails server -b 127.0.0.1 -p 3020
```

Abrir http://localhost:3020. Los seeds de desarrollo crean `admin@resilios.local` con clave `admin123456` y `cajero.a@resilios.local` con clave `cajero123`. No usar esas cuentas ni claves en produccion.

## Pruebas

Con las mismas variables de conexion:

```sh
RAILS_ENV=test bundle exec rails db:prepare
bundle exec rails test
node test/javascript/scale_controller_test.cjs
bundle exec rails zeitwerk:check
```

Las pruebas Rails utilizan `resilios_pos_test`; no apuntarlas a una base con datos reales. Las pruebas JavaScript verifican el controlador de peso sin una balanza fisica.

## Pendientes de verificacion

- Permisos de ventas suspendidas, abonos y cierres en los controladores POS.
- Concurrencia en numeracion de ventas, reservas, anulaciones y abonos.
- Reanudacion de ventas por peso y conservacion de sus datos.
- Impresora, bridge de hardware, despliegue y restauracion de respaldos.
## Administracion de usuarios

Entrar con una cuenta administradora y abrir **Sistema > Usuarios**. El modulo permite crear administradores y cajeros, buscar por nombre o correo, filtrar por rol o estado y editar cuentas. Los cajeros requieren terminal A o B.

Al editar, dejar ambos campos de contrasena vacios conserva la clave actual. Desactivar una cuenta impide el acceso, incluidas las sesiones existentes, y conserva el historial. Un administrador no puede desactivar su propia cuenta ni quitarse su rol desde este modulo. No hay eliminacion de usuarios.

Las pruebas de acceso, creacion, edicion y desactivacion estan en `test/integration/admin_users_test.rb`.

## Logo del negocio

En Sistema > Configuración, seleccionar un archivo PNG, JPG o WebP de hasta 2 MB y guardar. El formulario muestra el logo guardado y permite reemplazarlo. Guardar sin seleccionar otro archivo conserva el logo actual. Los archivos se guardan mediante Active Storage en storage/; respaldar este directorio junto con la base de datos. Ejecutar las migraciones al actualizar una instalación existente. El logo se imprime al inicio del ticket ESC/POS como imagen monocromática, ajustada al papel de 58 u 80 mm. Requiere libvips y una impresora compatible con GS v 0; la salida en papel depende del modelo y del bridge. Referencia: https://download4.epson.biz/sec_pubs/pos/reference_en/escpos/gs_lv_0.html

## Catalogo de granja

El seed predeterminado carga ocho categorias y 26 productos para aves, bovinos, porcinos, equinos, ovinos y caprinos, conejos, granos y forrajes, y accesorios. Para actualizar una instalacion existente sin volver a cargar usuarios ni clientes:

```sh
bundle exec rails runner script/seed_farm_catalog.rb
```

Los productos nuevos tienen precios sinteticos entre 1.800 y 110.000 COP, costo del 75% del precio y existencias de 20 unidades o 100 kg para granel. Son datos de demostracion, no cotizaciones ni inventario real. El impuesto sigue en cero, pendiente de configurar; no representa una clasificacion tributaria. El seed completa los registros anteriores solo cuando precio, costo y stock estan todos en cero. No repone productos agotados con precio configurado. No se inventan codigos de barras. Los productos a granel usan kilogramos.

El seed es repetible: identifica por SKU y conserva precios, existencias, impuestos y cambios de los productos ya creados. Desactiva los productos originales de demostracion por nombre y SKU, sin borrarlos ni cambiar ventas historicas. Conserva otros productos. Solo desactiva categorias anteriores que ya no tengan productos activos. El archivo db/seeds/products.rb se conserva como referencia del catalogo original y no se carga desde db:seed.
## Windows nativo

Validado localmente con RubyInstaller 3.4.6 x64, PostgreSQL 17.11 para Windows y libvips 8.18.6. El servidor y la base funcionan sin WSL ni Docker. Requiere RubyInstaller con Devkit y Ruby en PATH; Node.js solo es necesario para las pruebas JavaScript.

En PowerShell, desde la carpeta del proyecto:

```powershell
.\script\windows\install-dependencies.ps1
.\script\windows\setup.ps1
.\script\windows\start.ps1
```

Abrir http://localhost:3021. El servidor se inicia oculto y escucha solo en el equipo local. PostgreSQL usa 127.0.0.1:55433. Los registros estan en log/windows-server.out.log, log/windows-server.err.log y log/windows-postgres.log.

```powershell
.\script\windows\test.ps1
.\script\windows\stop.ps1
```

Los binarios se descargan desde EDB (enlazado por https://www.postgresql.org/download/windows/), el repositorio oficial de libvips https://github.com/libvips/build-win64-mxe y MSYS2 https://packages.msys2.org/packages/mingw-w64-ucrt-x86_64-libyaml. Las dependencias se guardan en vendor/windows, excluido de Git. El instalador valida el SHA256 publicado de libyaml. RubyInstaller usa RUBY_DLL_PATH para cargar las DLL; environment.ps1 configura ese valor.

La base nativa se guarda en storage/windows-postgres. La clave local generada se guarda en config/windows.local.ps1, excluido de Git. Conservarla; no subirla al repositorio. Para respaldo de datos usar pg_dump y copiar storage (adjuntos) y la configuracion local. No copiar una base PostgreSQL activa como respaldo. setup.ps1 no migra automaticamente instalaciones anteriores de WSL: esa transferencia se hace mediante pg_dump/pg_restore a una base nueva.

### Impresion en Windows

Instalar en Windows el controlador de cada impresora. Al cobrar con la opcion de ticket marcada, el POS abre el ticket guardado. Tambien se puede abrir desde Ventas > Ver > Imprimir ticket (Windows / termica).

- EPSON L3110: seleccionar EPSON / hoja A4, pulsar Imprimir y elegir EPSON L3110 en el dialogo del navegador.
- Termica: elegir Termica 58 mm o Termica 80 mm, pulsar Imprimir y seleccionar la impresora con ese papel en su controlador.
- Usar escala 100 %, margenes adecuados al papel y desactivar encabezados y pies del navegador.
- El logo se incluye en ambos formatos. No hace falta el bridge del puerto 8088 para esta modalidad.
- Chrome o Edge de Windows muestran el dialogo estandar. Algunos navegadores embebidos no exponen la impresion; en ese caso abrir la misma URL en Chrome o Edge.
- Cancelar la impresion no anula ni repite la venta. El sistema no afirma que el papel salio: eso depende del controlador y la impresora.

La descarga ESC/POS se conserva para integraciones directas existentes; requiere hardware compatible y no debe enviarse como RAW a la EPSON L3110. El usuario confirmó la impresión física correcta en esta versión.
## Windows 11 con Docker

Consultar [instalación y respaldo](INSTALACION_DOCKER_WINDOWS_11.md).

## Accesos para Windows con Docker

Comenzar por [EMPEZAR_AQUI.md](EMPEZAR_AQUI.md). Ejecutar Instalar.cmd con Docker Desktop abierto.
