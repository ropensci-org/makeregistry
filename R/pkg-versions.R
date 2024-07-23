# Functions to extract version numbers of packages, both from CRAN and latest
# GitHub releases.

check_pkg_version_path <- function () {
    cm_path <- normalizePath (file.path ("raw_cm.json"), mustWork = FALSE)

    if (!file.exists (cm_path)) {
        stop (
            "This function can only be run in the ",
            "output directory of 'roregistry', which ",
            "must contain the 'raw_cm.json' file.",
            call. = FALSE
        )
    }

    return (cm_path)
}

#' Extract data on releases of packages, both on CRAN and GitHub.
#'
#' @param CRAN_only If `TRUE`, return only those rows of `repo_data` which
#' correspond to packages which are or were on CRAN; otherwise return all data.
#' @return A `data.frame` with one row for each package, and columns containing
#' information on the package including dates and version numbers of GitHub and
#' CRAN releases (if any).
#'
#' @export
registry_pkg_versions <- function (CRAN_only = TRUE) {

    cm_path <- check_pkg_version_path ()

    # Code from list-packages.R to get all pkgs:
    hosted_packages <- get_hosted_packages()
    other_packages <- get_other_packages()
    packages <- c(hosted_packages, other_packages)
    packages <- packages[order(purrr::map_chr(packages, "package"))]
    packages <- lapply (packages, function (i) i [c ("package", "url", "branch")])
    packages <- data.frame (do.call (rbind, lapply (packages, unlist)))

    ptn <- "^https\\:\\/\\/github\\.com\\/|\\/.*$"
    packages$org <- gsub (ptn, "", packages$url)
    packages$repo <- gsub ("^.*\\/", "", packages$url)
    # All "official" packages are in "ropensci" only:
    index <- which (grepl ("ropensci|r-lib", packages$org) & packages$org != "ropensci")
    packages <- packages [-index, ]
    packages_other <- packages [which (!packages$org == "ropensci"), c ("org", "repo")]

    packages_other_dat <- apply (packages_other, 1, function (i) {
        get_pkg_release_data (org = as.character (i [1]), repo = as.character (i [2]))
    })
    packages_other_dat <- do.call (rbind, packages_other_dat)

    rbind (get_pkg_releases_data ("ropensci"), packages_other_dat) |>
        add_pkg_name (cm_path) |>
        add_CRAN_version (CRAN_only = CRAN_only)
}

#' Main function to extract and collate data on package releases, both on
#' GitHub and CRAN.
#'
#' @param org Name of GitHub organization for which data are to be extracted.
#' @param n Number of entries returned from a single queries. Queries are run
#' until all data are extracted, so this parameter has no effect, and should
#' not be modified.
#' @return A `data.frame` of package data.
#'
#' @noRd
get_pkg_releases_data <- function (org = "ropensci", n = 100L) {

    q <- get_releases_query (org = org, n = n)
    dat <- gh::gh_gql (query = q)
    page_info <- dat$data$repositoryOwner$repositories$pageInfo
    repo_data <- dat$data$repositoryOwner$repositories$nodes
    while (page_info$hasNextPage) {
        q <- get_releases_query (org = org, n = n, end_cursor = page_info$endCursor)
        dat <- gh::gh_gql (query = q)
        page_info <- dat$data$repositoryOwner$repositories$pageInfo
        repo_data <- c (repo_data, dat$data$repositoryOwner$repositories$nodes)
    }

    return (repo_data_to_df (repo_data))
}

get_pkg_release_data <- function (org = "ropensci", repo = "") {

    q <- get_single_release_query (org = org, repo = repo)
    dat <- gh::gh_gql (query = q)

    repo_data_to_df (list (dat$data$repository))
}

#' Convert GitHub graphql list data to a flat `data.frame`.
#'
#' @param repo_data A list returned directly from `gh::gh_gql`.
#' @return The input data converted into a flat `data.frame`.
#'
#' @noRd
repo_data_to_df <- function (repo_data) {

    do.call (rbind, lapply (repo_data, function (i) {

        nodes <- i$releases$nodes

        if (length (nodes) == 0L) {
            node1 <- list (
                author = list (email = NA_character_, login = NA_character_),
                name = NA_character_,
                publishedAt = NA_character_,
                isLatest = NA_character_,
                isPrerelease = NA_character_,
                tagName = NA_character_
            )
        } else {
            node1 <- nodes [[1]]
        }

        data.frame (
            name = i$name,
            url = i$url,
            author_email = node1$author$email,
            author_login = node1$author$login,
            name = null_na (node1$name),
            publishedAt = null_na (node1$publishedAt),
            isLatest = null_na (node1$isLatest),
            isPrerelease = null_na (node1$isPrerelease),
            tagName = null_na (node1$tagNam)
        )
    }))
}

#' Construct the GitHub graphql query to extract data on releases for an entire
#' GitHub organization.
#'
#' @param org Name of GitHub organization for which data are to be extracted.
#' @param n Number of entries returned from a single queries. Queries are run
#' until all data are extracted, so this parameter has no effect, and should
#' not be modified.
#' @return A complex nested list of results.
#'
#' @noRd
get_releases_query <- function (org = "ropensci", n = 100, end_cursor = NULL) {

    after_txt <- ""
    if (!is.null (end_cursor)) {
        after_txt <- paste0 (", after:\"", end_cursor, "\"")
    }

    q <- paste0 ("{
        repositoryOwner(login:\"", org, "\") {
            ... on Organization {
                repositories (first: ", n, after_txt, "){
                    pageInfo {
                        hasNextPage
                        endCursor
                    }
                    nodes {
                        name
                        url
                        releases(first: 1, orderBy: {field: CREATED_AT, direction: DESC}) {
                            nodes {
                                author {
                                    email
                                    login
                                }
                                name
                                createdAt
                                isLatest
                                isPrerelease
                                publishedAt
                                tagName
                            }
                        }
                    }
                }
            }
        }
    }")

    return (q)
}

#' Modified version of `get_releases_query` for single repo only.
#'
#' @param org Name of GitHub organization for which data are to be extracted.
#' @param repo Name of GitHub repository for which data are to be extracted.
#' @return A complex nested list of results.
#'
#' @noRd
get_single_release_query <- function (org = "ropensci", repo = "") {

    q <- paste0 ("{
        repository(owner:\"", org, "\", name:\"", repo, "\") {
            name
            url
            releases(first: 1, orderBy: {field: CREATED_AT, direction: DESC}) {
                nodes {
                    author {
                        email
                        login
                    }
                    name
                    createdAt
                    isLatest
                    isPrerelease
                    publishedAt
                    tagName
                }
            }
        }
    }")

    return (q)
}

#' Add actual package names to `repo_data`, which need not necessarily be
#' identical to repository names.
#'
#' @param repo_data `data.frame` of repository data.
#' @param cm_path Result of `check_pkg_version_path` function, as path to
#' `raw_cm.json` file stored in `roregistry` repository.
#' @return Input `data.frame` with additional column of "pkg_name" appended.
#'
#' @noRd
add_pkg_name <- function (repo_data, cm_path) {

    identifier <- codeRepository <- NULL # suppress no visible binding msgs

    cm <- jsonlite::read_json (cm_path, simplifyVector = TRUE) |>
        dplyr::select (identifier, codeRepository) |>
        dplyr::rename (pkg_name = identifier, url = codeRepository)
    dplyr::left_join (repo_data, cm, by = "url")
}

#' Add current CRAN version identifier to `repo_data`.
#'
#' @param repo_data `data.frame` of repository data.
#' @param CRAN_only If `TRUE`, return only those rows of `repo_data` which
#' correspond to packages which are or were on CRAN; otherwise return all data.
#'
#' @return Input `data.frame` with additional column of "Version" appended, and
#' potentially including only those rows which describe packages on CRAN.
#'
#' @noRd
add_CRAN_version <- function (repo_data, CRAN_only = TRUE) {

    Package <- Version <- NULL # suppress no visible binding msgs

    ap <- data.frame (utils::available.packages ()) |>
        dplyr::select (Package, Version) |>
        dplyr::rename (pkg_name = Package)
    repo_data <- dplyr::left_join (repo_data, ap, by = "pkg_name")
    if (CRAN_only) {
        repo_data <- dplyr::filter (repo_data, !is.na (Version))
    }
    return (repo_data)
}
