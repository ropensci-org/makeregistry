# current categories information
categories <- readr::read_csv(
  here::here(
    file.path(
      "inst",
      "scripts",
      "final_categories.csv"
      )
    )
  )

library("magrittr")

# current packages
jsonlite::read_json("https://raw.githubusercontent.com/ropensci/roregistry/gh-pages/registry.json") %>%
  .[[1]] %>%
  purrr::map_chr("name") -> packages

categories <- dplyr::left_join(
  tibble::tibble(name = packages),
  categories
)
# update csv by hand and save it

# only keep categories information
# for current packages
categories <- dplyr::filter(categories,
                            name %in% packages)
readr::write_csv(categories, here::here(
  file.path(
    "inst",
    "scripts",
    "final_categories.csv"
  )
)
)


