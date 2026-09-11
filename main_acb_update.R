source("setup.R")

# Refresca horarios (por si sale el calendario de Copa/Supercopa) y sale si hoy
# no hay partidos: así el cron puede correr cada 10 min todos los días sin gastar.
source("scripts/06_horarios.R")

hay_partido_hoy <- read_csv("data/horarios.csv", show_col_types = FALSE) %>%
  filter(as_date(cuando) == today()) %>%
  nrow() > 0

if (!hay_partido_hoy) {
  quit(save = "no")
}

# Hay partidos hoy: cada script corre su parte incremental (los backfill_*() no).
source("scripts/01_calendario.R")
source("scripts/02_pbp.R")
source("scripts/03_boxscore.R")
source("scripts/04_stats_equipos.R")
source("scripts/05_pbp_clean.R")
