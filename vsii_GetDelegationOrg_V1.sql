USE [HRM_Portal_02]
GO
/****** Object:  StoredProcedure [dbo].[vsii_GetDelegationOrg]    Script Date: 5/30/2019 2:21:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Script for SelectTopNRows command from SSMS  ******/
ALTER procedure [dbo].[vsii_GetDelegationOrg]
@orgLs as [dbo].[LocationIDList] readonly
as
begin
select os.OBJID from [dbo].[HRM_PORTAL_OrganizationStructure] os 
where 1 = (case when os.level = '1' then 1
when os.level = '2' and os.ORGLV1 not in (select * from @orgLs) then 1 
when os.level = '3' and os.ORGLV2 not in (select * from @orgLs) then 1 
when os.level = '4' and os.ORGLV3 not in (select * from @orgLs) then 1 
when os.level = '5' and os.ORGLV4 not in (select * from @orgLs) then 1 
when os.level = '6' and os.ORGLV5 not in (select * from @orgLs) then 1 
when os.level = '7' and os.ORGLV6 not in (select * from @orgLs) then 1 
when os.level = '8' and os.ORGLV7 not in (select * from @orgLs) then 1 
when os.level = '9' and os.ORGLV8 not in (select * from @orgLs) then 1 
when os.level = '10' and os.ORGLV9 not in (select * from @orgLs) then 1 
when os.level = '11' and os.ORGLV10 not in (select * from @orgLs) then 1 
else 0 end) and os.OBJID in (select * from @orgLs)

end


