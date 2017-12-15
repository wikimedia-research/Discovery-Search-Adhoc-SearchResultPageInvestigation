library(magrittr)

# library(ggforce) # devtools::install_github('thomasp85/ggforce')
# ?ggforce::geom_parallel_sets

flow <- list(
  nodes = data.frame(
    name = c(
      "Visited", # 0
      "Did not search", # 1
      "Searched", # 2
      "Tracked", # 3
      "Not tracked", # 4
      "Autocomplete only", # 5
      "Both types of search", # 6
      "Full-text only", # 7
      "Click", # 8
      "No Click" # 9
    ),
    group = c("User", "Action", "Action", "EL", "EL", "Search", "Search", "Search", "Clickthrough", "Clickthrough"),
    stringsAsFactors = FALSE
  ),
  links = as.data.frame(magrittr::set_colnames(do.call(rbind, list(
    c(0, 1, 50),
    c(0, 2, 50),
    c(2, 3, 1), # 1 in 2000 get selected for event logging
    c(2, 4, 1999),
    c(3, 5, 75),
    c(3, 6, 19),
    c(3, 7, 6),
    c(5, 8, 89),
    c(5, 9, 11),
    c(6, 8, 66),
    c(6, 9, 34),
    c(7, 8, 35),
    c(7, 9, 65)
  )), c("source", "target", "value")))
)

# flow_v2 <- flow$links
# flow_v2$source %<>% factor(., 0:9, flow$nodes$name)
# flow_v2$target %<>% factor(., 0:9, flow$nodes$name)
# flow_v2 %<>%
#   gather_set_data(1:2)

library(networkD3) # install.packages("networkD3")
sankeyNetwork(
  Links = flow$links, Nodes = flow$nodes, Source = "source",
  Target = "target", Value = "value", NodeID = "name",
  units = "%", nodeWidth = 30, NodeGroup = "group",
  fontSize = 12, fontFamily = "Source Sans Pro"
)

library(sankey) # devtools::install_github("mangothecat/sankey")
flow_v3 <- flow
names(flow_v3$links)[3] <- "weight"
flow_v3$links$source <- flow_v3$nodes$name[flow_v3$links$source + 1]
flow_v3$links$target <- flow_v3$nodes$name[flow_v3$links$target + 1]
flow_v3$links %<>%
  dplyr::mutate(
    curvestyle = "sin",
    col = "#000000"
  )
flow_v3$nodes %<>%
  dplyr::mutate(
    col = "#f0f0f0",
    srt = 0
  )
s <- make_sankey(flow_v3$nodes, flow_v3$link, gravity = "top")
plot(s)
