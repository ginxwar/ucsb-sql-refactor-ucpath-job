--original, reformatted SQL
SELECT j.* 
FROM   hcm_ods.ps_job J 
WHERE  j.effdt = 
       ( 
			SELECT Max(j1.effdt) 
			FROM   hcm_ods.ps_job J1 
			WHERE  j.emplid = j1.emplid 
			AND    j.empl_rcd = j1.empl_rcd 
			AND    j1.effdt <= Getdate()
	   ) 
AND    j.effseq = 
       ( 
            SELECT Max(j2.effseq) 
            FROM   hcm_ods.ps_job J2 
            WHERE  j.emplid = j2.emplid 
            AND    j.empl_rcd = j2.empl_rcd 
            AND    j.effdt = j2.effdt
		) 
--total count: 48701



/*
according to UCPath documentation, there is no primary key in the ps_job table.
However, the candidate key consists of:
emplid, empl_rcd, effdt, effseq
*/

select
			emplid, empl_rcd, effdt, effseq
			,count(*)

from		hcm_ods.ps_job

group by	emplid, empl_rcd, effdt, effseq
having		count(*) > 1
order by	count(*) desc


--lets examine the data a bit and find the most complex person and job
select		emplid, count(*)
from		hcm_ods.ps_job
group by	emplid
order by	count(*) desc
--emplid: 51321753, 46 rows!


--what does emplid 51321753 look like?
select		*
from		hcm_ods.ps_job
where		emplid = 51321753



--refactor 1st attempt
select					
			emplid, empl_rcd, effdt, effseq

			-- dont know what to order by
			, rank = row_number() over (partition by emplid, empl_rcd)
			
from		hcm_ods.PS_JOB
where		emplid = 51321753
/*
group by modifies entire query
partition by does not.  partition by runs with the window function and changes how the window function is calculated
*/

--2nd attempt
select					
			emplid, empl_rcd, effdt, effseq

			--ordered by effdt, effseq
			, rank = row_number() over (partition by emplid, empl_rcd order by effdt desc, effseq desc)
			
from		hcm_ods.PS_JOB
where		emplid = 51321753


--but we only want the latest, so pull just the first
;with
rankedJobs as (
	select					
				emplid, empl_rcd, effdt, effseq

				--ordered by effdt, effseq
				, rank = row_number() over (partition by emplid, empl_rcd order by effdt desc, effseq desc)
			
	from		hcm_ods.PS_JOB
)
select		*
from		rankedJobs
where		emplid = 51321753
			and	rank = 1

--you dont need to use a common table expression (CTE), a subquery would work just fine too




------------------
--can we trust this dataset?  can we trust that this will work across the ENTIRE dataset?
------------------

--lets prove it with EXCEPT
;with
rankedJobs as (
	select					
				emplid, empl_rcd, effdt, effseq

				--ordered by effdt, effseq
				, rank = row_number() over (partition by emplid, empl_rcd order by effdt desc, effseq desc)
			
	from		hcm_ods.PS_JOB
)
select		emplid, empl_rcd, effdt, effseq
from		rankedJobs
where		rank = 1
--48701




except

SELECT j.emplid, j.empl_rcd, j.effdt, j.effseq
FROM   hcm_ods.ps_job J 
WHERE  j.effdt = 
       ( 
			SELECT Max(j1.effdt) 
			FROM   hcm_ods.ps_job J1 
			WHERE  j.emplid = j1.emplid 
			AND    j.empl_rcd = j1.empl_rcd 
			AND    j1.effdt <= Getdate()
	   ) 

AND    j.effseq = 
       ( 
            SELECT Max(j2.effseq) 
            FROM   hcm_ods.ps_job J2 
            WHERE  j.emplid = j2.emplid 
            AND    j.empl_rcd = j2.empl_rcd 
            AND    j.effdt = j2.effdt
		)	
--total count: 48701







--WHOOPS!  What happened here with 23567832, 2019-09-16
select		*
from		hcm_ods.ps_job
where		emplid = 23567832


--WHOOPS!  What happened here with 23567832, 2016-08-28



--ahh, forgot about future dates, lets exclude them
;with
rankedJobs as (
	select					
				emplid, empl_rcd, effdt, effseq

				--ordered by effdt, effseq
				, rank = row_number() over (partition by emplid, empl_rcd order by effdt desc, effseq desc)
			
	from		hcm_ods.PS_JOB
	where		effdt <= getdate()
)
select		emplid, empl_rcd, effdt, effseq
from		rankedJobs
where		rank = 1
--still 48701 rows


--final verification?
;with
rankedJobs as (
	select					
				emplid, empl_rcd, effdt, effseq

				--ordered by effdt, effseq
				, rank = row_number() over (partition by emplid, empl_rcd order by effdt desc, effseq desc)
			
	from		hcm_ods.PS_JOB
	where		effdt <= getdate()
)
select		emplid, empl_rcd, effdt, effseq
from		rankedJobs
where		rank = 1

except

SELECT j.emplid, j.empl_rcd, j.effdt, j.effseq
FROM   hcm_ods.ps_job J 
WHERE  j.effdt = 
       ( 
			SELECT Max(j1.effdt) 
			FROM   hcm_ods.ps_job J1 
			WHERE  j.emplid = j1.emplid 
			AND    j.empl_rcd = j1.empl_rcd 
			AND    j1.effdt <= Getdate()
	   ) 

AND    j.effseq = 
       ( 
            SELECT Max(j2.effseq) 
            FROM   hcm_ods.ps_job J2 
            WHERE  j.emplid = j2.emplid 
            AND    j.empl_rcd = j2.empl_rcd 
            AND    j.effdt = j2.effdt
		)	


--verification complete!  final refactored version?

;with
rankedJobs as (
	select					
				emplid, empl_rcd, effdt, effseq

				--ordered by effdt, effseq
				, rank = row_number() over (partition by emplid, empl_rcd order by effdt desc, effseq desc)
			
	from		hcm_ods.PS_JOB
	where		effdt <= getdate()
)
select		emplid, empl_rcd, effdt, effseq
from		rankedJobs
where		rank = 1


----------
-- VERSUS
----------


SELECT j.emplid, j.empl_rcd, j.effdt, j.effseq
FROM   hcm_ods.ps_job J 
WHERE  j.effdt = 
       ( 
			SELECT Max(j1.effdt) 
			FROM   hcm_ods.ps_job J1 
			WHERE  j.emplid = j1.emplid 
			AND    j.empl_rcd = j1.empl_rcd 
			AND    j1.effdt <= Getdate()
	   ) 

AND    j.effseq = 
       ( 
            SELECT Max(j2.effseq) 
            FROM   hcm_ods.ps_job J2 
            WHERE  j.emplid = j2.emplid 
            AND    j.empl_rcd = j2.empl_rcd 
            AND    j.effdt = j2.effdt
		)	
