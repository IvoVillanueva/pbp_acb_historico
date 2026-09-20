source("setup.R")

if (!dir.exists("data_boxscores")) dir.create("data_boxscores")

# Boxscore de jugador, 3 competiciones desde 1983 -> data_boxscores/boxscore_acb_{año}.csv

boxdf <- function(id_m) {
  url <- paste0(acb_api, "Boxscore/playermatchstatistics?idMatch=", id_m)
  Sys.sleep(0.5)
  box <- fromJSON(content(GET(url, add_headers(authorization = auth)), "text"))
  if (length(box) == 0) {
    return(NULL)
  }
  box %>%
    tibble() %>%
    unnest(
      c(competition, edition, local_team, visitor_team, license),
      names_sep = "_"
    ) %>%
    select(where(~ !is.list(.))) %>%
    mutate(license_id_type = as.numeric(license_id_type))
}

# Backfill (a mano, una vez): un fichero por temporada, salta el año ya hecho.
backfill_boxscore <- function() {
  calendario <- read_csv("data/calendario_historico.csv", show_col_types = FALSE) %>%
    filter(edition_year >= 1983)
  una_temporada <- function(temporada) {
    fichero <- paste0("data_boxscores/boxscore_acb_", temporada, ".csv")
    if (file.exists(fichero)) {
      return(invisible(NULL))
    }
    calendario %>%
      filter(edition_year == temporada) %>%
      pull(id) %>%
      map_df(boxdf) %>%
      write.csv(fichero, row.names = FALSE)
  }
  walk(sort(unique(calendario$edition_year)), una_temporada)
}

# En temporada: añade al fichero del año los partidos que aún no están.
actualiza_boxscore <- function(temporada) {
  fichero <- paste0("data_boxscores/boxscore_acb_", temporada, ".csv")
  hecho <- if (file.exists(fichero)) {
    read_csv(fichero, show_col_types = FALSE, col_types = cols(pno = "c", license_id_type = "d"))
  } else {
    NULL
  }
  read_csv("data/calendario_historico.csv", show_col_types = FALSE) %>%
    filter(edition_year == temporada, !id %in% hecho$id_match) %>%
    pull(id) %>%
    map_df(boxdf) %>%
    bind_rows(hecho) %>%
    write.csv(fichero, row.names = FALSE)
}

actualiza_boxscore(temporada_actual())
