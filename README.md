# makeregistry

The goal of makeregistry is to create the JSON that's used to display packages on ropensci.org/packages

## Installation

``` r
remotes::install_github("rosadmin/makeregistry")
```

## Example

This is a basic example which shows you how to solve a common problem. Currently you need to run it from inside the RStudio thing, where the repos/ live.

``` r
codemeta <- makeregistry::create_codemetas()
makeregistry:::write_json(codemeta, path = "raw_cm.json", pretty=TRUE,             auto_unbox = TRUE)
makeregistry::create_registry(cm = "raw_cm.json",
                              outpat = "registry.json")
```

