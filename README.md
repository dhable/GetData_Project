# GetData_Project

Course project for the Getting and Cleaning Data Course.

## Script Requirements

My solution uses the data.table and reshape2 packages that can be installed from CRAN.
The script does call library(...) for each but does not install them. If you get an error
about missing packages when running, you'll need to install these two libraries.

There is also one variable near the top of the script, data_url. This should be a string of 
where the data can be downloaded from. If the "UCI HAR Dataset" directory is missing, the 
script will use this URL to attempt to download and unpack the data.

If you do not want to download a dataset, you'll need to ensure that the dataset directory
does exist.

## Operations

The script roughly performs the following on the UCI HAR Dataset.

1. Reads information from features.txt, activity_labels.txt to load up human friendly
   labels for the numeric codes that appear in the raw data set.
   
2. Filter out all the data observations except for the mean and standard dev. observations.
   
3. Using the tables from 1, look at subject, activity, and observation data files and
   bulds a single data table with values from each. It repeats this for the train and 
   test directories.
   
4. Melts the table into a narrow table - each of the observations in the complete
   data table becomes a row in the new data table.
   
5. Splits up the variable names into different component - the Domain (time or frequency), name,
   the type of stat, and the axis (if exists, otherwise NA). While this wasn't explicitly called
   for in the instructions, each value represents a key into the what the value being measured was
   and keeping them separate makes future data analysis easier.
   
6. Finally, the script aggerates values that have the same value for all the keys and uses the
   mean function. This gives us a single value for each subject, activity, signal domain, signal name,
   stat type and the axis being measured.
   
The result is an output of a file called something like '20141215_093642_avg_HCI_data.txt', where
the first component is the year, month day, hour, minute, second of when the data set was fetched. 
This is handled automatically if you let the script download the data files from the internet. Otherwise,
you can update the behavior by simply running Unix 'touch' on the file to change the modified timestamp.