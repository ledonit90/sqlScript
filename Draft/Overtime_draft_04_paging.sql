 -- OVERTIME ----
 declare @StartDate datetime
 set @StartDate = '20180112'
 declare @EndDate datetime
 set @EndDate  = '20190912'

 DECLARE @NumberOfPages INT = 30
 DECLARE @FirstPage INT = 0

 create table #danhsach (PERNR char(8))
 create table #LoaiDieuChinhTable (SubStatus INT)
 create table #OTTYPE (OTTYPE varchar(2))

 insert into #OTTYPE
 values('01')

  insert into #OTTYPE
 values('02')

 insert into #OTTYPE
 values('03')
 

 insert into #LoaiDieuChinhTable
 values(1)
 insert into #LoaiDieuChinhTable
 values(2)
 insert into #LoaiDieuChinhTable
 values(3)

 insert into #danhsach 
select PERNR from HRM_PORTAL_OverTime

--select  distinct * from #danhsach

BEGIN TRY DROP TABLE #RESULT END TRY BEGIN CATCH END CATCH

CREATE TABLE #RESULT (ID INT IDENTITY(1,1) PRIMARY KEY
						,PERNR CHAR(8)
						,BEGDA DATETIME
						,ENDDA DATETIME
						,BEGUZ TIME
						,ENDUZ TIME
						,OTTYPE VARCHAR(2)
						,SUBSTATUS INT
						,OverTimeInMinutes INT
						,REASON Nvarchar(300)
						,fullname Nvarchar(300)
						,s2 Nvarchar(300)
						,s3 Nvarchar(300)
						,s1 Nvarchar(300))

INSERT INTO #RESULT

SELECT                  PERNR
						,BEGDA
						,ENDDA
						,BEGUZ
						,ENDUZ
						,OTTYPE
						,SUBSTATUS
						,OverTimeInMinutes
						,REASON
						,fullname
						,s2
						,s3
						,s1

FROM (

select *,
(select TOP 1 STEXT from HRM_PORTAL_OrgUnit where res.ORGEH = OBJID ORDER BY ENDDA DESC) as s2,
case when DATEDIFF(MINUTE, BEGUZ, ENDUZ) >= 0 then DATEDIFF(MINUTE, BEGUZ, ENDUZ) * tmp
			else (DATEDIFF(MINUTE, BEGUZ, ENDUZ) + 24* 60) * tmp
			end as OverTimeInMinutes
from (
select *,
(SELECT TOP 1 CONCAT(personal.VORNA, ' ', personal.NACHN) FROM [HRM_PORTAL_Personal] personal where personal.PERNR = t.PERNR order by ENDDA DESC ) as fullName,
case when @StartDate between BEGDA and ENDDA and @EndDate between BEGDA and ENDDA then DATEDIFF(day, @StartDate, @EndDate) + 1
	 when BEGDA between @StartDate and @EndDate and ENDDA between  @StartDate and @EndDate then DATEDIFF(day, BEGDA, ENDDA) + 1
	 when @StartDate between BEGDA and ENDDA and ENDDA between @StartDate and @EndDate then DATEDIFF(day, @StartDate, ENDDA) + 1
	 when BEGDA between @StartDate and @EndDate and @EndDate between BEGDA and ENDDA then DATEDIFF(day, BEGDA, @EndDate) + 1
	 end as tmp
from (
select * from HRM_PORTAL_OverTime n 
where STATUS in (3, 6)
AND n.PERNR in (select * from #danhsach)
AND OTTYPE in (select * from #OTTYPE) and SUBSTATUS in (select * from #LoaiDieuChinhTable)
AND (@StartDate between n.BEGDA and n.ENDDA and @EndDate between n.BEGDA and n.ENDDA
	OR n.BEGDA between @StartDate and @EndDate and n.ENDDA between  @StartDate and @EndDate
	OR @StartDate between n.BEGDA and n.ENDDA and n.ENDDA between @StartDate and @EndDate
	OR n.BEGDA between @StartDate and @EndDate and @EndDate between n.BEGDA and n.ENDDA
)
) t
LEFT JOIN (select PERNR as PERNR_oa, PLANS, ORGEH, BEGDA as BEGDA_oa, ENDDA as ENDDA_oa  from HRM_PORTAL_OrganizationalAssignment) oa
ON (oa.PERNR_oa = t.PERNR and t.ENDDA between oa.BEGDA_oa and oa.ENDDA_oa )

) res

LEFT JOIN (select OBJID as OBJID1, STEXT as s1 from HRM_PORTAL_OrganizationStructure) org
 ON org.OBJID1 = res.ORGEH

 --LEFT JOIN (select STEXT as s2 , OBJID as OBJID2  from HRM_PORTAL_OrgUnit) ou
 --ON ou.OBJID2 = org.OBJID1

 LEFT JOIN (select STEXT as s3, OBJID as OBJID3 from HRM_PORTAL_Position) position
 ON position.OBJID3 = res.PLANS

 ) A
BEGIN TRY DROP TABLE #DSPERNRDIS END TRY BEGIN CATCH END CATCH

 CREATE TABLE #DSPERNRDIS (
						STT bigint
						, PERNR CHAR(8)
						, NumberOfPages int
						)
insert into #DSPERNRDIS
 select * from ( select distinct ROW_NUMBER() over (order by s1, PERNR) AS STT, PERNR, (select count(*) from (select distinct PERNR, s1 from #RESULT) as mtb )as NumberOfPages from (select distinct PERNR, s1 from #RESULT) as tsa) pernrTable


select * from #RESULT as result
 Left join #DSPERNRDIS as pernrTable on result.PERNR = pernrTable.PERNR  
 WHERE pernrTable.STT > @FirstPage AND pernrTable.STT <= @FirstPage + @NumberOfPages
 order by result.s1, pernrTable.STT

drop table #danhsach
drop table #LoaiDieuChinhTable
drop table #OTTYPE