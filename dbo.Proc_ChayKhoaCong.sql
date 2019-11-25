CREATE PROCEDURE [dbo].[Proc_ChayKhoaCong]
as
-- Cong viec cua cai nay chi la tao ra cac ban ghi thoi.
-- lay orgID tap doan
	declare @currentDate datetime = getdate()
	declare @dayofMonth int = day(@currentDate)
	declare @dayofweek int = DATEPART(WEEKDAY, @currentDate)
	declare @ngaykhoacong datetime
	declare @weekDaykhoacong int
	declare @dayOfRun int
	declare @songaytru int
	declare @JKdayOfWeekTapDoan int
	declare @JKNumWeekUnlockTapDoan int
	declare @periodDayTapDoan int
	declare @periodDayEndTapDoan int 
	declare @OrgLv2 char(8)
	-- lay du lieu dayofweek theo ngay thang
	if(@dayofweek = 1)
	begin
		set @dayofweek = 7
	end
	else
	begin 
		set @dayofweek = @dayofweek - 1
	end

	declare @ORGTapDoan varchar(20) 
	sET @ORGTapDoan = (select top 1 ORGLV1  from HRM_PORTAL_OrganizationStructure where LEVEL like '%7%')
	declare lsOrglv2 cursor
	forward_only
	static
	Read_only
	for select OBJID from HRM_PORTAL_OrganizationStructure where rtrim(ltrim(LEVEL)) = '2'

	-- kiem tra khoa cong theo thang cua tap doan
	if((select count(*) from VSII_KeyJob where STATUS = 1 and Location = @ORGTapDoan and KeyJobType = 1) !=  0)
	begin
		set @periodDayTapDoan = (select top 1 PeriodDay from VSII_KeyJob where STATUS = 1 and Location = @ORGTapDoan and KeyJobType = 1)
		set @periodDayEndTapDoan = (select top 1 PeriodDayEnd from VSII_KeyJob where STATUS = 1 and Location = @ORGTapDoan and KeyJobType = 1)
		
		-- xac dinh ngay hien tai 
		-- xac dinh ngay chay khoa cong gan nhat
		set @ngaykhoacong = DATEADD(DAY, -1 * @periodDayEndTapDoan, @currentDate)
		set @dayOfRun = day(@ngaykhoacong);
		if(@dayOfRun = @periodDayTapDoan)
		begin
			Exec BlockPendingRequests @BlockOrgid = @ORGTapDoan, @DATE = @ngaykhoacong
			insert into VSII_KeyJob_History(idJK, jobKeytime, KeyJobType, NumWeekUnlock, daysOfWeek, PeriodDay, PeriodDayEnd, Location, EDSTA, EDEND, Note,BEGDATE,ENDDATE,STATUS,CreatedBy,CreatedDate,UpdatedBy,UpdatedDate, NgayKhoaCongHienTai) select id as idJK, jobKeytime, KeyJobType, NumWeekUnlock, daysOfWeek, PeriodDay, PeriodDayEnd, Location, EDSTA, EDEND, Note,BEGDATE,ENDDATE,STATUS,CreatedBy,CreatedDate,UpdatedBy,UpdatedDate, NgayKhoaCongHienTai = @ngaykhoacong from VSII_KeyJob where STATUS = 1 and Location = @ORGTapDoan
		end
	end
	-- kiem tra khoa cong theo tuan
	if((select count(*) from VSII_KeyJob where STATUS = 1 and Location = @ORGTapDoan and KeyJobType = 2) !=  0)
	begin
		set @JKdayOfWeekTapDoan = (select top 1 daysOfWeek from VSII_KeyJob where STATUS = 1 and Location = @ORGTapDoan and KeyJobType = 2)
		set @JKNumWeekUnlockTapDoan = (select top 1 NumWeekUnlock from VSII_KeyJob where STATUS = 1 and Location = @ORGTapDoan and KeyJobType = 2)

		if(@dayofweek = @JKdayOfWeekTapDoan)
		begin
			-- xac dinh ngay chay khoa cong la cach bao nhieu tuan, ngay chu nhat la bao nhieu ngay
			set @songaytru = -7 * @JKNumWeekUnlockTapDoan
			set @ngaykhoacong = DATEADD(DAY, @songaytru , @currentDate)
			set @weekDaykhoacong = datepart(WEEKDAY,@ngaykhoacong)

			if(@weekDaykhoacong = 1)
			begin
				set @weekDaykhoacong = 0
			end
			else
			begin 
				set @weekDaykhoacong = 8 - @weekDaykhoacong
			end

		    set @ngaykhoacong = DATEADD(DAY, @weekDaykhoacong , @ngaykhoacong)

			Exec BlockPendingRequests  @BlockOrgid = @ORGTapDoan, @DATE = @ngaykhoacong
			insert into VSII_KeyJob_History(idJK, jobKeytime, KeyJobType, NumWeekUnlock, daysOfWeek, PeriodDay, PeriodDayEnd, Location, EDSTA, EDEND, Note,BEGDATE,ENDDATE,STATUS,CreatedBy,CreatedDate,UpdatedBy,UpdatedDate, NgayKhoaCongHienTai) select id as idJK, jobKeytime, KeyJobType, NumWeekUnlock, daysOfWeek, PeriodDay, PeriodDayEnd, Location, EDSTA, EDEND, Note,BEGDATE,ENDDATE,STATUS,CreatedBy,CreatedDate,UpdatedBy,UpdatedDate, NgayKhoaCongHienTai = @ngaykhoacong from VSII_KeyJob where STATUS = 1 and Location = @ORGTapDoan
		end
	end


-- lay orgID cac P&L
	open lsOrglv2
	fetch next  from lsOrglv2 into @OrgLv2
	while @@FETCH_STATUS = 0
	begin
		-- kiem tra khoa cong theo thang cua tap doan
		if((select count(*) from VSII_KeyJob where STATUS = 1 and Location = @OrgLv2 and KeyJobType = 1) !=  0)
		begin
			set @periodDayTapDoan = (select top 1 daysOfWeek from VSII_KeyJob where STATUS = 1 and Location = @OrgLv2 and KeyJobType = 1)
			set @periodDayEndTapDoan = (select top 1 daysOfWeek from VSII_KeyJob where STATUS = 1 and Location = @OrgLv2 and KeyJobType = 1)
		
			-- xac dinh ngay hien tai 
			-- xac dinh ngay chay khoa cong gan nhat
			set @ngaykhoacong = DATEADD(DAY, -1 * @periodDayEndTapDoan, @currentDate)
			set @dayOfRun = day(@ngaykhoacong);
			if(@dayOfRun = @periodDayTapDoan)
			begin
				Exec BlockPendingRequests @BlockOrgid = @OrgLv2, @DATE = @ngaykhoacong
				insert into VSII_KeyJob_History(idJK, jobKeytime, KeyJobType, NumWeekUnlock, daysOfWeek, PeriodDay, PeriodDayEnd, Location, EDSTA, EDEND, Note,BEGDATE,ENDDATE,STATUS,CreatedBy,CreatedDate,UpdatedBy,UpdatedDate, NgayKhoaCongHienTai) select id as idJK, jobKeytime, KeyJobType, NumWeekUnlock, daysOfWeek, PeriodDay, PeriodDayEnd, Location, EDSTA, EDEND, Note,BEGDATE,ENDDATE,STATUS,CreatedBy,CreatedDate,UpdatedBy,UpdatedDate, NgayKhoaCongHienTai = @ngaykhoacong from VSII_KeyJob where STATUS = 1 and Location = @OrgLv2 and KeyJobType = 1 
			end
		end
		-- kiem tra khoa cong theo tuan
		if((select count(*) from VSII_KeyJob where STATUS = 1 and Location = @OrgLv2 and KeyJobType = 2) !=  0)
		begin
			set @JKdayOfWeekTapDoan = (select top 1 daysOfWeek from VSII_KeyJob where STATUS = 1 and Location = @OrgLv2 and KeyJobType = 2)
			set @JKNumWeekUnlockTapDoan = (select top 1 NumWeekUnlock from VSII_KeyJob where STATUS = 1 and Location = @OrgLv2 and KeyJobType = 2)

			if(@dayofweek = @JKdayOfWeekTapDoan)
			begin
				-- xac dinh ngay chay khoa cong la cach bao nhieu tuan, ngay chu nhat la bao nhieu ngay
				set @songaytru = -7 * @JKNumWeekUnlockTapDoan
				set @ngaykhoacong = DATEADD(DAY, @songaytru , @currentDate)
				set @weekDaykhoacong = datepart(WEEKDAY,@ngaykhoacong)

				if(@weekDaykhoacong = 1)
				begin
					set @weekDaykhoacong = 0
				end
				else
				begin 
					set @weekDaykhoacong = 8 - @weekDaykhoacong
				end
				set @ngaykhoacong = DATEADD(DAY, @weekDaykhoacong , @ngaykhoacong)
				Exec BlockPendingRequests @BlockOrgid = @OrgLv2, @DATE = @ngaykhoacong
				insert into VSII_KeyJob_History(idJK, jobKeytime, KeyJobType, NumWeekUnlock, daysOfWeek, PeriodDay, PeriodDayEnd, Location, EDSTA, EDEND, Note,BEGDATE,ENDDATE,STATUS,CreatedBy,CreatedDate,UpdatedBy,UpdatedDate, NgayKhoaCongHienTai) select id as idJK, jobKeytime, KeyJobType, NumWeekUnlock, daysOfWeek, PeriodDay, PeriodDayEnd, Location, EDSTA, EDEND, Note,BEGDATE,ENDDATE,STATUS,CreatedBy,CreatedDate,UpdatedBy,UpdatedDate, NgayKhoaCongHienTai = @ngaykhoacong from VSII_KeyJob where STATUS = 1 and Location = @OrgLv2 and KeyJobType = 2
			end
		end

		fetch next from lsOrglv2 into @OrgLv2
	end
	CLOSE lsOrglv2
	deallocate lsOrglv2