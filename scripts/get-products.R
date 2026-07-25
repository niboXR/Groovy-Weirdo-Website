#####################################
# Exchange client details for token #
#####################################
library(httr2)
library(jsonlite)
library(dplyr)
library(tidyr)
library(purrr)
library(stringr)
library(readr)
library(glue)
library(htmltools)  # for safe HTML escaping

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


# Halt render if product count hits the single-page API limit
if (nrow(shopify_products) >= 250) {
  stop(
    "\n\n",
    "==================== QUARTO RENDER HALTED ====================\n",
    "Shopify product count has reached 250, the per-page API limit.\n",
    "Shop data may now be incomplete.\n\n",
    "Action needed: update the product pull to use pagination before\n",
    "re-rendering this site.\n",
    "================================================================\n",
    call. = FALSE
  )}

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


################################
# Create image gallery snippet #
################################ 

# 1. Define the function to generate a single snippet
generate_image_gallery <- function(id, handle) {
  
  
  # write image array to inject into image-scroller
  product_row <- shopify_products[shopify_products$handle == handle, ]
  
  images_df <- product_row$images[[1]]
  if (is.null(images_df) || nrow(images_df) == 0) {
    image_records <- list()
  } else {
    # Build src/label pairs
    src <- images_df$src
    
    # Use alt text as label; fall back to product title if alt is missing/blank
    label <- images_df$alt
    if (is.null(label)) label <- rep(NA_character_, length(src))
    fallback_title <- product_row$title[[1]]
    label <- ifelse(is.na(label) | label == "", fallback_title, label)
    
    keep <- !is.na(src)
    image_records <- data.frame(src = src[keep], label = label[keep], stringsAsFactors = FALSE)
  }
  
  # Build JS array of objects: [{ src: "...", label: "..." }, ...]
  if (length(image_records) == 0 || nrow(image_records) == 0) {
    js_array <- "[]"
  } else {
    js_array <- toJSON(image_records, dataframe = "rows", auto_unbox = TRUE, pretty = TRUE)
  }
  
  js_code <- paste0("const images = ", js_array, ";")
  
  # get template image gallery
  image_scroller_html <- paste(readLines("_includes/image-scroller.html", warn = FALSE), collapse = "\n")
  
  # update gallery
  updated_image_scroller_html <- gsub(
    pattern = 'const images = [];',
    replacement = js_code,
    x = image_scroller_html,
    fixed = TRUE
  )
  
  # save gallery
  new_filepath <- paste0("_includes/image-scroller-", handle, ".html")
  writeLines(updated_image_scroller_html, new_filepath)
  
}



# 2. Loop through the rows to generate all configurations
all_product_images <- lapply(1:nrow(products), function(i) {
  generate_image_gallery(
    id = products$id[i],
    handle   = products$handle[i]
  )
})


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

##################
# REVIEW CONTENT #
##################

  # Get orders data from shopify API for verification
  orders_url <- paste0("https://", shop_url, "/admin/api/", api_version, "/orders.json?status=any&limit=250")
  
  orders_resp <- request(orders_url) %>%
    req_headers(
      "X-Shopify-Access-Token" = access_token,
      "Content-Type"           = "application/json"
    ) %>% req_perform()
  
  rm(orders_url)

  shopify_orders <- orders_resp %>% resp_body_string() %>% fromJSON() # Parse and display the data frame
  shopify_orders <- shopify_orders$orders
  
  
  # Halt render if order count hits the single-page API limit
  if (nrow(shopify_orders) >= 250) {
    stop(
      "\n\n",
      "==================== QUARTO RENDER HALTED ====================\n",
      "Shopify order count has reached 250, the per-page API limit.\n",
      "Review verification data may now be incomplete.\n\n",
      "Action needed: update the order pull to use pagination before\n",
      "re-rendering this site.\n",
      "================================================================\n",
      call. = FALSE
    )}
    
  orders_for_verification <- shopify_orders %>%
    select(id, email, line_items) %>%
    unnest(line_items, names_sep = "_") %>%
    select(order_id = id, email, product_id = line_items_product_id, product_title = line_items_title) %>%
    mutate(
      order_id   = as.character(order_id),
      product_id = as.character(product_id),
      email = tolower(trimws(email))
    )


  # Get review data
  library(googlesheets4)
  
  # Rerun this if authorization expires
  # gs4_deauth()
  # gs4_auth(scopes = "spreadsheets", cache = FALSE)
  
  options(gargle_oauth_cache = ".secrets")
  gs4_auth(scopes = "spreadsheets", cache = ".secrets")
  
  sheet_url <- "https://docs.google.com/spreadsheets/d/1Y4kLf0jEiHy136NEQmvJPkpwuCMSk6FjM4WIxN23ZbI/edit?gid=0#gid=0"

  reviews <- read_sheet(sheet_url, sheet = "Reviews")  # update sheet name/gid as needed
  
  #function to make image links directly embeddable
  extract_drive_image_url <- function(drive_link, width = 300) {
    if (is.na(drive_link) || !nzchar(drive_link)) return(NA_character_)
    
    file_id <- stringr::str_extract(drive_link, "(?<=/d/)[a-zA-Z0-9_-]+")
    
    if (is.na(file_id)) return(NA_character_)
    
    paste0("https://lh3.googleusercontent.com/d/", file_id, "=w", width)
  }  
  
  reviews <- reviews %>%
    mutate(
      productId     = as.character(productId),
      reviewerEmail = tolower(trimws(reviewerEmail)),
      image = purrr::map_chr(image, extract_drive_image_url),
      verified = purrr::map2_lgl(
        productId, reviewerEmail,
        ~ any(orders_for_verification$product_id == .x & orders_for_verification$email == .y)
      )
      
    )
  
    # Filter to verified reviews
    verified_reviews <- reviews %>%
      filter(verified)


  # Build review content as HTML snippets from verified reviews
    output_dir <- "_includes/product-reviews"
    if (!dir.exists(output_dir)) dir.create(output_dir)
    
    # --- Step 1: Dedup — one review per reviewer per product, keep most recent ---
    verified_reviews <- verified_reviews %>%
      group_by(productId, reviewerEmail) %>%
      slice_max(order_by = Timestamp, n = 1, with_ties = FALSE) %>%
      ungroup()
    
    
    # --- Build review summary --- #
    build_star_svg <- function(fill_pct) {
      sprintf('
  <span class="rv-star" style="--rv-fill: %d%%;">
    <svg viewBox="0 0 83.77 83.07" class="rv-star-outline">
      <path d="M60.24,79.8l-17.23-17.74c-.22-.22-.57-.18-.75.06l-14.4,20.11c-1.21,1.71-3.91.64-3.63-1.43l3.12-24.53c.04-.29-.2-.57-.51-.55l-24.7,1.28c-2.09.11-2.94-2.64-1.16-3.74l21.14-12.86c.26-.17.31-.51.11-.73L5.81,21.14c-1.39-1.56.24-3.95,2.2-3.23l23.23,8.5c.29.11.61-.07.64-.37L36.15,1.67c.37-2.06,3.23-2.28,3.91-.29l7.84,23.47c.09.29.42.42.7.28l21.71-11.87c1.84-1.01,3.8,1.1,2.66,2.86l-13.45,20.75c-.17.26-.06.61.22.72l22.81,9.56c1.93.81,1.5,3.67-.59,3.87l-24.63,2.42c-.31.04-.51.33-.42.62l6.73,23.8c.57,2.02-1.93,3.45-3.39,1.96v-.02Z"/>
    </svg>
    <span class="rv-star-fill-clip">
      <svg viewBox="0 0 83.77 83.07" class="rv-star-fill-svg">
        <path d="M60.24,79.8l-17.23-17.74c-.22-.22-.57-.18-.75.06l-14.4,20.11c-1.21,1.71-3.91.64-3.63-1.43l3.12-24.53c.04-.29-.2-.57-.51-.55l-24.7,1.28c-2.09.11-2.94-2.64-1.16-3.74l21.14-12.86c.26-.17.31-.51.11-.73L5.81,21.14c-1.39-1.56.24-3.95,2.2-3.23l23.23,8.5c.29.11.61-.07.64-.37L36.15,1.67c.37-2.06,3.23-2.28,3.91-.29l7.84,23.47c.09.29.42.42.7.28l21.71-11.87c1.84-1.01,3.8,1.1,2.66,2.86l-13.45,20.75c-.17.26-.06.61.22.72l22.81,9.56c1.93.81,1.5,3.67-.59,3.87l-24.63,2.42c-.31.04-.51.33-.42.62l6.73,23.8c.57,2.02-1.93,3.45-3.39,1.96v-.02Z"/>
      </svg>
    </span>
  </span>', round(fill_pct))
    }
    
    build_star_row <- function(avg_rating) {
      purrr::map_chr(1:5, function(i) {
        fill <- max(0, min(1, avg_rating - (i - 1))) * 100
        build_star_svg(fill)
      }) %>% paste(collapse = "")
    }
    
    # --- Step 2: Build HTML per product ---
    build_review_html <- function(product_id) {
      
      product_reviews <- verified_reviews %>% filter(productId == product_id)
      
      if (nrow(product_reviews) == 0) {
        return('<p class="rv-no-reviews">This product does not have any reviews yet. Be the first to leave a review.</p>')      }
      
      ratings <- as.numeric(product_reviews$rating)
      avg_rating <- round(mean(ratings, na.rm = TRUE), 1)
      review_count <- nrow(product_reviews)
      
      summary_html <- sprintf(
        '<div class="rv-summary">
  <div class="rv-star-row">%s</div>
  <span class="rv-summary-count">%.1f stars based on %d review%s</span>
</div>',
        build_star_row(avg_rating),
        avg_rating, review_count, if (review_count == 1) "" else "s"
      )
      
      reviews_html <- product_reviews %>%
        pmap_chr(function(reviewerName, rating, image, reviewContent, ...) {
          
          rating <- as.numeric(rating)
          stars_filled <- strrep("★", rating)
          stars_empty  <- strrep("☆", 5 - rating)
          
          image_tag <- if (!is.na(image) && nzchar(image)) {
            sprintf(
              '<img src="%s" alt="Photo from %s" class="rv-review-image" loading="lazy">',
              htmlEscape(image), htmlEscape(reviewerName)
            )
          } else {
            ""
          }
          
          sprintf(
'<div class="rv-review">
  <div class="rv-review-header">
    <div class="rv-review-author">
      <span class="rv-display-name">%s</span>
      <span class="rv-verified-badge">
        <svg class="rv-verified-icon" viewBox="0 0 24 24" fill="none" aria-hidden="true">
          <path d="M9 12.5L11 14.5L15.5 9.5" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
          <circle cx="12" cy="12" r="10" stroke="currentColor" stroke-width="1.5"/>
        </svg>
        Verified
      </span>
    </div>
    <span class="rv-review-rating" aria-label="%s out of 5 stars">%s</span>
  </div>
  <div class="rv-review-body">
    <p class="rv-review-content">%s</p>
    %s
  </div>
</div>',
            htmlEscape(reviewerName),
            rating,
            build_star_row(rating),
            htmlEscape(reviewContent),
            image_tag
          )
        }) %>%
        paste(collapse = "\n")
      
      paste(summary_html, reviews_html, sep = "\n")
    }
    
    # --- Step 3: Write files ---
    all_product_ids <- shopify_products$id %>% as.character()
    
    walk(all_product_ids, ~ {
      html_content <- build_review_html(.x)
      wrapped_content <- paste0("```{=html}\n", html_content, "\n```\n")
      writeLines(wrapped_content, file.path(output_dir, paste0(.x, ".html")))
    })
  
  


########################
# REVIEW FORM SNIPPETS #
########################

# Define the function to generate a single snippet
all_review_forms <- function(id, handle) {
  
  generic_review_form <- paste(readLines("_includes/review-form.html", warn = FALSE), collapse = "\n")
  
  specific_review_form <- generic_review_form %>%
    gsub(pattern = 'SHOPIFY_PRODUCT_ID', replacement = id, x = ., fixed = TRUE) %>% #replace with real product id
    gsub(pattern = 'SHOPIFY_PRODUCT_HANDLE', replacement = handle, x = ., fixed = TRUE)
  
  new_filepath <- paste0("_includes/review-form-", handle, ".html")
  writeLines(specific_review_form, new_filepath)
  
}

# Loop through the rows to generate all html snippets
all_html_buttons <- lapply(1:nrow(products), function(i) {
  all_review_forms(
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
  
  #adds add button to yaml for listings
  add_button_html <- read_file(glue("_includes/add-button-{handle}.html"))
  indented_button <- paste0("  ", gsub("\n", "\n  ", add_button_html))
  
  
  markdown_content <- str_glue('
---
id: {id}
handle: {handle}
title-block-style: none
title: "{title}"
price: "${price}"
categories: "{product_type}"
desc: "{desc}"
image: "{image_link}"
sort-date: "{date}"
header-includes: |
  <style>#title-block-header {{ display: none; }}</style>
add-button: |
{indented_button}
---

{{{{< include ../_includes/image-scroller-{handle}.html >}}}}

# {title}
**${price}**

{desc}

{{{{< include ../_includes/buy-button-{handle}.html >}}}}

{{{{< include ../_includes/add-button-{handle}.html >}}}}

---

<section id="reviews">

  <!-- ONLY this header will be centered -->
  <h1 style="text-align: center;">Reviews</h1>

{{{{< include ../_includes/product-reviews/{id}.html >}}}}

</section>

---

<section id="leave-a-review">

  <!-- ONLY this header will be centered -->
  <h1 style="text-align: center;">Leave a Review</h1>

{{{{< include ../_includes/review-form-{handle}.html >}}}}

</section>


---

[Back to shop](../shop.html)


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