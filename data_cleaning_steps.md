# Data Cleaning steps
1.	I saved a copy of each ride data CSV file as an XLSX file and completed steps 2-9 on each file in Excel.
2.	I created a column called ride_length, and populated it by finding the difference between start_at and end_at. I formatted the new column as HH:MM:SS.
3.	I created a column called day_of_week and populated it by calling the WEEKDAY function on the start_at column. I formatted the new column as a number between 1 and 7. Sunday = 1
4.	I formatted start_at and end_at as yyyy-mm-dd hh:mm:ss
5.	Some rides have start times that occurred after the recorded end time. These records have been deleted.
6.	Some rides are 0 seconds, or just a few seconds. Some such rides show the bike rides starting and stopping miles apart. Since this is not characteristic of an actual ride, rides that are 10 seconds or less have been deleted.
7.	There are a few bike stations that appear to be maintenance/testing facilities. Rides starting or ending at these have been deleted.
8.	There are several rides that lasted many days or weeks. Rides lasting 24 hours or more have been deleted.
9.	Each month’s XLSX file was saved as a CSV file.
10.	Using a basic text editor I combined the CSV files into a single file for use in SQL and RStudio.
