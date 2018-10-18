is_package <- function(path){
  all(c("DESCRIPTION", "NAMESPACE", "man", "R") %in%
        dir(path))
}
# from https://github.com/jeroen/jsonlite/blob/1f9e609e7d0ed702ede9c82aa5482ba08d5e5ab2/R/read_json.R#L22
# only until new jsonlite version on CRAN (encoding fix)
write_json <- function(x, path, ...) {
  json <- jsonlite::toJSON(x, ...)
  writeLines(json, path, useBytes = TRUE)
}
