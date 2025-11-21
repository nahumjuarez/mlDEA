# mlDEA

`mlDEA` es un paquete R que implementa el núcleo de optimización para
evaluar eficiencia técnica bajo tecnología secuencial indirecta.

**Proporciona:**

- un solver DEA input-oriented (CCR), y
- un módulo para construir tecnología secuencial (periodos ≤ t)
  y proyectar una DMU objetivo sobre dicha frontera.

Este bloque corresponde exactamente a los programas lineales usados en
la parte base del índice Malmquist / Malmquist-Luenberger, aunque el
cálculo del índice completo no está incluido en esta versión.

## Problema que resuelve

- Construir la **frontera tecnológica secuencial** hasta un periodo dado  
  (`dea_seq_indirect()` toma todas las observaciones con `tiempo <= periodo`).
- Resolver el **modelo DEA input-oriented clásico** (minimiza `theta`, mantiene los outputs al menos en su nivel observado y permite contraer inputs).
- Reportar métricas clave para analizar **eficiencia técnica**, **lambdas** y la **proyección sobre la frontera** (inputs y outputs proyectados).

## Funciones disponibles

| Función              | Descripción breve                                                                                     |
|----------------------|--------------------------------------------------------------------------------------------------------|
| `solve_dea_input()`  | Resuelve el PL DEA input-oriented dado `x0`, `y0`, `Xref`, `Yref`. Incluye controles básicos de NA/negativos. |
| `dea_seq_indirect()` | Arma la tecnología secuencial a partir de un panel (`tiempo ≤ periodo`) y delega en `solve_dea_input()`.      |

## Resultados que devuelve

Ambas funciones retornan una lista con:

- `theta`: puntaje de eficiencia radial.
- `lambdas`: pesos óptimos.
- `x_opt`: inputs proyectados.
- `y_opt`: outputs proyectados.
- `status`: código del solver.
- `status_message`: explicación del estado del solver.

`dea_seq_indirect()` agrega:

- `reference_data`: subconjunto del panel con tecnología ≤ periodo.
- `target`: registro original de la DMU evaluada.

## Parámetros de saneamiento de datos

- **`na_rm`**: controla si se eliminan referencias con valores NA.  
- **`allow_negative`**: permite o no valores negativos en los datos.

---

## Instalación

Existen dos formas de instalar `mlDEA`:

### 1. Instalación recomendada (desde GitHub)

```r
install.packages("remotes")
remotes::install_github("nahumjuarez/mlDEA")
library(mlDEA)
````
**2. Instalación desde carpeta local**

setwd("ruta/donde/esta/la/carpeta/mlDEA")
install.packages(".", repos = NULL, type = "source")
library(mlDEA)


**Ejemplo mínimo de uso**

library(mlDEA)

# Panel de ejemplo
data_example <- data.frame(
  id   = c("A", "A", "B", "B"),
  year = c(1,   2,   1,   2),
  x1   = c(5,   4,   6,   5),
  y1   = c(10, 11,  9,  10)
)

# Evaluar la DMU "A" en el periodo 2 usando tecnología secuencial indirecta
res <- dea_seq_indirect(
  data        = data_example,
  id_col      = "id",
  time_col    = "year",
  input_cols  = "x1",
  output_cols = "y1",
  dmu_id      = "A",
  period      = 2
)

res$theta      # eficiencia
res$lambdas    # pesos óptimos
res$x_opt      # inputs proyectados
res$y_opt      # outputs proyectados
