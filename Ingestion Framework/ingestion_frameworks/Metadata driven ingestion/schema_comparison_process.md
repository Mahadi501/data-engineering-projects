# Schema Comparison Process
This documents the high level pseudo logic to create the schema comparison process between the incoming file and the schema registry table and then take approriate action based on the comparison result. 

## Steps
1. Read the file header of the incoming csv file to see what columns are coming and be able to store them into a variable. 
2. Read the active schema from the schema registry table.
3. Compare the file header and schema registry table to determine the following:
   - Columns added
   - Columns removed
   - Columns Renamed
   - Columns Order Changed
   - Data Type Changed
4. Based on the comparison assign a classification
   - SCHEMA_MATCH
   - COLUMN_ADDED
   - COLUMN_REMOVED
   - COLUMN_RENAMED
   - COLUMN_REORDERED
   - DATA_TYPE_CHANGED
5. Apply the schema evolution rules:
   - COLUMN_REORDERED: Allow the new column to be loaded
   - COLUMN_ADDED: Allow load and flag for review
   - COLUMN_REMOVED: Reject load and raise warning
   - COLUMN_RENAMED: Reject load and raise investigation
   - DATA_TYPE_CHANGED: Reject load and raise investigation

## Architecture 
Incoming File -> Raw Variant Bronze -> Metadata Driven Mapping -> Typed Bronze

Raw layer bronze should not care about the file mapping, it should capture the file as it is in the raw bronze. So if the business asks what file was loaded last year on Jan012025, then this can be answered with confidence. Helpful to track lineage and track audit information.

Typed Bronze, convert all schema versions into a single business model. Apply column mapping, handle renamed columns, Populate missing columnns with nulls or defaults. Provide a stable interface for downstream consumers. 




        