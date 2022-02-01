clone_repos <- function() {
  dir.create("ropensci")
  dir.create("ropenscilabs")
  dir.create("others")
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
    return("others")
  }

  org <- remotes::parse_github_url(repo[["url"]])$username
  if (! (org %in% c("ropensci", "ropenscilabs"))) {
    return("others")
  }

  org
}
