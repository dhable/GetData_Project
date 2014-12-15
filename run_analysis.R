#
# Author: Dan Hable
library(data.table)
library(plyr)

# Configurable location that the data can be downloaded from. After changing
# this value, delete the existing local data in order to force a download.
data_url <- "https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip"



# Helper function that will set the modified date on a directory
# or file to the current system time. This is the equivlent of using
# the 'touch' Unix command.
file.touch <- function(path) {  
  Sys.setFileTime(path, Sys.time())
}

# Function that will check that the UCI HAR data set exists in the current
# working directory. If it does not, then this function will attempt to
# download the dataset, unzip it and update the time that it was downloaded
# by adjusting the modified date.
ensure_data_exists <- function() {
  if(!file.exists("./UCI HAR Dataset")) {
    download.file(data_url, "./dataset-tmp.zip", method="curl")
    unzip("./dataset-tmp.zip")
    file.remove("./dataset-tmp.zip")
    
    # Set the directory time to the current system time. This will serve as a record
    # of when the data files were last downloaded from the Internet URL.
    file.touch("./UCI HAR Dataset")
  }
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
  feature_key <- fread("UCI HAR Dataset/features.txt", sep = " ", header = FALSE)
  setnames(feature_key, c("feature_id", "feature_name"))
  setkey(feature_key, feature_id)
  
  activity_key <- fread("UCI HAR Dataset/activity_labels.txt", sep = " ", header = FALSE)
  setnames(activity_key, c("activity_id", "activity_name"))
  setkey(activity_key, activity_id)
    
  list(features = feature_key, activities = activity_key)
}


# Given a list of files in the dataset, join them into a single raw table for futher
# manipulation.
#
# Inputs:
#   files - a list of named file paths containing the data to use in the resulting table
#      subject_data_file = file containing id of phone user
#      activity_data_file = file containing id of the activity being performed
#      feature_data_file = file containing the aggerate data observations
#
# Returns:
#   A single data.table object that represents the data from the three files. This data
#   may not be tidy yet.
build_raw_table <- function(files, labels = load_labels()) {
  # Load the list of unique ids of the subjects that reported the observations.
  subjects <- fread(files$subject_data_file, header = FALSE)
  setnames(subjects, "subject_id")
  setkey(subjects, subject_id)
    
  # Load the list of all the activities being done by the subjects relating to the observations.
  # This will result in numeric codes, so merge this in with the activity labels so both numeric
  # code and text label are reported.
  activities <- fread(files$activity_data_file, header = FALSE)
  setnames(activities, "activity_id")
  setkey(activities, activity_id)
  activities <- merge(activities, labels$activities)
    
  # Load all of the features reported on per subject. Since this data set is missing nice column
  # names, use the label set for the column names instead. 
  # Note: I kept getting crashes when I tried to use fread. I need to revisit this if I have
  #       time to make it consistent.
  features <- read.table(files$feature_data_file, header = FALSE, col.names = labels$features$feature_name)
  
  # Merge all of the tables into a single data table and return the results
  data.table(subjects, activities, features)
}


# Based on the current data set directory layout, makes enough calls to generate
# a single data.table object with all of the raw observations.
#
# Output:
#   A single data.table object with the same formar from build_raw_table. This
#   object will have more rows.
build_single_raw_table <- function() {
  # Load the label data tables once and then pass them into the build_raw_table 
  # method. If not, we'd process the label files multiple times for no necessary
  # reason.
  data_labels <- load_labels()
  
  # Load the set of data. Since the file names are unique, I just hard coded the individual
  # data set loads instead of trying to come up with a progrmatic way. If the number of data
  # sets expands, this might need to be revisited.
  training_data <- build_raw_table(list(subject_data_file = "UCI HAR Dataset/train/subject_train.txt",
                                        activity_data_file = "UCI HAR Dataset/train/y_train.txt",
                                        feature_data_file = "UCI HAR Dataset/train/X_train.txt"), 
                                   labels = data_labels)
  
  test_data <- build_raw_table(list(subject_data_file = "UCI HAR Dataset/test/subject_test.txt",
                                    activity_data_file = "UCI HAR Dataset/test/y_test.txt",
                                    feature_data_file = "UCI HAR Dataset/test/X_test.txt"), 
                               labels = data_labels)
  
  # Return a concatated list of the data tables into a single data table.
  rbindlist(list(training_data, test_data))
}





# The Script
ensure_data_exists()

dateDownloaded <- file.get_time("./UCI HAR Dataset")
dateAnalysis <- date()

raw_dataset <- build_single_raw_table()
