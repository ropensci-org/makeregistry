# makeregistry

The goal of makeregistry is to create the JSON that's used to display packages on ropensci.org/packages

## Installation

``` r
remotes::install_github("maelle/makeregistry")
```

## Example

This is a basic example which shows you how to solve a common problem. Currently you need to run it from inside the RStudio thing, where the repos/ live.

The codemeta creation needs to be run in RStudio cloud where we have a repos/ folder with all clones. The `old_cm` parameter allows to use older entries for packages for which CodeMeta creation fails for some reason.s

``` r

if(!file.exists("old_cm.json")){
  old_cm <- "https://github.com/ropensci/roregistry/blob/ex/codemeta.json?raw=true"
}else{
  old_cm <- "raw_cm.json"
}

codemeta <- makeregistry::create_codemetas(old_cm = old_cm)

makeregistry:::write_json(codemeta, path = "raw_cm.json",
                          pretty=TRUE,
                          auto_unbox = TRUE)

makeregistry::create_registry(cm = "raw_cm.json",
                              outpat = "registry.json")
                              
# or, as long as we don't have raw_cm.json

makeregistry::create_registry(cm = "https://github.com/ropensci/roregistry/blob/ex/codemeta.json?raw=true",
                              outpat = "registry.json")
                              
# find some way to upload the that to roweb2
```

