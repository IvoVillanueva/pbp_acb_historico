source("setup.R")

# Play-by-play de la temporada en curso -> data_pbps/pbp_acb_{año}.csv -
# El histórico ya está. Baja solo los partidos que aún no están en el
# fichero de la temporada y los añade.

calendario <- read_csv("data/calendario_historico.csv", show_col_types = FALSE)
temporada <- temporada_actual()
fichero <- paste0("data_pbps/pbp_acb_", temporada, ".csv")
hecho <- if (file.exists(fichero)) read_csv(fichero, show_col_types = FALSE) else NULL

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

calendario %>%
  filter(edition_year == temporada, !id %in% hecho$id_match) %>%
  pull(id) %>%
  map_df(pbpdf) %>%
  bind_rows(hecho) %>%
  write.csv(fichero, row.names = FALSE)
