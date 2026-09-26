source("setup.R")

# Horarios de la temporada en curso (comp 1-3) -> data/horarios.csv

ed <- temporada_actual() - 1935

jornadas <- read_csv("data/ids_partidos_historico.csv", show_col_types = FALSE) %>%
  filter(id_edition == ed) %>%
  select(id_competition, id)

una_jornada <- function(id_competition, id_matchweek) {
  link <- paste0(
    acb_api, "Matches/matchesbymatchweeklite?idCompetition=", id_competition,
    "&idEdition=", ed, "&idMatchweek=", id_matchweek
  )
  Sys.sleep(0.5)
  m <- fromJSON(content(GET(link, add_headers(authorization = auth)), "text"))
  if (length(m) == 0) {
    return(NULL)
  }
  m %>%
    tibble() %>%
    unnest(c(local_team, visitor_team), names_sep = "_") %>%
    transmute(
      id, id_competition,
      jornada = matchweek_number,
      local = local_team_team_abbrev_name,
      visitante = visitor_team_team_abbrev_name,
      finalized,
      cuando = with_tz(as_datetime(date) + seconds(time), "Europe/Madrid")
    )
}

map2_df(jornadas$id_competition, jornadas$id, una_jornada) %>%
  arrange(cuando) %>%
  write.csv("data/horarios.csv", row.names = FALSE)
