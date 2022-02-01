# packages from our organizations ----------------------------------------------

github_organizations <- c(
  "ropensci",
  "ropensci-org",
  "ropensci-review-tools",
  "ropenscilabs"
)

excludes <- readLines(here::here("inst", "info", "exclude_list.txt"))

list_organization_repos <- function(github_organization, excludes) {
  repos <- gh::gh(
    "/orgs/{org}/repos",
    org = github_organization,
    .limit = Inf
  )
  repos <- repos[!purrr::map_lgl(repos, "fork")]
  repos <- repos[!purrr::map_lgl(repos, "private")]
  repos <- repos[!purrr::map_lgl(repos, "archived")]
  repos <- repos[! (purrr::map_chr(repos, "name") %in% excludes)]

  pluck_repo <- function(repo) {

    list(
      package = repo[["name"]],
      url = repo[["html_url"]],
      branch = repo[["default_branch"]]
    )
  }

  purrr::map(repos, pluck_repo)
}

packages <- github_organizations |>
  purrr::map(list_organization_repos, excludes = excludes) |>
  unlist(recursive = FALSE)

# packages from elsewhere ------------------------------------------------------

others <- jsonlite::read_json(here::here("inst", "info", "not_transferred.json"))

format_other_repo <- function(repo) {
  if (grepl("github\\.com", repo[["url"]])) {
    github_info <- remotes::parse_github_url(repo[["url"]])
    gh_repo <- gh::gh(
      "/repos/{owner}/{repo}",
      owner = github_info$username,
      repo = github_info$repo
    )
    branch <- gh_repo[["default_branch"]]
  } else {
    branch <- "master"
  }

  list(
    package = repo[["package"]],
    url = repo[["url"]],
    branch = branch,
    subdir = repo[["subdir"]]
  )
}

other_packages <- purrr::map(others, format_other_repo)

# merge all --------------------------------------------------------------------
packages <- c(packages, other_packages)
packages <- packages[order(purrr::map_chr(packages, "package"))]
jsonlite::write_json(
  packages,
  "packages.json",
  auto_unbox = TRUE,
  pretty= TRUE
)
