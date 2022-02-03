#' Clone all ropensci packages & create `"last_commits.csv"`
#'
#' @param pkgs_file `"packages.json"` file for all rOpenSci packages.
#'
#' @export
#'
track_repos <- function(pkgs_file = "https://raw.githubusercontent.com/ropensci/roregistry/gh-pages/packages.json") {
  dir.create(file.path("repos", "ropensci"), recursive = TRUE)
  dir.create(file.path("repos", "ropenscilabs"), recursive = TRUE)
  dir.create(file.path("repos", "others"), recursive = TRUE)
  packages <- jsonlite::read_json(pkgs_file)
  commits <- purrr::map_df(packages, track_repo)
  write.csv(commits, file = "last_commits.csv", row.names = FALSE)
}

track_repo <- function(repo) {
  withr::local_dir(guess_folder(repo))
  tempf <- withr::local_tempfile()
  # TODO: use gert when it becomes possible
  sys::exec_wait(
    "git",
    args = c("clone", "--depth",  "1", sprintf("%s", repo[["url"]]), repo[["package"]])
  )

  tibble::tibble(
    name = repo[["package"]],
    date_last_commit = as.character(
      gert::git_log(max = 1, repo = repo[["package"]])[["time"]]
    )
  )
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
