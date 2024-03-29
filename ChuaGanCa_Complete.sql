USE [HRM_Portal_02]
GO
/****** Object:  StoredProcedure [dbo].[sproc_Report_ChuaGanCa]    Script Date: 6/6/2019 5:43:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[sproc_Report_ChuaGanCa] 
@StartDate DATETIME,
@EndDate DATETIME,
@danhsach AS DanhSachType READONLY,
@Lang varchar(10),
@RecPerPage INT,
@PageIndex INT

AS
begin
	DECLARE @CurrentDate datetime = GETDATE()
	 DECLARE @FirstRec INT
	 DECLARE @LastRec INT
	 DECLARE @NumberOfPages INT
 
	 SET @FirstRec = (@PageIndex - 1)*@RecPerPage + 1
	 SET @LastRec = @PageIndex *@RecPerPage

	 BEGIN TRY DROP TABLE #TMP END TRY BEGIN CATCH END CATCH
	 BEGIN TRY DROP TABLE #KhongGanCa END TRY BEGIN CATCH END CATCH
	 BEGIN TRY DROP TABLE #TEMPKhongGanCa END TRY BEGIN CATCH END CATCH
	 CREATE TABLE #TMP(rownumber int, PERNR char(8))
	 CREATE TABLE #KhongGanCa (PERNR char(8), ngay datetime )
	 CREATE TABLE #TEMPKhongGanCa (PERNR char(8))

	 BEGIN TRY DROP TABLE #RESULT2 END TRY BEGIN CATCH END CATCH
	 CREATE TABLE #RESULT2 (
							OrganizationName nvarchar(200)
						, PERNR CHAR(8)
						, NACHN nvarchar(100)
						, VORNA nvarchar(100)
						, Fullname nvarchar(200)
						, PositionName nvarchar(200)
						, CounterPernr int)

	 BEGIN TRY DROP TABLE #RESULT END TRY BEGIN CATCH END CATCH
	 CREATE TABLE #RESULT (
							  STT INT
							, OrganizationName nvarchar(200)
							, PERNR CHAR(8)
							, NACHN nvarchar(100)
							, VORNA nvarchar(100)
							, FullName nvarchar(200)
							, PositionName nvarchar(200))

	--End khai báo

	INSERT INTO #TMP (rownumber, PERNR)
	SELECT ROW_NUMBER() OVER (ORDER BY PERNR) as rownumber, ds.PERNR as PERNR FROM @danhsach ds
	DECLARE @cnt int = 1 
	DECLARE @units int = (SELECT count(*) FROM @danhsach)

	-- duyệt từng nhân viên XXX
	WHILE @cnt <= @units 
		BEGIN 
			DECLARE @PERNR char(8) = (SELECT PERNR FROM #TMP WHERE rownumber = @cnt) 
			DECLARE @Ngay datetime
			SET @Ngay = @StartDate 

			--- MAIN ---
				WHILE (@Ngay <= @EndDate) 
					BEGIN 
						DECLARE @MaCa char(8) = (SELECT TOP 1 SCHKZ FROM HRM_PORTAL_WorkScheduleRule WHERE PERNR = @PERNR AND @Ngay BETWEEN BEGDA AND ENDDA)
						DECLARE @defaultShift char(4)
						SET @defaultShift = (SELECT TOP 1 CASE
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
								   WHERE SCHKZ = @MaCa AND KJAHR = YEAR(@Ngay) AND MONAT = MONTH(@Ngay)) 

							--select @defaultShift
							DECLARE @count int
							SET @count = (SELECT COUNT(*) FROM HRM_PORTAL_SetShift WHERE PERNR = @PERNR AND (DailyWSID not like '%flex%' or DailyWSID is null) AND @Ngay BETWEEN BEGDA AND ENDDA) + (CASE WHEN @defaultShift like '%flex%' THEN 0 ELSE 1 END) 

							--select @count
							IF (@count = 0) 
							BEGIN
								INSERT INTO #KhongGanCa VALUES (@PERNR, @Ngay) 
							END

						SET @Ngay = DATEADD(DAY, 1, @Ngay) 
					END
		SET @cnt = @cnt + 1 
	END 
	insert into #TEMPKhongGanCa select distinct PERNR from #KhongGanCa

	if(@Lang = 'vi')
	begin
		insert into #RESULT2(OrganizationName,PERNR,NACHN,VORNA,Fullname,PositionName,CounterPernr)
		select orgUnit.Stext as OrganizationName
			, kgc.PERNR
			, per.NACHN
			, per.VORNA
			, per.NACHN + ' ' + per.VORNA as Fullname
			, position.Stext PositionName
			, row_number() over(partition by kgc.PERNR order by orgUnit.Stext,position.Stext) as CounterPernr
			from #TEMPKhongGanCa kgc
			JOIN HRM_PORTAL_Personal per ON per.PERNR = kgc.PERNR AND @CurrentDate BETWEEN per.BEGDA AND per.ENDDA
			JOIN HRM_PORTAL_OrganizationalAssignment org ON org.PERNR = kgc.PERNR AND @CurrentDate BETWEEN org.BEGDA AND org.ENDDA
			JOIN HRM_PORTAL_OrgUnit orgUnit ON orgUnit.[OBJID] = org.ORGEH AND @CurrentDate between orgUnit.BEGDA and orgUnit.ENDDA
			JOIN HRM_PORTAL_Position position ON position.[OBJID] = org.PLANS AND @CurrentDate between position.BEGDA and position.ENDDA
		
		insert into #RESULT select STT, OrganizationName, PERNR, NACHN, VORNA, FullName, PositionName from (select row_number() over (order by res2.OrganizationName,res2.Fullname) as STT,* from #RESULT2 res2  where res2.CounterPernr = 1) a
		set @NumberOfPages =  (select count(distinct PERNR) from #RESULT)
		select *,@NumberOfPages as NumberOfPages from #RESULT res
		join #KhongGanCa kgc on res.PERNR = kgc.PERNR and res.STT >= @FirstRec and res.STT <= @LastRec order by res.STT
	end
	else
	begin
	insert into #RESULT2(OrganizationName,PERNR,NACHN,VORNA,Fullname,PositionName,CounterPernr)
		select orgUnit.Stext as OrganizationName
			, kgc.PERNR
			, per.NACHN
			, per.VORNA
			, per.VORNA + ' ' + per.NACHN  as Fullname
			, position.Stext PositionName
			, row_number() over(partition by kgc.PERNR order by orgUnit.Stext,position.Stext) as CounterPernr
			from #TEMPKhongGanCa kgc
			JOIN HRM_PORTAL_Personal per ON per.PERNR = kgc.PERNR AND @CurrentDate BETWEEN per.BEGDA AND per.ENDDA
			JOIN HRM_PORTAL_OrganizationalAssignment org ON org.PERNR = kgc.PERNR AND @CurrentDate BETWEEN org.BEGDA AND org.ENDDA
			JOIN HRM_PORTAL_OrgUnit orgUnit ON orgUnit.[OBJID] = org.ORGEH AND @CurrentDate between orgUnit.BEGDA and orgUnit.ENDDA
			JOIN HRM_PORTAL_Position position ON position.[OBJID] = org.PLANS AND @CurrentDate between position.BEGDA and position.ENDDA
		
		insert into #RESULT select STT, OrganizationName, PERNR, NACHN, VORNA, FullName, PositionName from (select row_number() over (order by res2.OrganizationName,res2.Fullname) as STT,* from #RESULT2 res2 where res2.CounterPernr = 1) a
		set @NumberOfPages =  (select count(distinct PERNR) from #RESULT)
		select *,@NumberOfPages as NumberOfPages from #RESULT res
		join #KhongGanCa kgc on res.PERNR = kgc.PERNR and res.STT >= @FirstRec and res.STT <= @LastRec order by res.STT
	end
end
