.create_cm <- function(pkg, org, old_cm, folder) {
  pkg_name <- gsub(sprintf("%s\\/.*\\/", folder), "", pkg)
  print(pkg_name)

  codemeta_written <- FALSE

  # Find older codemeta entry for this package if available
  if (!is.null(old_cm)) {

    if (length(old_cm[purrr::map_chr(old_cm, "identifier") == pkg_name]) > 0) {
      old_entry <- old_cm[purrr::map_chr(old_cm, "identifier") == pkg_name][[1]]

    } else {
      old_entry <- NULL
    }
  } else {
    old_entry <- NULL
  }

  info <- try(
    codemeta::write_codemeta(
      path = pkg,
      verbose = FALSE,
      file = NULL
    ),
    silent = TRUE
  )

  if (inherits(info, "try-error")) {
    print(info)
    print(toupper(pkg))
    return(old_entry)
  }

  # for other repos, the URLs in DESCRIPTION have to be right
  if (org %in% c("ropensci", "ropenscilabs", "ropensci-archive")) {
    info$codeRepository <- paste0("https://github.com/",
      org, "/", info$identifier)
  }

  if (!is.null(info$codeRepository)) {
    info$readme <- sprintf("%s/blob/HEAD/README.md", info$codeRepository)

    throwaway_readme <- withr::local_tempfile()
    raw_readme <- sub("github", "raw.githubusercontent", info$readme)
    raw_readme <- sub("blob/", "", raw_readme)
    dl <- try(curl::curl_download(raw_readme, throwaway_readme), silent = TRUE)
    if (!inherits(dl, "try-error")) {
      badges <- codemetar::extract_badges(throwaway_readme)

      review_url <- badges[grepl("ropensci/onboarding", badges$link)|grepl("ropensci/software-review", badges$link), "link"]
      review_url <- sub("onboarding", "software-review", review_url)

      if (isTRUE(nzchar(review_url))) {
        info$review <- list(
          "@type" = "Review",
          "url" = review_url,
          "provider" = "https://ropensci.org"
        )
      }

      info$developmentStatus <- badges[grepl("repostatus\\.org", badges$link)|grepl("lifecycle", badges$link), "link"]

    }


  }

  runiv <- jsonlite::read_json(sprintf("https://ropensci.r-universe.dev/packages/%s", info$identifier))
  if (length(runiv) > 0) {
    info$keywords <- unlist(runiv[[length(runiv)]]$`_builder`$gitstats$topics)
  }

  info
}

create_cm <- memoise::memoise(.create_cm)

#' Create the codemetas for all files
#'
#' @param old_cm path to latest CodeMeta file
#' @param folder folder under which the folders with packages are.
#'
#' @return A JSON codemeta
#' @export
create_codemetas <- function(old_cm = NULL, folder = "repos"){
  if(!is.null(old_cm)){
    old_cm <- jsonlite::read_json(old_cm)
    old_cm <- old_cm[lengths(old_cm) > 0]
  }

  list_repos <- function(directory) {
    tibble::tibble(
      folder = dir(file.path(folder, directory), full.names = TRUE),
      org = directory
    )
  }
  folders <- dir(folder) |>
    purrr::map_df(list_repos) |>
    dplyr::rowwise() |>
    dplyr::mutate(is_package = is_package(.data$folder, old_cm))

  packages <- dplyr::filter(folders, is_package)

  purrr::map2(
    packages$folder, packages$org,
    create_cm,
    old_cm = old_cm, folder = folder
  )
}
