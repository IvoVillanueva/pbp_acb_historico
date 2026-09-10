source("setup.R")

if (!dir.exists("data_pbp_clean")) dir.create("data_pbp_clean")

# pbp limpio por temporada (2016 en adelante):
# valoración y flags por evento + quinteto en pista -> data_pbp_clean/pbp_clean_acb_{año}.csv

jornadas <- read_csv("data/calendario_historico.csv", show_col_types = FALSE) %>%
  select(
    id_match = id, matchweek_number, week_description,
    abb_local = local_team_team_abbrev_name
  )

enriquece <- function(pbp) {
  pbp %>%
    select(
      id_competition, edition_year, id_match, matchweek_number, week_description, order,
      abb_local,
      abb = team_team_abbrev_name, license_id, license_licenseStr15,
      license_licenseAbbrev, license_licenseNick,
      id_play = id_playbyplaytype, type_description, type_normalized_description,
      local, period, minute, second, crono, score_local, score_visitor, wall_clock
    ) %>%
    arrange(id_match, order) %>%
    group_by(id_match) %>%
    mutate(
      player_asist = if_else(str_detect(type_description, "Asistencia"),
        license_licenseStr15, NA_character_
      ),
      player_shoot = if_else(str_detect(type_description, "Asistencia"),
        lag(license_licenseStr15), NA_character_
      ),
      asist_type = if_else(str_detect(type_description, "Asistencia"),
        lag(type_description), NA_character_
      ),
      recovered_block = if_else(
        type_description == "Rebote Defensivo" & lead(type_description) == "Tapón",
        1, 0,
        missing = 0
      ),
      player_points = case_when(
        type_normalized_description == "2-Point Shot Made" ~ 2,
        type_normalized_description == "Dunk" ~ 2,
        type_normalized_description == "3-Point Shot Made" ~ 3,
        type_normalized_description == "Free Throw Made" ~ 1,
        TRUE ~ 0
      ),
      msg_type = case_when(
        type_description %in% c("Intento fallado de 2", "Intento fallado de 3", "Mate fuera") ~ 1,
        type_description %in% c("Canasta de 2", "Canasta de 3", "Mate") ~ 2,
        type_description %in% c("Intento fallado de 1", "Canasta de 1") ~ 3,
        TRUE ~ 0
      ),
      three_make = if_else(type_normalized_description == "3-Point Shot Made", 1, 0),
      three_misses = if_else(type_normalized_description == "3-Point Shot Missed", 1, 0),
      two_make = if_else(type_normalized_description == "2-Point Shot Made", 1, 0),
      two_misses = if_else(type_normalized_description == "2-Point Shot Missed", 1, 0),
      free_make = if_else(type_normalized_description == "Free Throw Made", 1, 0),
      free_misses = if_else(type_normalized_description == "Free Throw Missed", 1, 0),
      dunk = if_else(type_normalized_description == "Dunk", 1, 0),
      dunk_misses = if_else(type_normalized_description == "Missed Dunk", 1, 0),
      valoracion = case_when(
        type_normalized_description == "2-Point Shot Made" ~ 2,
        type_normalized_description == "3-Point Shot Made" ~ 3,
        type_normalized_description == "Free Throw Made" ~ 1,
        type_normalized_description == "Free Throw Missed" ~ -1,
        type_normalized_description == "2-Point Shot Missed" ~ -1,
        type_normalized_description == "3-Point Shot Missed" ~ -1,
        type_normalized_description == "Defensive Rebound" ~ 1,
        type_normalized_description == "Block Received" ~ -1,
        type_normalized_description == "Assist 3-Point Shot" ~ 1,
        type_normalized_description == "Block" ~ 1,
        type_normalized_description == "Unsportsmanlike 2FT" ~ -1,
        type_normalized_description == "Double Foul - No FT" ~ -1,
        type_normalized_description == "Foul No FT" ~ -1,
        type_normalized_description == "Offensive Rebound" ~ 1,
        type_normalized_description == "Assist 2-Point Shot" ~ 1,
        type_normalized_description == "Offensive Foul" ~ -1,
        type_normalized_description == "Foul Received" ~ 1,
        type_normalized_description == "Foul 2FT" ~ -1,
        type_normalized_description == "Turnover" ~ -1,
        type_normalized_description == "Steal" ~ 1,
        type_normalized_description == "Foul 1FT" ~ -1,
        type_normalized_description == "Foul 3FT" ~ -1,
        type_normalized_description == "Technical Foul 1FT" ~ -1,
        type_normalized_description == "Double Unsportsmanlike - No FT" ~ -1,
        type_normalized_description == "Assist Foul Received" ~ 1,
        type_normalized_description == "Missed Dunk" ~ -1,
        type_normalized_description == "Dunk" ~ 2,
        TRUE ~ 0
      ),
      reboundOff = if_else(type_normalized_description == "Offensive Rebound", 1, 0),
      reboundDef = if_else(type_normalized_description == "Defensive Rebound", 1, 0),
      rebounds = if_else(
        type_normalized_description %in% c("Defensive Rebound", "Offensive Rebound"), 1, 0
      ),
      asistencias = if_else(str_detect(type_normalized_description, "Assist"), 1, 0),
      pts_diff = abs(score_local - score_visitor)
    ) %>%
    ungroup()
}

# Quinteto en pista para cada evento de un partido.
# - El equipo de cada jugador se toma de su equipo más frecuente en el partido
#   (no del tag de la fila, que la fuente a veces etiqueta mal en los cambios).
# - Dentro de cada equipo, la n-ésima salida se empareja con la n-ésima entrada
#   y el cambio se aplica en el `order` de la salida (la entrada a veces se
#   registra decenas de eventos después).
# - Si el que entra ya está en pista, no se hace nada (evita duplicados).
quinteto_partido <- function(ev) {
  ev <- arrange(ev, order)
  home <- ev$abb_local[1]
  ev <- ev %>%
    left_join(
      ev %>%
        filter(!is.na(license_licenseStr15), !is.na(abb)) %>%
        count(license_licenseStr15, abb) %>%
        group_by(license_licenseStr15) %>%
        slice_max(n, n = 1, with_ties = FALSE) %>%
        ungroup() %>%
        transmute(license_licenseStr15, lado = if_else(abb == home, "h", "a")),
      by = "license_licenseStr15"
    )

  sf <- ev %>%
    filter(type_normalized_description == "Starting Five") %>%
    slice_head(n = 10)
  inicial <- set_names(
    c(
      (sf %>% filter(lado == "a" | is.na(lado)) %>% pull(license_licenseStr15))[1:5],
      (sf %>% filter(lado == "h") %>% pull(license_licenseStr15))[1:5]
    ),
    c(paste0("a", 1:5), paste0("h", 1:5))
  )

  subs <- ev %>%
    filter(str_detect(type_normalized_description, "Substitution")) %>%
    transmute(
      order, lado,
      rol = if_else(type_normalized_description == "Substitution - Out", "sale", "entra"),
      jugador = license_licenseStr15
    ) %>%
    group_by(lado, rol) %>%
    mutate(k = row_number()) %>%
    ungroup()
  pares <- inner_join(
    subs %>% filter(rol == "sale") %>% select(lado, k, order, sale = jugador),
    subs %>% filter(rol == "entra") %>% select(lado, k, entra = jugador),
    by = c("lado", "k")
  ) %>%
    arrange(order)

  estados <- accumulate(seq_len(nrow(pares)), .init = inicial, function(lineup, i) {
    slots <- paste0(pares$lado[i], 1:5)
    if (pares$entra[i] %in% lineup[slots]) {
      return(lineup)
    }
    j <- match(pares$sale[i], lineup[slots])
    if (is.na(j)) j <- match(NA, lineup[slots])
    if (!is.na(j)) lineup[slots[j]] <- pares$entra[i]
    lineup
  })

  idx <- map_int(ev$order, ~ sum(pares$order <= .x)) + 1L
  bind_cols(ev, map_df(estados[idx], as_tibble_row))
}

clean_temporada <- function(temporada) {
  fichero <- paste0("data_pbp_clean/pbp_clean_acb_", temporada, ".csv")
  if (file.exists(fichero)) {
    return(invisible(NULL))
  }
  read_csv(paste0("data_pbps/pbp_acb_", temporada, ".csv"), show_col_types = FALSE) %>%
    left_join(jornadas, by = "id_match") %>%
    enriquece() %>%
    group_split(id_match) %>%
    map_df(quinteto_partido) %>%
    write.csv(fichero, row.names = FALSE)
}

años <- list.files("data_pbps") %>%
  str_extract("[0-9]{4}") %>%
  as.integer() %>%
  sort()

walk(años, clean_temporada)



# pbp_clean <- list.files("data_pbp_clean", full.names = TRUE) %>%
#   map_df(~ read_csv(., show_col_types = FALSE))
