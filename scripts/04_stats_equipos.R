source("setup.R")

if (!dir.exists("data_stats_equipos")) dir.create("data_stats_equipos")

# Stats de equipo, 3 competiciones desde 1983 -> data_stats_equipos/stats_equipos_acb_{año}.csv

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

# Backfill (a mano, una vez): un fichero por temporada, salta el año ya hecho.
backfill_stats_equipos <- function() {
  calendario <- read_csv("data/calendario_historico.csv", show_col_types = FALSE) %>%
    filter(edition_year >= 1983)
  una_temporada <- function(temporada) {
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
  walk(sort(unique(calendario$edition_year)), una_temporada)
}

# En temporada: sobrescribe los de hoy que sigan en juego (la API los va
# actualizando en directo) y vuelve a pedir los finalizados que falten o cuyos
# puntos no sumen el resultado del calendario (se guardaron a medias).
actualiza_stats_equipos <- function(temporada) {
  fichero <- paste0("data_stats_equipos/stats_equipos_acb_", temporada, ".csv")
  hecho <- if (file.exists(fichero)) {
    read_csv(fichero, show_col_types = FALSE)
  } else {
    tibble(id_match = numeric(), points = numeric())
  }

  finalizados <- read_csv("data/calendario_historico.csv", show_col_types = FALSE) %>%
    filter(edition_year == temporada) %>%
    left_join(count(hecho, id_match, wt = points), by = c(id = "id_match")) %>%
    filter(is.na(n) | n != score_local + score_visitor) %>%
    pull(id)

  en_juego <- read_csv("data/horarios.csv", show_col_types = FALSE) %>%
    filter(as_date(cuando) == today(), !finalized) %>%
    pull(id)

  ids <- union(finalizados, en_juego)
  if (length(ids) == 0) {
    return(invisible(NULL))
  }
  bind_rows(filter(hecho, !id_match %in% ids), map_df(ids, statsdf)) %>%
    write.csv(fichero, row.names = FALSE)
}

actualiza_stats_equipos(temporada_actual())
