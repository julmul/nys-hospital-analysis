#####################################################
# Utility functions for analysis
# Author: Julia Muller
# Date: 2 December 2024
# Last modified: February 2025
#####################################################

# Ensure specified directory exists and create it if not
ensure_directory <- function(directory) {
  if(!dir.exists(directory)) {
    dir.create(directory);
  }
}

# Query RSQLite database and return results
query_db <- function(query, db = 'derived_data/hospital-discharges.db') {
  conn <- dbConnect(SQLite(), dbname = db)
  data <- dbGetQuery(conn, query)
  dbDisconnect(conn)
  return(data)
}
