# makeregistry

The goal of makeregistry is to create the JSON that's used to display packages on ropensci.org/packages

## Installation

``` r
remotes::install_github("ropensci/codemetar")
remotes::install_github("ropensci-org/makeregistry")
```

## Example

This is a basic example which shows you how to solve a common problem. 

The codemeta creation needs to be run in the server where we have a repos/ folder with all clones. The `old_cm` parameter allows to use older entries for packages for which CodeMeta creation fails for some reason.

``` r

if(!file.exists("raw_cm.json")){
  old_cm <- "https://github.com/ropensci/roregistry/blob/gh-pages/raw_cm.json?raw=true"
}else{
  old_cm <- "raw_cm.json"
}

codemeta <- makeregistry::create_codemetas(old_cm = old_cm)

jsonlite::write_json(codemeta, path = "raw_cm.json",
                     pretty = TRUE, auto_unbox = TRUE)

makeregistry::create_registry(cm = "raw_cm.json",
                              outpat = "registry.json")
                              
# find some way to upload raw_cm.json and registry.json to the roregistry repo.
```


## automation files

files in inst/automation

* cronjob - cron jobs, urls for healthchecks.io hidden
* exclude_list.txt - repos to ignore in git cloning
* not_transferred.txt - repos gone through software review, but not transferred to an ropensci github org
* make_registry.R - R script to do the registry creation
* make_registry.sh - shell script to run make_registry.R, push to github and clean up tar.gz files to save disk space
* pull down any new repos or changes in existing repos
    * pull_other.sh - not in github.com/ropensci or github.com/ropenscilabs
    * pull_ropensci.sh - in github.com/ropensci
    * pull_ropenscilabs.sh - in github.com/ropenscilabs
