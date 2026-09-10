# Actualización en temporada: cada script sourceado corre su parte incremental
# (los backfill_*() no se llaman). Orden: calendario primero, pbp_clean último.
source("calendario.R")
source("pbp.R")
source("boxscore.R")
source("stats_equipos.R")
source("pbp_clean.R")
