# Actualización en temporada: cada script sourceado corre su parte incremental
# (los backfill_*() no se llaman). Orden: calendario primero, pbp_clean último.
source("01_calendario.R")
source("02_pbp.R")
source("03_boxscore.R")
source("04_stats_equipos.R")
source("05_pbp_clean.R")
