# Instalación rápida en Windows 11

1. Instala Docker Desktop con WSL 2 y contenedores Linux; reinicia si lo solicita.
2. Abre Docker Desktop y espera a que esté listo.
3. Clona el repositorio o descarga y extrae el ZIP en una carpeta local, por ejemplo C:\ResiliOS.
4. Haz doble clic en Instalar.cmd. No hace falta instalar Ruby ni PostgreSQL en Windows.
5. Espera: la primera descarga puede tardar varios minutos. Cuando la aplicación responda se abrirá el navegador.

La ventana muestra los errores y permanece abierta al terminar. No cierres Docker Desktop mientras uses el punto de venta.

## Accesos
- Instalar.cmd: genera claves si no existen, construye y arranca.
- Iniciar.cmd: inicia el sistema y abre el navegador.
- Detener.cmd: detiene los contenedores conservando los datos.
- Respaldar.cmd: pausa la aplicación durante la copia y la reanuda si estaba en marcha.
- Actualizar.cmd: requiere Git y una copia clonada sin cambios locales; respalda, descarga con git pull --ff-only, reconstruye y abre el sistema.

La actualización de una copia descargada como ZIP debe hacerse siguiendo la guía técnica. El instalador conserva un .env existente; si está incompleto, muestra el error para corregirlo.

## Primer ingreso
Usuario: admin@resilios.local. Contraseña: admin123456.
Crear el administrador definitivo en Sistema > Usuarios, ingresar con él y desactivar las cuentas de demostración. Crear los cajeros. Configurar datos y logo del negocio. Cambiar precios y existencias sintéticos antes de vender.

## Impresión
Instalar las impresoras en Windows. Usar Edge o Chrome y elegir EPSON / hoja A4 o térmica 58/80 mm en el ticket. Comprobar logo, escala y márgenes.

## Respaldos
Se guardan en backups, cada uno en una carpeta con fecha e identificador. Solo considerar terminado un respaldo que incluya COMPLETO.txt. Copiar toda la carpeta a otro dispositivo protegido: incluye claves y datos del negocio.
checksums.json permite comprobar que los archivos no cambiaron; no sustituye la prueba de restauración.

Para restauración, cambio de puerto y diagnóstico consultar INSTALACION_DOCKER_WINDOWS_11.md. La configuración predeterminada abre http://localhost:3021. Nunca usar docker compose down -v: elimina los datos.