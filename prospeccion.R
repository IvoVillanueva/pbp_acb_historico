source("setup.R")

# Prospección: desde qué temporada hay play-by-play -------------------

n_eventos <- function(id_m) {
  url <- paste0(acb_api, "PlayByPlay/matchevents?idMatch=", id_m, "&jvFilter=true")
  Sys.sleep(0.5)
  NROW(fromJSON(content(GET(url, add_headers(authorization = auth)), "text")))
}

read_csv("data/calendario_historico.csv", show_col_types = FALSE) %>%
  group_by(edition_year) %>%
  slice(1) %>%
  ungroup() %>%
  transmute(edition_year, eventos = map_int(id, n_eventos)) %>%
  print(n = Inf)
