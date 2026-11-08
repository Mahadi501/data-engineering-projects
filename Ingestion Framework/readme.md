## Comparing Different File Ingestion Approaches in Snowflake

# Author

Mahad Rashid

# Overview

This project demonstrates and compares four different approaches to ingesting data from an AWS S3 external stage into Snowflake tables:

- Positional-based ingestion
- Column name-based ingestion
- Variant-based ingestion
- Metadata-driven ingestion

The objective is to understand how each approach works, evaluate its advantages and limitations, and assess how effectively it handles schema changes (schema drift) in source files.

# Objective

The primary objective is to explore how different Snowflake file ingestion techniques handle changes in source file structures.

The comparison focuses on:

How source columns are mapped to target table columns.

Whether changes in column order or the addition of new columns affect ingestion.

How each approach handles schema drift.

The risk of incorrect data mapping and silent data quality issues.

The flexibility and maintainability of each approach.

# Technology Stack

Snowflake – Data ingestion, storage and transformation.

AWS S3 – Storage for source files.

AWS IAM – Authentication and access management between Snowflake and S3.

Git / GitHub – Source control and project documentation.

AWS S3 and Snowflake Connectivity

Source files are stored in an AWS S3 bucket and accessed through a Snowflake external stage.

For this demonstration, AWS IAM user credentials are used to establish the connection between Snowflake and S3. This approach is functional but is not recommended for production environments because it relies on long-lived access keys and secret keys.

The preferred production approach is to use a Snowflake Storage Integration with an AWS IAM role.Due to configuration limitations encountered during this experiment, I used IAM user credentials instead.For further information, refer to the official Snowflake documentation:

- Configuring an AWS S3 Storage Integration

- Configuring AWS IAM User Credentials

# Comparing File Ingestion Approaches

## 1. Positional-Based Data Ingestion

How it works

Positional-based ingestion maps source file columns to target table columns using positional references such as $1, $2, $3, and so on.

This approach assumes that the source file maintains a consistent column order across different file versions.

Advantages

- Simple to implement.

- Requires minimal configuration.

- Suitable when source file structures are stable and predictable.

Disadvantages

- Highly dependent on the source column order.

- Changes to the source file structure can result in incorrect column mapping.

- Does not automatically detect whether a source column has been added, removed or repositioned.

- Can introduce silent data quality issues when Snowflake performs implicit data type conversions.

### Experiment: Impact of Schema Changes

During testing, I introduced a new column, OFFICES_COUNT, at position 8 in the source CSV file.

Previously, position 8 contained effective_date. However, the original COPY INTO statement was not updated and continued mapping 8 to the target effective_date column.

The new source file contained the numeric value 12 at position $8.

Instead of rejecting the record, Snowflake implicitly converted the numeric value into a timestamp:

Source value:       12
Target value:       1970-01-01 00:00:12.000

The COPY operation completed successfully without reporting a loading error, despite the fact that the data was mapped incorrectly.

This highlighted an important limitation: a successful COPY operation does not necessarily mean that the data has been loaded correctly.

The experiment demonstrated that positional-based ingestion is vulnerable to schema drift, particularly when columns are added, removed or reordered.

Code: traditional_copy_into.sql


## 2. Match by column name Data Ingestion
How it works:
In this type of ingestion, we do not have to hardcoding the position of the columns to column names. It works by infering what positions  are the incoming columns coming in the file and then automatically assign them to the underlying table columns.

Advantages

- Simple to implement.

- Requires minimal configuration.

- Suitable when source file structures column names remain same and only their positioning may change. Also the total column count remains the same.

- Does not silently ingest columns like positional based ingestion. 


 Disadvantage: 
 - You cannot create additional metadata column when you ingest using match by column names. If the incoming file does not have the metadata columns then you cant yourself create it.
 - The file format has to have the parse_header enabled otherwise ingestion through match by column is not possibl.
- If the total number of column changes, even though previous column still exists, it will still give an error.

### Experiment: Impact of Schema Changes
1. I tried loadind a file with columns moved around but with the same number of columns, the ingestion went through and was incorrect.
2. I tried thinking of adding a new column and kept all existing columns thinking that the new columns will not be ingested as the downstream table does not a column for it and rest will be ingested. But it gives out error that the column number have changed.

Code: match_by_cols_name.sql

## 3. Variant based Data Ingestion

How it works:
Using the object_construct pass in a key value pair for the incoming file. For example, if the file has three columns: 
name,
place,
animal
then 
object_construct(
'name',$1,
'place',$2,
'thing',$3
)
If there is a chance that the incoming file may contain extra 1-2 column after thing then you can handle this by using: 
object_construct_keep_null(
'name',$1,
'place',$2,
'thing',$3
'extra_column1',$4,
'extra_column2',$5,
)
If the incoming file only has 3 columns then extra_column1 and extra_column2 will become null. 
Once the data comes into a variant object, the downstream table can then load it up and rename column as needed.

### Advantages
- **Schema flexibility:** The raw ingestion layer can accommodate optional fields and variations in incoming file structures, provided the expected positional mappings are handled.
- **Metadata capture:** Additional metadata columns can be captured during ingestion, such as file name, load timestamp, batch ID and file row number.
- **Separation of ingestion and transformation:** Raw data can be retained in a VARIANT column, allowing downstream models to handle business-specific transformations independently.
- **Reduced coupling:** Changes to downstream business logic do not necessarily require changes to the raw ingestion table.

### Disadvantages

- **Increased complexity:** The implementation is more complicated than conventional column-based ingestion.
- **Downstream schema dependency:** Successful raw ingestion does not guarantee successful downstream processing. For example, if a downstream model expects `employee_id` to exist but the incoming file does not contain it at the expected position, the downstream transformation may fail or produce incorrect results.
- **Positional dependency:** When using `$1`, `$2`, `$3`, etc., changes to the order of incoming CSV columns can result in incorrect attribute mappings.
- **Explicit mapping maintenance:** New columns must be accounted for in the object construction logic if they need to be retained.


### Experiment: Impact of Schema Changes
1. Change the order of existing columns: The data was loaded into the variant column. No error raised however, the downstream table failed as it expected date column at position 2. 
2. Test ingestion with a file containing only one column, It progressed, all the other columns were marked as null