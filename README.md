# mlDEA

`mlDEA` es un paquete de R para resolver modelos DEA (Data Envelopment Analysis) **input-oriented (CCR)** con **tecnología secuencial indirecta**.  

Su objetivo es proveer el **bloque de optimización** que se necesita en análisis de productividad tipo Malmquist / Malmquist-Luenberger;  
la construcción del índice completo se deja explícitamente para versiones posteriores.

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

Ambas funciones retornan una lista con las siguientes entradas principales:

- `theta`: puntuación de eficiencia radial (≤ 1 para DMUs eficientes, bajo la convención input-oriented).
- `lambdas`: pesos óptimos asignados a las observaciones de referencia.
- `x_opt`: combinación lineal óptima de inputs sobre la frontera secuencial.
- `y_opt`: outputs proyectados sobre la frontera (en input-oriented, coinciden con `y0`).
- `status`: código de salida de `lpSolve::lp()` (0 = solución óptima).
- `status_message`: texto explicando el código de estado del solver.

`dea_seq_indirect()` agrega además:

- `reference_data`: subconjunto del panel usado para construir la tecnología (todas las filas con tiempo ≤ `period`).
- `target`: registro original de la DMU objetivo (útil para verificar inputs/outputs observados).

## Parámetros de saneamiento de datos

- `na_rm` (`FALSE` por defecto):  
  - Si es `TRUE`, las observaciones de referencia con NA se eliminan antes de formar la tecnología  
    (la DMU objetivo siempre debe estar completa).  
  - Si es `FALSE`, se lanza un error si se detectan NA.
- `allow_negative` (`FALSE` por defecto):  
  define si se permiten valores negativos en inputs/outputs. Útil cuando se modelan balances netos,
  emisiones netas, etc.

## Instalación local

```r
# Ubícate en el directorio padre de la carpeta mlDEA
setwd("C:/Users/Nahum Caleb/Documents/Proyectos/Libreria de Malmquist-Luenberger")
install.packages("mlDEA", repos = NULL, type = "source")
