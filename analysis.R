library(magrittr)
library(ggplot2)

events <- readr::read_rds(file.path("data", "events.rds")) %>%
  dplyr::mutate(date = as.Date(ts)) %>%
  dplyr::group_by(session_id) %>%
  dplyr::mutate(
    first_ts = min(ts),
    query_length = nchar(query)
  ) %>%
  dplyr::ungroup() %>%
  dplyr::arrange(first_ts, session_id, ts, source, query_length) %>%
  dplyr::select(-c(first_ts, event_id)) %>%
  dplyr::group_by(session_id) %>%
  dplyr::ungroup() %>%
  dplyr::select(session_id, date, ts, event, source, input_location, query, dplyr::everything())

# events %>%
#   dplyr::group_by(session_id) %>%
#   dplyr::summarize(session_length = max(ts) - min(ts)) %>%
#   dplyr::arrange(desc(session_length)) %>%
#   View

events$auto2full <- FALSE
pb <- progress::progress_bar$new(total = nrow(events))
for (i in 3:nrow(events)) {
  if (
    events$session_id[i - 1] == events$session_id[i] &&
    events$source[i - 1] == "autocomplete" &&
    events$event[i - 1] == "click" &&
    events$click_position[i - 1] == -1 &&
    events$source[i] == "fulltext" &&
    events$event[i] == "searchResultPage"
  ) {
    events$auto2full[i - 1] <- TRUE
    events$auto2full[i] <- TRUE
    if (
      events$session_id[i - 2] == events$session_id[i - 1] &&
      events$source[i - 2] == "autocomplete" &&
      events$event[i - 2] == "searchResultPage"
    ) {
      if (
        events$auto2full[i] &&
        !(
          grepl(events$query[i - 2], events$query[i], fixed = TRUE) ||
          stringdist::stringsim(events$query[i - 2], events$query[i], method = "lcs") >= 0.7
        )
      ) {
        events$auto2full[c(i - 2, i - 1, i)] <- NA
      } else {
        events$auto2full[c(i - 2, i - 1, i)] <- TRUE
      }
    } else {
      events$auto2full[c(i - 2, i - 1, i)] <- NA
    }
  }
  pb$tick()
}; rm(i, pb)

events %<>%
  dplyr::group_by(session_id) %>%
  dplyr::summarize(
    tainted = any(is.na(auto2full)),
    multiday = (max(date) - min(date)) > 1,
    pages_visited = length(unique(article_id))
  ) %T>%
  {
    message("Removing ", sum(.$tainted), " sessions that exhibit weird event flow.")
    message("Removing ", sum(.$multiday), " sessions that happened over multiple days.")
    message("Removing ", sum(.$pages_visited > 15), " sessions that visited more than 15 pages.")
  } %>%
  dplyr::filter(!(tainted | multiday | pages_visited > 15)) %>%
  dplyr::select(-c(tainted, multiday, pages_visited)) %>%
  dplyr::left_join(events, by = "session_id")

condense <- function(df) {
  if (nrow(df) > 1) {
    substrings <- logical(nrow(df))
    for (i in 2:nrow(df)) {
      if (!any(is.na(df$query[c(i - 1, i)]))) {
        if (
          grepl(df$query[i - 1], df$query[i], fixed = TRUE) ||
          df$query[i - 1] == df$query[i]
        ) {
          substrings[i - 1] <- TRUE
        }
      }
    }
    return(df[!substrings, ])
  } else {
    return(df)
  }
}
condensed <- events %>%
  dplyr::group_by(session_id) %>%
  dplyr::do(condense(.)) %>%
  dplyr::ungroup()

condensed %>%
  dplyr::group_by(session_id) %>%
  dplyr::summarize(both = all(c("autocomplete", "fulltext") %in% source)) %>%
  dplyr::ungroup() %>%
  dplyr::filter(both) %>%
  dplyr::inner_join(condensed) %>%
  View

# % of Searches
events %>%
  dplyr::group_by(session_id) %>%
  dplyr::summarize(
    auto = "autocomplete" %in% source,
    full = "fulltext" %in% source,
    date = min(date)
  ) %>%
  tidyr::gather("search", "uses", -c(session_id, date)) %>%
  dplyr::group_by(date, search) %>%
  dplyr::summarize(prop = 100 * mean(uses)) %>%
  tidyr::spread(search, prop) %>%
  summary
events %>%
  dplyr::group_by(session_id) %>%
  dplyr::summarize(
    uses = dplyr::case_when(
      "autocomplete" %in% source && !("fulltext" %in% source) ~ "autocomplete only",
      !("autocomplete" %in% source) && "fulltext" %in% source ~ "full-text only",
      TRUE ~ "both"
    ),
    date = min(date)
  ) %>%
  dplyr::group_by(date, uses) %>%
  dplyr::summarize(sessions = n()) %>%
  dplyr::group_by(date) %>%
  dplyr::mutate(prop = 100 * sessions / sum(sessions)) %>%
  dplyr::select(-sessions) %>%
  dplyr::ungroup() %>%
  tidyr::spread(uses, prop) %>%
  summary

# Clickthrough Rate -- need to exclude clicks from auto to full-text SRP
events %>%
  dplyr::group_by(date, session_id) %>%
  dplyr::summarize(
    max_results = max(results_returned, na.rm = TRUE),
    uses = dplyr::case_when(
      "autocomplete" %in% source && !("fulltext" %in% source) ~ "autocomplete only",
      !("autocomplete" %in% source) && "fulltext" %in% source ~ "full-text only",
      TRUE ~ "both"
    ),
    clickthrough = any(event == "click" & !auto2full),
    auto_clickthru = any(event[source == "autocomplete" & !auto2full] == "click"),
    full_clickthru = any(event[source == "fulltext" & !auto2full] == "click")
  ) %>%
  dplyr::ungroup() %>%
  dplyr::filter(max_results > 0) %>%
  dplyr::group_by(date, uses) %>%
  dplyr::summarize(
    ctr = mean(clickthrough, na.rm = TRUE),
    auto_ctr = mean(auto_clickthru, na.rm = TRUE),
    full_ctr = mean(full_clickthru, na.rm = TRUE)
  ) %>%
  dplyr::ungroup() %>%
  dplyr::mutate(uses = factor(uses)) %>%
  View

auto2full <- events %>%
  dplyr::group_by(date, session_id) %>%
  dplyr::filter("click" %in% event && "autocomplete" %in% source) %>%
  dplyr::summarize(
    # Detect whether an autocomplete click was immediately followed by a full-text SRP:
    # switched = any((which(event == "click" & source == "autocomplete") + 1) %in% which(event == "searchResultPage" & source == "fulltext")),
    switchedV2 = any(auto2full),
    used_fulltext = "fulltext" %in% source,
    `full-text but not switched` = any(event == "searchResultPage" & source == "fulltext" & !auto2full)
  ) %>%
  dplyr::ungroup()
auto2full %>%
  dplyr::group_by(date) %>%
  dplyr::summarize(
    # `went to full-text SRP from autocomplete` = 100 * mean(switched),
    `went to full-text SRP from autocomplete (v2)` = 100 * mean(switchedV2),
    `used full-text but separate from autocomplete` = 100 * mean(`full-text but not switched`),
  ) %>%
  View

events %>%
  dplyr::group_by(date, session_id) %>%
  dplyr::summarize(
    used_auto = "autocomplete" %in% source,
    used_full = "fulltext" %in% source
  ) %>%
  dplyr::ungroup() %>%
  dplyr::filter(used_full) %>%
  dplyr::inner_join(events, by = c("date", "session_id")) %>%
  dplyr::group_by(date, session_id) %>%
  dplyr::top_n(1, dplyr::desc(ts)) %>%
  dplyr::group_by(date, source) %>%
  dplyr::tally() %>%
  dplyr::mutate(n = 100 * n / sum(n)) %>%
  tidyr::spread(source, n) %>%
  View
