select *
from layoffs;

create table layoffs_staging
like layoffs;

select *
from layoffs_staging;

insert into layoffs_staging
select *
from layoffs;

-- remove duplicates 
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



 -- standrizing data 
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

-- delete unnecessary rows and columns 
delete
from layoffs_staging2
where total_laid_off is null
and percentage_laid_off is null; 

alter table layoffs_staging2
drop column row_num;

-- first project is DOOONE 

select * 
from layoffs_staging2;




