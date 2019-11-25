--CREATE TYPE BlockedRequestTable AS TABLE
--(
--   ID INT,
--   RequestID INT,
--   TableName TEXT
--)

CREATE PROCEDURE [dbo].[BlockPendingRequests]
@BlockOrgid char(8),
@DATE DATETIME
AS

	declare @OrgLevel nvarchar(8) = (select top 1 LEVEL from HRM_PORTAL_OrganizationStructure  where OBJID = @BlockOrgid )
	if(ltrim(rtrim(@OrgLevel)) = '1')
	begin
		-- UPDATE STATUS = 2 => 7 (BLOCKED)
		UPDATE HRM_PORTAL_CongTac
		SET STATUS = 7, CHANGEREQUEST = 0
		WHERE status = 2
		AND @DATE >= BEGDA 

		-- UPDATE STATUS = 2 => 7 (BLOCKED)
		UPDATE HRM_PORTAL_NghiPhep
		SET STATUS = 7, CHANGEREQUEST = 0
		WHERE status = 2
		AND  @DATE >= BEGDA 

		-- UPDATE STATUS = 2 => 7 (BLOCKED)
		UPDATE HRM_PORTAL_OverTime
		SET STATUS = 7
		WHERE status = 2
		AND  @DATE >= BEGDA 

		-- UPDATE STATUS = 2 => 7 (BLOCKED)
		UPDATE HRM_PORTAL_TimeIn_Out_Change
		SET STATUS = 7
		WHERE status = 2
		AND ERDAT <= @DATE

		Update HRM_PORTAL_TimeIn_Out set CHANGEREQUEST = 0 where ID in ( select OriginID_IN from HRM_PORTAL_TimeIn_Out_Change where status=7 and ERDAT <= @DATE union select OriginID_OUT from HRM_PORTAL_TimeIn_Out_Change where status=7 and ERDAT <= @DATE ) and CHANGEREQUEST != 0

		-- UPDATE STATUS = 2 => 7 (BLOCKED)
		UPDATE VSII_DCCongKyTruoc
		SET STATUS = 7
		WHERE status = 2
		AND CREATEDATE <= @DATE
	end
	else if(ltrim(rtrim(@OrgLevel)) = '2')
	begin
		-- khoa cong toan tap doan
		-- danh sach cac phong ban cua ca p&L
		BEGIN TRY DROP TABLE #TEMPORG END TRY BEGIN CATCH END CATCH
		CREATE TABLE #TEMPORG ( OBJID char(8) )
		insert into #TEMPORG select OBJID from HRM_PORTAL_OrganizationStructure where ORGLV2 = @BlockOrgid
		-- lay nhan vien trong danh sach status = 2 de tang performance
		BEGIN TRY DROP TABLE #TEMP1 END TRY BEGIN CATCH END CATCH
		CREATE TABLE #TEMP1 ( PERNR varchar(8) )
		insert into #TEMP1 select distinct congtac.PERNR from HRM_PORTAL_CongTac congtac join  HRM_PORTAL_OrganizationalAssignment oa on oa.PERNR = congtac.PERNR where status = 2 and oa.ORGEH in (select * from #TEMPORG) and @DATE between oa.BEGDA and oa.ENDDA
		
		-- UPDATE STATUS = 2 => 7 (BLOCKED)
		UPDATE HRM_PORTAL_CongTac
		SET STATUS = 7, CHANGEREQUEST = 0
		WHERE PERNR IN
		(SELECT * from #TEMP1)
		AND status = 2
		AND  @DATE >= BEGDA 

		-- lay nhan vien trong danh sach status = 2 de tang performance
		BEGIN TRY DROP TABLE #TEMP2 END TRY BEGIN CATCH END CATCH
		CREATE TABLE #TEMP2 ( PERNR varchar(8) )
		insert into #TEMP2 select distinct nghiphep.PERNR from HRM_PORTAL_NghiPhep nghiphep join  HRM_PORTAL_OrganizationalAssignment oa on oa.PERNR = nghiphep.PERNR where status = 2 and oa.ORGEH in (select * from #TEMPORG)
		-- UPDATE STATUS = 2 => 7 (BLOCKED)
		UPDATE HRM_PORTAL_NghiPhep
		SET STATUS = 7, CHANGEREQUEST = 0
		WHERE PERNR IN
		(SELECT * from #TEMP2)
		AND status = 2
		AND @DATE >= BEGDA 

		-- lay nhan vien trong danh sach status = 2 de tang performance
		BEGIN TRY DROP TABLE #TEMP3 END TRY BEGIN CATCH END CATCH
		CREATE TABLE #TEMP3 ( PERNR varchar(8) )
		insert into #TEMP3 select distinct overtime.PERNR from HRM_PORTAL_OverTime overtime join  HRM_PORTAL_OrganizationalAssignment oa on oa.PERNR = overtime.PERNR where status = 2 and oa.ORGEH in (select * from #TEMPORG)
		-- UPDATE STATUS = 2 => 7 (BLOCKED)
		UPDATE HRM_PORTAL_OverTime
		SET STATUS = 7
		WHERE PERNR IN
		(SELECT * from #TEMP3)
		AND status = 2
		AND  @DATE >= BEGDA 

		-- lay nhan vien trong danh sach status = 2 de tang performance
		BEGIN TRY DROP TABLE #TEMP4 END TRY BEGIN CATCH END CATCH
		CREATE TABLE #TEMP4 ( PERNR varchar(8) )
		insert into #TEMP4 select distinct inoutChange.PERNR from HRM_PORTAL_TimeIn_Out_Change inoutChange join  HRM_PORTAL_OrganizationalAssignment oa on oa.PERNR = inoutChange.PERNR where status = 2 and oa.ORGEH in (select * from #TEMPORG)
		-- UPDATE STATUS = 2 => 7 (BLOCKED)
		UPDATE HRM_PORTAL_TimeIn_Out_Change
		SET STATUS = 7
		WHERE PERNR IN
		(SELECT * from #TEMP4)
		AND status = 2
		AND ERDAT <= @DATE

		Update HRM_PORTAL_TimeIn_Out set CHANGEREQUEST = 0 where ID in ( select OriginID_IN from HRM_PORTAL_TimeIn_Out_Change where status= 7 and ERDAT <= @DATE union select OriginID_OUT from HRM_PORTAL_TimeIn_Out_Change where status = 7 and ERDAT <= @DATE ) and CHANGEREQUEST != 0
			
		-- lay nhan vien trong danh sach status = 2 de tang performance
		BEGIN TRY DROP TABLE #TEMP5 END TRY BEGIN CATCH END CATCH
		CREATE TABLE #TEMP5 ( PERNR varchar(8) )
		insert into #TEMP5 select distinct dcckt.PERNR from VSII_DCCongKyTruoc dcckt join  HRM_PORTAL_OrganizationalAssignment oa on oa.PERNR = dcckt.PERNR where status = 2 and oa.ORGEH in (select * from #TEMPORG)
		-- UPDATE STATUS = 2 => 7 (BLOCKED)
		UPDATE VSII_DCCongKyTruoc
		SET STATUS = 7
		WHERE PERNR IN
		(SELECT * from #TEMP5)
		AND status = 2
		AND CREATEDATE <= @DATE

		drop table #TEMPORG
		drop table #TEMP1
		drop table #TEMP2
		drop table #TEMP3
		drop table #TEMP4
		drop table #TEMP5
	end