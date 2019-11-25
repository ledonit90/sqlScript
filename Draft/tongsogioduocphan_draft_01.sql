 

--CREATE TYPE DanhSachType AS TABLE
--(
--   PERNR char(8)
--)

--CREATE TYPE PhongBanType AS TABLE
--(
--   ORGEH char(8)
--)
 
 -- 
 --CREATE PROCEDURE TongThoiGianDVPB
	
 -- @phongban as PhongBanType READONLY,
 -- @danhsach as DanhSachType READONLY,
 -- @StartDate datetime,
 -- @EndDate datetime

 -- AS

 declare @StartDate datetime
 set @StartDate = '20181101'
 declare @EndDate datetime
 set @EndDate  = '20190531'
 

 
 create table #danhsach (PERNR char(8))
 insert into #danhsach values ('03001107');
 insert into #danhsach values ('00944496');
 insert into #danhsach values ('00947597');
 insert into #danhsach values ('03000500');
 insert into #danhsach values ('00300817');
 insert into #danhsach values ('00308161');
 insert into #danhsach values ('00311050');
 insert into #danhsach values ('00312212');
 insert into #danhsach values ('00947644');
 

--select  distinct * from #danhsach

create table #tmpDS (PERNR char(8))

insert into #tmpDS
select  distinct * from #danhsach

create table #RESULT (ORGEH char(8), PERNR char(8))
CREATE TABLE #TMP(rownumber int, PERNR char(8))

INSERT INTO #TMP (rownumber, PERNR)
SELECT ROW_NUMBER() OVER (ORDER BY PERNR), * from #tmpDS

--select distinct * from #TMP

declare @cnt int = 1
declare @units int = (select count(*) from #TMP)
--select count(*) from #TMP

--
-- xóa bảng tạm #Res
begin try drop table #Res end try
begin catch end catch


-- create a temp table #Res
create table #Res (PERNR char (8), ORGEH char(8), currDate datetime, TongGioDuocPhan int)
---

-- duyệt từng nhân viên XXX
while @cnt <= @units
begin
	-- lấy nhân viên tương ứng với @cnt hiện tại
	--select * from #TMP where rownumber = @cnt
	declare @curr_nhanvien char(8) = (select PERNR from #TMP where rownumber = @cnt)

	--select @curr_nhanvien
-- duyệt từng ngày trong khoảng thời gian @StartDate tới @EndDate
	declare @currDate Datetime
    set @currDate = @StartDate

	while @currDate <= @EndDate
	begin
		declare @sub nvarchar(2)
		if (DAY(@currDate) <= 9)
		begin
			set @sub = concat('0', DAY(@currDate))
		end
		else
		begin
			set @sub = DAY(@currDate)
		end

		DECLARE @Ngay char(5) 
		SET @Ngay = CONCAT('TPR', @sub)

		--- ########### ---------
		-- xóa bảng tạm #TMP_PhongBan
		begin try drop table #TMP_PhongBan end try
		begin catch end catch

	-- Lấy danh sách phòng ban tương ứng với mỗi nhân viên tương ứng với @currDate
		create table #TMP_PhongBan (ID int IDENTITY(1,1) PRIMARY KEY, ORGEH char(8))

		-- insert danh sách phòng ban tương ứng với thời điểm currDate vào bảng tạm #TMP_PhongBan
		insert into #TMP_PhongBan
		select ORGEH from HRM_PORTAL_OrganizationalAssignment where PERNR = @curr_nhanvien AND @currDate  BETWEEN BEGDA AND ENDDA
		order by AEDTM desc


		declare @rows int = (select count(*) from #TMP_PhongBan)
		declare @idx int  = 1

	-- duyệt từng phòng ban tương ứng với mỗi nhân viên XXX
		while @idx <= @rows
			begin

			-- lấy phòng ban hiện tại
			declare @curr_phongban char(8) = (select ORGEH from  #TMP_PhongBan where ID = @idx)


			-- khai báo biến @TotalPlannedTime
			DECLARE @TotalPlannedTime int
			SET @TotalPlannedTime = 0

			-- khai báo biến @TotalPlannedTime
			DECLARE @TotalOfManualShift int
			SET @TotalOfManualShift = 0

			-- tính thời gian từ bảng setshift
			SET @TotalOfManualShift =
  (SELECT sum(workingTimeInMinutes) AS total
   FROM
     (SELECT PERNR,
             BEGDA,
             ENDDA,
             STARTTIME,
             ENDTIME,
             BREAKSTART,
             BREAKEND,
             total - breakDiff AS workingTimeInMinutes
      FROM
        (SELECT PERNR,
                BEGDA,
                ENDDA,
                STARTTIME,
                ENDTIME,
                BREAKSTART,
                BREAKEND,
                DATEDIFF (MINUTE, STARTTIME, ENDTIME) AS diff,
                CASE
                    WHEN STARTTIME < ENDTIME THEN DATEDIFF (MINUTE, STARTTIME, ENDTIME)
                    ELSE (DATEDIFF (MINUTE, STARTTIME, CONVERT(Datetime, '23:59:59', 24)) + 1) + DATEDIFF (MINUTE, CONVERT(Datetime, '00:00:00', 24), ENDTIME)
                END AS total,
                dateadd(HOUR, 5, ENDTIME) AS time_added,
                (DATEDIFF (MINUTE, STARTTIME, CONVERT(Datetime, '23:59:59', 24)) + 1) AS diff1,
                DATEDIFF (MINUTE, CONVERT(Datetime, '00:00:00', 24), ENDTIME) AS diff2,
                CASE
					WHEN BREAKSTART is null THEN 0
					WHEN BREAKEND is null THEN 0
                    WHEN BREAKSTART < BREAKEND THEN DATEDIFF (MINUTE, BREAKSTART, BREAKEND)
                    ELSE (DATEDIFF (MINUTE, BREAKSTART, CONVERT(Datetime, '23:59:59', 24)) + 1) + DATEDIFF (MINUTE, CONVERT(Datetime, '00:00:00', 24), BREAKEND)
				    
                END AS breakDiff
         FROM [dbo].[HRM_PORTAL_SetShift]
         WHERE PERNR = @curr_nhanvien
           AND @currDate BETWEEN BEGDA AND ENDDA ) AS t) AS T2
		   )
			
			-- so sánh logic 
			if (@TotalOfManualShift > 0)
			begin
				set @TotalPlannedTime = @TotalPlannedTime + @TotalOfManualShift
			end
			else
			begin
				 set @TotalPlannedTime = @TotalPlannedTime + (SELECT top 1 SOLLZ * 60
                   FROM HRM_PORTAL_DailyWorkSchedule
                   WHERE TPROG =
                       (SELECT CASE
                                   WHEN TPR01 = @Ngay THEN TPR01
                                   WHEN TPR02 = @Ngay THEN TPR02
                                   WHEN TPR03 = @Ngay THEN TPR03
                                   WHEN TPR04 = @Ngay THEN TPR04
                                   WHEN TPR05 = @Ngay THEN TPR05
                                   WHEN TPR06 = @Ngay THEN TPR06
                                   WHEN TPR07 = @Ngay THEN TPR07
                                   WHEN TPR08 = @Ngay THEN TPR08
                                   WHEN TPR09 = @Ngay THEN TPR09
                                   WHEN TPR10 = @Ngay THEN TPR10
                                   WHEN TPR11 = @Ngay THEN TPR11
                                   WHEN TPR12 = @Ngay THEN TPR12
                                   WHEN TPR13 = @Ngay THEN TPR13
                                   WHEN TPR14 = @Ngay THEN TPR14
                                   WHEN TPR15 = @Ngay THEN TPR15
                                   WHEN TPR16 = @Ngay THEN TPR16
                                   WHEN TPR17 = @Ngay THEN TPR17
                                   WHEN TPR18 = @Ngay THEN TPR18
                                   WHEN TPR19 = @Ngay THEN TPR19
                                   WHEN TPR20 = @Ngay THEN TPR20
                                   WHEN TPR21 = @Ngay THEN TPR21
                                   WHEN TPR22 = @Ngay THEN TPR22
                                   WHEN TPR23 = @Ngay THEN TPR23
                                   WHEN TPR24 = @Ngay THEN TPR24
                                   WHEN TPR25 = @Ngay THEN TPR25
                                   WHEN TPR26 = @Ngay THEN TPR26
                                   WHEN TPR27 = @Ngay THEN TPR27
                                   WHEN TPR28 = @Ngay THEN TPR28
                                   WHEN TPR29 = @Ngay THEN TPR29
                                   WHEN TPR30 = @Ngay THEN TPR30
                                   ELSE TPR31
                               END AS TPR
                        FROM HRM_PORTAL_MonthlyWorkSchedule
                        WHERE SCHKZ =
                            (SELECT top 1 SCHKZ
                             FROM HRM_PORTAL_WorkScheduleRule
                             WHERE PERNR = @curr_nhanvien
                               AND @currDate BETWEEN BEGDA AND ENDDA  AND KJAHR = YEAR(@currDate) AND MONAT = MONTH(@currDate) )))
			end

			--select @TotalPlannedTime
			set @TotalPlannedTime = (case when @TotalPlannedTime is not null then @TotalPlannedTime else 0 end)
			-- insert into create table #Res (PERNR char (8), ORGEH char(8), currDate Datetime, TongGioDuocPhan int)
			insert into #Res
			values(@curr_nhanvien, @curr_phongban, @currDate, @TotalPlannedTime)

			set @idx = @idx + 1
		end

		--- ###########----------
	--select @currDate
	SET @currDate = DATEADD(DAY, 1, @currDate)
	end


set @cnt = @cnt + 1
end

--select * from #Res

-- Join để lấy thông tin chức danh, tên phòng ban tương ứng với từng thời điểm

select * from (
select * from (
SELECT * , 

(SELECT TOP 1 CONCAT(personal.VORNA, ' ', personal.NACHN) FROM [HRM_PORTAL_Personal] personal where personal.PERNR = #Res.PERNR ORDER BY AEDTM DESC)
as fullname

 FROM #Res ) as t

 LEFT JOIN (select PERNR as PERNR_oa, PLANS, ORGEH as ORGEH_oa, BEGDA as BEGDA_oa, ENDDA as ENDDA_oa  from HRM_PORTAL_OrganizationalAssignment) oa
ON (oa.PERNR_oa = t.PERNR and t.currDate between oa.BEGDA_oa and oa.ENDDA_oa )

 LEFT JOIN (select OBJID as OBJID1, STEXT as s1 from HRM_PORTAL_OrganizationStructure) org
 ON org.OBJID1 = t.ORGEH

 LEFT JOIN (select STEXT as s2 , OBJID as OBJID2  from HRM_PORTAL_OrgUnit) ou
 ON ou.OBJID2 = org.OBJID1

 ) res

 LEFT JOIN (select STEXT as s3, OBJID as OBJID3 from HRM_PORTAL_Position) position
 ON position.OBJID3 = res.PLANS

drop table #danhsach
drop table #TMP
drop table #RESULT
drop table #tmpDS
drop table #Res
