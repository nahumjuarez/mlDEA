# mlDEA

Paquete R minimalista para resolver modelos DEA (Data Envelopment Analysis) del
tipo input-oriented (CCR) con tecnología secuencial indirecta
(Malmquist-Luenberger). El objetivo es proveer el bloque de optimización; la
construcción del índice completo quedará para una versión posterior.

## Problema que resuelve

- Construir la frontera tecnológica secuencial hasta un periodo dado
  (`dea_seq_indirect()` toma todas las observaciones con tiempo <= periodo).
- Resolver el modelo DEA input-oriented clásico (minimiza `theta`, mantiene
  outputs al menos en su nivel observado y permite contraer inputs).
- Reportar métricas clave para analizar eficiencia técnica, lambdas y proyección
  sobre la frontera.

## Funciones disponibles

| Función             | Descripción breve                                                                 |
|---------------------|------------------------------------------------------------------------------------|
| `solve_dea_input()` | Resuelve el PL DEA input-oriented dado `x0`, `y0`, `Xref`, `Yref`. Incluye controles de NA/negativos. |
| `dea_seq_indirect()`| Arma la tecnología secuencial a partir de un panel (tiempo ≤ periodo) y delega en `solve_dea_input()`. |

## Resultados que devuelve

Ambas funciones retornan una lista con las siguientes entradas principales:

- `theta`: puntuación de eficiencia (≤ 1 cuando la DMU es eficiente).
- `lambdas`: pesos óptimos asignados a las observaciones de referencia.
- `x_opt`: combinación lineal óptima de inputs sobre la frontera secuencial.
- `y_opt`: outputs proyectados sobre la frontera (idénticos a `y0` en input-oriented).
- `status`: código de salida de `lpSolve::lp()` (0 = solución óptima).
- `status_message`: texto explicando el código de estado del solver.

`dea_seq_indirect()` agrega además:

- `reference_data`: subconjunto del panel usado para construir la tecnología (tiempo <= periodo).
- `target`: registro original de la DMU objetivo (útil para verificar inputs/outputs observados).

## Parámetros de saneamiento de datos

- `na_rm` (`FALSE` por defecto): si es `TRUE`, las referencias con NA se eliminan
  antes de formar la tecnología (la DMU objetivo siempre debe estar completa).
  Si es `FALSE`, se emite un error si se detectan NA.
- `allow_negative` (`FALSE` por defecto): establece si se permiten valores
  negativos en inputs/outputs. Útil cuando se modelan emisiones netas, balances,
  etc.

## Instalación local

```r
# Ubícate en el directorio padre de la carpeta mlDEA
setwd("C:/Users/Nahum Caleb/Documents/Proyectos/Libreria de Malmquist-Luenberger")
install.packages("mlDEA", repos = NULL, type = "source")
```

Dependencias: `lpSolve` debe estar instalado previamente (`install.packages("lpSolve")`).

## Ejemplo de uso

```r
rm(list = ls())
library(mlDEA)

panel <- data.frame(
  id   = c("A", "A", "B", "B"),
  year = c(1,   2,   1,   2),
  x1   = c(5,   4,   6,   5),
  y1   = c(10, 11,  9,  10)
)

res <- dea_seq_indirect(
  data        = panel,
  id_col      = "id",
  time_col    = "year",
  input_cols  = "x1",
  output_cols = "y1",
  dmu_id      = "A",
  period      = 2
)

res$theta    # eficiencia
res$lambdas  # pesos óptimos
res$x_opt    # inputs proyectados
res$y_opt    # outputs proyectados (input-oriented => se mantienen)
```

## Flujo de trabajo recomendado (estilo CRAN)

1. **Documentación con roxygen2**
   ```r
   devtools::document("mlDEA")
   ```
   Esto genera/actualiza `NAMESPACE` y los archivos `man/*.Rd`.

2. **Pruebas automatizadas** (`testthat`):
   ```r
   devtools::test("mlDEA")
   ```

3. **Viñeta**: compila `vignettes/mlDEA.Rmd` con `devtools::build_vignettes()`.

4. **Chequeos completos**:
   ```r
   devtools::check("mlDEA")
   ```
   El paquete debe pasar `R CMD check` sin `ERROR`/`WARNING` y con un número
   mínimo de `NOTE` (idealmente cero).

## Recomendaciones y precauciones

- Asegúrate de que la combinación (`dmu_id`, `period`) sea única en el panel.
- La tecnología secuencial se construye con todos los periodos <= `period`. Si
  prefieres ventanas móviles o tecnologías contemporáneas, filtra el panel antes
  de llamar a `dea_seq_indirect()`.
- Si el solver entrega un `status` distinto de 0, revisa el mensaje
  (`status_message`) para entender el motivo (problema infactible, sin acotar,
  etc.) y ajusta tus datos o modelo.
