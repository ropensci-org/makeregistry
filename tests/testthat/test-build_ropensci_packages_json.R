test_that("build_ropensci_packages_json works", {
  temp_json <- withr::local_tempfile(fileext = ".json")
  build_ropensci_packages_json(out_file = temp_json)
  expect_true(file.exists(temp_json))
  pkgs <- jsonlite::read_json(temp_json)
  expect_true(length(pkgs) > 250)
  expect_snapshot(unique(lapply(pkgs, names)))
})
