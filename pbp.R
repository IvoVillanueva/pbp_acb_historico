source("setup.R")

# Backfill play-by-play (desde 2016-17) -> data_pbps/pbp_acb_{año}.csv -

partidos <- read_csv("data/calendario_historico.csv", show_col_types = FALSE) %>%
  filter(edition_year >= 2016) %>%
  select(edition_year, id)

pbpdf <- function(id_m) {
  url <- paste0(acb_api, "PlayByPlay/matchevents?idMatch=", id_m, "&jvFilter=true")
  Sys.sleep(0.5)
  eventos <- fromJSON(content(GET(url, add_headers(authorization = auth)), "text"))
  if (length(eventos) == 0) {
    return(NULL)
  }
  eventos %>%
    tibble() %>%
    unnest(
      c(competition, edition, license, team, type, statistics),
      names_sep = "_"
    ) %>%
    select(!c(id_subphase, id_round, license_media, team_media, contains("_date"))) %>%
    mutate(
      license_id_type = as.numeric(license_id_type),
      crono = hms::as_hms(crono)
    )
}

pbp_temporada <- function(temporada) {
  partidos %>%
    filter(edition_year == temporada) %>%
    pull(id) %>%
    map_df(pbpdf) %>%
    write.csv(paste0("data_pbps/pbp_acb_", temporada, ".csv"), row.names = FALSE)
}

walk(unique(partidos$edition_year), pbp_temporada)


# Completar cada pbp_acb_{año}.csv con los id_match de Copa y Supercopa -
# Preserva lo ya bajado (Liga): solo añade los partidos de las
# competiciones 2 y 3 que aún no están en el fichero.

completa_copas <- function(temporada) {
  fichero <- paste0("data_pbps/pbp_acb_", temporada, ".csv")
  hecho <- read_csv(fichero, show_col_types = FALSE)
  read_csv("data/calendario_historico.csv", show_col_types = FALSE) %>%
    filter(
      edition_year == temporada,
      id_competition %in% c(2, 3),
      !id %in% hecho$id_match
    ) %>%
    pull(id) %>%
    map_df(pbpdf) %>%
    bind_rows(hecho) %>%
    write.csv(fichero, row.names = FALSE)
}

walk(unique(partidos$edition_year), completa_copas)




pbp_acb_2025 <- read_csv("data_pbps/pbp_acb_2025.csv")
