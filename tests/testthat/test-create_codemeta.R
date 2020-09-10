test_that("create_codemeta works", {
  cm <- create_codemetas(folder = testthat::test_path("packages"))
  testthat::expect_snapshot_output(cm)

  tmp <- tempdir(check = TRUE)
  jsonlite::write_json(
    cm,
    path = file.path(tmp, "raw_cm.json"),
    pretty = TRUE,
    auto_unbox = TRUE
    )

  testthat::expect_snapshot_output(
    create_codemetas(
      old_cm = file.path(tmp, "raw_cm.json"),
      folder = testthat::test_path("packages")
      )
    )
})
