## Exploratory Data Analysis Project

-- Will work a lot with `total_laid_off` and some `percentage_laid_off`

SELECT *
FROM layoffs_staging2;


-- max and min laid off at one time --

SELECT MIN(total_laid_off), MAX(total_laid_off)
FROM layoffs_staging2;


-- viewing company layoffs ordered by most total company layoffs --
SELECT company, SUM(total_laid_off) AS total_company_laid_off
FROM layoffs_staging2
GROUP BY company
ORDER BY total_company_laid_off DESC;


-- viewing date range of dataset layoffs --
-- About 3 years worth of data (2020-03-11 to 2023-03-06) --
SELECT MIN(`date`), MAX(`date`)
FROM layoffs_staging2;

-- Number of layoffs per location & country desc --
SELECT location, country, SUM(total_laid_off) AS num_location_layoffs
FROM layoffs_staging2
GROUP BY location, country
ORDER BY num_location_layoffs DESC;

SELECT country, SUM(total_laid_off) AS num_location_layoffs
FROM layoffs_staging2
GROUP BY country
ORDER BY num_location_layoffs DESC;


-- Number of layoffs per industry desc --
SELECT industry, SUM(total_laid_off) AS num_industry_layoffs
FROM layoffs_staging2
GROUP BY industry
ORDER BY num_industry_layoffs DESC;


-- order layoffs by year. How many layoffs world-wide per year given dataset. --
SELECT YEAR(`date`), SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY YEAR(`date`)
ORDER BY YEAR(`date`) DESC;


-- total layoffs by Funding Stages --
SELECT stage, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY stage
ORDER BY SUM(total_laid_off) DESC;


-- Total laid off ordered ASC by month--
SELECT SUBSTRING(`date`, 1, 7) AS `year_month`, 
SUM(total_laid_off) AS monthly_laid_off
FROM layoffs_staging2
GROUP BY `year_month`
HAVING `year_month` IS NOT NULL
ORDER BY `year_month`;

-- Taking above query, turning into CTE for furthur analysis --
WITH cte_monthly_laid_off AS
(
SELECT SUBSTRING(`date`, 1, 7) AS `year_month`, 
SUM(total_laid_off) AS monthly_laid_off
FROM layoffs_staging2
GROUP BY `year_month`
HAVING `year_month` IS NOT NULL
ORDER BY `year_month`
)
-- Creating Window Function to Create Rolling Total --
SELECT `year_month`,
monthly_laid_off,
SUM(monthly_laid_off) OVER (ORDER BY `year_month`) AS rolling_total
FROM cte_monthly_laid_off;



-- created multiple combined CTEs. 
-- cte_yearly_laid_off(1st cte) shows company layoffs per year
-- company_ranking(2nd cte) works off the cte_yearly_laid_off to get a ranking of layoffs by year per company
WITH cte_yearly_laid_off (company, Years, total_laid_off) AS
(
SELECT company,
YEAR(`date`), 
SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY company, YEAR(`date`)
),
company_ranking AS 
(
SELECT * ,
DENSE_RANK() OVER (PARTITION BY years ORDER BY total_laid_off DESC) AS Ranking
FROM cte_yearly_laid_off
WHERE years IS NOT NULL
)
-- utilizing CTE to show top 5 ranked (most layoffs) for given year)
SELECT *
FROM company_ranking
WHERE Ranking <= 5;

