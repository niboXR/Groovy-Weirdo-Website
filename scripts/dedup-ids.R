library(xml2)

html_files <- list.files("docs", pattern = "\\.html$", recursive = TRUE, full.names = TRUE)

for (filepath in html_files) {
  doc <- read_html(filepath)
  
  seen <- c()
  nodes <- xml_find_all(doc, "//*[@id]")
  
  for (node in nodes) {
    id <- xml_attr(node, "id")
    if (id %in% seen) {
      xml_attr(node, "id") <- NULL
    } else {
      seen <- c(seen, id)
    }
  }
  
  write_html(doc, filepath)
  cat("Deduplicated:", filepath, "\n")
}