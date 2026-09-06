library(tidyverse)
library(jsonlite)
library(httr)


# Token ----------------------------------------------------------------

auth <- "***REMOVED***"

# Backfill: año + jornada de todas las temporadas -> data/ids_partidos_historico.csv

get_ids <- function(ed) {
  url <- paste0("ACB_API/Matchweeks/lite?idCompetition=1&idEdition=", ed)
  Sys.sleep(0.5)
  fromJSON(content(GET(url, add_headers(authorization = auth)), "text")) %>%
    tibble() %>%
    unnest(cols = edition) %>%
    select(id, id_edition,  year, id_phase, num_matchweek, descriptor) %>%
    arrange(num_matchweek)
}

map_df(40:91, get_ids) %>%
  write.csv("data/ids_partidos_historico.csv", row.names = FALSE)
