source("setup.R")

# Refresca horarios (por si sale el calendario de Copa/Supercopa) y sale si
# ningún partido empezó en las últimas 24 horas: así el cron puede correr cada
# hora sin gastar, y un partido que acaba pasada la medianoche (en UTC, la hora
# del runner) aún tiene su pasada final. A mano (workflow_dispatch) corre siempre.
source("scripts/06_horarios.R")

hay_partido_reciente <- read_csv("data/horarios.csv", show_col_types = FALSE) %>%
  filter(between(cuando, now() - hours(24), now())) %>%
  nrow() > 0

if (!hay_partido_reciente && Sys.getenv("GITHUB_EVENT_NAME") != "workflow_dispatch") {
  quit(save = "no")
}

# Cada script corre su parte incremental (los backfill_*() no).
source("scripts/01_calendario.R")
source("scripts/02_pbp.R")
source("scripts/03_boxscore.R")
source("scripts/04_stats_equipos.R")
source("scripts/05_pbp_clean.R")
