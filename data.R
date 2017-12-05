# Since Analytics removed log DB from analytics-store on 2017-11-28, this script cannot be run onwards.

library(magrittr)

if (!grepl("^stat1", Sys.info()["nodename"])) {
  message("Creating an auto-closing SSH tunnel in the background...")
  # See https://gist.github.com/scy/6781836 for more info.
  system("ssh -f -o ExitOnForwardFailure=yes stat1006.eqiad.wmnet -L 3307:db1108.eqiad.wmnet:3306 sleep 10")
  library(RMySQL)
  con <- dbConnect(MySQL(), host = "127.0.0.1", group = "client", dbname = "log", port = 3307)
} else {
  con <- wmf::mysql_connect("log", hostname = "db1108.eqiad.wmnet")
}

revision <- 16909631; wiki <- "enwiki"
query <- paste0(readr::read_lines("events.sql"), collapse = "\n")

end_date <- Sys.Date() - 1
start_date <- end_date - 14

results <- do.call(rbind, lapply(seq(start_date, end_date, "day"), function(ref_date) {
  start_date <- format(ref_date, "%Y%m%d")
  end_date <- format(ref_date + 1, "%Y%m%d")
  query <- glue::glue(query)
  result <- wmf::mysql_read(query, "log", con = con)
  result$ts %<>% lubridate::ymd_hms()
  result$date <- as.Date(result$ts)
  result <- result[order(result$session_id, result$event_id, result$ts), ]
  result <- result[!duplicated(result$event_id), ]
  return(result)
}))

results <- results[order(results$date, results$session_id, results$ts), ]

wmf::mysql_close(con)

# namespaces <- dplyr::data_frame(
#   id = c(0:15, 100, 101, 108, 109, 118, 119, 828, 829, 2300, 2301, 2302, 2303, -1, -2),
#   namespace = c(
#     "Main/Article", "Talk",
#     paste0(as.vector(vapply(c(
#       "User", "Wikipedia", "File", "MediaWiki", "Template", "Help", "Category", "Portal", "Book", "Draft", "Module", "Gadget", "Gadget definition"
#     ), rep.int, c("", ""), times = 2)), c("", " Talk")),
#     "Special", "Media"
#   )
# )
# results %<>%
#   dplyr::left_join(namespaces, by = c("article_ns" = "id")) %>%
#   dplyr::select(-article_ns)

if (!dir.exists("data")) dir.create("data")
readr::write_rds(results, file.path("data", "events.rds"))
