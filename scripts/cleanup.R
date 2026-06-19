#########################################
# Cleanup temporary and redundant files #
#########################################

# 1. Define the targets for deletion
file_to_delete  <- "index.md"
folders_to_clear <- c("pages", "shop")

# 2. Delete the individual file
if (file.exists(file_to_delete)) {
  file.remove(file_to_delete)
  message("Successfully deleted: ", file_to_delete)
} else {
  message("File not found (already deleted): ", file_to_delete)
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