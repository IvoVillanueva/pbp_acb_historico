source("setup.R")

if (!dir.exists("data_boxscores")) dir.create("data_boxscores")

# Backfill boxscore: 3 competiciones desde 1983 -> data_boxscores/boxscore_acb_{año}.csv

calendario <- read_csv("data/calendario_historico.csv", show_col_types = FALSE) %>%
  filter(edition_year >= 1983)

boxdf <- function(id_m) {
  url <- paste0(acb_api, "Boxscore/playermatchstatistics?idMatch=", id_m)
  Sys.sleep(0.5)
  box <- fromJSON(content(GET(url, add_headers(authorization = auth)), "text"))
  if (length(box) == 0) {
    return(NULL)
  }
  box %>%
    tibble() %>%
    unnest(
      c(competition, edition, local_team, visitor_team, license),
      names_sep = "_"
    ) %>%
    select(where(~ !is.list(.)))
}

boxscore_temporada <- function(temporada) {
  fichero <- paste0("data_boxscores/boxscore_acb_", temporada, ".csv")
  if (file.exists(fichero)) {
    return(invisible(NULL))
  }
  calendario %>%
    filter(edition_year == temporada) %>%
    pull(id) %>%
    map_df(boxdf) %>%
    write.csv(fichero, row.names = FALSE)
}

walk(sort(unique(calendario$edition_year)), boxscore_temporada)

# boxscore <- list.files("data_boxscores", full.names = TRUE) %>%
#   map_df(~ read_csv(.x, show_col_types = FALSE, col_types = cols(pno = "c")))
#
