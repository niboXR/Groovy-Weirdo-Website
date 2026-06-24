
html_files <- list.files("docs", pattern = "\\.html$", recursive = TRUE, full.names = TRUE)

for (filepath in html_files) {
  html <- readLines(filepath, encoding = "UTF-8", warn = FALSE)
  text <- paste(html, collapse = "\n")
  
  seen <- c()
  matches <- gregexpr('id="([^"]+)"', text, perl = TRUE)
  ids <- regmatches(text, matches)[[1]]
  
  for (id_attr in ids) {
    id_val <- sub('id="([^"]+)"', "\\1", id_attr)
    if (id_val %in% seen) {
      text <- sub(paste0(' id="', id_val, '"'), "", text, fixed = TRUE)
    } else {
      seen <- c(seen, id_val)
      text <- sub(paste0('id="', id_val, '"'), paste0('id="KEEP_', id_val, '"'), text, fixed = TRUE)
    }
  }
  
  text <- gsub('id="KEEP_', 'id="', text, fixed = TRUE)
  
  writeLines(text, filepath, useBytes = FALSE)
  cat("Deduplicated:", filepath, "\n")
}