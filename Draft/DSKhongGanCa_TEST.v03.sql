
--ALTER PROCEDURE DSKhongGanCa 
DECLARE @StartDate DATETIME = '20190328' 
--SET @StartDate = '20191127' 
DECLARE @EndDate DATETIME =  '20190329' 
DECLARE @NumberOfPages INT = 10
DECLARE @FirstPage INT = 1
--SET @EndDate = '20191130' 
--DECLARE @PERNR char(8) = '00000002'
--SET @PERNR = '00000002'

--AS

  create table #danhsach (PERNR char(8))
  --insert into #danhsach
  --values ('00000002')

  --insert into #danhsach
  --values ('00000003')
    insert into #danhsach
  values ('00300796')
  insert into #danhsach
  values ('00329838')
  insert into #danhsach
  values ('00929401')
  insert into #danhsach
  values ('00300813')
  insert into #danhsach
  values ('00329837')
  insert into #danhsach
  values ('03011498')

  create table #tmpDS (PERNR char(8))

insert into #tmpDS
select  distinct * from #danhsach

CREATE TABLE #TMP(rownumber int, PERNR char(8))

INSERT INTO #TMP (rownumber, PERNR)
SELECT ROW_NUMBER() OVER (ORDER BY PERNR), * from #tmpDS

declare @cnt int = 1
declare @units int = (select count(*) from #TMP)



  CREATE TABLE #KhongGanCa (
    PERNNR char(8),
    ngay datetime
  )

  -- duyệt từng nhân viên XXX
while @cnt <= @units
	BEGIN

  declare @PERNR char(8) = (select PERNR from #TMP where rownumber = @cnt)

  DECLARE @Ngay datetime
  SET @Ngay = @StartDate

   --- MAIN ---
  WHILE (@Ngay <= @EndDate)
  BEGIN

    DECLARE @defaultShift char(4)
    SET @defaultShift = (SELECT
      CASE
        WHEN DAY(@Ngay) = 1 THEN TPR01
        WHEN DAY(@Ngay) = 2 THEN TPR02
        WHEN DAY(@Ngay) = 3 THEN TPR03
        WHEN DAY(@Ngay) = 4 THEN TPR04
        WHEN DAY(@Ngay) = 5 THEN TPR05
        WHEN DAY(@Ngay) = 6 THEN TPR06
        WHEN DAY(@Ngay) = 7 THEN TPR07
        WHEN DAY(@Ngay) = 8 THEN TPR08
        WHEN DAY(@Ngay) = 9 THEN TPR09
        WHEN DAY(@Ngay) = 10 THEN TPR10
        WHEN DAY(@Ngay) = 11 THEN TPR11
        WHEN DAY(@Ngay) = 12 THEN TPR12
        WHEN DAY(@Ngay) = 13 THEN TPR13
        WHEN DAY(@Ngay) = 14 THEN TPR14
        WHEN DAY(@Ngay) = 15 THEN TPR15
        WHEN DAY(@Ngay) = 16 THEN TPR16
        WHEN DAY(@Ngay) = 17 THEN TPR17
        WHEN DAY(@Ngay) = 18 THEN TPR18
        WHEN DAY(@Ngay) = 19 THEN TPR19
        WHEN DAY(@Ngay) = 20 THEN TPR20
        WHEN DAY(@Ngay) = 21 THEN TPR21
        WHEN DAY(@Ngay) = 22 THEN TPR22
        WHEN DAY(@Ngay) = 23 THEN TPR23
        WHEN DAY(@Ngay) = 24 THEN TPR24
        WHEN DAY(@Ngay) = 25 THEN TPR25
        WHEN DAY(@Ngay) = 26 THEN TPR26
        WHEN DAY(@Ngay) = 27 THEN TPR27
        WHEN DAY(@Ngay) = 28 THEN TPR28
        WHEN DAY(@Ngay) = 29 THEN TPR29
        WHEN DAY(@Ngay) = 30 THEN TPR30
        ELSE TPR31
      END AS TPR
    FROM HRM_PORTAL_MonthlyWorkSchedule
    WHERE SCHKZ = (SELECT TOP 1
      SCHKZ
    FROM HRM_PORTAL_WorkScheduleRule
    WHERE PERNR = @PERNR
    AND @Ngay BETWEEN BEGDA AND ENDDA)
    AND KJAHR = YEAR(@Ngay)
    AND MONAT = MONTH(@Ngay))

    --select @defaultShift

    DECLARE @count int
    SET @count = (SELECT
      COUNT(*)
    FROM HRM_PORTAL_SetShift
    WHERE PERNR = @PERNR
    AND @Ngay BETWEEN BEGDA AND ENDDA)
    + (CASE
      WHEN @defaultShift <> 'FLEX' THEN 1
      ELSE 0
    END)
    --select @count

    IF (@count = 0)

    BEGIN

      INSERT INTO #KhongGanCa
        VALUES (@PERNR, @Ngay)

    END

    SET @Ngay = DATEADD(DAY, 1, @Ngay)
  END

  
  set @cnt = @cnt + 1
end

  --SELECT * FROM #KhongGanCa

 BEGIN TRY DROP TABLE #RESULT END TRY BEGIN CATCH END CATCH

 CREATE TABLE #RESULT (
						PERNR CHAR(8)
						,BEGDA DATETIME
						,ENDDA DATETIME
						,FullName nvarchar(200)
						,s3 nvarchar(200)
						,s1 nvarchar(200)
						,ngay DATETIME)

  
  INSERT INTO #RESULT
  SELECT 
	                     PERNR
						,BEGDA
						,ENDDA
						,FullName
						,s3
						,s1
						,ngay
  

  FROM (
  SELECT *,
  (SELECT TOP 1 CONCAT(personal.VORNA, ' ', personal.NACHN) FROM [HRM_PORTAL_Personal] personal where personal.PERNR = res.PERNNR order by AEDTM DESC) as FullName
  FROM #KhongGanCa res
  LEFT JOIN (SELECT PERNR, ORGEH, PLANS, BEGDA, ENDDA, AEDTM FROM HRM_PORTAL_OrganizationalAssignment) oa
  ON (oa.PERNR = res.PERNNR and res.ngay BETWEEN oa.BEGDA and oa.ENDDA)


  LEFT JOIN (select OBJID as OBJID1, STEXT as s1 from HRM_PORTAL_OrganizationStructure) org
 ON org.OBJID1 = oa.ORGEH

 LEFT JOIN (select STEXT as s3, OBJID as OBJID3, BEGDA as BEGDA_p, ENDDA as ENDDA_p from HRM_PORTAL_Position) position
 ON (position.OBJID3 = oa.PLANS AND res.ngay between position.BEGDA_p and position.ENDDA_p)

 ) A


BEGIN TRY DROP TABLE #DSPERNRDIS END TRY BEGIN CATCH END CATCH

 CREATE TABLE #DSPERNRDIS (
						STT int
						,PERNR CHAR(8)
						, NumberOfPages int
						)
insert into #DSPERNRDIS
 select * from ( select distinct ROW_NUMBER() over (order by s1, PERNR) AS STT, PERNR, (select count(*) from (select distinct PERNR, s1 from #RESULT) txkd) as NumberOfPages from (select distinct PERNR, s1 from #RESULT) as tsa) pernrTable

 select * from #RESULT as result
 Left join #DSPERNRDIS as pernrTable on result.PERNR = pernrTable.PERNR  
 WHERE pernrTable.STT > @FirstPage AND pernrTable.STT <= @FirstPage + @NumberOfPages
 order by result.s1, pernrTable.STT, result.FullName, result.ngay


  DROP TABLE #KhongGanCa
  DROP TABLE #danhsach
  DROP TABLE #tmpDS
  DROP TABLE #TMP