source("setup.R")

if (!dir.exists("data_stats_equipos")) dir.create("data_stats_equipos")

# Backfill stats de equipo: 3 competiciones desde 1983 -> data_stats_equipos/stats_equipos_acb_{año}.csv

calendario <- read_csv("data/calendario_historico.csv", show_col_types = FALSE) %>%
  filter(edition_year >= 1983)

statsdf <- function(id_m) {
  url <- paste0(acb_api, "Boxscore/teammatchstatistics?idMatch=", id_m)
  Sys.sleep(0.1)
  stats <- fromJSON(content(GET(url, add_headers(authorization = auth)), "text"))
  if (length(stats) == 0) {
    return(NULL)
  }
  stats %>%
    tibble() %>%
    unnest(
      c(competition, edition, local_team, visitor_team),
      names_sep = "_"
    ) %>%
    select(where(~ !is.list(.)))
}

stats_equipos_temporada <- function(temporada) {
  fichero <- paste0("data_stats_equipos/stats_equipos_acb_", temporada, ".csv")
  if (file.exists(fichero)) {
    return(invisible(NULL))
  }

  calendario %>%
    filter(edition_year == temporada) %>%
    pull(id) %>%
    map_df(statsdf) %>%
    write.csv(fichero, row.names = FALSE)
}

walk(sort(unique(calendario$edition_year)), stats_equipos_temporada)



stats_teams <- list.files("data_stats_equipos", full.names = TRUE) %>%
  map_df(~ read_csv(., show_col_types = FALSE))
