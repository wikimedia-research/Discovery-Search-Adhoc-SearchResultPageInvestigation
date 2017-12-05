SELECT
  ts, session_id, event_id, event, source,
  input_location, results_returned, query,
  -- page_title AS article_title,
  -- page_namespace AS article_ns,
  article_id, click_position
FROM (
  SELECT
    timestamp AS ts,
    event_searchSessionId AS session_id,
    event_uniqueId AS event_id,
    event_action AS event,
    event_source AS source,
    event_inputLocation AS input_location,
    event_hitsReturned AS results_returned,
    event_query AS query,
    event_articleId AS article_id,
    event_position AS click_position
  FROM log.TestSearchSatisfaction2_{revision}
  WHERE timestamp >= '{start_date}'
    AND timestamp < '{end_date}'
    AND wiki = '{wiki}'
    AND event_subTest IS NULL
    AND event_action IN('searchResultPage', 'click')
) AS events
-- LEFT JOIN {wiki}.page AS pages
--  ON events.article_id = pages.page_id;
