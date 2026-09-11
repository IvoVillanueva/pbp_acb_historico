
source("setup.R")

headers <- c(
  "accept" = "*/*",
  "accept-language" = "es-ES,es;q=0.9,en;q=0.8",
  "origin" = "https://live.acb.com",
  "referer" = "https://live.acb.com/",
  "user-agent" = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/140.0.0.0 Safari/537.36",
  "x-apikey" = "0dd94928-6f57-4c08-a3bd-b1b2f092976e"
)


url = "https://api2.acb.com/api/seasondata/Competition/matches?competitionId=1&isRoundSelected=false"

res <- GET(url = url, add_headers(.headers = headers))
json_resp <- fromJSON(content(res, "text"))

 pluck(json_resp, "matches") 
 








