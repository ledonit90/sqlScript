USE [HRM_Portal_02]
GO
/****** Object:  StoredProcedure [dbo].[vsii_proc_GetAddFulllTime]    Script Date: 6/3/2019 12:03:14 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[vsii_proc_GetAddFulllTime]
@lsPernr as [dbo].[PernrTable] READONLY,
@StartDate datetime,
@EndDate datetime,
@pageSize int,
@page int
AS
 declare @totalRecord int

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
 