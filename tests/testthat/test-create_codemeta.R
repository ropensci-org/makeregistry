test_that("create_codemeta works", {
  tmp <- tempdir(check = TRUE)

  cm <- create_codemetas(folder = testthat::test_path("packages"))

  change_runtimePlatform <- function(cm) {
    cm$runtimePlatform <- "Rrrr"
    cm
  }

  cm <- lapply(cm, change_runtimePlatform)
  jsonlite::write_json(
      cm,
      file.path(tmp, "raw_cm.json"),
      pretty = TRUE,
      auto_unbox = TRUE
    )

  testthat::expect_snapshot_file(file.path(tmp, "raw_cm.json"))

  dir.create(file.path(tmp, "packages"))
  file.copy(
    testthat::test_path("packages"),
    tmp,
    recursive = TRUE)

  # case where the package source is no longer ok, use previous entry
  file.remove(file.path(tmp, "packages", "ropensci", "pkg1", "NAMESPACE"))

  cm2 <- create_codemetas(
      old_cm = file.path(tmp, "raw_cm.json"),
      folder = file.path(tmp, "packages")
    )
  change_runtimePlatform <- function(cm) {
    cm$runtimePlatform <- "Rrrr"
    cm
  }

  cm2 <- lapply(cm2, change_runtimePlatform)
  jsonlite::write_json(
      cm2,
      file.path(tmp, "cm2.json"),
      pretty = TRUE,
      auto_unbox = TRUE
    )

  testthat::expect_snapshot_file(file.path(tmp, "cm2.json"))
})
