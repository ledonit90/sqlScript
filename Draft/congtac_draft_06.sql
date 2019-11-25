 -- CONG TAC ----
 declare @StartDate datetime
 set @StartDate = '20190101'
 declare @EndDate datetime
 set @EndDate  = '20190531'

  declare  @FirstPage INT
  set @FirstPage = 0

  declare  @NumberOfPages INT
  set @NumberOfPages = 100

 create table #danhsach (PERNR char(8))
 create table #LoaiDieuChinhTable (SubStatus INT)
 create table #LoaiCongTacTable(SUBTY CHAR (4))
 create table #NoiCongTacTable([LOCAT] NVARCHAR (20) NOT NULL)
 create table #ThanhPhoTable (GBDEP_DESC NVARCHAR (150))
 create table #QuocGiaTable (NATIO_DESC NVARCHAR (150))

 insert into #LoaiCongTacTable
 values('CT01')

  insert into #LoaiCongTacTable
 values('CT02')

 insert into #LoaiCongTacTable
 values('CT03')

  insert into #LoaiCongTacTable
 values('CT04')

 insert into #NoiCongTacTable
 values ('1')

  insert into #NoiCongTacTable
 values ('0')

 insert into #ThanhPhoTable
 values(N'Ngoại tỉnh')

 insert into #ThanhPhoTable
 values(N'Hà Nội')

  insert into #ThanhPhoTable
 values(N'Điện Biên')

  insert into #ThanhPhoTable
 values(N'Lào Cai')
   insert into #ThanhPhoTable
 values(NULL)

 insert into #QuocGiaTable
 values (N'Việt Nam')
  insert into #QuocGiaTable
 values (N'Andorra')
 
 insert into #LoaiDieuChinhTable
 values(1)
 insert into #LoaiDieuChinhTable
 values(2)
 insert into #LoaiDieuChinhTable
 values(3)

 insert into #danhsach 
 values('00323985')

BEGIN TRY DROP TABLE #RESULT END TRY BEGIN CATCH END CATCH

 CREATE TABLE #RESULT (ID INT IDENTITY(1,1) PRIMARY KEY
						,PERNR CHAR(8)
						,BEGDA DATETIME
						,ENDDA DATETIME
						,BEGUZ TIME
						,ENDUZ TIME
						,SUBTY CHAR (4)
						,SUBSTATUS INT
						,LCT NVARCHAR(200)
						,LOCAT INT
						,NATIO_DESC NVARCHAR (150)
						,GBDEP_DESC NVARCHAR (150)
						,ADDRESS NVARCHAR (150)
						,TRANS NVARCHAR(200)
						,REASON NVARCHAR(200)
						,fullname NVARCHAR(200)
						,s2 NVARCHAR(200)
						,s3 NVARCHAR(200))

 INSERT INTO #RESULT

SELECT                   PERNR
						,BEGDA
						,ENDDA
						,BEGUZ
						,ENDUZ
						,SUBTY
						,SUBSTATUS
						,LCT
						,LOCAT
						,NATIO_DESC
						,GBDEP_DESC
						,ADDRESS
						,TRANS
						,REASON
						,fullname
						,s2
						,s3

FROM (

select *,
(select TOP 1 STEXT from HRM_PORTAL_OrgUnit where res.ORGEH = OBJID ORDER BY ENDDA DESC) as s2
 from (
select *,
(SELECT TOP 1 CONCAT(personal.VORNA, ' ', personal.NACHN) FROM [HRM_PORTAL_Personal] personal where personal.PERNR = t.PERNR order by AEDTM DESC ) as fullName
 from (
select *,
case when LOCAT = '0' then 'Trong nuoc'
else 'Ngoai nuoc'
end
as 'NoiCongTac'
from HRM_PORTAL_CongTac n 
where n.PERNR in (select * from #danhsach)
and SUBTY in (select * from #LoaiCongTacTable) and SUBSTATUS in (select * from #LoaiDieuChinhTable)
AND (@StartDate between n.BEGDA and n.ENDDA and @EndDate between n.BEGDA and n.ENDDA
	OR n.BEGDA between @StartDate and @EndDate and n.ENDDA between  @StartDate and @EndDate
	OR @StartDate between n.BEGDA and n.ENDDA and n.ENDDA between @StartDate and @EndDate
	OR n.BEGDA between @StartDate and @EndDate and @EndDate between n.BEGDA and n.ENDDA
)
AND  STATUS in (3, 6)
and SUBTY in (select * from #LoaiCongTacTable) and SUBSTATUS in (select * from #LoaiDieuChinhTable) and LOCAT  in (select * from #NoiCongTacTable) and (GBDEP_DESC in (select * from #ThanhPhoTable) or (GBDEP_DESC is null and LOCAT ='1'))
and NATIO in (select * from #QuocGiaTable)
) t

LEFT JOIN (select PERNR as PERNR_oa, PLANS, ORGEH, BEGDA as BEGDA_oa, ENDDA as ENDDA_oa  from HRM_PORTAL_OrganizationalAssignment) oa
ON (oa.PERNR_oa = t.PERNR and t.ENDDA between oa.BEGDA_oa and oa.ENDDA_oa )

) res

 LEFT JOIN (select OBJID as OBJID1, STEXT as s1 from HRM_PORTAL_OrganizationStructure) org
 ON org.OBJID1 = res.ORGEH

 --LEFT JOIN (select STEXT as s2 , OBJID as OBJID2 from HRM_PORTAL_OrgUnit) ou
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
 select * from ( select distinct ROW_NUMBER() over (order by s2, PERNR) AS STT, PERNR, (select count(*) from (select distinct PERNR, s2 from #RESULT) as mtb )as NumberOfPages from (select distinct PERNR, s2 from #RESULT) as tsa) pernrTable

 select * from #RESULT as result
 Left join #DSPERNRDIS as pernrTable on result.PERNR = pernrTable.PERNR  
 WHERE pernrTable.STT > @FirstPage AND pernrTable.STT <= @FirstPage + @NumberOfPages
 order by result.s2, pernrTable.STT

drop table #RESULT
drop table #danhsach
drop table #LoaiDieuChinhTable
drop table #LoaiCongTacTable
drop table #NoiCongTacTable
drop table #ThanhPhoTable
drop table #QuocGiaTable