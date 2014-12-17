#
# Author: Dan Hable
library(data.table)
library(reshape2)
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
  setnames(feature_key, c("Feature.Id", "Feature.Name"))
  setkey(feature_key, Feature.Id)
  
  activity_key <- fread("UCI HAR Dataset/activity_labels.txt", sep = " ", header = FALSE)
  setnames(activity_key, c("Activity.Id", "Activity.Name"))
  setkey(activity_key, Activity.Id)
    
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
  setnames(subjects, "Subject.Id")
  setkey(subjects, Subject.Id)
    
  # Load the list of all the activities being done by the subjects relating to the observations.
  # This will result in numeric codes, so merge this in with the activity labels so both numeric
  # code and text label are reported.
  activities <- fread(files$activity_data_file, header = FALSE)
  setnames(activities, "Activity.Id")
  setkey(activities, Activity.Id)
  activities <- merge(activities, labels$activities)
  activities[,Activity.Id:=NULL]
    
  # Load all of the features reported on per subject. Since this data set is missing nice column
  # names, use the label set for the column names instead. 
  # Note: I kept getting crashes when I tried to use fread. I need to revisit this if I have
  #       time to make it consistent.
  features <- read.table(files$feature_data_file, header = FALSE)
  features <- data.table(features) # dirty hack
  
  # Grab only a subset of the columns that we want to keep in the final data set
  # and massage the names to be a bit more friendly. This involves setting dashes 
  # to underscore and dropping the paren pairs from the name.
  mean_std_cols <- grep("(mean\\(\\))|(std\\(\\))", labels$features$Feature.Name, perl = TRUE)
  mean_std_names <- gsub("[\\(\\)]", "", labels$features$Feature.Name[mean_std_cols])
  mean_std_names <- gsub("-", "_", mean_std_names)
  
  # Finally build the features data set and set the names of the variables to the
  # clean names we built above.
  features <- features[,mean_std_cols, with = FALSE]
  setnames(features, mean_std_names)
    
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


tidy_up_dataset <- function(dt) {  
  # Some simple functions to help flatten out lists after calling strsplit.
  element1Domain <- function(x) { 
    substr(x[1], 1, 1) 
  }
  element1Name <- function(x) { substr(x[1], 2, nchar(x[1])) }    
  element2 <- function(x) { x[2] }
  element3 <- function(x) { x[3] }
  
  # Transform the data table into a tall but narrow table by introducing a
  # variable and value column.
  tidy_dt <- melt(dt, id=c("Subject.Id", "Activity.Name"))
  setnames(tidy_dt, "value", "Signal.Value")
    
  # The variable name contains additional information and values that we can extract
  # using the split functionality. Add each of these values into the data table.
  name_components <- strsplit(as.character(tidy_dt$variable), "_")
  tidy_dt[, Signal.Domain := sapply(name_components, element1Domain)]
  tidy_dt[, Signal.Name := sapply(name_components, element1Name)]
  tidy_dt[, StatType := sapply(name_components, element2)]
  tidy_dt[, Axis := sapply(name_components, element3)]
  tidy_dt[, variable := NULL]
  
  # Clean up the names and types of the signal domain and stat type fields. Both are
  # better modeled as factors since they are discrete values.
  tidy_dt[, Signal.Domain := ifelse(Signal.Domain == "t", "Time", "Frequency")]
  tidy_dt[, Signal.Domain := as.factor(Signal.Domain)]
  tidy_dt[, StatType := as.factor(StatType)]
  
  tidy_dt
}


# The Script
ensure_data_exists()

dateDownloaded <- file.get_time("./UCI HAR Dataset")
dateAnalysis <- date()

clean_dataset <- build_single_raw_table()
tidy_dataset <- tidy_up_dataset(clean_dataset)

