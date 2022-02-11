#' Build rOpenSci packages.json
#'
#' @param out_file where to save the JSON file
#'
#' @export
#'
build_ropensci_packages_json <- function(out_file = "packages.json") {

  # packages from our organizations
  hosted_packages <- get_hosted_packages()

  # packages from elsewhere or with not standard repo structure
  other_packages <- get_other_packages()

  # merge all --------------------------------------------------------------------
  packages <- c(hosted_packages, other_packages)
  packages <- packages[order(purrr::map_chr(packages, "package"))]
  jsonlite::write_json(
    packages,
    out_file,
    auto_unbox = TRUE,
    pretty= TRUE
  )

}

get_hosted_packages <- function() {

  github_organizations <- c("ropensci", "ropenscilabs")

  excludes <- readLines(system.file("info", "exclude_list.txt", package = "makeregistry"))

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

    purrr::map(
      repos,
      function(repo) {
        list(
          package = repo[["name"]],
          url = repo[["html_url"]],
          branch = repo[["default_branch"]]
        )
      }
    )
  }

  github_organizations |>
    purrr::map(list_organization_repos, excludes = excludes) |>
    unlist(recursive = FALSE)

}

get_other_packages <- function() {

  others <- jsonlite::read_json(system.file("info", "not_transferred.json", package = "makeregistry"))

  format_other_repo <- function(repo) {
    if (grepl("github\\.com", repo[["url"]])) {
      github_info <- remotes::parse_github_url(repo[["url"]])
      gh_repo <- gh::gh(
        "/repos/{owner}/{repo}",
        owner = github_info$username,
        repo = github_info$repo
      )
      default_branch <- gh_repo[["default_branch"]]
    } else {
      default_branch <- NULL
    }

    out <- list(
      package = repo[["package"]],
      url = repo[["url"]]
    )
    if(length(default_branch))
      out$branch = default_branch
    if(length(repo$subdir))
      out$subdir = repo$subdir
    return(out)
  }

  purrr::map(others, format_other_repo)
}
