# Actualización en temporada: cada script sourceado corre su parte incremental
# (los backfill_*() no se llaman). Orden: calendario primero, pbp_clean último.
# Correr desde la raíz del repo.
source("scripts/01_calendario.R")
source("scripts/02_pbp.R")
source("scripts/03_boxscore.R")
source("scripts/04_stats_equipos.R")
source("scripts/05_pbp_clean.R")
