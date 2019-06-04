.get_review_table <- function(){
  # reviews table
  reviews <- airtabler::airtable(base = "appZIB8hgtvjoV99D",
                                   table = "Reviews")
  reviews <- reviews$Reviews$select_all()
  reviews <- reviews[lengths(reviews$reviewer) == 1,]
  reviews <- tidyr::unnest(reviews, reviewer)
  reviews <- as.data.frame(reviews)
  reviews <- reviews[!is.na(reviews$onboarding_url),]

  # reviewers table
  reviewers <- airtabler::airtable(base = "appZIB8hgtvjoV99D",
                                 table = "Reviewers")
  reviewers <- reviewers$Reviewers$select_all()
  reviewers <- as.data.frame(reviewers)

  # join
  reviews <- dplyr::left_join(reviews, reviewers, by = c("reviewer" = "id"))
  reviews$review <- gsub(".*issues\\/", "", reviews$onboarding_url)
  reviews <- reviews[!is.na(reviews$name),]
  reviews[, c("review", "name", "github")]
}

get_review_table <- memoise::memoise(.get_review_table)

get_review <- function(entry){
  if(!is.null(entry$review)){
    if(grepl("ropensci\\/onboarding|ropensci\\/software-review", entry$review$url)){
     review <- list(url = entry$review$url)
     review$reviewers <- get_reviewers(id = gsub(".*issues\\/", "", entry$review$url),
                                       reviews = get_review_table())
     review

    }else{
      ""
    }
  }else{
    ""
  }

}

get_reviewers <- function(id, reviews){
  reviewers <- reviews[reviews$review == id, c("name", "github")]
  as.list(split(reviewers,
                reviewers$github))
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
  return(status)
}

guess_status <- function(entry){

  if(grepl("ropenscilabs", entry$codeRepository)){
    "http://www.repostatus.org/#concept"
  }else{
    "http://www.repostatus.org/#active"
  }
}


get_cran <- function(pkg, cran){
  pkg %in% cran
}

get_bioc <- function(pkg, bioc_names){
  pkg %in% bioc_names
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
                                     get_cran, cran)

  website_info$on_bioc <- purrr::map(website_info$name,
                                     get_bioc, bioc_names)

  website_info$url <- website_info$github

  website_info$description <- sub(".*\\:", "", website_info$description)
  website_info$description <- trimws(website_info$description)

  # add categories
  category_info <- readr::read_csv("https://raw.githubusercontent.com/ropensci/roregistry/gh-pages/final_categories.csv")

  website_info <- dplyr::left_join(website_info,
                                   category_info, by = "name")


  website_info <- dplyr::rowwise(website_info)

    list(packages = website_info,
       date = format(Sys.time(), format = "%F %R %Z")) %>%
    jsonlite::toJSON(auto_unbox = TRUE,
                     pretty = TRUE) %>%
    writeLines(outpat)


}
