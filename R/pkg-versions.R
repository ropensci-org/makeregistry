#' Ensure CRAN versions are released on GitHUb
#'
#' @export
registry_pkg_versions <- function () {

}

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
