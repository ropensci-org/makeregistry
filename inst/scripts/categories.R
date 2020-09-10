old_registry <- jsonlite::read_json("https://raw.githubusercontent.com/ropensci/roregistry/gh-pages/registry.json")
old_registry <- old_registry$packages
old_info <- tibble::tibble(name = purrr::map_chr(old_registry, "name"),
                           ropensci_category = purrr::map_chr(old_registry, "ropensci_category"),
                           github = purrr::map_chr(old_registry, "github"),
                        description = purrr::map_chr(old_registry, "description"),
                          status = purrr::map_chr(old_registry, "status"))

packages <- jsonlite::read_json("https://raw.githubusercontent.com/ropensci/roregistry/ex/registry2.json")
packages <- tibble::tibble(name = purrr::map_chr(packages$package, "name"))

packages <- dplyr::left_join(packages, old_info,
                             by = "name")

readr::write_csv(packages, "inst/scripts/categories.csv")
