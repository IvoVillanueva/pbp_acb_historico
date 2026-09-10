source("setup.R")

# Backfill jornadas: competiciones 1-3 x ediciones 40-91 -> data/ids_partidos_historico.csv

get_ids <- function(comp, ed) {
  url <- paste0(
    acb_api, "Matchweeks/lite?idCompetition=",
    comp, "&idEdition=", ed
  )
  Sys.sleep(0.5)
  res <- fromJSON(content(GET(url, add_headers(authorization = auth)), "text"))
  if (length(res) == 0) {
    return(NULL)
  }
  res %>%
    tibble() %>%
    unnest(cols = edition) %>%
    select(id, id_competition, id_edition, year, id_phase, num_matchweek, descriptor) %>%
    arrange(num_matchweek)
}

grid <- expand_grid(comp = 1:3, ed = 40:91)

map2_df(grid$comp, grid$ed, get_ids) %>%
  write.csv("data/ids_partidos_historico.csv", row.names = FALSE)
