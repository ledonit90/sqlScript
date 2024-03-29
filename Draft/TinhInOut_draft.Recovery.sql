--USE [HRM_Portal_02_01]
--GO
--/****** Object:  StoredProcedure [dbo].[sproc_GetCaANDBreakCa]    Script Date: 9/11/2019 5:28:13 PM ******/
--SET ANSI_NULLS ON
--GO
--SET QUOTED_IDENTIFIER ON
--GO
 
--ALTER PROCEDURE dbo.sproc_GetCaANDSplitCa
--    -- @phongban as PhongBanType READONLY,
--	  @listInOut as [dbo].[DataInsertInOut] READONLY
--    @danhsach as dbo.DanhSachType READONLY,
--    @StartDate datetime,
--    @EndDate datetime
--AS
--begin
	
	Set nocount on
	declare @StartDate datetime = '20190908'
	declare @EndDate datetime = '20190913'

	BEGIN TRY DROP TABLE #LocationList END TRY BEGIN CATCH END CATCH
	create table #LocationList( ID nvarchar(50) )
	insert into #LocationList select os.OBJID from [dbo].[HRM_PORTAL_OrganizationStructure] os where os.ORGLV2 in ('45007010','45005001')
	BEGIN TRY DROP TABLE #danhsach END TRY BEGIN CATCH END CATCH
	CREATE TABLE #danhsach(PERNR char(8))
	INSERT INTO #danhsach --values('00947614'),('03553974'),('00947635')
	SELECT distinct oa.PERNR AS id
	FROM HRM_PORTAL_OrganizationalAssignment oa
	JOIN HRM_PORTAL_Action a on oa.PERNR = a.PERNR
	WHERE  oa.ORGEH in (select * from #LocationList) 
		and a.MASSN not in ('ZG','ZH','ZI','ZJ') 
		and a.STAT2 <> 0
		and ((@StartDate BETWEEN a.BEGDA AND a.ENDDA) or (@EndDate BETWEEN a.BEGDA AND a.ENDDA))
		and ((@StartDate BETWEEN oa.BEGDA AND oa.ENDDA) or (@EndDate BETWEEN oa.BEGDA AND oa.ENDDA))
	
	--BEGIN TRY DROP TABLE #danhsach END TRY BEGIN CATCH END CATCH
	--CREATE TABLE #danhsach(PERNR char(8))
	--INSERT INTO #danhsach  --values('00365231'),('03553974'),('00947635')
	----select top 20000 PERNR from(
	--SELECT DISTINCT PERNR from [HRM_PORTAL_Action]
	--WHERE STAT2 = 3 
	--AND MASSN IN ('ZA', 'ZB', 'ZC', 'ZD', 'ZE', 'ZF')
	--AND (
	--(CONVERT(DATE, DATEADD(DAY, -1, GETDATE())) BETWEEN BEGDA AND ENDDA)
	--OR
	--(CONVERT(DATE, DATEADD(DAY, -2, GETDATE())) BETWEEN BEGDA AND ENDDA)
	--OR
	--(CONVERT(DATE, GETDATE()) BETWEEN BEGDA AND ENDDA)
	--)
	--) as t

	-- Du lieu InOut
	BEGIN TRY DROP TABLE #DataInOut END TRY BEGIN CATCH END CATCH
	create table #DataInOut( [PERNR] [varchar](10) NULL, [ERDAT] char(8) NULL, [ERTIM] char(6) NULL, [SATZA] [char](3) NULL,[TimeStamp] [bigint] NULL)
	insert into #DataInOut([PERNR] ,[ERDAT],[ERTIM],[SATZA])
	select [PERNR] ,[ERDAT],[ERTIM],[SATZA]
	from [dbo].[VIN_CENTRALIZED] where PERNR in (select cast(PERNR as int) from #danhsach)
	update #DataInOut set [TimeStamp] = dbo.UNIX_TIMESTAMP([ERDAT] + cast(CAST(STUFF(STUFF([ERTIM],5,0,':'),3,0,':') AS time) as datetime))

--------------------------------- MAIN -------------------------------------------------
	SET NOCOUNT ON
	------------------- bien cho con tro ----------------@ngayMerge
	declare @PERNR char(8)
	declare @ngaycur datetime
	declare @ngayMerge datetime
	declare @startTime time
	declare @endTime time
	declare @startTimeBreak time
	declare @endTimeBreak time
	declare @TimeStampStart int
	declare @TimeStampStartMerge int
	declare @TimeStampEnd int
	declare @TimeStampEndMerge int
	declare @shiftType char(2)
	declare @CuoiCung bit = 0
	declare @CurrSTT int
	declare @ID int
	declare @STT int
	------------------------ Maximum of meger ca ---------------------
	declare @countMerge int = 0
	declare @prevPENRN char(8) = 0
	declare @curPENRN char(8) = 0
	declare @curStart int = 0
	declare @prevEnd int = 0
	------------------------------------ cac hang so -----------------------------
	declare @startDateTimeStamp int = dbo.UNIX_TIMESTAMP(@startDate)
	declare @endDateTimeStamp int = dbo.UNIX_TIMESTAMP(@EndDate + cast('23:59:59' as datetime))

	BEGIN TRY DROP TABLE #DaDuyet END TRY BEGIN CATCH END CATCH
	create table #DaDuyet( ID char(8))

	BEGIN TRY DROP TABLE #ACTIVEPERNR END TRY BEGIN CATCH END CATCH
	create table #ACTIVEPERNR( PERNR char(8))

	BEGIN TRY DROP TABLE #ManuallyUpdate END TRY BEGIN CATCH END CATCH
	create table #ManuallyUpdate( PERNR char(8),Ngay Datetime)

	BEGIN TRY DROP TABLE #TMPPERNR END TRY BEGIN CATCH END CATCH
	create table #TMPPERNR( PERNR char(8))

	BEGIN TRY DROP TABLE #RESULTCALAMVIEC END TRY BEGIN CATCH END CATCH
	create table #RESULTCALAMVIEC(PERNR char(8), ngay datetime,startTime time, endTime time, 
	startTimeBreak time, endTimeBreak time, shiftType char(2))
	---------- khai bao bang cho ca gan setshift -----------------------------------------
	BEGIN TRY DROP TABLE #CA_SETSHIFT_RESULT END TRY BEGIN CATCH END CATCH
	create table #CA_SETSHIFT_RESULT(PERNR char(8), ngay datetime,startTime time, endTime time, 
	startTimeBreak time, endTimeBreak time, shiftType char(20))
	----------- khai bao bang tam cho tinh toan ca mac dinh -------------------------------
	BEGIN TRY DROP TABLE #CaORG_AND_Rule END TRY BEGIN CATCH END CATCH
	create table #CaORG_AND_Rule( PERNR char(8),SCHKZ char(8),BTRTL char(4), WERKS char(4))
	BEGIN TRY DROP TABLE #MaCaTheoNgay END TRY BEGIN CATCH END CATCH
	create table #MaCaTheoNgay( PERNR char(8), MaCa char(4),  MosID int null)

	BEGIN TRY DROP TABLE #CA_MACDINH_RESULT END TRY BEGIN CATCH END CATCH
	create table #CA_MACDINH_RESULT(PERNR char(8), ngay datetime,startTime time, endTime time, 
	startTimeBreak time, endTimeBreak time, shiftType char(2))
	------------------- khai bao bang tam cho ca lam them gio -----------------------------
	BEGIN TRY DROP TABLE #CA_OVERTIME END TRY BEGIN CATCH END CATCH
	create table #CA_OVERTIME(PERNR char(8), ngay datetime,startTime time, endTime time, 
	startTimeBreak time, endTimeBreak time, shiftType char(2))

	------------------- Ca break - Insert tat ca cac ca duoc break ----------------------
	BEGIN TRY DROP TABLE #CA_Break END TRY BEGIN CATCH END CATCH
	create table #CA_Break(PERNR char(8), ngay datetime,startTime time, endTime time, 
	startTimeBreak time, endTimeBreak time, shiftType char(2))

	BEGIN TRY DROP TABLE #CA_Break_TMP END TRY BEGIN CATCH END CATCH
	create table #CA_Break_TMP(PERNR char(8), ngay datetime,startTime time, endTime time, 
	startTimeBreak time, endTimeBreak time, shiftType char(2))

	------------------- Ca Merge - Insert tat ca cac ca duoc Merge ----------------------
	BEGIN TRY DROP TABLE #CA_DuyNhat_Merge END TRY BEGIN CATCH END CATCH
	create table #CA_DuyNhat_Merge(PERNR char(8), ngay datetime,startTime time, endTime time, 
	startTimeBreak time, endTimeBreak time, shiftType char(2),duynhat int)

	BEGIN TRY DROP TABLE #CA_TMP_Merge END TRY BEGIN CATCH END CATCH
	create table #CA_TMP_Merge(ID int,PERNR char(8), ngay datetime, shiftType char(2), StartTimeStamp bigint, EndTimeStamp bigint,STT int)

	BEGIN TRY DROP TABLE #CA_TMP_Merge2 END TRY BEGIN CATCH END CATCH
	create table #CA_TMP_Merge2(ID int,PERNR char(8), ngay datetime, shiftType char(2),StartTimeStamp bigint,EndTimeStamp bigint,STT int)

	BEGIN TRY DROP TABLE #CA_Can_Merge END TRY BEGIN CATCH END CATCH
	create table #CA_Can_Merge(ID int,PERNR char(8), ngay datetime, shiftType char(2),StartTimeStamp bigint,EndTimeStamp bigint,STT int)

	BEGIN TRY DROP TABLE #CA_Can_MergeDau END TRY BEGIN CATCH END CATCH
	create table #CA_Can_MergeDau(PERNR char(8), ngay datetime, shiftType char(2),StartTimeStamp bigint,EndTimeStamp bigint,STT int)

	BEGIN TRY DROP TABLE #CA_Can_MergeCuoi END TRY BEGIN CATCH END CATCH
	create table #CA_Can_MergeCuoi(PERNR char(8), ngay datetime, shiftType char(2),StartTimeStamp bigint,EndTimeStamp bigint,STT int)

	BEGIN TRY DROP TABLE #CA_Can_MergeID1 END TRY BEGIN CATCH END CATCH
	create table #CA_Can_MergeID1(ID int)
	BEGIN TRY DROP TABLE #CA_Can_MergeID END TRY BEGIN CATCH END CATCH
	create table #CA_Can_MergeID(ID int)
	BEGIN TRY DROP TABLE #CA_Can_MergeCuoiID END TRY BEGIN CATCH END CATCH
	create table #CA_Can_MergeCuoiID(ID int)

	BEGIN TRY DROP TABLE #CA_Merge END TRY BEGIN CATCH END CATCH
	create table #CA_Merge(PERNR char(8), ngay datetime, shiftType char(2),StartTimeStamp bigint,EndTimeStamp bigint)

	BEGIN TRY DROP TABLE #Result END TRY BEGIN CATCH END CATCH
	create table #Result(ID int,PERNR char(8), ngay datetime,shiftType char(2),StartTimeStamp bigint,EndTimeStamp bigint)

	BEGIN TRY DROP TABLE #Result2 END TRY BEGIN CATCH END CATCH
	create table #Result2(ID int,PERNR char(8), ngay datetime,startTime time, endTime time, 
	startTimeBreak time, endTimeBreak time, shiftType char(2),StartTimeStamp bigint,EndTimeStamp bigint,LastOutPlanned bigint)

	BEGIN TRY DROP TABLE #Result3 END TRY BEGIN CATCH END CATCH
	create table #Result3(ID int,PERNR char(8), ngay datetime, shiftType char(2),StartTimeStamp int,EndTimeStamp int,LastOutPlanned int,NextInPlanned int)
	-- Lay Ma Ca theo uu tien setshift + OT, neu ko co setshift + OT => ca mac dinh + OT
	
	BEGIN TRY DROP TABLE #Result4 END TRY BEGIN CATCH END CATCH
	create table #Result4(ID int,PERNR char(8), ngay datetime, shiftType char(2),StartTimeStamp bigint,EndTimeStamp bigint,LastOutPlanned bigint,NextInPlanned bigint, ManuallyUpdate bit)

	BEGIN TRY DROP TABLE #KetQuaInOUT END TRY BEGIN CATCH END CATCH
	create table #KetQuaInOUT(ID int,PERNR char(8), TargetDate datetime,Ngay char(8),ThoiGian char(6),unixTime int,SATZA2 char(3),SATZA char(3),IsOvernight bit,TimeStampPlanSortOrder int, RowID int)

	declare @Ngay datetime
	set @Ngay = @StartDate

	while (@Ngay <= @EndDate)
	begin
		-- nhung thang active trong ngay hom day
		BEGIN TRY truncate table #ACTIVEPERNR END TRY BEGIN CATCH END CATCH
		insert into #ACTIVEPERNR
		select distinct tmp.PERNR
		from #danhsach tmp 
		join HRM_PORTAL_Action ac on ac.PERNR = tmp.PERNR  
		and ac.MASSN not in ('ZG','ZH','ZI','ZJ') 
		and ac.STAT2 <> 0 and (@Ngay BETWEEN ac.BEGDA AND ac.ENDDA)
		-------------------------- trong bang HRM_PORTAL_TimeIn_Out co manualUpdated = 1 --------------------
		-------------------------- ( nhan vien duoc update manually ) -----------------------------
		insert into #ManuallyUpdate(PERNR,Ngay)
		select atp.PERNR,@Ngay as Ngay 
		from #ACTIVEPERNR atp 
		join HRM_PORTAL_TimeIn_Out inout 
		on atp.PERNR = inout.PERNR and TargetDate = @Ngay AND ManuallyUpdated  = 1


		declare @Ngay2 varchar(10)
		SET @Ngay2 = convert(varchar(10),@Ngay, 111)
		-- cac ca gan trong hrm_portal_setshift	
		BEGIN TRY truncate table #CA_SETSHIFT_RESULT END TRY BEGIN CATCH END CATCH	
		insert into #CA_SETSHIFT_RESULT (PERNR, ngay,startTime, endTime, startTimeBreak, endTimeBreak, shiftType)
		select s.PERNR,@Ngay as ngay,s.STARTTIME, s.ENDTIME, s.BREAKSTART, s.BREAKEND, 's'  -- s - setshift
		from [HRM_PORTAL_SetShift] s join #ACTIVEPERNR atp on s.PERNR = atp.PERNR
		WHERE @Ngay BETWEEN BEGDA AND ENDDA and s.STARTTIME is not null and s.ENDTIME is not null and s.DailyWSID != 'OFF'

		BEGIN TRY truncate table #TMPPERNR END TRY BEGIN CATCH END CATCH	
		insert into #TMPPERNR select * from #ACTIVEPERNR where pernr  not in (select pernr from #CA_SETSHIFT_RESULT)
		-- cac ca gan mac dinh da loai cac nhan vien co trong setshift
		-- lay thong tin ca theo phong ban cua nhan vien va thong tin Rule gan ca
		BEGIN TRY truncate table #CaORG_AND_Rule END TRY BEGIN CATCH END CATCH
		insert into #CaORG_AND_Rule
		select tmp.PERNR, wsr.SCHKZ,oa.BTRTL,oa.WERKS
		from #TMPPERNR tmp
		join HRM_PORTAL_WorkScheduleRule wsr on tmp.PERNR = wsr.PERNR AND @Ngay BETWEEN BEGDA AND ENDDA
		join HRM_PORTAL_OrganizationalAssignment oa on tmp.PERNR = oa.PERNR and @Ngay between oa.BEGDA AND oa.ENDDA

		-- lay thong tin ca
		BEGIN TRY truncate table #MaCaTheoNgay END TRY BEGIN CATCH END CATCH
		insert into #MaCaTheoNgay
		select wsr.PERNR, (CASE
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
									END) as MaCa, mws.MOSID
		from #CaORG_AND_Rule wsr
		join HRM_PORTAL_MapPSGrpPerArea map on map.BTRTL = wsr.BTRTL and wsr.WERKS = map.WERKS
		join HRM_PORTAL_MonthlyWorkSchedule mws on wsr.SCHKZ = mws.SCHKZ 
		AND mws.KJAHR = YEAR(@Ngay) AND mws.MONAT = MONTH(@Ngay) and mws.MOSID = map.MOSID
		-- tinh toan ca mac dinh
		BEGIN TRY truncate table #CA_MACDINH_RESULT END TRY BEGIN CATCH END CATCH
		insert into #CA_MACDINH_RESULT(PERNR, ngay,startTime, endTime, startTimeBreak, endTimeBreak, shiftType)
		select tsgMaCa.PERNR,@Ngay as ngay, dws.SOBEG, dws.SOEND, wsb.PABEG, wsb.PAEND ,'D' -- D - DailyWorkingSchedule
		from #MaCaTheoNgay tsgMaCa
		join HRM_PORTAL_DailyWorkSchedule dws on dws.TPROG = tsgMaCa.MaCa and dws.MOTPR = tsgMaCa.MosID and rtrim(ltrim(tsgMaCa.MaCa)) != 'OFF'
		left join HRM_PORTAL_WorkScheduleBreak wsb on wsb.PAMOD = dws.PAMOD and dws.MOTPR = wsb.MOTPR
		where  dws.SOBEG is not null and dws.SOEND is not null
		
		-- ca OT
		BEGIN TRY truncate table #CA_OVERTIME END TRY BEGIN CATCH END CATCH
		insert into #CA_OVERTIME(PERNR, ngay,startTime, endTime, startTimeBreak, endTimeBreak, shiftType)
		select overtime.PERNR,@Ngay as ngay, overtime.BEGUZ, overtime.ENDUZ, null, null ,'O' -- O - Overtime
		from [HRM_PORTAL_OverTime] overtime
		join #ACTIVEPERNR atp on atp.PERNR = overtime.PERNR
		WHERE @Ngay BETWEEN BEGDA AND ENDDA 
		AND STATUS IN (3, 6)
		AND ID NOT IN (SELECT ORIGINID FROM [HRM_PORTAL_OverTime] z WHERE z.PERNR = overtime.PERNR AND STATUS IN (3,6) AND SUBSTATUS = 3)
		AND ORIGINID NOT IN (SELECT ORIGINID FROM [HRM_PORTAL_OverTime] z WHERE z.PERNR = overtime.PERNR AND STATUS IN (3,6) AND SUBSTATUS = 3)
		AND STATUS <> 4
		AND overtime.BEGUZ is not null and overtime.ENDUZ is not null
		
		insert into #RESULTCALAMVIEC
		select * from #CA_SETSHIFT_RESULT

		insert into #RESULTCALAMVIEC
		select * from #CA_MACDINH_RESULT

		insert into #RESULTCALAMVIEC
		select * from #CA_MACDINH_RESULT

		insert into #RESULTCALAMVIEC
		select * from #CA_OVERTIME

		set @Ngay = DATEADD(day,1, @Ngay)
	end

	BEGIN TRY drop table #CA_OVERTIME END TRY BEGIN CATCH END CATCH
	BEGIN TRY drop table #CA_SETSHIFT_RESULT END TRY BEGIN CATCH END CATCH
	BEGIN TRY drop table #CA_MACDINH_RESULT END TRY BEGIN CATCH END CATCH

	-- Break Ca
	insert into #CA_Break
	select * from #RESULTCALAMVIEC rclv 
	where rclv.startTimeBreak is null or rclv.endTimeBreak is null or rclv.startTimeBreak = '' or rclv.endTimeBreak = ''
	or ((rclv.startTimeBreak < rclv.endTimeBreak	
		and	 datediff(SECOND,rclv.startTimeBreak, rclv.endTimeBreak) < 7200) 
		or (rclv.startTimeBreak > rclv.endTimeBreak 
		and (datediff(SECOND,rclv.startTimeBreak,'23:59:59') + datediff(SECOND,0,rclv.endTimeBreak) + 1 < 7200)))

	insert into #CA_Break_TMP
	select *
	from #RESULTCALAMVIEC rclv 
	where rclv.startTimeBreak is not null and rclv.endTimeBreak is not null and rclv.startTimeBreak != '' and rclv.endTimeBreak != ''
	and ((rclv.startTimeBreak < rclv.endTimeBreak	and	 datediff(SECOND,rclv.startTimeBreak,rclv.endTimeBreak) >= 7200) 
		or (rclv.startTimeBreak > rclv.endTimeBreak and (datediff(SECOND,rclv.startTimeBreak,'23:59:59') + datediff(SECOND,0,rclv.endTimeBreak) + 1 >= 7200)))

	insert into #CA_Break
	select PERNR, ngay, startTime, startTimeBreak, '', '', shiftType
	from #CA_Break_TMP

	insert into #CA_Break(PERNR, ngay ,startTime, endTime, 
	startTimeBreak, endTimeBreak, shiftType)
	select PERNR, 
	case when startTime > endTime and startTime > endTimeBreak then dateadd(day,1,ngay) else ngay end as ngay
	, endTimeBreak, endTime, '', '', shiftType
	from #CA_Break_TMP

	-- Nghiep Vu MERGE Ca
	-- chi tra lai truong du lieu duy nhat
	insert into #CA_DuyNhat_Merge(PERNR, ngay,startTime, endTime, startTimeBreak, endTimeBreak, shiftType,duynhat)
	select PERNR, ngay,startTime, endTime, startTimeBreak, endTimeBreak, shiftType,
	Row_number() over (partition by ca.PERNR,ngay,startTime,endTime,startTimeBreak, endTimeBreak order by ngay, startTime) as duynhat
	from #CA_Break ca

	-- tinh toan dua tren bang du lieu tam
	insert into #CA_TMP_Merge(ID,PERNR, ngay, shiftType,StartTimeStamp,EndTimeStamp,STT)
	select Row_number() over (order by PERNR, ngay,startTime, endTime, startTimeBreak, endTimeBreak) as ID,
	PERNR, ngay,shiftType,
	dbo.UNIX_TIMESTAMP(ngay + CAST(startTime AS DATETIME)) as StartTimeStamp,
	case when startTime > endTime then dbo.UNIX_TIMESTAMP(ngay + CAST(endTime AS DATETIME)) + 86400
	else dbo.UNIX_TIMESTAMP(ngay + CAST(endTime AS DATETIME)) end  as EndTimeStamp,
	Row_number() over (partition by ca.PERNR order by ngay, startTime, endTime, startTimeBreak, endTimeBreak) as STT
	from #CA_DuyNhat_Merge ca where duynhat = 1

	insert into #CA_Can_Merge(ID,PERNR, ngay, shiftType,StartTimeStamp,EndTimeStamp,STT)
	select b.ID,b.PERNR, b.ngay, b.shiftType,b.StartTimeStamp,b.EndTimeStamp,Row_number() over (order by b.PERNR, b.ngay, b.StartTimeStamp, b.EndTimeStamp) as STT
	from #CA_TMP_Merge a join #CA_TMP_Merge b on a.STT - b.STT = 1 and a.PERNR = b.PERNR and a.EndTimeStamp != 0 and b.EndTimeStamp !=0
	where a.StartTimeStamp - b.EndTimeStamp < 7200

	--------------------------- Xac dinh ca dau tien cua merge ca --------------------

	insert into #CA_Can_Merge(ID,PERNR, ngay, shiftType,StartTimeStamp,EndTimeStamp,STT) values(0,'0000000c','19900101','s',0,0,0)

	insert into #CA_Can_MergeDau(PERNR, ngay, shiftType, StartTimeStamp,EndTimeStamp,STT)
	select a.PERNR, a.ngay, a.shiftType,a.StartTimeStamp,a.EndTimeStamp,Row_number() over (order by a.PERNR, a.ngay, a.StartTimeStamp, a.EndTimeStamp) as STT
	from #CA_Can_Merge a left join #CA_Can_Merge b on a.STT - b.STT = 1
	where a.StartTimeStamp - b.EndTimeStamp >= 7200 or a.PERNR != b.PERNR

	delete #CA_Can_Merge where ID = 0 and STT = 0

	insert into #CA_Can_MergeID1 select ca.ID from #CA_Can_Merge ca
	insert into #CA_Can_MergeID1 select ca.ID + 1 as ID from #CA_Can_Merge ca
	insert into #CA_Can_MergeID select distinct ca.ID from #CA_Can_MergeID1 ca

	insert into #CA_Can_MergeCuoiID(ID)
	select caID.ID from #CA_Can_MergeID caID 
	left join #CA_Can_Merge ca on caID.ID = ca.ID 
	where ca.ID is null
	
	----- Insert ca can merge cuoi
	insert into #CA_Can_MergeCuoi(PERNR, ngay, shiftType, StartTimeStamp, EndTimeStamp, STT)
	select ca.PERNR, ca.ngay, ca.shiftType, ca.StartTimeStamp, EndTimeStamp,
	Row_number() over (order by PERNR, ngay, StartTimeStamp,EndTimeStamp) as STT
	 from #CA_TMP_Merge ca join #CA_Can_MergeCuoiID caID on ca.ID = caID.ID

	insert into #CA_Merge(PERNR, ngay, shiftType,StartTimeStamp,EndTimeStamp)
	select canerge.PERNR, canerge.ngay, canerge.shiftType, canerge.StartTimeStamp,canerge.EndTimeStamp
	from #CA_TMP_Merge canerge left join #CA_Can_MergeID ca on canerge.ID = ca.ID where ca.ID is null

	insert into #CA_Merge(PERNR, ngay, shiftType,StartTimeStamp,EndTimeStamp)
	select a.PERNR, a.ngay, a.shiftType, a.StartTimeStamp,b.EndTimeStamp
	from #CA_Can_MergeDau a join #CA_Can_MergeCuoi b on a.STT= b.STT  and a.PERNR = b.PERNR

	-- tra lai cho service voi goi han LastOutPlanned va NexInPlanned
	insert into #Result select Row_number() over (order by PERNR, ngay, StartTimeStamp,EndTimeStamp) as ID
	,PERNR, ngay, shiftType, StartTimeStamp, EndTimeStamp 
	from #CA_Merge ca

	------------- Xac dinh NextInPlanned và LastOutPlanned
	insert into #Result2(ID,PERNR, ngay, shiftType, StartTimeStamp,EndTimeStamp,LastOutPlanned)
	select ca1.ID,ca1.PERNR, ca1.ngay,ca1.shiftType,ca1.StartTimeStamp,ca1.EndTimeStamp,
	 case when ca2.ID is null then @startDateTimeStamp else ca2.EndTimeStamp end as LastOutPlanned
	from #Result ca1
	left join #Result ca2 on ca1.PERNR = ca2.PERNR and ca1.ID - ca2.ID = 1
	--left join #Result ca3 on ca1.PERNR = ca3.PERNR and ca3.ID - ca1.ID = 1

	insert into #Result3(ID,PERNR, ngay, shiftType, StartTimeStamp,EndTimeStamp,LastOutPlanned,NextInPlanned)
	select ca1.ID,ca1.PERNR, ca1.ngay, ca1.shiftType,ca1.StartTimeStamp,ca1.EndTimeStamp,ca1.LastOutPlanned,
	 case when ca3.ID is null then @endDateTimeStamp else ca3.StartTimeStamp end as NextInPlanned
	 --case when ca2.ID is null and ca1.ngay = @EndDate  then dbo.UNIX_TIMESTAMP(ca1.ngay + cast('23:59:59' as datetime)) when ca2.ID is null and ca1.ngay != @EndDate then @endDateTimeStamp else dbo.UNIX_TIMESTAMP(ca2.ngay + CAST(ca2.startTime AS DATETIME)) end as NextInPlanned
	from #Result2 ca1
	--left join #Result ca2 on ca1.PERNR = ca2.PERNR and ca1.ID - ca2.ID = 1
	left join #Result2 ca3 on ca1.PERNR = ca3.PERNR and ca3.ID - ca1.ID = 1

	----------------------- Xac dinh du lieu la UpdateManually -----------------------------------
	insert into #Result4(ID,PERNR, ngay, shiftType, StartTimeStamp,EndTimeStamp,LastOutPlanned,NextInPlanned,ManuallyUpdate)
	select ca.ID,ca.PERNR, ca.ngay, ca.shiftType, ca.StartTimeStamp,
	ca.EndTimeStamp, ca.LastOutPlanned, ca.NextInPlanned, case when mu.PERNR is null then cast(0 as bit) else cast(1 as bit) end as ManuallyUpdate 
	from #Result3 ca left join #ManuallyUpdate mu 
	on ca.PERNR = mu.PERNR and ca.ngay = mu.Ngay
	where ca.ngay > @StartDate and ca.ngay < @EndDate

	--select * from #Result4
	--------------------- Tim Kiem du lieu phu hop insert vao bang ket qua dua tren du lieu inout
	insert into #KetQuaInOUT(ID,PERNR, TargetDate,Ngay,ThoiGian,unixTime,SATZA2,SATZA,IsOvernight ,TimeStampPlanSortOrder,RowID)
	select ca.ID, ca.PERNR, ca.ngay, data.[ERDAT],data.ERTIM,
	data.[TimeStamp] as unixTime
	,'P10',data.SATZA, dbo.IsOverNight(ca.StartTimeStamp,ca.EndTimeStamp),ca.StartTimeStamp,
	row_number() over(partition by ca.Pernr, ca.ngay,ca.StartTimeStamp order by data.[TimeStamp]) as RowID
	from #Result4 ca left join #DataInOut data 
	on cast(data.PERNR as int) = cast(ca.PERNR as int) and data.[TimeStamp] between (ca.LastOutPlanned + ca.StartTimeStamp) /2 and ca.EndTimeStamp 
	and data.SATZA = 'P10' and ca.ManuallyUpdate != 1
	and data.[TimeStamp] != 0

	insert into #KetQuaInOUT(ID, PERNR, TargetDate, Ngay, ThoiGian, unixTime, SATZA2, SATZA ,IsOvernight ,TimeStampPlanSortOrder , RowID)
	select ca.ID, ca.PERNR, ca.ngay, data.[ERDAT],data.ERTIM, data.[TimeStamp] as unixTime
	,'P20',data.SATZA, dbo.IsOverNight(ca.StartTimeStamp,ca.EndTimeStamp),ca.EndTimeStamp,
	row_number() over(partition by ca.Pernr, ca.ngay,ca.StartTimeStamp order by data.[TimeStamp] desc) as RowID
	from #Result4 ca left join #DataInOut data 
	on cast(data.PERNR as int) = cast(ca.PERNR as int) and data.[TimeStamp] between ca.StartTimeStamp and (ca.NextInPlanned + ca.EndTimeStamp)/2
	and data.SATZA = 'P20' and ca.ManuallyUpdate != 1
	and data.[TimeStamp] != 0

	insert into [dbo].[HRM_PORTAL_TimeIn_Out_test](
		[PERNR],
		[ERDAT],
		[ERTIM],
		[SATZA],
		[TERID], 
		[LDATE],
		[LTIME],
		[ULDATE],
		[ULTIME],
		[IP],
		LastOut,
		[TimeStamp],
		[TargetDate],
		[ModifiedDate],
		[IsOvernight],
		[TimeStampPlanSortOrder]
	)
	select	kq.[PERNR],
			case when kq.Ngay is null or kq.Ngay = '' then '19700101' else kq.Ngay end,
			case when kq.ThoiGian is null or kq.ThoiGian = '' then '070000' else kq.ThoiGian  end,
			kq.[SATZA],
			'',
			'',
			'',
			'',
			'',
			'IP OF AUTO JOB',
			case when kq.unixTime is null or kq.unixTime = '' then 0 else kq.unixTime end,
			case when kq.unixTime is null or kq.unixTime = '' then 0 else kq.unixTime end,
			convert(varchar, kq.[TargetDate], 112),
			dbo.UNIX_TIMESTAMP(GetDate()),
			kq.IsOvernight,
			kq.TimeStampPlanSortOrder
	from #KetQuaInOUT kq
	where kq.RowID = 1
--end
--declare @time time =  '23:59:59'
--declare @date datetime =  '20190909'
--declare @date2 datetime =  '2019-09-10 00:00:00.000'
--select dbo.UNIX_TIMESTAMP(@date2)
--select dbo.UNIX_TIMESTAMP(@date + cast('23:59:59' as datetime))
--1568073600

--truncate table [dbo].[HRM_PORTAL_TimeIn_Out]
--select * from [dbo].[HRM_PORTAL_TimeIn_Out]

-- truncate table [dbo].[HRM_PORTAL_TimeIn_Out_test]
-- select * from [dbo].[HRM_PORTAL_TimeIn_Out_test]