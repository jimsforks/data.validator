library(data.validator)
library(magrittr)
library(assertr)

validator <- create_validator()

file <- system.file("extdata", "population.csv", package = "data.validator")
population <- read.csv(file, colClasses = c("character", "character", "character", "integer", "integer", "integer"))
population %>%
  insist(within_n_sds(3), total, success_fun = success_append, error_fun = error_append) %>%
  add_results(validator)
validator

render_leaflet_report <- function(validation_results, population_data, correct_col, violated_col) {
  file <- system.file("extdata", "counties.json", package = "data.validator")
  states <- rgdal::readOGR(file, GDAL1_integer64_policy = TRUE, verbose = FALSE)

  violated <- validation_results %>%
    tidyr::unnest(error_df, keep_empty = TRUE) %>%
    dplyr::pull(index)

  states@data <- dplyr::left_join(states@data, population_data,
                                  by = c("JPT_KOD_JE" = "county_ID"))
  states@data$color <- correct_col
  states@data$color[violated] <- violated_col
  states@data$label <- glue::glue("County: {states@data$county} <br>",
                                  "Population: {states@data$total}")

  htmltools::tagList(
    htmltools::h2("Counties not fitting within 3 standard deviations"),
    leaflet::leaflet(states) %>%
      leaflet::addPolygons(color = "#444444", weight = 1, smoothFactor = 0.5,
                           opacity = 0.5, fillOpacity = 0.5,
                           fillColor = states@data$color,
                           label = states@data$label %>% lapply(htmltools::HTML),
                           highlightOptions = leaflet::highlightOptions(color = "white",
                                                                        weight = 2,
                                                                        bringToFront = TRUE))
  )
}

save_report(
  validator,
  ui_constructor = render_leaflet_report,
  population_data = population,
  correct_col = "#52cf0a",
  violated_col = "#bf0b4d"
)
