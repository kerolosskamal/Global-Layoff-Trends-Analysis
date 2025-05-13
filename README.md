# Global-Layoff-Trends-Analysis

- Utilized SQL to Conduct data cleaning and exploratory data analysis (EDA) on global company layoff datasets.

## Responsibilities included
- removing duplicates
- standardizing data
- deleting unnecessary rows
- identifying trends, patterns, and outliers to drive meaningful insights into layoff trends across various industries

# First part : Data Cleaning 

 ## Remove duplicates 
 ```sql
select  *, row_number() over (partition by company, location, industry
, total_laid_off, percentage_laid_off, `date`
, stage, country, funds_raised_millions) as row_num 
from layoffs_staging;

with t1 as ( select  *, row_number() over (partition by company, location, industry
, total_laid_off, percentage_laid_off, `date`
, stage, country, funds_raised_millions) as row_num 
from layoffs_staging) 
select * 
from t1 layoffs_staging
where row_num > 1 ;
 
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
  `row_num` int
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;


insert into layoffs_staging2 
select * , row_number() over (partition by company, location, industry
, total_laid_off, percentage_laid_off, `date`
, stage, country, funds_raised_millions) as row_num 
from layoffs_staging;

delete
from layoffs_staging2
where row_num > 1;
```


 ## Standrizing data
 ```sql
 select company, trim(company)
 from layoffs_staging2;
 
 update layoffs_staging2
 set company = trim(company);
 
 
select  distinct industry 
from layoffs_staging2
order by 1;

update layoffs_staging2
set industry = 'crypto'
where industry like 'crypto%';

select distinct industry 
from layoffs_staging2;

select distinct country ,replace(country, '.', ' ')
from layoffs_staging2
order by 1;

update layoffs_staging2
set country = replace(country, '.', ' ')
where country like 'United States%';

select `date`,
str_to_date(`date`, '%m/%d/%Y')
from layoffs_staging2;

update layoffs_staging2
set `date` = str_to_date(`date`, '%m/%d/%Y');



alter table layoffs_staging2
modify column `date` date;

select * 
from layoffs_staging2;


update layoffs_staging2
set industry = null
where industry = '';

select t1.industry, t2.industry
from layoffs_staging2 as t1
join layoffs_staging2 as t2 
	on t1.company = t2.company 
where t1.industry is null 
and t2.industry is not null ;    

update layoffs_staging2 as t1 
join layoffs_staging2 as t2
	on t1.company = t2.company
set t1.industry = t2.industry    
where t1.industry is null 
and t2.industry is not null;    

select * 
from layoffs_staging2;
```
## Delete unnecessary rows and columns 
```sql
delete
from layoffs_staging2
where total_laid_off is null
and percentage_laid_off is null; 

alter table layoffs_staging2
drop column row_num;
```

# Second Part : EDA 
- Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

 ## Looking at Percentage to see how big these layoffs were
 ```sql

SELECT MAX(percentage_laid_off),  MIN(percentage_laid_off)
FROM world_layoffs.layoffs_staging2
WHERE  percentage_laid_off IS NOT NULL;
```
## Which companies had 1 which is basically 100 percent of they company laid off
```sql

SELECT *
FROM world_layoffs.layoffs_staging2
WHERE  percentage_laid_off = 1; 
-- these are mostly startups it looks like who all went out of business during this time

-- if we order by funcs_raised_millions we can see how big some of these companies were
SELECT *
FROM world_layoffs.layoffs_staging2
WHERE  percentage_laid_off = 1
ORDER BY funds_raised_millions DESC;
-- BritishVolt looks like an EV company, Quibi! I recognize that company - wow raised like 2 billion dollars and went under - ouch
```
## Companies with the biggest single Layoff
```sql
SELECT company, total_laid_off
FROM world_layoffs.layoffs_staging
ORDER BY 2 DESC
LIMIT 5;
-- now that's just on a single day
```
## Companies with the most Total Layoffs
```sql

SELECT company, SUM(total_laid_off)
FROM world_layoffs.layoffs_staging2
GROUP BY company
ORDER BY 2 DESC
LIMIT 10;
```


- By location
```sql  
SELECT location, SUM(total_laid_off)
FROM world_layoffs.layoffs_staging2
GROUP BY location
ORDER BY 2 DESC
LIMIT 10;
```
## This it total in the past 3 years or in the dataset
```sql

SELECT country, SUM(total_laid_off)
FROM world_layoffs.layoffs_staging2
GROUP BY country
ORDER BY 2 DESC;

SELECT YEAR(date), SUM(total_laid_off)
FROM world_layoffs.layoffs_staging2
GROUP BY YEAR(date)
ORDER BY 1 ASC;


SELECT industry, SUM(total_laid_off)
FROM world_layoffs.layoffs_staging2
GROUP BY industry
ORDER BY 2 DESC;


SELECT stage, SUM(total_laid_off)
FROM world_layoffs.layoffs_staging2
GROUP BY stage
ORDER BY 2 DESC;
```



## Earlier we looked at Companies with the most Layoffs. Now let's look at that per year.
```sql

WITH Company_Year AS 
(
  SELECT company, YEAR(date) AS years, SUM(total_laid_off) AS total_laid_off
  FROM layoffs_staging2
  GROUP BY company, YEAR(date)
)
, Company_Year_Rank AS (
  SELECT company, years, total_laid_off, DENSE_RANK() OVER (PARTITION BY years ORDER BY total_laid_off DESC) AS ranking
  FROM Company_Year
)
SELECT company, years, total_laid_off, ranking
FROM Company_Year_Rank
WHERE ranking <= 3
AND years IS NOT NULL
ORDER BY years ASC, total_laid_off DESC;
```



## Rolling Total of Layoffs Per Month
```sql
SELECT SUBSTRING(date,1,7) as dates, SUM(total_laid_off) AS total_laid_off
FROM layoffs_staging2
GROUP BY dates
ORDER BY dates ASC;
```
## now use it in a CTE so we can query off of it
```sql
WITH DATE_CTE AS 
(
SELECT SUBSTRING(date,1,7) as dates, SUM(total_laid_off) AS total_laid_off
FROM layoffs_staging2
GROUP BY dates
ORDER BY dates ASC
)
SELECT dates, SUM(total_laid_off) OVER (ORDER BY dates ASC) as rolling_total_layoffs
FROM DATE_CTE
ORDER BY dates ASC;
```

