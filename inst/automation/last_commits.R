library(gert)
library(dplyr)
library(desc)
dirs <- c(
  "repos/other",
  "repos/ropensci",
  "repos/ropenscilabs"
)
each_repo <- function(path) {
  desc_file <- file.path(path, "DESCRIPTION")
  if (!file.exists(desc_file)) {
    df <- data.frame(
      name = NA_character_,
      date_last_commit = NA_character_,
      stringsAsFactors = FALSE)
    return(df)
  }
  name <- desc::desc_get_field("Package", file = desc_file)
  date <- as.character(gert::git_log(max = 1, repo = path)$time)
  data.frame(name = name, date_last_commit = date,
    stringsAsFactors = FALSE)
}
out <- list()
for (i in seq_along(dirs)) {
  children <- list.dirs(dirs[i], recursive=FALSE)
  out[[i]] <- lapply(children, each_repo)
}
df <- na.omit(dplyr::bind_rows(unlist(out, FALSE)))

f <- "last_commits.csv"
write.csv(df, file = f, row.names = FALSE)
