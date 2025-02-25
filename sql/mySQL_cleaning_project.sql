## Data Cleaning ##

SELECT *
FROM layoffs;

-- 1. Remove Duplicates
-- 2. Standarize the Data
-- 3. Null Values or blank values
-- 4. Remove columns/rows that are not necessary

-- Staging area( staging table to work with to not alter raw data table)

CREATE TABLE layoffs_staging
LIKE layoffs;

SELECT * 
FROM layoffs_staging;

INSERT INTO layoffs_staging
SELECT *
FROM layoffs;


# Removing Duplicates

SELECT * 
FROM layoffs_staging;

-- Using window function to partition unique rows
-- smart to use all columns in partition when checking for duplicates, 
-- the goal is to make sure there is a 1 in the parition row_number for each record
-- if there was anything 2 and up that means there is a duplicate

SELECT *,
ROW_NUMBER() OVER
(PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging;

-- creating CTE for query above
-- like a temp table 

WITH duplicate_cte AS
(
SELECT *,
ROW_NUMBER() OVER
(PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging
)
-- querying cte for duplicates
SELECT * FROM duplicate_cte
WHERE row_num > 1;

-- testing to make sure there is actually a duplicate for one of the cte_duplicates

SELECT *
FROM layoffs_staging
WHERE company = 'Yahoo';

SELECT *
FROM layoffs_staging
WHERE company = 'Casper';

-- Need to
-- create another staging table to add row_num column
-- from this second staging table we can delete duplicates

-- first, need to create second staging table
-- will add extra column for row_num( so we can delete records with 2 in row_num entry)

CREATE TABLE `layoffs_staging2` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
  `row_num` INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

SELECT *
FROM layoffs_staging2;

-- NOW INSERT QUERY FROM CTE ABOVE INTO TABLE

INSERT INTO layoffs_staging2
SELECT *,
ROW_NUMBER() OVER
(PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging;

-- now delete where row_num is two (duplicates

DELETE
FROM layoffs_staging2
WHERE row_num > 1;

-- duplicates removed


# Standardizing data

SELECT *
FROM layoffs_staging2;


-- removing whitespaces

SELECT company, TRIM(company)
FROM layoffs_staging2;

-- updating table 
UPDATE layoffs_staging2
SET company = TRIM(company);

SELECT company
FROM layoffs_staging2;


-- checking out industry
-- need to establiash standardization for some of these

SELECT DISTINCT industry
FROM layoffs_staging2
ORDER BY 1;

-- Crypto has many different names but most likely same industries

-- most industries within 'Crypto' are labled as such, with a few exceptions
-- where some are labled like "Cryptocurrencies" etc.
-- need to update these to be 'Crypto'

SELECT *
FROM layoffs_staging2
WHERE industry LIKE 'Crypto%';

-- this will change all other crypto industry names to one standard 'Crypto'

UPDATE layoffs_staging2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';


-- looking at location for any issues that might need standardization

SELECT DISTINCT location
FROM layoffs_staging2;

-- looks good

-- checking country for any issues


SELECT DISTINCT country
FROM layoffs_staging2
ORDER BY country;

-- United States has two entries ('United States', and 'United States.')

-- this easily removes the trailing period (.) at the end
-- views current country column, and fixed column needed
SELECT DISTINCT country, TRIM(TRAILING '.' FROM country) as fixed_us
FROM layoffs_staging2
WHERE country LIKE 'United States%'
ORDER BY country;

-- updating column to reflect US changes 

UPDATE layoffs_staging2
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE 'United States%';


-- need to convert date column from text into date column
-- also need to format it the same across the board

-- first format date column 

SELECT `date`, STR_TO_DATE(`date`, '%m/%d/%Y')
FROM layoffs_staging2;

UPDATE layoffs_staging2
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');

SELECT `date`
FROM layoffs_staging2;

-- now convert to date by altering table

ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE;



# Nulls and Blank Values


-- checking for nulls/blanks in industry column
-- need to populate data if possible
-- change blanks to null values for now 

UPDATE layoffs_staging2
SET industry = NULL
WHERE industry = '';

-- checking one of the companies with a null industry entry
SELECT *
FROM layoffs_staging2
WHERE company = 'Carvana';

-- this is a SELF JOIN to view one table with NULLs and the other without NULLS
-- the goal will be to update the overall table with NULL values of one table
-- into the other table that has the populated data (industries)

-- this join show the first table with NULLs for industry
-- and the other table t2 populated with industry data
SELECT *
FROM layoffs_staging2 t1
JOIN layoffs_staging2 t2
	ON t1.company = t2.company
WHERE t1.industry IS NULL
AND
t2.industry IS NOT NULL;

-- Now, need to Update with a SELF JOIN so we can populate the NULLs from the table 2

UPDATE layoffs_staging2 AS t1
JOIN layoffs_staging2 AS t2
	ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE t1.industry IS NULL
AND
t2.industry IS NOT NULL;

-- testing it out to see if worked

SELECT *
FROM layoffs_staging2
WHERE industry IS NULL;

-- success
-- Ballys is the only one that has no industry for any record
SELECT * 
FROM layoffs_staging2
WHERE company LIKE 'Bally%';

-- cant populate total_laid_off, percentage_laid_off
-- cant populated funds raised
-- based on current data 


## Remove columns/rows that are not necessary/ dont help us

-- these are records that have NULLS for total_laid_off and percentage_laid_off
-- cannot trust data

-- remove those records with Nulls for those fields

-- accidentally did this but did not mean to do OR logical operator
-- meant to do AND (dropped table, re- ran all queries from above ahhh)
DELETE 
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND
percentage_laid_off IS NULL; 

-- now need to drop column 'row_num' since no longer needed

ALTER TABLE layoffs_staging2
DROP COLUMN row_num;

SELECT *
FROM layoffs_staging2;









