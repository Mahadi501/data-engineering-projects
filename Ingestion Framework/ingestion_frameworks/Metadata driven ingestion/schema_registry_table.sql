-- create the schema registry table to document all versions of employer source files 
CREATE TABLE IF NOT EXISTS INSURANCE_DEV.DBT_MTEST.SCHEMA_REGISTRY_TABLE 
(
SOURCE_NAME VARCHAR,
SCHEMA_VERSION VARCHAR,
COLUMN_NAME VARCHAR,
DATA_TYPE VARCHAR,
COLUMN_POSITION NUMBER,
EFFECTIVE_FROM_DATE DATE,
EFFECTIVE_TO_DATE DATE,
CURRENT_FLAG BOOLEAN
)
COMMENT = 'Table stores expected schema for all versions of incoming source files from S3 Stage';


-- inserting record for v1
INSERT INTO INSURANCE_DEV.DBT_MTEST.SCHEMA_REGISTRY_TABLE
(SOURCE_NAME,SCHEMA_VERSION,COLUMN_NAME,DATA_TYPE,COLUMN_POSITION,EFFECTIVE_FROM_DATE,EFFECTIVE_TO_DATE,CURRENT_FLAG)
VALUES 
-- VERSION 1
('AWS S3', 'version1','employer_id','VARCHAR',0,'01/01/2024','01/01/2025',FALSE),
('AWS S3', 'version1','abn','VARCHAR',1,'01/01/2024','01/01/2025',FALSE),
('AWS S3', 'version1','employer_name','VARCHAR',2,'01/01/2024','01/01/2025',FALSE),
('AWS S3', 'version1','industry','VARCHAR',3,'01/01/2024','01/01/2025',FALSE),
('AWS S3', 'version1','region','VARCHAR',4,'01/01/2024','01/01/2025',FALSE),
('AWS S3', 'version1','premium_segment','VARCHAR',5,'01/01/2024','01/01/2025',FALSE),
('AWS S3', 'version1','employee_count','NUMBER',6,'01/01/2024','01/01/2025',FALSE),
('AWS S3', 'version1','effective_date','date',7,'01/01/2024','01/01/2025',FALSE),
('AWS S3', 'version1','last_updated_date','date',8,'01/01/2024','01/01/2025',FALSE),
-- VERSION 2
('AWS S3', 'version2','employer_id','VARCHAR',0,'01/01/2024','01/01/2025',FALSE),
('AWS S3', 'version2','abn','VARCHAR',1,'01/01/2024','01/01/2025',FALSE),
('AWS S3', 'version2','employer_name','VARCHAR',2,'01/01/2024','01/01/2025',FALSE),
('AWS S3', 'version2','industry','VARCHAR',3,'01/01/2024','01/01/2025',FALSE),
('AWS S3', 'version2','region','VARCHAR',4,'01/01/2024','01/01/2025',FALSE),
('AWS S3', 'version2','premium_segment','VARCHAR',5,'01/01/2024','01/01/2025',FALSE),
('AWS S3', 'version2','employee_count','NUMBER',6,'01/01/2024','01/01/2025',FALSE),
('AWS S3', 'version2','offices_count','NUMBER',7,'01/01/2024','01/01/2025',FALSE),
('AWS S3', 'version2','effective_date','date',8,'01/01/2024','01/01/2025',FALSE),
('AWS S3', 'version2','last_updated_date','date',9,'01/01/2024','01/01/2025',FALSE),
--VERSION 3
('AWS S3', 'version3','employer_id','VARCHAR',0,'01/01/2024','01/01/2025',FALSE),
('AWS S3', 'version3','abn','VARCHAR',1,'01/01/2024','01/01/2025',FALSE),
('AWS S3', 'version3','employer_name','VARCHAR',2,'01/01/2024','01/01/2025',FALSE),
('AWS S3', 'version3','industry','VARCHAR',3,'01/01/2024','01/01/2025',FALSE),
('AWS S3', 'version3','region','VARCHAR',4,'01/01/2024','01/01/2025',FALSE),
('AWS S3', 'version3','premium_size','VARCHAR',5,'01/01/2024','01/01/2025',FALSE),
('AWS S3', 'version3','employee_count','NUMBER',6,'01/01/2024','01/01/2025',FALSE),
('AWS S3', 'version3','offices_count','NUMBER',7,'01/01/2024','01/01/2025',FALSE),
('AWS S3', 'version3','effective_date','date',8,'01/01/2024','01/01/2025',FALSE),
('AWS S3', 'version3','last_updated_date','date',9,'01/01/2024','01/01/2025',FALSE),
--VERSION 4
('AWS S3', 'version4','employer_id','VARCHAR',0,'01/01/2024',NULL,TRUE),
('AWS S3', 'version4','abn','VARCHAR',1,'01/01/2024',NULL,TRUE),
('AWS S3', 'version4','employer_name','VARCHAR',2,'01/01/2024',NULL,TRUE),
('AWS S3', 'version4','industry','VARCHAR',3,'01/01/2024',NULL,TRUE),
('AWS S3', 'version4','region','VARCHAR',4,'01/01/2024',NULL,TRUE),
('AWS S3', 'version4','premium_size','VARCHAR',5,'01/01/2024',NULL,TRUE),
('AWS S3', 'version4','employee_count','NUMBER',6,'01/01/2024',NULL,TRUE),
('AWS S3', 'version4','offices_count','NUMBER',7,'01/01/2024',NULL,TRUE),
('AWS S3', 'version4','hazard_material_handle','boolean',8,'01/01/2024',NULL,TRUE),
('AWS S3', 'version4','effective_date','date',9,'01/01/2024',NULL,TRUE),
('AWS S3', 'version4','last_updated_date','date',10,'01/01/2024',NULL,TRUE);

SELECT * FROM 
INSURANCE_DEV.DBT_MTEST.SCHEMA_REGISTRY_TABLE
WHERE CURRENT_FLAG = TRUE;

--delete from INSURANCE_DEV.DBT_MTEST.SCHEMA_REGISTRY_TABLE;

