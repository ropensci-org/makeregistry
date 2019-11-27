.create_cm <- function(pkg, org, old_cm){

  if(!is.null(old_cm)){
    if(length(old_cm[purrr::map_chr(old_cm, "identifier") ==
                     gsub("repos\\/.*\\/", "", pkg)]) > 0){
      old_entry <- old_cm[purrr::map_chr(old_cm, "identifier") ==
               gsub("repos\\/.*\\/", "", pkg)][[1]]

      if (!file.exists(file.path(pkg, "codemeta.json"))){
        jsonlite::write_json(old_entry, path = file.path(pkg, "codemeta.json"))
        codemeta_written <- TRUE
      }
    } else {
      old_entry <- NULL
    }
  } else {
      old_entry <- NULL
    }

  info <- try(codemetar::create_codemeta(pkg = pkg, verbose = FALSE,
                                         force_update = TRUE),
              silent = TRUE)

  if (codemeta_written) {
    file.remove(file.path(pkg, "codemeta.json"))
  }

  if(!inherits(info, "try-error")) {
    # for other repos, the URLs in DESCRIPTION have to be right
    if(org %in% c("ropensci", "ropenscilabs")){
      info$codeRepository <- paste0("https://github.com/",
                                    org, "/", info$identifier)
    }

    return(info)
  }else{
    print(toupper(pkg))

    if (is.null(old_entry)){
      return(old_entry)
      } else {
        NULL
      }
    }else{
      NULL
    }

  }

}
create_cm <- memoise::memoise(.create_cm)

#' Create the codemetas for all files
#'
#' @param old_cm path to latest CodeMeta version
#'
#' @return A JSON codemeta
#' @export
#'
#' @examples
create_codemetas <- function(old_cm = NULL){
  if(!is.null(old_cm)){
    old_cm <- jsonlite::read_json(old_cm)
    old_cm <- old_cm[lengths(old_cm) > 0]
  }

  folders <- rbind(tibble::tibble(folder = dir("repos/other", full.names = TRUE),
                                  org = "other"),
                   tibble::tibble(folder = dir("repos/ropenscilabs", full.names = TRUE),
                                  org = "ropenscilabs"),
                   tibble::tibble(folder = dir("repos/ropensci", full.names = TRUE),
                                  org = "ropensci"))
  folders <- dplyr::rowwise(folders)
  folders <- dplyr::mutate(folders, is_package = is_package(folder))

  packages <- dplyr::filter(folders, is_package)

  purrr::map2(packages$folder,
              packages$org, create_cm,
              old_cm = old_cm)
}
