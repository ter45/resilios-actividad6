# Actividad 6 - ResiliOS POS

## Archivos

- Informe_Actividad6_ResiliOS.pdf: informe técnico de 13 páginas con UML y resultados.
- Presentacion_Actividad6_ResiliOS.pptx: 11 diapositivas editables, con notas de exposición y gráfico editable.
- Guion_video.md: recorrido de exposición y demo de aproximadamente 12 minutos.
- comparacion.csv: resumen de las mediciones; JSON con muestras completas en evidencias.
- diagramas/: fuentes PlantUML editables de componentes, clases, secuencia y actividad.
- evidencias/: métricas, pruebas automatizadas y captura de la demo.
- Prototipo_ResiliOS_Actividad6.zip: código completo del ejercicio con scripts y pruebas.
- ResiliOS_Actividad6.bundle: repositorio Git transportable con la revisión inicial y el commit de la actividad.

## Qué está comprobado

La versión inicial pasó 38 pruebas Rails y 324 comprobaciones. La modificada pasó 46 pruebas y 362 comprobaciones, además de 11 pruebas JavaScript. Zeitwerk validó la carga de constantes. En el navegador se comprobó búsqueda dentro de Granos, paginación 40/40/5, bloqueo del avance en la última página y selección de un producto hacia el carrito.

Los tiempos son de solicitudes de integración en Rails, no de red real ni de tareas humanas. Los tamaños ensayados fueron 100, 1.000 y 10.000 productos sintéticos. El informe conserva las regresiones observadas en algunos casos, especialmente consultas sin resultados.

## Demo en este equipo

La copia ejecutada está en `C:\Users\SOFO\AppData\Local\Temp\resilios-actividad6-20260928`. La copia permanente de código queda en la carpeta `prototipo` de la actividad. Los cambios no se instalaron en el POS original de D:.

La demo escucha en http://127.0.0.1:3036. Usuario exclusivo del laboratorio: `demo.actividad6@example.test`. Clave de demostración: `DemoActividad6!`. No utilizar esta cuenta ni esta base para información real.

Si el servidor se detiene, ejecutar desde la copia del prototipo en PowerShell:

```powershell
.\activity-run.ps1 -RailsArgs @('server','-b','127.0.0.1','-p','3036')
```

Requiere que la base aislada esté iniciada en el puerto 55436. En este equipo se creó en `%TEMP%\resilios-actividad6-pg` con los binarios PostgreSQL existentes del proyecto original. Solo escucha en loopback y contiene datos sintéticos. El script `activity-run.ps1` utiliza las DLL de Ruby/libvips/libyaml ya instaladas en D:; esas dependencias no van incluidas en el ZIP.

## Reproducir en otro equipo

Instalar Ruby compatible con Rails 8.1, Bundler, PostgreSQL 17, Node.js y las dependencias del README del proyecto. El ZIP contiene código, no instaladores ni base de datos. En Windows, adaptar las rutas de `activity-run.ps1` a las DLL disponibles; en otro sistema, ejecutar Rails con las variables equivalentes.

Configurar una instancia PostgreSQL exclusiva para la actividad en `127.0.0.1:55436`, usuario `resilios`, y crear la base `resilios_pos_test`. Usar `RAILS_ENV=test`, `DB_HOST=127.0.0.1`, `DB_PORT=55436`, `DB_USERNAME=resilios` y la contraseña configurada en esa instancia. No apuntar las pruebas a una instalación real.

```powershell
bundle install
# Solo en la base de laboratorio nueva o expresamente descartable:
.\activity-run.ps1 db:schema:load
.\activity-run.ps1 test
node --test test/javascript/search_controller_test.cjs test/javascript/scale_controller_test.cjs
.\activity-run.ps1 zeitwerk:check
```

Para medir, comenzar con la base de laboratorio vacía, antes de cargar la demo. El benchmark verifica entorno test, puerto 55436 y ausencia de productos previos. Cada catálogo se revierte al terminar.

```powershell
$env:ACTIVITY_VARIANT = 'optimized'
.\activity-run.ps1 test script/activity_benchmark.rb
```

Para reproducir la línea base, crear otra copia del repositorio en la revisión `29be809`, copiar únicamente el script de benchmark desde la versión del ejercicio y ejecutar con `ACTIVITY_VARIANT=baseline`. Usar los mismos datos, configuración y condiciones. No volver el repositorio de trabajo atrás ni sobrescribir cambios propios.

Después de medir se puede preparar la demo:

```powershell
.\activity-run.ps1 runner script/activity_demo.rb
.\activity-run.ps1 -RailsArgs @('server','-b','127.0.0.1','-p','3036')
```

Para recuperar el repositorio transportable:

```powershell
git clone ResiliOS_Actividad6.bundle resilios-actividad6
```

## Pendientes de entrega académica

- Confirmar institución, docente y composición del equipo. Solo se proporcionó el nombre JESUS TELMO NENE; la guía indica equipos de 3 a 4 personas.
- Grabar el video, publicarlo en YouTube como no listado e incluir el enlace en el informe y el LMS.
- Publicar el código en el repositorio que corresponda a la entrega y añadir su URL. El bundle conserva un repositorio local; no acredita publicación en GitHub.
- Revisar la fecha límite del LMS y realizar la carga de los archivos.

El PDF es una versión técnica para revisión: no contiene enlaces inventados de video o repositorio ni datos institucionales sin confirmar.
