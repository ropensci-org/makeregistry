get_review <- function(entry){
  if(!is.null(entry$review)){
    if(grepl("ropensci\\/onboarding", entry$review$url)){
      issue <- gsub("https\\:\\/\\/github\\.com\\/ropensci\\/onboarding\\/issues\\/",
                    "", entry$review$url)
      badge <- glue::glue('<a target="_blank" href="https://github.com/ropensci/onboarding/issues/{issue}"><i class="fa fa-comments" title = "rOpenSci software review" style="font-size:1.2rem;color: #01dc0b;float: right;"></i></a>')

    }else{
      badge <- glue::glue('<i class="fa fa-comments" style="font-size:1.2rem;color: #dfe3eb;float: right;"></i>')

    }
  }else{
    badge <- glue::glue('<i class="fa fa-comments" style="font-size:1.2rem;color: #dfe3eb;float: right;"></i>')

  }

  return(list(badge = badge,
              review = !(badge=="")))
}

get_maintainer <- function(entry){
  maintainer <- entry$maintainer[[1]]
  if(maintainer$`@type` == "Organization"){
    toString(maintainer$name)
  }else{
    if(length(maintainer$givenName) > 1){
      maintainer$givenName <- paste(maintainer$givenName[1],
                                    maintainer$givenName[2])
    }

    paste(maintainer$givenName, maintainer$familyName)
  }


}

get_keywords <- function(entry){
  keywords <- unlist(entry$keywords)
  keywords <- keywords[!keywords %in% c("r", "rstats", "r-package")]
  if(length(keywords > 0)){
    toString(sort(keywords))
  }else{
    ""
  }

}

get_coderepo <- function(entry){
  if(!is.null(entry$codeRepository)){
    gsub("\\#.*", "", entry$codeRepository)
  }else{
    ""
  }
}

get_status <- function(entry){
  if(!is.null(entry$developmentStatus)){
    status <- unlist(entry$developmentStatus)
    status <- status[grepl("repostatus", status)]
    if(length(status) > 0){
      status <- status
    }else{
      status <- guess_status(entry)
    }
  }else{
    status <- guess_status(entry)
  }
  status <- gsub("http(s)?\\:\\/\\/www\\.repostatus\\.org\\/\\#",
                 "", status)
  badge <- glue::glue('<a target="_blank" href="https://www.repostatus.org/#{status}"><p class="label {status}">{status}</p></a>')
  return(list(status = status,
              badge = badge))
}

guess_status <- function(entry){

  if(grepl("ropenscilabs", entry$codeRepository)){
    "http://www.repostatus.org/#concept"
  }else{
    "http://www.repostatus.org/#active"
  }
}

create_details <- function(url, on_cran, onboarding){
  glue::glue('{on_cran$badge} <a target="_blank" href="{url}"><i class="fa fa-github" style="font-size:1.2rem;color: #01dc0b;padding-left:5px;"></i></a> {onboarding$badge }')
}

get_cran <- function(pkg, cran, bioc_names){
  on_cran <- pkg %in% cran
  if(on_cran){
    badge <- glue::glue('<a target="_blank" href="https://cran.r-project.org/package={pkg}"><p class="label cran">cran</p></a>')
  }
  else{
    if(pkg %in% bioc_names){
      on_cran <- TRUE
      badge <- glue::glue('<a target="_blank" href="https://bioconductor.org/packages/release/bioc/html/{pkg}.html"><p class="label bioc">bioc</p></a>')
    }else{
      on_cran <- FALSE
      badge <- glue::glue('<p class="label nocran">cran</p>')
    }
  }

  list(on_cran = on_cran,
       badge = badge)
}


#' Title
#'
#' @param cm Path to the JSON codemeta
#' @param outpat Path where to save the JSON
#'
#' @export
#'
#' @examples
create_registry <- function(cm, outpat){
  registry <- jsonlite::read_json(cm)
  registry <- registry[lengths(registry) > 0]
  website_info <- tibble::tibble(name = purrr::map_chr(registry, "identifier"),
                                 description = purrr::map_chr(registry, "name"),
                                 details = purrr::map_chr(registry, "description"),
                                 maintainer = purrr::map_chr(registry, get_maintainer),
                                 keywords = purrr::map_chr(registry, get_keywords),
                                 github = purrr::map_chr(registry, get_coderepo),
                                 status = purrr::map(registry, get_status),
                                 onboarding = purrr::map(registry, get_review))

  available_packages <- memoise::memoise(available.packages)
  cran <- available_packages()[,1] %>% as.character()
  cran <- cran[cran != "dashboard"]

  repos <- c(
    BioCsoft = "https://bioconductor.org/packages/release/bioc",
    BioCann = "https://bioconductor.org/packages/release/data/annotation",
    BioCexp = "https://bioconductor.org/packages/release/data/experiment")


  bioc_names <- rownames(available_packages(repos = repos))

  website_info$on_cran <- purrr::map(website_info$name,
                                     get_cran, cran,
                                     bioc_names)

  website_info$url <- website_info$github

  website_info$description <- sub(".*\\:", "", website_info$description)
  website_info$description <- trimws(website_info$description)

  # add categories
  category_info <- readr::read_csv("https://raw.githubusercontent.com/ropensci/roregistry/gh-pages/final_categories.csv")

  website_info <- dplyr::left_join(website_info,
                                   category_info, by = "name")


  website_info <- dplyr::rowwise(website_info)
  website_info <- dplyr::mutate(website_info,
                                details = create_details(url, on_cran, onboarding))


  list(packages = website_info,
       date = format(Sys.time(), format = "%F %R %Z")) %>%
    jsonlite::toJSON(auto_unbox = TRUE,
                     pretty = TRUE) %>%
    writeLines(outpat)


}
