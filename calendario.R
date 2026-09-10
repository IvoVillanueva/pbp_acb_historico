source("setup.R")

# ================================================================
# Backfill (una vez): jornadas y partidos de comp 1-3, 1975-2025
# ================================================================

get_ids <- function(comp, ed) {
  url <- paste0(acb_api, "Matchweeks/lite?idCompetition=", comp, "&idEdition=", ed)
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

schedule <- function(id_competition, id_edition, id) {
  link <- paste0(
    acb_api, "Matches/matchesbymatchweeklite?idCompetition=",
    id_competition, "&idEdition=", id_edition, "&idMatchweek=", id
  )
  Sys.sleep(0.5)
  matches <- fromJSON(content(GET(link, add_headers(authorization = auth)), "text"))
  if (length(matches) == 0) {
    return(NULL)
  }
  matches %>%
    tibble() %>%
    unnest(
      c(competition, edition, phase, local_team, visitor_team, arena),
      names_sep = "_"
    ) %>%
    mutate(matchweek_number = as.numeric(matchweek_number))
}

backfill_calendario <- function() {
  grid <- expand_grid(comp = 1:3, ed = 40:91)
  map2_df(grid$comp, grid$ed, get_ids) %>%
    write.csv("data/ids_partidos_historico.csv", row.names = FALSE)

  read_csv("data/ids_partidos_historico.csv", show_col_types = FALSE) %>%
    select(id_competition, id_edition, id) %>%
    pmap_df(schedule) %>%
    select(where(~ !is.list(.))) %>%
    filter(finalized == TRUE) %>%
    write.csv("data/calendario_historico.csv", row.names = FALSE)
}

# ================================================================
# En temporada: refresca solo la edición en curso y fusiona por id
# ================================================================

edicion_actual <- function() {
  hoy <- today()
  (if (month(hoy) >= 9) year(hoy) else year(hoy) - 1) - 1935
}

# jornadas nuevas de la edición (los cruces de playoff se publican sobre la marcha)
actualiza_ids <- function(ed) {
  map2_df(1:3, rep(ed, 3), get_ids) %>%
    bind_rows(read_csv("data/ids_partidos_historico.csv", show_col_types = FALSE)) %>%
    distinct(id, .keep_all = TRUE) %>%
    write.csv("data/ids_partidos_historico.csv", row.names = FALSE)
}

# partidos finalizados de la edición; distinct(id) con lo nuevo primero
actualiza_calendario <- function(ed) {
  read_csv("data/ids_partidos_historico.csv", show_col_types = FALSE) %>%
    filter(id_edition == ed) %>%
    select(id_competition, id_edition, id) %>%
    pmap_df(schedule) %>%
    select(where(~ !is.list(.))) %>%
    filter(finalized == TRUE) %>%
    bind_rows(read_csv("data/calendario_historico.csv", show_col_types = FALSE)) %>%
    distinct(id, .keep_all = TRUE) %>%
    write.csv("data/calendario_historico.csv", row.names = FALSE)
}

# Al correr el script: refresco de la edición en curso (lo del backfill es
# backfill_calendario(), a mano y una sola vez).
ed_actual <- edicion_actual()
actualiza_ids(ed_actual)
actualiza_calendario(ed_actual)
