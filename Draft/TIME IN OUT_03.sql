
 declare @StartDate datetime
 set @StartDate = '20180101'
 declare @EndDate datetime
 set @EndDate  = '20180131'

 create table #danhsach (PERNR char(8))

 insert into #danhsach 
 values('00000002')
 insert into #danhsach 
 values('03510341')
 insert into #danhsach 
 values('03501947')

--select  distinct * from #danhsach

select * ,
(select TOP 1 STEXT from HRM_PORTAL_OrgUnit where res.ORGEH = OBJID ORDER BY ENDDA DESC) as s2,
case when LATE_EARLY > 0  then 1
	else 0
	end as isLateEarly
from (
select *,
(SELECT TOP 1 CONCAT(personal.VORNA, ' ', personal.NACHN) FROM [HRM_PORTAL_Personal] personal where personal.PERNR = t.PERNR order by AEDTM DESC ) as fullName
from (
select * from [HRM_PORTAL_TimeEvaluationResult]
where LATE_EARLY > 0
AND PERNR in (select * from #danhsach)
AND [Date] between @StartDate and @EndDate
) t
LEFT JOIN (select PERNR as PERNR_oa, PLANS, ORGEH, BEGDA, ENDDA from HRM_PORTAL_OrganizationalAssignment) oa
ON (oa.PERNR_oa = t.PERNR and t.DATE between BEGDA and ENDDA )

--order by ORGEH, PERNR, DATE

) res

 LEFT JOIN (select OBJID as OBJID1, STEXT as s1 from HRM_PORTAL_OrganizationStructure) org
 ON org.OBJID1 = res.ORGEH

 --LEFT JOIN (select STEXT as s2 , OBJID as OBJID2  from HRM_PORTAL_OrgUnit) ou
 --ON ou.OBJID2 = org.OBJID1

 LEFT JOIN (select STEXT as s3, OBJID as OBJID3 from HRM_PORTAL_Position) position
 ON position.OBJID3 = res.PLANS

order by ORGEH, PERNR, DATE


drop table #danhsach