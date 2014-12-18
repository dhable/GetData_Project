# GetData_Project Code Book

The resulting data file contains the following fields:

* Subject.Id (int) - This is a anonymous id for a subject in the test and is 
  represented by a int.
  
* Activity.Name (factor) - The name of the activity being performed by by the
  subject when the observation was being made.
  
* Signal.Domain (factor) - Denotes whether the signal was captured raw (time) or
  if a signal was passed through a Fast Fourier Transform algorithm. (frequency)
  
* Signal.Name (char) - Th name of the signal sensor that recorded the reading
                                            
* StatType (factor) - Indicates the type of statistic method used on the raw
  data. The values are either "mean" or "std", standard deviation.
  
* Axis (char) - A character representing X,Y or Z; the direction of travel on the
  plane when the reading was taken. Can also be NA for observations where direction
  of travel does not exist.
  
* Signal.Value.Mean (num) - The value of the signal.