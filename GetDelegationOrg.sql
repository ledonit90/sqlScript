USE [HRM_Portal_02]
GO
/****** Object:  StoredProcedure [dbo].[vsii_GetOrgsWithDelegation]    Script Date: 6/3/2019 10:38:28 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

--/****** Object:  StoredProcedure [dbo].[vsii_GetDelegationOrg]    Script Date: 5/26/2019 3:47:16 PM ******/
--SET ANSI_NULLS ON
--GO
--SET QUOTED_IDENTIFIER ON
--GO
--/****** Script for SelectTopNRows command from SSMS  ******/
ALTER procedure [dbo].[vsii_GetOrgsWithDelegation]
@pernr char(8),
@actionID int,
@StartDate datetime,
@EndDate datetime,
@isAdmin bit
as
begin
	--declare @pernr char(8) = '00944429'
	--declare @actionID int = 126
	--declare @StartDate datetime = '20190530'
	--declare @EndDate datetime = '20190530'
	--declare @isAdmin bit = 1
	if(@isAdmin = 1)
	begin
	 -- lay list org level 1
	 declare @orlv1 char(8) = (select top 1 os.ORGLV1 from HRM_PORTAL_OrganizationStructure os)
	 -- lay toan bo org
		select (case when isnumeric(os.objid) = 1 then convert(int,os.objid) else 0 end) as Id,
				convert(int,os.LEVEL) as level,
				os.STEXT as Name,
				(case when os.LEVEL = '1' then 0
				when os.LEVEL = '2'  then convert(int,os.ORGLV1)
				when os.LEVEL = '3'  then convert(int,os.ORGLV2)
				when os.LEVEL = '4'  then convert(int,os.ORGLV3)
				when os.LEVEL = '5'  then convert(int,os.ORGLV4)
				when os.LEVEL = '6'  then convert(int,os.ORGLV5)
				when os.LEVEL = '7'  then convert(int,os.ORGLV6)
				when os.LEVEL = '8'  then convert(int,os.ORGLV7)
				when os.LEVEL = '9'  then convert(int,os.ORGLV8)
				when os.LEVEL = '10' then convert(int,os.ORGLV9)
				when os.LEVEL = '11' then convert(int,os.ORGLV10)
				else 0 end) as ParentId
		from [dbo].[HRM_PORTAL_OrganizationStructure] os
		join [dbo].[HRM_PORTAL_OrgUnit] ou on ou.OBJID = os.OBJID
		where((@StartDate between ou.BEGDA and ou.ENDDA) 
		or (@EndDate between ou.BEGDA and ou.ENDDA))
	end
	else
	begin
		declare @UQLocation nvarchar(max)
		declare @UQAction nvarchar(max)
		declare @OrgID char(8)
		declare @OrgLevel int

		declare UyQuyen cursor
		forward_only
		static
		Read_only
		for select vud.LocationDelegation,vud.ActionDelegation from [dbo].[VSII_User_Delegate] vud 
		where vud.DelegatedId = @pernr 
		and ((@StartDate between vud.StartDate and vud.EndDate)
		or (@EndDate between vud.StartDate and vud.EndDate)) 
		and vud.isApply = 1

		CREATE TABLE #TempOrgID(
			OBJID char(8)
		)

		CREATE TABLE #ListRootOrgID(
			OBJID char(8),
			Level int
		)

		CREATE TABLE #RESULT(
			Id int NOT NULL,
			level int NULL,
			Name nvarchar(40) NULL,
			ParentId int NULL
		)

		-- lay danh sach phong ban theo phan quyen
		insert into #TempOrgID select os.OBJID from [dbo].[VSII_User_Location] vul
		join [dbo].[HRM_PORTAL_OrganizationStructure] os on vul.LocationID = os.OBJID
		join [dbo].[HRM_PORTAL_OrgUnit] ou on ou.OBJID = os.OBJID
		where vul.PERNR = @pernr and ((@StartDate between ou.BEGDA and ou.ENDDA) or (@EndDate between ou.BEGDA and ou.ENDDA))

	
		OPEN UyQuyen
		FETCH NEXT FROM UyQuyen
			  INTO @UQLocation, @UQAction 
		WHILE @@FETCH_STATUS = 0
		BEGIN
			if(@actionID in (select (case when isnumeric(uqA.items) = 1 then convert(int,uqA.items) else -1 end) as ActionID from dbo.Split(@UQAction,',') as uqA ))
			begin
				insert into #TempOrgID select rtrim(ltrim(items)) from dbo.Split(@UQLocation,',')
			end

			FETCH NEXT FROM UyQuyen
				  INTO @UQLocation, @UQAction
		END
		CLOSE UyQuyen
		DEALLOCATE UyQuyen

		insert into #ListRootOrgID
		select os.OBJID,os.level from [dbo].[HRM_PORTAL_OrganizationStructure] os
		where 1 = (case when os.level = 1 then 1
		when os.level = 2 and os.ORGLV1 not in (select * from #TempOrgID) then 1 
		when os.level = 3 and os.ORGLV2 not in (select * from #TempOrgID) then 1 
		when os.level = 4 and os.ORGLV3 not in (select * from #TempOrgID) then 1 
		when os.level = 5 and os.ORGLV4 not in (select * from #TempOrgID) then 1 
		when os.level = 6 and os.ORGLV5 not in (select * from #TempOrgID) then 1 
		when os.level = 7 and os.ORGLV6 not in (select * from #TempOrgID) then 1 
		when os.level = 8 and os.ORGLV7 not in (select * from #TempOrgID) then 1 
		when os.level = 9 and os.ORGLV8 not in (select * from #TempOrgID) then 1 
		when os.level = 10 and os.ORGLV9 not in (select * from #TempOrgID) then 1 
		when os.level = 11 and os.ORGLV10 not in (select * from #TempOrgID) then 1 
		else 0 end) and os.OBJID in (select * from #TempOrgID)

		-- lay tat ca phong ban len
		declare CursorRootOrgID cursor 
		forward_only
		static
		Read_only
		for select * from #ListRootOrgID

		OPEN CursorRootOrgID
		FETCH NEXT FROM CursorRootOrgID
			  INTO @OrgID, @OrgLevel 
		WHILE @@FETCH_STATUS = 0
		BEGIN
			if(@OrgID <> '')
			begin
				insert into #RESULT
				select 
				(case when isnumeric(os.objid) = 1 then convert(int,os.objid) else 0 end) as Id,
				convert(int,os.LEVEL) as level,
				os.STEXT as Name,
				(case when os.LEVEL = '1' then 0
				when os.LEVEL = '2' AND  os.ORGLV2 <> @OrgID then convert(int,os.ORGLV1)
				when os.LEVEL = '3' AND  os.ORGLV3 <> @OrgID then convert(int,os.ORGLV2)
				when os.LEVEL = '4' AND  os.ORGLV4 <> @OrgID then convert(int,os.ORGLV3)
				when os.LEVEL = '5' AND  os.ORGLV5 <> @OrgID then convert(int,os.ORGLV4)
				when os.LEVEL = '6' AND  os.ORGLV6 <> @OrgID then convert(int,os.ORGLV5)
				when os.LEVEL = '7' AND  os.ORGLV7 <> @OrgID then convert(int,os.ORGLV6)
				when os.LEVEL = '8' AND  os.ORGLV8 <> @OrgID then convert(int,os.ORGLV7)
				when os.LEVEL = '9' AND  os.ORGLV9 <> @OrgID then convert(int,os.ORGLV8)
				when os.LEVEL = '10' AND  os.ORGLV10 <> @OrgID then convert(int,os.ORGLV9)
				when os.LEVEL = '11' AND  os.ORGLV11 <> @OrgID then convert(int,os.ORGLV10)
				else 0 end) as ParentId
				 from [dbo].[HRM_PORTAL_OrganizationStructure] os
				join [dbo].[HRM_PORTAL_OrgUnit] ou on ou.OBJID = os.OBJID
				where  1 = (case when @OrgLevel = 1 and os.ORGLV1 = @OrgID then 1
					when @OrgLevel = 2 and os.ORGLV2 = @OrgID then 1 
					when @OrgLevel = 3 and os.ORGLV3 = @OrgID then 1 
					when @OrgLevel = 4 and os.ORGLV4 = @OrgID then 1 
					when @OrgLevel = 5 and os.ORGLV5 = @OrgID then 1 
					when @OrgLevel = 6 and os.ORGLV6 = @OrgID then 1 
					when @OrgLevel = 7 and os.ORGLV7 = @OrgID then 1 
					when @OrgLevel = 8 and os.ORGLV8 = @OrgID then 1 
					when @OrgLevel= 9 and os.ORGLV9 = @OrgID then 1 
					when @OrgLevel = 10 and os.ORGLV10 = @OrgID then 1 
					when @OrgLevel = 11 and os.ORGLV11 = @OrgID then 1 
					else 0 end) 
					AND ((@StartDate between ou.BEGDA and ou.ENDDA) 
					or (@EndDate between ou.BEGDA and ou.ENDDA))
			end
			FETCH NEXT FROM CursorRootOrgID
				  INTO @OrgID, @OrgLevel
		END
		CLOSE CursorRootOrgID
		DEALLOCATE CursorRootOrgID

		select * from #RESULT order by level
	end
end