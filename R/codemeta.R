.create_cm <- function(pkg, org, old_cm, folder) {
  pkg_name <- gsub(sprintf("%s\\/.*\\/", folder), "", pkg)

  codemeta_written <- FALSE

  # Finding older codemeta entry for this package if available
  if (!is.null(old_cm)) {

    if (length(old_cm[purrr::map_chr(old_cm, "identifier") == pkg_name]) > 0) {
      old_entry <- old_cm[purrr::map_chr(old_cm, "identifier") == pkg_name][[1]]

      local_pkg_codemeta <- file.exists(file.path(pkg, "codemeta.json"))

      if (!local_pkg_codemeta) {
        jsonlite::write_json(
          old_entry,
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

  info <- try(
    codemetar::create_codemeta(
      pkg = pkg,
      verbose = FALSE,
      force_update = TRUE
    ),
    silent = TRUE
  )

  if (codemeta_written) {
    file.remove(file.path(pkg, "codemeta.json"))
  }

  if (!inherits(info, "try-error")) {
    # for other repos, the URLs in DESCRIPTION have to be right
    if (org %in% c("ropensci", "ropenscilabs", "ropensci-archive")) {
      info$codeRepository <- paste0("https://github.com/",
        org, "/", info$identifier)
    }
    return(info)
  } else {
    print(toupper(pkg))
    return(old_entry)
  }
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
