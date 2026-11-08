# Framework Rules to handle Schema Evolution:  

## 1) Column Order Changed 
### Detection Method:
Same column exists but orders have changed between schema registry table & file header

### Action: 
Allow the new column to be loaded

### Audit Requirement:
Record that column order changed. 


## 2) New Column Added 
### Detection Method:
Column exists inside the file header but not in the schema registry

### Action: 
Allow load and flag for review

### Audit Requirement:
Record the new column name


## 3) Column Removed 
### Detection Method:
Column does not exist inside the file header but exists in the schema registry

### Action: 
Reject load and raise warning

### Audit Requirement:
Record the missing column


## 4) Column Renamed 
### Detection Method:
Expected column missing and unexpected column appears. Total Column count remains the same

### Action: 
Reject load and raise investigation

### Audit Requirement:
Record both column names


## 5) Data Type Changed 
### Detection Method:
Schema Registry data type differs from the incoming file datatype

### Action: 
Reject load and raise investigation

### Audit Requirement:
Log old and new datatype

