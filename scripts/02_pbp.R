source("setup.R")

if (!dir.exists("data_pbps")) dir.create("data_pbps")

# Play-by-play, 3 competiciones desde 2016-17 -> data_pbps/pbp_acb_{año}.csv

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
      crono = hms::as_hms(crono),
      shirt_number = as.character(shirt_number)
    )
}

# Backfill (a mano, una vez): un fichero por temporada, salta el año ya hecho.
backfill_pbp <- function() {
  calendario <- read_csv("data/calendario_historico.csv", show_col_types = FALSE) %>%
    filter(edition_year >= 2016)
  una_temporada <- function(temporada) {
    fichero <- paste0("data_pbps/pbp_acb_", temporada, ".csv")
    if (file.exists(fichero)) {
      return(invisible(NULL))
    }
    calendario %>%
      filter(edition_year == temporada) %>%
      pull(id) %>%
      map_df(pbpdf) %>%
      write.csv(fichero, row.names = FALSE)
  }
  walk(sort(unique(calendario$edition_year)), una_temporada)
}

# En temporada: sobrescribe los de hoy que sigan en juego (la API los va
# actualizando en directo) y vuelve a pedir los finalizados que falten o cuyo
# marcador final no coincida con el del calendario (se guardaron a medias).
actualiza_pbp <- function(temporada) {
  fichero <- paste0("data_pbps/pbp_acb_", temporada, ".csv")
  hecho <- if (file.exists(fichero)) {
    read_csv(fichero, show_col_types = FALSE, col_types = cols(shirt_number = "c"))
  } else {
    tibble(id_match = numeric(), score_local = numeric(), score_visitor = numeric())
  }

  finalizados <- read_csv("data/calendario_historico.csv", show_col_types = FALSE) %>%
    filter(edition_year == temporada) %>%
    left_join(
      summarise(hecho, across(c(score_local, score_visitor), max), .by = id_match),
      by = c(id = "id_match"),
      suffix = c("", "_pbp")
    ) %>%
    filter(
      is.na(score_local_pbp) | score_local_pbp != score_local | score_visitor_pbp != score_visitor
    ) %>%
    pull(id)

  en_juego <- read_csv("data/horarios.csv", show_col_types = FALSE) %>%
    filter(as_date(cuando) == today(), !finalized) %>%
    pull(id)

  ids <- union(finalizados, en_juego)
  if (length(ids) == 0) {
    return(invisible(NULL))
  }
  bind_rows(filter(hecho, !id_match %in% ids), map_df(ids, pbpdf)) %>%
    write.csv(fichero, row.names = FALSE)
}

actualiza_pbp(temporada_actual())
