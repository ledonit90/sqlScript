 -- NGHI PHEP ----
 declare @StartDate datetime
 set @StartDate = '20190101'
 declare @EndDate datetime
 set @EndDate  = '20190531'

 create table #danhsach (PERNR char(8))
 create table #LoaiDieuChinhTable (SubStatus INT)
 create table #LoaiNghiTable(SUBTY CHAR (4))

 insert into #LoaiNghiTable
	values('PQ01')

 insert into #LoaiNghiTable
	values('PQ02')

 insert into #LoaiNghiTable
	values('UN03')
 insert into #LoaiNghiTable
	values('PN01')
 insert into #LoaiNghiTable
   values('PN04')

 

 insert into #LoaiDieuChinhTable
 values(1)
 insert into #LoaiDieuChinhTable
 values(2)
 insert into #LoaiDieuChinhTable
 values(3)

 insert into #danhsach 
 values('03504665')

  insert into #danhsach 
 values('00323981')
  insert into #danhsach 
 values('00323985')
  insert into #danhsach 
 values('00333503')
 insert into #danhsach 
 values('00358148')

 BEGIN TRY DROP TABLE #RESULT END TRY BEGIN CATCH END CATCH
  CREATE TABLE #RESULT (
						PERNR CHAR(8)
						, fullName text
						, s2 text
						, s3 text
						, MLN text
						, SUBSTATUS int
						, BEGDA Datetime
						, ENDDA Datetime
						, BEGUZ time
						, ENDUZ time
						,totalMinutes INT
						,totalOfDays INT
						,REASON TEXT
						)

INSERT INTO #RESULT
SELECT                   						
						PERNR
						, fullName
						, s2
						, s3
						, MLN
						, SUBSTATUS 
						, BEGDA
						, ENDDA
						, BEGUZ
						, ENDUZ
						, totalMinutes
						, totalOfDays
						, REASON

FROM (
select *,
 case when SUBSTATUS  = 3 then tmp * (-1)
	else tmp
	end as totalOfDays,
case when BEGUZ is not null and ENDUZ is not null then 
												  case when SUBSTATUS in (1, 2) then (f.tmp)*(DATEDIFF(MINUTE, BEGUZ, ENDUZ))
												  when SUBSTATUS  = 3 then (f.tmp) * (-1)* (DATEDIFF(MINUTE, BEGUZ, ENDUZ))
												  else 0
												  end 
									else 0
									end as totalMinutes
from (
select *,
(select TOP 1 STEXT from HRM_PORTAL_OrgUnit where res.ORGEH = OBJID ORDER BY ENDDA DESC) as s2,
(SELECT TOP 1 CONCAT(personal.VORNA, ' ', personal.NACHN) FROM [HRM_PORTAL_Personal] personal where personal.PERNR = res.PERNR order by AEDTM DESC) as fullName,
case when @StartDate between BEGDA and ENDDA and @EndDate between BEGDA and ENDDA then DATEDIFF(day, @StartDate, @EndDate) + 1
	 when BEGDA between @StartDate and @EndDate and ENDDA between  @StartDate and @EndDate then DATEDIFF(day, BEGDA, ENDDA) + 1
	 when @StartDate between BEGDA and ENDDA and ENDDA between @StartDate and @EndDate then DATEDIFF(day, @StartDate, ENDDA) + 1
	 when BEGDA between @StartDate and @EndDate and @EndDate between BEGDA and ENDDA then DATEDIFF(day, BEGDA, @EndDate) + 1
	 end as tmp

from (
select * from (
select * from HRM_PORTAL_NghiPhep n 
where n.PERNR in (select * from #danhsach)
AND STATUS in (3, 6)
AND SUBTY in (select * from #LoaiNghiTable) and SUBSTATUS in (select * from #LoaiDieuChinhTable)
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

 ) f
 ) TempNghiPhepTable

 select * from #RESULT

drop table #danhsach
drop table #LoaiDieuChinhTable
drop table #LoaiNghiTable