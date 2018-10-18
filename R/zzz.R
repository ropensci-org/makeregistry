is_package <- function(path){
  all(c("DESCRIPTION", "NAMESPACE", "man", "R") %in%
        dir(path))
}
