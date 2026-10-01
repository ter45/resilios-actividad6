# Actividad 6 — Navegación del catálogo en ResiliOS POS

Trabajo individual de JESUS TELMO NENE para Arquitectura de Software.

El ejercicio mejora la búsqueda del catálogo: conserva la categoría al escribir, separa las búsquedas por nombre y código mediante Strategy, pagina los resultados y agrupa las reservas para calcular disponibilidad.

## Ejecutar la demo con Docker

Requiere Docker Desktop con contenedores Linux. Desde esta carpeta:

```sh
docker compose -f compose.demo.yml up -d --build
```

Abrir http://127.0.0.1:3036/pos. Cuenta exclusiva de demostración: `demo.actividad6@example.test`, contraseña `DemoActividad6!`.

```sh
docker compose -f compose.demo.yml stop
```

La primera construcción descarga Ruby y sus dependencias. La base usa un volumen independiente. Al iniciar se preparan 170 productos sintéticos en Granos y Forrajes. Estas credenciales y la configuración test son únicamente para laboratorio local. No se incluyen clientes del proyecto original, bases de datos, claves Rails ni credenciales de despliegue.

## Recorrido de demostración

Seleccionar Granos, escribir Alimento y recorrer las páginas 1, 2 y 3: 40, 40 y 5 productos. En la última página Siguiente queda deshabilitado. Seleccionar Alimento Granos 081 para incorporarlo al carrito. No es necesario cobrar.

## Código de la mejora

- `app/services/catalog/`: estrategias y servicio de navegación.
- `app/controllers/pos/products_controller.rb`: respuesta paginada y reservas agrupadas.
- `app/javascript/controllers/search_controller.js`: filtros, páginas y respuestas fuera de orden.
- `test/`: pruebas Rails y JavaScript.
- `script/activity_benchmark.rb`: comparación reproducible con datos sintéticos.
- `evidence/`: resultados de la evaluación original.
- `diagramas/`: fuentes UML.

## Evaluación y alcance

La evaluación original en Windows registró 46 pruebas Rails con 362 comprobaciones y 11 pruebas JavaScript. La versión inicial registró 38 pruebas y 324 comprobaciones. Los JSON conservan las mediciones originales; no son mediciones del contenedor Docker. No se midió productividad humana ni carga concurrente de cajeros.

Para ejecutar pruebas desde un entorno de desarrollo, instalar también los grupos test/development de Bundler, preparar una base test exclusiva y ejecutar `bundle exec rails test` y `node --test test/javascript/search_controller_test.cjs test/javascript/scale_controller_test.cjs`. El script de benchmark exige una base de laboratorio vacía en puerto 55436. La imagen de demo omite herramientas de test; no debe usarse como prueba de que toda la suite pasó en Docker.

## Procedencia

Copia académica del proyecto ResiliOS POS, basada en la revisión inicial `29be809` y la implementación de la actividad `372ea3e`. Este repositorio inicia un historial nuevo y contiene la adaptación posterior del arranque en Docker. Las funciones de venta, crédito, inventario y peso pertenecen al proyecto existente.
