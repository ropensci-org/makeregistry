# makeregistry

The goal of makeregistry is to create the JSON that's used to display packages on ropensci.org/packages

## Installation

``` r
remotes::install_github("ropensci/codemetar", ref = "dev")
remotes::install_github("ropenscilabs/makeregistry")
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

makeregistry:::write_json(codemeta, path = "raw_cm.json",
                          pretty=TRUE,
                          auto_unbox = TRUE)

makeregistry::create_registry(cm = "raw_cm.json",
                              outpat = "registry.json")
                              
# find some way to upload raw_cm.json and registry.json to the roregistry repo.
```


## automation files

files in inst/automation

* cronjob - cron jobs, urls for healthchecks.io hidden
* exclude_list.txt - repos to ignore in git cloning
* make_registry.R - R script to do the registry creation
* make_registry.sh - shell script to run make_registry.R, push to github and clean up tar.gz files to save disk space
* pull_changes.sh - for loop across each repo dir to pull down any changes
* pull_new_ropensci.sh - pull down any new repos in github.com/ropensci
* pull_new_ropenscilabs.sh - pull down any new repos in github.com/ropenscilabs



