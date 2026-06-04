
##################################
# Get Homepage and name it index #
##################################

source_file <- "../../Homepage.md"
copied_file   <- "index.md"

if (file.exists(source_file)) {
  file.copy(from = source_file, to = copied_file, overwrite = TRUE)
  message("Homepage successfully copied and renamed to index.md")
} else {
  stop("Error: Source file '../../Homepage.md' not found.")
}


#########
# PAGES #
#########

# Define directory paths
source_dir <- "../../Pages"
dest_dir   <- "pages"

# 1. Create local pages directory if it does not exist
if (!dir.exists(dest_dir)) {
  dir.create(dest_dir, recursive = TRUE)
}

# 2. Verify source directory exists, then copy files
if (dir.exists(source_dir)) {
  
  # Find all .md files in the source directory
  files_to_copy <- list.files(path = source_dir, pattern = "\\.md$", full.names = TRUE)
  
  if (length(files_to_copy) > 0) {
    # Build the matching destination file paths
    dest_files <- file.path(dest_dir, basename(files_to_copy))
    
    dest_files <- gsub(" ", "-", tolower(dest_files))
    
    # Copy all files at once
    file.copy(from = files_to_copy, to = dest_files, overwrite = TRUE)
    message(paste("Successfully synced", length(files_to_copy), "pages to pages/"))
  } else {
    message("No .md files found in the source Pages directory.")
  }
  
} else {
  stop("Error: Source directory '../../Pages' not found.")
}

# Replace dynamic metadata from Obsidian {{property}} with format for quarto {{< meta property >}} 
for (file_path in dest_files) {
  # 1. Read the file contents line by line
  file_contents <- readLines(file_path, warn = FALSE)
  
  # 2. Match dynamic text inside {{}} and replace with {{< meta property >}}
  # \\1 represents the exact text captured inside the ([A-Za-z0-9_-]+) group
  modified_contents <- gsub(
    pattern = "\\{\\{([A-Za-z0-9_-]+)\\}\\}", 
    replacement = "\\{\\{< meta \\1 >\\}\\}", 
    x = file_contents
  )
  
  # 3. Write the changes back to the original file
  writeLines(modified_contents, file_path)
}
##########################################
# Get assets? (come back to when needed) #
##########################################

# Images
source_dir <- "../../Assets/images"
dest_dir   <- "assets/images"

files_to_copy <- list.files(path = source_dir, full.names = TRUE)
dest_files <- file.path(dest_dir, basename(files_to_copy))
file.copy(from = files_to_copy, to = dest_files, overwrite = TRUE)





