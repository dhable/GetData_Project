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

