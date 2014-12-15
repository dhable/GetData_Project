#
# Author: Dan Hable

# Configurable location that the data can be downloaded from. After changing
# this value, delete the existing local data in order to force a download.
data_url <- "https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip"



# Helper function that will set the modified date on a directory
# or file to the current system time. This is the equivlent of using
# the 'touch' Unix command.
file.touch <- function(path) {  
  Sys.setFileTime(path, Sys.time())
}

# Helper function that will read the modified date on a directory
# or file. It returns the value as a string formatted similar to the
# date() function.
file.get_time <- function(path) {
  modified_time <- file.info(path)$mtime
  format(modified_time, "%a %b %d %H:%M:%S %Y")
}


# Helper function that will load all of the mapping files that map various numeric
# ids to human readable label values. Returns a list that currently contains the 
# label mappings for the feature types and  the activity types.
load_labels <- function() {
  list(features = read.table("UCI HAR Dataset/features.txt", sep = " ", header = FALSE,
                             col.names = c("feature_id", "feature_name")),
       
       activities = read.table("UCI HAR Dataset/activity_labels.txt", sep = " ", header = FALSE,
                               col.names = c("activity_id", "activity_name")))
}






build_table <- function(data_dir, labels) {  
  # Unique Ids for the people being studied
  subject_ids <- read.table(paste(data_dir, "subject_test.txt", sep = ""), header = FALSE)
  
  # Activity Being Performed
  activity_id <- read.table(paste(data_dir, "y_test.txt", sep = ""), header = FALSE)
  
  # Feature Readings
  features <- read.table(paste(data_dir, "X_test.txt", sep = ""), header = FALSE)
  
}



# The Script
if(!file.exists("./UCI HAR Dataset")) {
  download.file(data_url, "./dataset-tmp.zip", method="curl")
  unzip("./dataset-tmp.zip")
  file.remove("./dataset-tmp.zip")
  
  # Set the directory time to the current system time. This will serve as a record
  # of when the data files were last downloaded from the Internet URL.
  file.touch("./UCI HAR Dataset")
}

dateDownloaded <- file.get_time("./UCI HAR Dataset")
dateAnalysis <- date()
