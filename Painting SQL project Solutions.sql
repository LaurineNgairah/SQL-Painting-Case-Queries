-- Replacing the empty cells in the museum_id column with None 
set sql_safe_updates = 0;

UPDATE work
SET museum_id = 'None'
WHERE museum_id = '';

-- 1. All the paintings which are not displayed on any museums. There are 5,619  paintings not displayed on any museums
SELECT *
FROM work
WHERE museum_id = 'None';

-- 2. Are there museums without any paintings? There are 16 museums without paintings 
SELECT * 
FROM museum m
WHERE not exists 
	(SELECT 1 
    FROM work w
	WHERE w.museum_id=m.museum_id);
    
-- 3. How many paintings have an asking price of more than their regular price? None 
SELECT 
	COUNT(work_id)
FROM product_size
WHERE sale_price > regular_price;

-- 4. Identify the paintings whose asking price is less than 50% of its regular price. 38
SELECT 
w.name,
ps.size_id,
ps.sale_price
FROM work AS w
JOIN product_size as ps on w.work_id = ps.work_id
WHERE sale_price < (ps.regular_price * 0.5);

select * 
	from product_size
	where sale_price < (regular_price*0.5);
    
    
-- 5. Which canva size costs the most? '48\" x 96\"(122 cm x 244 cm)', '1115'

SELECT
cs.label AS canva, 
ps.sale_price
FROM 
	(SELECT *,
		  RANK() OVER(ORDER BY sale_price DESC) AS rnk 
		  FROM product_size) ps
	JOIN canvas_size cs ON cs.size_id=ps.size_id
	WHERE ps.rnk=1;			
    
-- 6. Fetch the top 10 most famous painting subject
select * 
from (
	    select s.subject,count(1) as no_of_paintings
		,rank() over(order by count(1) desc) as ranking
		from work w
		join subject s on s.work_id=w.work_id
		group by s.subject ) x
	where ranking <= 10;
    
    
-- 7. Identify the museums which are open on both Sunday and Monday. Display museum name, city
select distinct 
m.name as museum_name, 
m.city, 
m.state,
m.country
from museum_hours mh 
join museum m on m.museum_id=mh.museum_id
where day='Sunday'
	and exists (select 1 from museum_hours mh2 
				where mh2.museum_id=mh.museum_id 
			    and mh2.day='Monday');
-- OR
SELECT 
    m.name AS museum_name, 
    m.city
FROM 
    museum_hours AS mh 
JOIN 
    museum AS m ON m.museum_id = mh.museum_id
WHERE 
    mh.day IN ('Sunday', 'Monday')
GROUP BY 
    m.name, 
    m.city
HAVING 
    COUNT(DISTINCT mh.day) = 2;
    
    
-- 8. How many museums are open every single day?

select count(1)
	from (select museum_id, count(1)
		  from museum_hours
		  group by museum_id
		  having count(1) = 7) x;

-- 9. Which museum has the most no of most popular painting style?

with pop_style as 
			(select style,
			rank() over(order by count(1) desc) as rnk
			from work
			group by style),
		cte as
			(select w.museum_id,m.name as museum_name,ps.style, count(1) as no_of_paintings
			,rank() over(order by count(1) desc) as rnk
			from work w
			join museum m on m.museum_id=w.museum_id
			join pop_style ps on ps.style = w.style
			where w.museum_id is not null
			and ps.rnk=1
			group by w.museum_id, m.name,ps.style)
	select museum_name,style,no_of_paintings
	from cte 
	where rnk=1;
    
--  10. Which country has the 5th highest no of paintings?) Which country has the 5th highest no of paintings?
with cte as 
		(select m.country, count(1) as no_of_Paintings,
		rank() over(order by count(1) desc) as rnk
		from work w
		join museum m on m.museum_id=w.museum_id
		group by m.country)
select country, no_of_Paintings
from cte 
where rnk=5;


-- 11. Which are the 3 most popular and 3 least popular painting styles?
with cte as 
		(select style, count(1) as cnt
		, rank() over(order by count(1) desc) rnk
		, count(1) over() as no_of_records
		from work
		where style is not null
		group by style)
	select style,
	case when rnk <=3 then 'Most Popular' else 'Least Popular' end as remarks 
	from cte
	where rnk <=3
	or rnk > no_of_records - 3;

