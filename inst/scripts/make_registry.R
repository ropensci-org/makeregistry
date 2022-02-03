# cat("clone repos", sep = "\n")
makeregistry::track_repos()

old_cm <- "https://github.com/ropensci/roregistry/blob/gh-pages/raw_cm.json?raw=true"

# cat("creating codemetas", sep = "\n")
codemeta <- makeregistry::create_codemetas(old_cm = old_cm)

# cat("writing json", sep = "\n")
jsonlite::write_json(codemeta, path = "raw_cm.json",
  pretty=TRUE, auto_unbox = TRUE)

# cat("creating registry", sep = "\n")
makeregistry::create_registry(cm = "raw_cm.json",
  outpat = "registry.json")
