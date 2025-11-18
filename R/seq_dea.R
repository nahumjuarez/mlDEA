#' Sequential DEA (Input-Oriented, Tecnologia Secuencial Indirecta)
#'
#' Construye la tecnologia secuencial (usa todas las observaciones con
#' `time_col <= period`) y resuelve el modelo DEA CCR input-oriented asociado.
#' Es el bloque basico utilizado para calcular indices Malmquist-Luenberger,
#' aunque el indice completo no esta implementado en este paquete.
#'
#' @param data `data.frame` o `tibble` con el panel completo.
#' @param id_col Nombre de la columna que identifica la DMU.
#' @param time_col Nombre de la columna con el tiempo o periodo.
#' @param input_cols Vector de columnas que representan inputs (>= 1).
#' @param output_cols Vector de columnas que representan outputs (>= 1).
#' @param dmu_id Identificador de la DMU objetivo.
#' @param period Periodo de evaluacion; se consideran referencias con tiempo <= `period`.
#' @param na_rm Si es `TRUE`, elimina observaciones de referencia con NA (la DMU
#'   objetivo debe estar completa). Si es `FALSE`, lanza error ante cualquier NA.
#' @param allow_negative Indica si se permiten valores negativos en inputs/outputs.
#'   Por defecto (`FALSE`) se lanza error si se detectan valores < 0.
#'
#' @return Lista con `theta`, `lambdas`, `status`, `status_message`, `x_opt`,
#'   `y_opt`, `reference_data` (panel usado) y `target` (registro de la DMU objetivo).
#' @export
#'
#' @examples
#' panel <- data.frame(
#'   id = c("A", "A", "B", "B"),
#'   year = c(1, 2, 1, 2),
#'   x1 = c(5, 4, 6, 5),
#'   y1 = c(10, 11, 9, 10)
#' )
#'
#' dea_seq_indirect(
#'   data = panel,
#'   id_col = "id",
#'   time_col = "year",
#'   input_cols = "x1",
#'   output_cols = "y1",
#'   dmu_id = "A",
#'   period = 2
#' )
#'
#' @importFrom lpSolve lp
#' @importFrom stats complete.cases
#' @seealso [solve_dea_input()]
dea_seq_indirect <- function(data,
                             id_col,
                             time_col,
                             input_cols,
                             output_cols,
                             dmu_id,
                             period,
                             na_rm = FALSE,
                             allow_negative = FALSE) {
  stopifnot(is.data.frame(data))

  required_cols <- c(id_col, time_col, input_cols, output_cols)
  if (!all(required_cols %in% names(data))) {
    stop("Faltan columnas requeridas en 'data'.")
  }

  # Tecnologia secuencial: observaciones con tiempo <= period
  ref_data <- data[data[[time_col]] <= period, , drop = FALSE]
  if (nrow(ref_data) == 0) {
    stop("No hay observaciones para construir la tecnologia secuencial.")
  }

  # DMU objetivo exacta
  target <- data[data[[id_col]] == dmu_id & data[[time_col]] == period, , drop = FALSE]
  if (nrow(target) == 0) {
    stop("No se encontro la DMU objetivo en el periodo indicado.")
  }
  if (nrow(target) > 1) {
    stop("La combinacion DMU/periodo no es unica.")
  }

  # Validacion de NA en la observacion objetivo siempre estricta
  target_io <- target[, c(input_cols, output_cols), drop = FALSE]
  if (anyNA(target_io)) {
    stop("La DMU objetivo contiene NA en inputs/outputs. Limpia los datos antes de evaluar.")
  }

  # Limpieza opcional de referencias con NA
  refs_io <- ref_data[, c(input_cols, output_cols), drop = FALSE]
  if (na_rm) {
    complete_mask <- stats::complete.cases(refs_io)
    if (!all(complete_mask)) {
      ref_data <- ref_data[complete_mask, , drop = FALSE]
      refs_io <- refs_io[complete_mask, , drop = FALSE]
    }
    if (nrow(ref_data) == 0) {
      stop("No quedan referencias despues de remover NA. Revisa tus datos.")
    }
  } else if (anyNA(refs_io)) {
    stop("Los datos de referencia contienen NA. Usa na_rm = TRUE o limpia manualmente.")
  }

  Xref <- as.matrix(ref_data[, input_cols, drop = FALSE])
  Yref <- as.matrix(ref_data[, output_cols, drop = FALSE])
  x0 <- as.numeric(target[1, input_cols, drop = TRUE])
  y0 <- as.numeric(target[1, output_cols, drop = TRUE])

  res <- solve_dea_input(
    x0 = x0,
    y0 = y0,
    Xref = Xref,
    Yref = Yref,
    na_rm = na_rm,
    allow_negative = allow_negative
  )

  res$reference_data <- ref_data
  res$target <- target
  res
}

#' Resuelve un modelo DEA input-oriented clasico (CCR)
#'
#' @param x0 Vector numerico de inputs para la DMU objetivo (longitud K).
#' @param y0 Vector numerico de outputs para la DMU objetivo (longitud M).
#' @param Xref Matriz N x K con los inputs de referencia.
#' @param Yref Matriz N x M con los outputs de referencia.
#' @param na_rm Si es `TRUE`, elimina filas con NA en `Xref`/`Yref`.
#' @param allow_negative Si es `FALSE`, lanza error cuando hay valores negativos.
#'
#' @details El modelo corresponde a un DEA clasico input-oriented con rendimientos
#'   constantes a escala (CCR). Actualmente no se implementan orientaciones
#'   alternativas ni restricciones adicionales.
#'
#' @return Lista con `theta`, `lambdas`, `status`, `status_message`, `x_opt` y `y_opt`.
#' @export
solve_dea_input <- function(x0,
                            y0,
                            Xref,
                            Yref,
                            na_rm = FALSE,
                            allow_negative = FALSE) {
  Xref <- as.matrix(Xref)
  Yref <- as.matrix(Yref)
  x0 <- as.numeric(x0)
  y0 <- as.numeric(y0)

  if (nrow(Xref) != nrow(Yref)) {
    stop("Xref y Yref deben tener el mismo numero de filas (DMUs).")
  }

  if (!all(is.finite(c(x0, y0)))) {
    stop("x0/y0 deben contener solo valores finitos.")
  }

  # Gestion de NA en matrices de referencia
  combined_ref <- cbind(Xref, Yref)
  if (na_rm) {
    keep_rows <- stats::complete.cases(combined_ref)
    if (!all(keep_rows)) {
      Xref <- Xref[keep_rows, , drop = FALSE]
      Yref <- Yref[keep_rows, , drop = FALSE]
    }
    if (nrow(Xref) == 0) {
      stop("No quedan filas en Xref/Yref despues de remover NA.")
    }
  } else if (anyNA(combined_ref)) {
    stop("Xref/Yref contienen NA. Usa na_rm = TRUE o limpia tus datos.")
  }

  if (!allow_negative && (any(Xref < 0) || any(Yref < 0) || any(x0 < 0) || any(y0 < 0))) {
    stop("Se detectaron valores negativos en inputs/outputs. Ajusta tus datos o usa allow_negative = TRUE.")
  }

  N <- nrow(Xref)
  K <- ncol(Xref)
  M <- ncol(Yref)

  if (length(x0) != K) {
    stop("x0 debe tener la misma longitud que ncol(Xref).")
  }
  if (length(y0) != M) {
    stop("y0 debe tener la misma longitud que ncol(Yref).")
  }

  # Numero de variables: lambdas (N) + theta
  n_var <- N + 1

  # Objetivo: minimizar theta
  obj <- c(rep(0, N), 1)

  # Matriz de restricciones
  A <- matrix(0, nrow = K + M, ncol = n_var)
  dir <- c(rep("<=", K), rep(">=", M))
  rhs <- c(rep(0, K), y0)

  for (k in seq_len(K)) {
    A[k, ] <- c(Xref[, k], -x0[k])
  }

  for (m in seq_len(M)) {
    A[K + m, ] <- c(Yref[, m], 0)
  }

  sol <- lp(
    direction    = "min",
    objective.in = obj,
    const.mat    = A,
    const.dir    = dir,
    const.rhs    = rhs
  )

  status_map <- c(
    `0` = "Solucion optima encontrada",
    `2` = "Modelo es infeasible",
    `3` = "Modelo es no acotado",
    `4` = "Fallo: problemas numericos",
    `5` = "Se alcanzo el limite de iteraciones"
  )
  status_msg <- status_map[as.character(sol$status)]

  if (sol$status != 0) {
    stop(
      sprintf(
        "lpSolve no encontro solucion optima (status %s: %s).",
        sol$status,
        ifelse(is.na(status_msg), "motivo desconocido", status_msg)
      )
    )
  }

  theta <- sol$solution[n_var]
  lambdas <- sol$solution[seq_len(N)]

  x_opt <- as.numeric(t(lambdas) %*% Xref)
  y_opt <- as.numeric(t(lambdas) %*% Yref)

  list(
    theta = theta,
    lambdas = lambdas,
    status = sol$status,
    status_message = unname(status_msg),
    x_opt = x_opt,
    y_opt = y_opt
  )
}
