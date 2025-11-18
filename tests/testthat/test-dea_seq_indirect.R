test_that("dea_seq_indirect reproduce simple sequential DEA result", {
  panel <- data.frame(
    id = c("A", "A", "B", "B"),
    year = c(1, 2, 1, 2),
    x1 = c(5, 4, 6, 5),
    y1 = c(10, 11, 9, 10)
  )

  res <- dea_seq_indirect(
    data = panel,
    id_col = "id",
    time_col = "year",
    input_cols = "x1",
    output_cols = "y1",
    dmu_id = "A",
    period = 2
  )

  expect_equal(res$theta, 1)
  expect_equal(res$x_opt, 4)
  expect_equal(res$y_opt, 11)
  expect_equal(sum(res$lambdas), 1, tolerance = 1e-8)
})

test_that("na_rm removes incomplete references and guard against negatives", {
  panel <- data.frame(
    id = c("A", "A", "B"),
    year = c(1, 2, 1),
    x1 = c(5, 4, NA),
    y1 = c(10, 11, 9)
  )

  expect_error(
    dea_seq_indirect(
      data = panel,
      id_col = "id",
      time_col = "year",
      input_cols = "x1",
      output_cols = "y1",
      dmu_id = "A",
      period = 2
    ),
    "contienen NA"
  )

  panel_neg <- panel
  panel_neg$x1[1] <- -1

  expect_error(
    dea_seq_indirect(
      data = panel_neg,
      id_col = "id",
      time_col = "year",
      input_cols = "x1",
      output_cols = "y1",
      dmu_id = "A",
      period = 2,
      na_rm = TRUE
    ),
    "valores negativos"
  )
})
