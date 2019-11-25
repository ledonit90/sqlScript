ALTER PROCEDURE vsii_proc_GetNguongOT
@OrgLst as [dbo].[LocationIDList] READONLY,
@StatusLs as [dbo].[StatusPhanBo] READONLY,
@StartDate datetime,
@EndDate datetime,
@pageSize int,
@page int
AS
 if((select count(*) from @StatusLs) = 0)
 begin
	if(@StartDate <> '' and @EndDate <> '')
	begin
		select *,(select count(*) from VSII_NguongOT where ORGID in (select * from @OrgLst) and  EDSTA <= @EndDate and EDEND >= @StartDate) as total from VSII_NguongOT where ORGID in (select * from @OrgLst) and  EDSTA <= @EndDate and EDEND >= @StartDate order by STATUS, EDSTA, ORGID, UpdatedDate offset @pageSize * (@page - 1) rows fetch next @pageSize rows only
	end
	else if(@StartDate <> '')
	begin
		select *,(select count(*) from VSII_NguongOT where ORGID in (select * from @OrgLst) and EDEND >= @StartDate) as total from VSII_NguongOT where ORGID in (select * from @OrgLst) and EDEND >= @StartDate order by STATUS, EDSTA, ORGID, UpdatedDate offset @pageSize * (@page - 1) rows fetch next @pageSize rows only
	end
	else if(@EndDate <> '')
	begin
		select *,(select count(*) from VSII_NguongOT where ORGID in (select * from @OrgLst) and  EDSTA <= @EndDate) as total from VSII_NguongOT where ORGID in (select * from @OrgLst) and  EDSTA <= @EndDate order by STATUS, EDSTA, ORGID, UpdatedDate offset @pageSize * (@page - 1) rows fetch next @pageSize rows only
	end
 end
 else
 begin
 if(@StartDate <> '' and @EndDate <> '')
	begin
		select *,(select count(*) from VSII_NguongOT where ORGID in (select * from @OrgLst) and STATUS in (select * from @StatusLs) and  EDSTA <= @EndDate and EDEND >= @StartDate) as total from VSII_NguongOT where ORGID in (select * from @OrgLst) and STATUS in (select * from @StatusLs) and  EDSTA <= @EndDate and EDEND >= @StartDate order by STATUS, EDSTA, ORGID, UpdatedDate offset @pageSize * (@page - 1) rows fetch next @pageSize rows only
	end
	else if(@StartDate <> '')
	begin
		select *,(select count(*) from VSII_NguongOT where ORGID in (select * from @OrgLst) and EDEND >= @StartDate  and STATUS in (select * from @StatusLs)) as total from VSII_NguongOT where ORGID in (select * from @OrgLst) and STATUS in (select * from @StatusLs) and EDEND >= @StartDate order by STATUS, EDSTA, ORGID, UpdatedDate offset @pageSize * (@page - 1) rows fetch next @pageSize rows only
	end
	else if(@EndDate <> '')
	begin
		select *,(select count(*) from VSII_NguongOT where ORGID in (select * from @OrgLst) and STATUS in (select * from @StatusLs) and EDSTA <= @EndDate) as total from VSII_NguongOT where ORGID in (select * from @OrgLst) and STATUS in (select * from @StatusLs) and  EDSTA <= @EndDate order by STATUS, EDSTA, ORGID, UpdatedDate offset @pageSize * (@page - 1) rows fetch next @pageSize rows only
	end
 end