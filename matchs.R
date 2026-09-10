source("setup.R")

# Calendario histórico -> data/calendario_historico.csv ---------------

jornadas <- read_csv("data/ids_partidos_historico.csv", show_col_types = FALSE)

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

jornadas %>%
  select(id_competition, id_edition, id) %>%
  pmap_df(schedule) %>%
  select(where(~ !is.list(.))) %>%
  filter(finalized == TRUE) %>%
  write.csv("data/calendario_historico.csv", row.names = FALSE)


# Actualización incremental: bajar una edición y fusionar por id ------
# La temporada que viene se corre solo la edición nueva; el resto del
# CSV se queda como está. distinct(id) con lo nuevo primero -> si un
# partido cambió (acta), gana la versión recién bajada.

actualiza_calendario <- function(ed) {
  jornadas %>%
    filter(id_edition == ed) %>%
    select(id_competition, id_edition, id) %>%
    pmap_df(schedule) %>%
    select(where(~ !is.list(.))) %>%
    filter(finalized == TRUE) %>%
    bind_rows(read_csv("data/calendario_historico.csv", show_col_types = FALSE)) %>%
    distinct(id, .keep_all = TRUE) %>%
    write.csv("data/calendario_historico.csv", row.names = FALSE)
}

actualiza_calendario(91)
