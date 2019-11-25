USE [HRM_Portal_20190502]
GO
/****** Object:  StoredProcedure [dbo].[vsii_proc_GetNguongOT]    Script Date: 5/24/2019 11:41:53 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create PROCEDURE [dbo].[getLocationTreeByUser]
@Pernr char(8),
@actionName nvarchar(50),
@ControllerName nvarchar(50),
@startDate datetime,
@endDate datetime
AS
 declare @totalRecord int
 if((select count(*) from @StatusLs) = 0)
 begin
	if(@StartDate <> '' and @EndDate <> '')
	begin
		set @totalRecord = (select count(*) from [dbo].[VSII_GanDuCong] where idnhanvien in (select * from @lsPernr) and  EDSTA <= @EndDate and EDEND >= @StartDate)
		select *, @totalRecord as total from [dbo].[VSII_GanDuCong] where idnhanvien in (select * from @lsPernr) and  EDSTA <= @EndDate and EDEND >= @StartDate order by STATUS, EDSTA, idnhanvien, UpdatedDate offset @pageSize * (@page - 1) rows fetch next @pageSize rows only
	end
	else if(@StartDate <> '')
	begin
		set @totalRecord =(select count(*) from [dbo].[VSII_GanDuCong] where idnhanvien in (select * from @lsPernr) and EDEND >= @StartDate)
		select *, @totalRecord as total from [dbo].[VSII_GanDuCong] where idnhanvien in (select * from @lsPernr) and EDEND >= @StartDate order by STATUS, EDSTA, idnhanvien, UpdatedDate offset @pageSize * (@page - 1) rows fetch next @pageSize rows only
	end
	else if(@EndDate <> '')
	begin
		set @totalRecord = (select count(*) from [dbo].[VSII_GanDuCong] where idnhanvien in (select * from @lsPernr) and  EDSTA <= @EndDate)
		select *,@totalRecord as total from [dbo].[VSII_GanDuCong] where idnhanvien in (select * from @lsPernr) and  EDSTA <= @EndDate order by STATUS, EDSTA, idnhanvien, UpdatedDate offset @pageSize * (@page - 1) rows fetch next @pageSize rows only
	end
	else
	begin
		set @totalRecord = (select count(*) from [dbo].[VSII_GanDuCong] where idnhanvien in (select * from @lsPernr))
		select *,@totalRecord as total from [dbo].[VSII_GanDuCong] where idnhanvien in (select * from @lsPernr) order by STATUS, EDSTA, idnhanvien, UpdatedDate offset @pageSize * (@page - 1) rows fetch next @pageSize rows only
	end
 end
 else
 begin
 if(@StartDate <> '' and @EndDate <> '')
	begin
		set @totalRecord = (select count(*) from [dbo].[VSII_GanDuCong] where idnhanvien in (select * from @lsPernr) and STATUS in (select * from @StatusLs) and  EDSTA <= @EndDate and EDEND >= @StartDate)
		select *,@totalRecord as total from [dbo].[VSII_GanDuCong] where idnhanvien in (select * from @lsPernr) and STATUS in (select * from @StatusLs) and  EDSTA <= @EndDate and EDEND >= @StartDate order by STATUS, EDSTA, idnhanvien, UpdatedDate offset @pageSize * (@page - 1) rows fetch next @pageSize rows only
	end
	else if(@StartDate <> '')
	begin
		set @totalRecord = (select count(*) from [dbo].[VSII_GanDuCong] where idnhanvien in (select * from @lsPernr) and EDEND >= @StartDate  and STATUS in (select * from @StatusLs))
		select *, @totalRecord as total from [dbo].[VSII_GanDuCong] where idnhanvien in (select * from @lsPernr) and STATUS in (select * from @StatusLs) and EDEND >= @StartDate order by STATUS, EDSTA, idnhanvien, UpdatedDate offset @pageSize * (@page - 1) rows fetch next @pageSize rows only
	end
	else if(@EndDate <> '')
	begin
		set @totalRecord = (select count(*) from [dbo].[VSII_GanDuCong] where idnhanvien in (select * from @lsPernr) and STATUS in (select * from @StatusLs) and EDSTA <= @EndDate)
		select *,@totalRecord as total from [dbo].[VSII_GanDuCong] where idnhanvien in (select * from @lsPernr) and STATUS in (select * from @StatusLs) and  EDSTA <= @EndDate order by STATUS, EDSTA, idnhanvien, UpdatedDate offset @pageSize * (@page - 1) rows fetch next @pageSize rows only
	end
	else
	begin
		set @totalRecord = (select count(*) from [dbo].[VSII_GanDuCong] where idnhanvien in (select * from @lsPernr) and STATUS in (select * from @StatusLs))
		select *,@totalRecord as total from [dbo].[VSII_GanDuCong] where idnhanvien in (select * from @lsPernr) and STATUS in (select * from @StatusLs) order by STATUS, EDSTA, idnhanvien, UpdatedDate offset @pageSize * (@page - 1) rows fetch next @pageSize rows only
	end
 end