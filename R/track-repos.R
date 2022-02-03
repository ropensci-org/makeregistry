#' Clone all ropensci packages & create `"last_commits.csv"`
#'
#' @export
#'
track_repos <- function() {
  dir.create(file.path("repos", "ropensci"), recursive = TRUE)
  dir.create(file.path("repos", "ropenscilabs"), recursive = TRUE)
  dir.create(file.path("repos", "others"), recursive = TRUE)
  packages <- jsonlite::read_json("https://raw.githubusercontent.com/ropensci/roregistry/gh-pages/packages.json")
  commits <- purrr::map_df(packages[1:10], clone_repo)
  write.csv(commits, file = "last_commits.csv", row.names = FALSE)
}

track_repo <- function(repo) {
  withr::local_dir(guess_folder(repo))
  # TODO: use gert when it becomes possible
  system(sprintf("git clone --depth 1 %s", repo[["url"]]))

  tibble::tibble(
    name = repo[["package"]],
    date_last_commit = gert::git_log(max = 1, repo = path)
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
