--USE [HRM_Portal_02]
--GO
--/****** Object:  StoredProcedure [dbo].[sproc_Report_ChuaGanCa]    Script Date: 6/5/2019 2:28:18 PM ******/
--SET ANSI_NULLS ON
--GO
--SET QUOTED_IDENTIFIER ON
--GO

--ALTER PROCEDURE [dbo].[sproc_Report_ChuaGanCa] 
--@StartDate DATETIME,
--@EndDate DATETIME,
--@danhsach AS DanhSachType READONLY,
--@Lang varchar(10),
--@RecPerPage INT,
--@PageIndex INT
--AS
--begin
	-- tha so luong ngay
	declare @StartDate datetime = '20190605'
	declare @EndDate datetime = '20190605'
	declare @Lang varchar(10) = 'vi'
	declare @RecPerPage int = 10
	declare @PageIndex int = 1

	BEGIN TRY DROP TABLE #LocationList END TRY BEGIN CATCH END CATCH
	create table #LocationList( ID nvarchar(50) )
	insert into #LocationList select os.OBJID from [dbo].[HRM_PORTAL_OrganizationStructure] os where os.orglv2 = '40000002'

	BEGIN TRY DROP TABLE #danhsach END TRY BEGIN CATCH END CATCH
	CREATE TABLE #danhsach(id char(8))
	INSERT INTO #danhsach 
	SELECT distinct oa.PERNR AS id
	FROM HRM_PORTAL_OrganizationalAssignment oa
	JOIN HRM_PORTAL_Action a on oa.PERNR = a.PERNR
	WHERE  oa.ORGEH in (select * from #LocationList) 
		and a.MASSN not in ('ZG','ZH','ZI','ZJ') 
		and a.STAT2 <> 0
		and ((@StartDate BETWEEN a.BEGDA AND a.ENDDA) or (@EndDate BETWEEN a.BEGDA AND a.ENDDA))
		and ((@StartDate BETWEEN oa.BEGDA AND oa.ENDDA) or (@EndDate BETWEEN oa.BEGDA AND oa.ENDDA))
		

	 DECLARE @CurrentDate datetime = GETDATE()
	 DECLARE @FirstRec INT = (@PageIndex - 1)*@RecPerPage + 1
	 DECLARE @LastRec INT = @PageIndex *@RecPerPage
	 DECLARE @STT INT = 1
	 DECLARE @Flag bit = 0
	 DECLARE @CurPernr char(8)
	 DECLARE @OrgName nvarchar(200)
	 DECLARE @NACHN nvarchar(100)
	 DECLARE @VORNA nvarchar(100)
	 DECLARE @FullName nvarchar(200)
	 DECLARE @PositionName nvarchar(200)

	 BEGIN TRY DROP TABLE #TMP END TRY BEGIN CATCH END CATCH
	 BEGIN TRY DROP TABLE #KETQUA END TRY BEGIN CATCH END CATCH
	 BEGIN TRY DROP TABLE #TMPPERNR END TRY BEGIN CATCH END CATCH
	 BEGIN TRY DROP TABLE #DisPERNR END TRY BEGIN CATCH END CATCH
	 CREATE TABLE #TMP (      PERNR CHAR(8)
							, OrganizationName nvarchar(200)
							, NACHN nvarchar(100)
							, VORNA nvarchar(100)
							, FullName nvarchar(200)
							, PositionName nvarchar(200))
	create table #TMPPERNR( PERNR char(8), SttNum int)
	create table #DisPERNR( PERNR char(8))
	CREATE TABLE #KETQUA (
							  STT int
							, PERNR CHAR(8)
							, OrganizationName nvarchar(200)
							, NACHN nvarchar(100)
							, VORNA nvarchar(100)
							, FullName nvarchar(200)
							, PositionName nvarchar(200)
							, ngay datetime)

	--End khai báo
	insert into #TMPPERNR (PERNR, SttNum)
	select kgc.id as PERNR, row_number() over(order by orgUnit.Stext,per.NACHN + ' ' + per.VORNA,position.Stext) as SttNum
		from #danhsach kgc
		JOIN HRM_PORTAL_Personal per ON per.PERNR = kgc.id AND @CurrentDate BETWEEN per.BEGDA AND per.ENDDA
		JOIN HRM_PORTAL_OrganizationalAssignment org ON org.PERNR = kgc.id AND @CurrentDate BETWEEN org.BEGDA AND org.ENDDA
		JOIN HRM_PORTAL_OrgUnit orgUnit ON orgUnit.[OBJID] = org.ORGEH AND @CurrentDate between orgUnit.BEGDA and orgUnit.ENDDA
		left JOIN HRM_PORTAL_Position position ON position.[OBJID] = org.PLANS AND @CurrentDate between position.BEGDA and position.ENDDA
	select * from #TMPPERNR order by SttNum
	---- duyệt từng nhân viên XXX
	declare DisPernrCursor cursor
	forward_only
	read_only
	for select * from #TMPPERNR order by SttNum

	open DisPernrCursor
	fetch next from DisPernrCursor into @CurPernr,
	WHILE @@FETCH_STATUS = 0 
	BEGIN 
		DECLARE @Ngay datetime
		SET @Ngay = @StartDate
		--- MAIN ---
		if( @CurPernr not in (select * from #DisPERNR))
		begin
			WHILE (@Ngay <= @EndDate)
			BEGIN 
				DECLARE @MaCa char(8) = (SELECT TOP 1 SCHKZ FROM HRM_PORTAL_WorkScheduleRule WHERE PERNR = @CurPernr AND @Ngay BETWEEN BEGDA AND ENDDA)
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
				SET @count = (SELECT COUNT(*) FROM HRM_PORTAL_SetShift WHERE PERNR = @CurPernr AND DailyWSID not like '%flex%' AND @Ngay BETWEEN BEGDA AND ENDDA) + (CASE WHEN @defaultShift like '%flex%' or @defaultShift is null or @defaultShift = ''  THEN 0 ELSE 1 END) 
				insert into #DisPERNR(PERNR) values(@CurPernr)
				--select @count
				IF (@count = 0) 
				BEGIN
					if(@STT between @FirstRec and @LastRec)
					begin
						select top 1 @OrgName = orgUnit.Stext,@NACHN = per.NACHN, @VORNA = per.VORNA @FullName = per.NACHN + ' ' + per.VORNA,@PositionName = position.Stext
						from HRM_PORTAL_Personal per ON per.PERNR = @CurPernr AND @CurrentDate BETWEEN per.BEGDA AND per.ENDDA
						JOIN HRM_PORTAL_OrganizationalAssignment org ON org.PERNR = per.PERNR AND @CurrentDate BETWEEN org.BEGDA AND org.ENDDA
						JOIN HRM_PORTAL_OrgUnit orgUnit ON orgUnit.[OBJID] = org.ORGEH AND @CurrentDate between orgUnit.BEGDA and orgUnit.ENDDA
						left JOIN HRM_PORTAL_Position position ON position.[OBJID] = org.PLANS AND @CurrentDate between position.BEGDA and position.ENDDA

						INSERT INTO #KETQUA(STT, PERNR, OrganizationName, NACHN, VORNA, FullName, PositionName, ngay) 
						VALUES (@STT,@CurPernr,@OrgName,@NACHN,@VORNA,@FullName,@PositionName, @Ngay)
						set @Flag = 1
					end
					else
					begin
						set @Flag = 1
					end

				END

				SET @Ngay = DATEADD(DAY, 1, @Ngay) 
			END
		end

		if(@Flag = 1)
		begin
			set @STT = @STT + 1
			set @Flag = 0
		end

		fetch next from DisPernrCursor into @CurPernr,@OrgName,@NACHN,@VORNA,@FullName,@PositionName
	END

	close DisPernrCursor
	DEALLOCATE DisPernrCursor

	select *,@STT - 1 as NumberOfPages  from #KETQUA
	
--END