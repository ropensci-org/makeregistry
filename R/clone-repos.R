#' Clone all ropensci packages
#'
#' @export
#'
clone_repos <- function() {
  dir.create(file.path("repos", "ropensci"), recursive = TRUE)
  dir.create(file.path("repos", "ropenscilabs"), recursive = TRUE)
  dir.create(file.path("repos", "others"), recursive = TRUE)
  packages <- jsonlite::read_json("https://raw.githubusercontent.com/ropensci/roregistry/gh-pages/packages.json")
  purrr::walk(packages[1:10], clone_repo)
}

clone_repo <- function(repo) {
  withr::local_dir(guess_folder(repo))
  # TODO: use gert when it becomes possible
  system(sprintf("git clone --depth 1 %s", repo[["url"]]))
}

guess_folder <- function(repo) {
  if (!grepl("github\\.com", repo[["url"]])) {
    return(file.path("repos", "others"))
  }

  org <- remotes::parse_github_url(repo[["url"]])$username
  if (! (org %in% c("ropensci", "ropenscilabs"))) {
    return(file.path("repos", "others"))
  }

  return(file.path("repos", org))
}
