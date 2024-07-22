#' Ensure CRAN versions are released on GitHUb
#'
#' @export
registry_pkg_versions <- function () {

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
