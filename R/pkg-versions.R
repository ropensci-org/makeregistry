#' Ensure CRAN versions are released on GitHUb
#'
#' @export
registry_pkg_versions <- function () {

}

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
