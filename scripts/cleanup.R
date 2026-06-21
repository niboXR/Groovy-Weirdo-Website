#########################################
# Cleanup temporary and redundant files #
#########################################

# 1. Define the targets for deletion
files_to_delete  <- c("index.md", "about.md", "portfolio.md", "shop.md")
folders_to_clear <- c("shop")

# 2. Delete the individual files
for (file in files_to_delete) {
  if (file.exists(file)) {
    file.remove(file)
    message("Successfully deleted: ", file)
    } else {
    message("File not found (already deleted): ", file)
  }
}

# 3. Delete everything inside the specified folders
for (folder in folders_to_clear) {
  if (dir.exists(folder)) {
    # recursive = TRUE deletes the folder and all its contents
    unlink(folder, recursive = TRUE)
    
    # Optional: Recreate the empty folder if your project structure requires it
    # dir.create(folder) 
    
    message("Successfully cleared and removed folder: ", folder)
  } else {
    message("Folder not found: ", folder)
  }
}