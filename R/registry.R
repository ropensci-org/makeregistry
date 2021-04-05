#' @importFrom rlang .data
get_review <- function(entry) {
  if (!is.null(entry$review)) {
    if (grepl("ropensci\\/onboarding|ropensci\\/software-review",
              entry$review$url)
    ) {
      entry$review$url
    } else {
      ""
    }
  } else {
    ""
  }
}

get_maintainer <- function(entry) {
  maintainer <- entry$maintainer[[1]]
  if (maintainer$`@type` == "Organization") {
    toString(maintainer$name)
  } else {
    if (length(maintainer$givenName) > 1) {
      maintainer$givenName <- paste(maintainer$givenName[1],
                                    maintainer$givenName[2])
    }
    paste(maintainer$givenName, maintainer$familyName)
  }
}

get_keywords <- function(entry) {
  keywords <- unlist(entry$keywords)
  keywords <- keywords[!keywords %in% c("r", "rstats", "r-package")]
  if (length(keywords > 0)) {
    toString(sort(keywords))
  } else {
    ""
  }
}

get_coderepo <- function(entry) {
  if (!is.null(entry$codeRepository)) {
    gsub("\\#.*", "", entry$codeRepository)
  } else {
    ""
  }
}

get_status <- function(entry) {
  if (!is.null(entry$developmentStatus)) {
    status <- unlist(entry$developmentStatus)
    status <- status[grepl("repostatus", status)]
    if (length(status) > 0) {
      status <- status
    } else {
      status <- guess_status(entry)
    }
  } else {
    status <- guess_status(entry)
  }
  status <- gsub("http(s)?\\:\\/\\/www\\.repostatus\\.org\\/\\#",
                 "https://www.repostatus.org#", status)
  return(status)
}

guess_status <- function(entry) {
  if (!"codeRepository" %in% names(entry)) {
    return("")
  }

  if (grepl("ropenscilabs", entry$codeRepository)) {
    return("https://www.repostatus.org/#concept")
  }

  if(grepl("ropensci-archive", entry$codeRepository)) {
    return("https://www.repostatus.org/#unsupported")
  }

  return("https://www.repostatus.org/#active")
}

get_cran <- function(pkg, cran) {
  pkg %in% cran
}

get_bioc <- function(pkg, bioc_names) {
  pkg %in% bioc_names
}

github_archived <- function(org) {
  token <- Sys.getenv("GITHUB_GRAPHQL_TOKEN")
  con <- ghql::GraphqlClient$new(
    url = "https://api.github.com/graphql",
    headers = list(Authorization = paste0("Bearer ", token))
  )

  qry <- ghql::Query$new()
  query_first <- '{
    repositoryOwner(login:"%s") {
      repositories(first: 100, isFork:false) {
        edges {
          node {
            name
            isArchived
          }
        }
        pageInfo {
          startCursor
          hasNextPage
          endCursor
        }
      }
    }
  }'
  qry$query('first', sprintf(query_first, org))

  query_cursor <- '
  query($cursor: String) {
    repositoryOwner(login:"%s") {
      repositories(first: 100, isFork:false, after:$cursor) {
        edges {
          node {
            name
            isArchived
          }
        }
        pageInfo {
          startCursor
          hasNextPage
          endCursor
        }
      }
    }
  }'
  qry$query('cursor', sprintf(query_cursor, org))

  x <- con$exec(qry$queries$first)
  res1 <- jsonlite::fromJSON(x)
  pag <- res1$data$repositoryOwner$repositories$pageInfo
  has_next_page <- pag$hasNextPage
  cursor <- pag$endCursor

  out <- list(res1$data$repositoryOwner$repositories$edges)

  if (!is.null(has_next_page)) {
    i <- 1
    while (has_next_page) {
      i <- i + 1
      # cat(i, sep = "\n")
      variable <- list(cursor = cursor)
      xx <- con$exec(qry$queries$cursor, variables = variable)
      res_next <- jsonlite::fromJSON(xx)
      out[[i]] <- res_next$data$repositoryOwner$repositories$edges
      has_next_page <- res_next$data$repositoryOwner$repositories$pageInfo$hasNextPage
      cursor <- res_next$data$repositoryOwner$repositories$pageInfo$endCursor
    }
  }

  tibble::as_tibble(dplyr::bind_rows(out)$node)
}

get_cran_archived <- function() {
  x <- "http://crandb.r-pkg.org/-/archivals"
  z <- crul::HttpClient$new(x)$get()
  w <- tibble::as_tibble(jsonlite::fromJSON(z$parse("UTF-8"))$package)
  dplyr::select(w, .data$Package, .data$Type)
}
is_cran_archived <- function(x, y) x %in% y

is_staff <- function(maintainer, pkg_name, staff, folder = folder) {
  # from pkgdown
  path_first_existing <- function(...) {
  paths <- fs::path(...)
  for (path in paths) {
    if (fs::file_exists(path))
      return(path)
  }

  NULL
}

  path <- path_first_existing(paste0(dir(folder, full.names = TRUE), "/", pkg_name))

  rbuildignore <- suppressWarnings(
    try(
      readLines(
        file.path(path, ".Rbuildignore")
      ),
      silent = TRUE
    )
  )

  if (inherits(rbuildignore, "try-error")) {
    rbuildignore <- ""
  }

  ".ropensci" %in% rbuildignore || maintainer %in% staff
}

get_type <- function(status) {
  if (grepl("concept", status) || grepl("wip", status)) {
    return("experimental")
  }
  if (grepl("abandoned", status) || grepl("unsupported", status)) {
    return("archived")
  }
  return("active")
}

#' Title
#'
#' @export
#' @param cm Path to the JSON codemeta
#' @param outpat Path where to save the JSON
#' @param time Time to add at the end
#' @importFrom ghql GraphqlClient Query
#' @importFrom crul HttpClient
#' @importFrom readr read_csv
create_registry <- function(cm, outpat, time = Sys.time(), folder = "repos") {
  registry <- jsonlite::read_json(cm)
  registry <- registry[lengths(registry) > 0]

  website_info <- tibble::tibble(
    name = purrr::map_chr(registry, "identifier"),
    description = purrr::map_chr(registry, "name"),
    details = purrr::map_chr(registry, "description"),
    maintainer = purrr::map_chr(registry, get_maintainer),
    keywords = purrr::map_chr(registry, get_keywords),
    github = purrr::map_chr(registry, get_coderepo),
    status = purrr::map(registry, get_status),
    onboarding = purrr::map(registry, get_review))

  available_packages <- memoise::memoise(utils::available.packages)
  cran <- available_packages()[,1] %>% as.character()
  cran <- cran[cran != "dashboard"]

  repos <- c(
    BioCsoft = "https://bioconductor.org/packages/release/bioc",
    BioCann = "https://bioconductor.org/packages/release/data/annotation",
    BioCexp = "https://bioconductor.org/packages/release/data/experiment")


  bioc_names <- rownames(available_packages(repos = repos))

  website_info$on_cran <- purrr::map(website_info$name,
                                     get_cran, cran)

  website_info$on_bioc <- purrr::map(website_info$name,
                                     get_bioc, bioc_names)

  website_info$type <- purrr::map_chr(website_info$status,
                                      get_type)

  website_info$url <- website_info$github

  website_info$description <- sub(".*\\:", "", website_info$description)
  website_info$description <- trimws(website_info$description)

  # add categories
  category_info <- readr::read_csv(
    system.file(file.path("scripts", "final_categories.csv"),
                package = "makeregistry"))
  website_info <- dplyr::left_join(website_info, category_info, by = "name")

  # add last commit dates
  if (file.exists("last_commits.csv")) {
    last_commits <- readr::read_csv("last_commits.csv")
    website_info <- dplyr::left_join(website_info, last_commits, by = "name")
  }

  # github archived?
  ga <- dplyr::bind_rows(
    lapply(c("ropensci", "ropenscilabs"), github_archived))
  website_info <- dplyr::left_join(website_info, ga, by = "name")
  website_info <- dplyr::rename(website_info, github_archived = .data$isArchived)

  # cran archived?
  ca <- get_cran_archived()
  website_info$cran_archived <- purrr::map(
    website_info$name, is_cran_archived, ca$Package)

  # staff maintained?
  staff <- readLines(system.file("scripts/staff.csv", package = "makeregistry"),
                     encoding = "UTF-8")
  website_info$staff_maintained <- purrr::map2(
    website_info$maintainer, website_info$name, is_staff, staff,
    folder = folder)

  website_info <- dplyr::rowwise(website_info)
  list(
    packages = website_info,
    date = format(time, format = "%F %R %Z", tz = "UTC")) %>%
    jsonlite::toJSON(auto_unbox = TRUE, pretty = TRUE) %>%
    writeLines(outpat, useBytes = TRUE)
}
