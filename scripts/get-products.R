#####################################
# Exchange client details for token #
#####################################
library(httr2)
library(jsonlite)
library(dplyr)
library(purrr)
library(stringr)
library(readr)
library(glue)

# Setup
shop_url <- "groovyweirdo.myshopify.com"
client_id <- "4abe712f0a06bc0dbe487a078432f006"
client_secret <- Sys.getenv("CLIENT_SECRET")
api_version <- "2026-04"


# Construct and execute the handshake request
token_url <- paste0("https://", shop_url, "/admin/oauth/access_token")

handshake_resp <- request(token_url) %>%
  req_headers("Content-Type" = "application/json") %>%
  req_body_json(list(
    client_id     = client_id,
    client_secret = client_secret,
    grant_type    = "client_credentials"  # Crucial for backend-to-backend apps
  )) %>%
  req_perform() # Execute the handshake

rm(client_id, client_secret)

# Parse the temporary access token from the handshake response
token_data   <- handshake_resp %>% resp_body_string() %>% fromJSON()
access_token <- token_data$access_token

print("Handshake successful! Access token acquired.")

rm(handshake_resp, token_data)

#################################
# Get Products from Shopify API #
#################################

# Construct the standard products endpoint URL
products_url <- paste0("https://", shop_url, "/admin/api/", api_version, "/products.json?limit=250")

# Query the products using the newly minted access token
product_resp <- request(products_url) %>%
  req_headers(
    "X-Shopify-Access-Token" = access_token,
    "Content-Type"           = "application/json"
  ) %>% req_perform()
  
rm(products_url)

# Parse and display the product data frame
shopify_products <- product_resp %>% resp_body_string() %>% fromJSON()
shopify_products <- shopify_products$products

#get clean data for pages
products <- shopify_products %>%
  filter(status == "active") %>% 
  rename(
    desc = body_html,
    date = published_at
    ) %>%
  mutate(
    id = format(id, scientific = FALSE),
    variant_count = sapply(shopify_products$variants, nrow),
    price = sapply(shopify_products$variants, function(df) df$price[1]),
    image = paste0("![",title,"](",image$src,")"),
    image_link = sapply(images, function(df) df$src[1]) # ! object of type closure is not subsettable
  ) %>%
  select(id, product_type, title, date, handle, desc, price, image, image_link)



##################################
# Create buy buttons html snippet #
################################## 

# Define the function to generate a single snippet

generate_shopify_buttons <- function(id, handle) {
  
  #add button
  add_button_html <- paste(readLines("_includes/add-button.html", warn = FALSE), collapse = "\n")
  
  updated_add_button_html <- add_button_html %>% 
    gsub(pattern = '8253393141826', replacement = id, x = ., fixed = TRUE) %>% #replace product id
    gsub(pattern = '1780618864944', replacement = handle, x = ., fixed = TRUE) #replace component id

  
  new_filepath <- paste0("_includes/add-button-", handle, ".html")
  writeLines(updated_add_button_html, new_filepath)
  
  #buy buttons
  buy_button_html <- paste(readLines("_includes/buy-button.html", warn = FALSE), collapse = "\n")
  
  updated_buy_button_html <- buy_button_html %>%
    gsub(pattern = '8253393141826', replacement = id, x = ., fixed = TRUE) %>% #replace product id
    gsub(pattern = '1780618864944', replacement = handle, x = ., fixed = TRUE) #replace component id
                                  
  
  new_filepath <- paste0("_includes/buy-button-", handle, ".html")
  writeLines(updated_buy_button_html, new_filepath)
  
}



# 3. Loop through the rows to generate all configurations
all_html_buttons <- lapply(1:nrow(products), function(i) {
  generate_shopify_buttons(
    id = products$id[i],
    handle   = products$handle[i]
  )
})


########################
# CREATE PRODUCT PAGES #
########################

output_dir <- "shop"
if (!dir.exists(output_dir)) dir.create(output_dir, recursive = TRUE)

# write function

write_product_markdown <- function(id, handle, title, product_type, date, desc, price, image, image_link) {
  filepath <- file.path(output_dir, paste0(handle, ".md"))
  
  # add_button_html <- paste(readLines("_includes/add-button.html", warn = FALSE), collapse = "\n")
  add_button_html <- read_file(glue("_includes/add-button-{handle}.html"))
  indented_button <- paste0("  ", gsub("\n", "\n  ", add_button_html))
  
  # Inject variables using str_glue. 
  # Backslashes escape quotes for valid YAML syntax inside the front matter.
  markdown_content <- str_glue('
---
id: {id}
handle: {handle}
title: "{title}"
price: "${price}"
categories: "{product_type}"
desc: "{desc}"
image: "{image_link}"
sort-date: "{date}"
add-button: |
{indented_button}
---

{image}{{.align-left style="max-width: 600px; width: 100%;"}}

**{price}**

{desc}

{{{{< include ../_includes/buy-button-{handle}.html >}}}}

{{{{< include ../_includes/add-button-{handle}.html >}}}}

# Reviews

This product does not have any reviews yet. Come back later to see reviews from verified buyers. 

')

  # Write the string to a file using UTF-8 encoding
  write_lines(markdown_content, filepath)
}


# 4. Iterate through rows and write files
pwalk(
  list(
    id = products$id,
    handle = products$handle,
    title = products$title,
    price = products$price,
    desc = products$desc,
    image = products$image,
    image_link = products$image_link,
    date = products$date,
    product_type = products$product_type
  ),
  write_product_markdown
)

cat(sprintf("Success: Generated %d product files.\n", nrow(products)))