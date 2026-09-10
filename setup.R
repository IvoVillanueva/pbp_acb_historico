library(tidyverse)
library(jsonlite)
library(httr)

auth <- Sys.getenv("ACB_TOKEN")
acb_api <- Sys.getenv("ACB_API")

# Año de la temporada en curso (salta en septiembre, cuando arranca la Supercopa)
temporada_actual <- function() {
  hoy <- today()
  if (month(hoy) >= 9) year(hoy) else year(hoy) - 1
}
