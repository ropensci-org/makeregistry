.create_cm <- function(pkg, org, old_cm) {
  codemeta_written <- FALSE
  if (!is.null(old_cm)) {
    if (
      length(old_cm[purrr::map_chr(old_cm, "identifier") ==
      gsub("repos\\/.*\\/", "", pkg)]) > 0
    ) {
      old_entry <- old_cm[purrr::map_chr(old_cm, "identifier") == gsub("repos\\/.*\\/", "", pkg)][[1]]
      if (!file.exists(file.path(pkg, "codemeta.json"))) {
        jsonlite::write_json(old_entry,
                             path = file.path(pkg, "codemeta.json"),
                             pretty = TRUE,
                             auto_unbox = TRUE
                             )
        codemeta_written <- TRUE
      }
    } else {
      old_entry <- NULL
    }
  } else {
    old_entry <- NULL
  }

  info <- try(codemetar::create_codemeta(pkg = pkg, verbose = FALSE,
    force_update = TRUE), silent = TRUE)

  if (codemeta_written) {
    file.remove(file.path(pkg, "codemeta.json"))
  }

  if (!inherits(info, "try-error")) {
    # for other repos, the URLs in DESCRIPTION have to be right
    if (org %in% c("ropensci", "ropenscilabs")) {
      info$codeRepository <- paste0("https://github.com/",
        org, "/", info$identifier)
    }
    return(info)
  } else {
    print(toupper(pkg))
    if (is.null(old_entry)) {
      return(old_entry)
    } else {
      NULL
    }
  }
}
create_cm <- memoise::memoise(.create_cm)

#' Create the codemetas for all files
#'
#' @param old_cm path to latest CodeMeta version
#' @param folder folder under which the
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
  folders <- purrr::map_df(dir(folder), list_repos)

  folders <- dplyr::rowwise(folders)

  folders <- dplyr::mutate(folders, is_package = is_package(.data$folder, old_cm))

  packages <- dplyr::filter(folders, is_package)

  purrr::map2(packages$folder,
              packages$org, create_cm,
              old_cm = old_cm)
}
