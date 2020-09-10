test_that("create_codemeta works", {
  testthat::expect_snapshot_output(create_codemetas(folder = testthat::test_path("packages")))
})
