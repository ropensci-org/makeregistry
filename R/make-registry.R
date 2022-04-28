#' Make `"raw_cm.json"` & `"registry.json"`.
#'
#' @export
#'
make_registry <- function() {
  # cat("clone repos", sep = "\n")
  track_repos(pkgs_file = "packages.json")

  old_cm <- "https://github.com/ropensci/roregistry/blob/gh-pages/raw_cm.json?raw=true"

  # cat("creating codemetas", sep = "\n")
  codemeta <- create_codemetas(old_cm = old_cm)

  # cat("writing json", sep = "\n")
  jsonlite::write_json(
    codemeta,
    path = "raw_cm.json",
    pretty = TRUE,
    auto_unbox = TRUE
  )

  # cat("creating registry", sep = "\n")
  makeregistry::create_registry(
    cm = "raw_cm.json",
    outpat = "registry.json"
  )

  pkgs <- jsonlite::read_json("registry.json")
  n_packages <- length(pkgs$packages)
  if (n_packages < 250) {
    stop(sprintf("Only %s package(s), this is not good. :-(", n_packages))
  }
}
