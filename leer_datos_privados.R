library(httr)
library(readr)

# GITHUB_PAT: Settings (GitHub) -> Developer settings -> Personal access
# tokens -> Fine-grained -> solo lectura de "Contents" en este repo.
# Se guarda en .Renviron como GITHUB_PAT=... Sin token, solo funciona si el
# repo es público.

leer_csv_github <- function(path, repo = "IvoVillanueva/pbp_acb_historico", branch = "main") {
  url <- paste0("https://api.github.com/repos/", repo, "/contents/", path, "?ref=", branch)
  pat <- Sys.getenv("GITHUB_PAT")
  headers <- c(Accept = "application/vnd.github.raw")
  if (nzchar(pat)) {
    headers["Authorization"] <- paste("Bearer", pat)
  }
  res <- GET(url, add_headers(.headers = headers))
  stop_for_status(res)
  read_csv(I(content(res, "text")), show_col_types = FALSE)
}

calendario <- leer_csv_github("data/calendario_historico.csv")
