GO
/****** Object:  StoredProcedure [dbo].[vsii_sproc_LoadUserForDelegation]    Script Date: 5/23/2019 6:23:45 PM ******/
--SET ANSI_NULLS ON
--GO
--SET QUOTED_IDENTIFIER ON
--GO
---- =============================================
---- Author:		<Author,,Name>
---- Create date: <Create Date,,>
---- Description:	<Description,,>
---- =============================================
--Create PROCEDURE [dbo].[vsii_sproc_LoadUserAllwithDirectboos]
--	-- Add the parameters for the stored procedure here
--	#LocationList AS dbo.LocationIDList READONLY,
--	@actionId int,
--	@edsta datetime,
--	@edend datetime,
--	@searchText NVARCHAR(Max),
--	@currentUser char(8),
--	@containDirectboss bit,
--	@isAll bit,
--	@page int,
--	@pageSize int,
--	@IsSupperAdmin bit
--AS
--BEGIN

	create table #LocationList( ID nvarchar(50) )
	insert into #LocationList select os.OBJID from [dbo].[HRM_PORTAL_OrganizationStructure] os where os.ORGLV2 ='45010218'
	declare @actionId int = 77
	declare @edsta datetime = '20190531'
	declare @edend datetime = '20190531'
	declare @searchText NVARCHAR(max) = ''
	declare @currentUser char(8) = '00375579'
	declare @containDirectboss bit = 1
	declare @isAll bit = 0
	declare @page int = 1
	declare @pageSize int = 300
	declare @IsSupperAdmin bit = 0

	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	declare @total int
	SET NOCOUNT ON;
	CREATE TABLE #AllMem(  
		id char(8)
	)

	CREATE TABLE #KetQua(  
		id CHAR(8), -- pernr
		Parentid CHAR(8), -- oa.ORGEH
		text nvarchar(250), -- full name
		Username nvarchar(100)
	)

	if(@containDirectboss = 1)
	begin
		declare @UQLocation nvarchar(max)
		declare @UQAction nvarchar(max)
		declare @AssignPerson char(8)
		declare @IsDirectBoss bit
		declare CursorUyQuyen cursor
		forward_only
		static
		Read_only
		for	select vud.PERNR,vud.LocationDelegation,vud.ActionDelegation, vud.isDirectBoss from [dbo].[VSII_User_Delegate] vud 
		where vud.DelegatedId = @currentUser
		-- Get all user in trong location -- loai tru nghi viec
		INSERT INTO #AllMem 
		SELECT distinct oa.PERNR AS id
		FROM HRM_PORTAL_OrganizationalAssignment oa
		JOIN HRM_PORTAL_Action a on oa.PERNR = a.PERNR	
		WHERE  oa.ORGEH in (select * from #LocationList) 
			and a.MASSN not in ('ZG','ZH','ZI','ZJ') 
			and a.STAT2 <> 0
			and ((@edsta BETWEEN a.BEGDA AND a.ENDDA) or (@edend BETWEEN a.BEGDA AND a.ENDDA))
			and ((@edsta BETWEEN oa.BEGDA AND oa.ENDDA) or (@edend BETWEEN oa.BEGDA AND oa.ENDDA))
		
		-- them direct boss tu delegation
		INSERT INTO #AllMem
		SELECT  distinct em.PERNR
		from HRM_PORTAL_EmployeeManager em
		JOIN HRM_PORTAL_Action a on em.PERNR = a.PERNR
		where em.DIRECT_BOSS = @currentUser
		and a.MASSN not in ('ZG','ZH','ZI','ZJ') 
		and a.STAT2 <> 0 
		and ((@edsta BETWEEN a.BEGDA AND a.ENDDA) or (@edend BETWEEN a.BEGDA AND a.ENDDA))

		OPEN CursorUyQuyen
		FETCH NEXT FROM CursorUyQuyen
			  INTO @AssignPerson,@UQLocation, @UQAction, @IsDirectBoss
		WHILE @@FETCH_STATUS = 0
		BEGIN
			if(@actionId in (select (case when isnumeric(uqA.items) = 1 then convert(int,uqA.items) else -1 end) as ActionID from dbo.Split(@UQAction,',') as uqA ) and @IsDirectBoss = 1)
			begin
				insert into #AllMem
				SELECT em.PERNR AS id
				from HRM_PORTAL_EmployeeManager em
				JOIN HRM_PORTAL_Action a on em.PERNR = a.PERNR
				where em.DIRECT_BOSS = @AssignPerson
				and a.MASSN not in ('ZG','ZH','ZI','ZJ') 
				and a.STAT2 <> 0
				and ((@edsta BETWEEN a.BEGDA AND a.ENDDA) or (@edend BETWEEN a.BEGDA AND a.ENDDA))
			end

			FETCH NEXT FROM CursorUyQuyen
				  INTO @UQLocation, @UQAction, @IsDirectBoss
		END
		CLOSE CursorUyQuyen
		DEALLOCATE CursorUyQuyen
		-- loc duy nhat

		if(@isAll = 1)
		begin
			select distinct *,'' as Parentid, '' as text from #AllMem
		end
		else
		begin
			insert into #KetQua
			select pp.PERNR as id,'' AS Parentid, ltrim(pp.NACHN + ' ' + pp.VORNA) AS text,ac.Username as Username 
			from VSII_Account ac
			left join HRM_PORTAL_Personal pp  on pp.PERNR = ac.PERNR
			where ((@edsta BETWEEN pp.BEGDA AND pp.ENDDA) or (@edend BETWEEN pp.BEGDA AND pp.ENDDA))
			and ac.PERNR in (select * from #AllMem)
			
			set @total = (select count(kq.id) from #KetQua kq where (@searchText = '' OR (text like'%'+ @searchText+'%') OR (Username like '%'+ @searchText+'%'))
			group by kq.id,kq.text,kq.Parentid,kq.Username)

			SELECT *, @total as total from #KetQua kq
			where (@searchText = '' OR (text like'%'+ @searchText+'%') OR (Username like '%'+ @searchText+'%'))
			group by kq.id,kq.text,kq.Parentid,kq.Username
			ORDER BY text
			offset @pageSize * (@page - 1) rows fetch next @pageSize rows only 
		end
	end
	else
	begin
		INSERT INTO #AllMem 
		SELECT distinct oa.PERNR AS id
		FROM HRM_PORTAL_OrganizationalAssignment oa
		JOIN HRM_PORTAL_Action a on oa.PERNR = a.PERNR	
		WHERE  oa.ORGEH in (select * from #LocationList) 
			and a.MASSN not in ('ZG','ZH','ZI','ZJ') 
			and a.STAT2 <> 0
			and ((@edsta BETWEEN a.BEGDA AND a.ENDDA) or (@edend BETWEEN a.BEGDA AND a.ENDDA))
			and ((@edsta BETWEEN oa.BEGDA AND oa.ENDDA) or (@edend BETWEEN oa.BEGDA AND oa.ENDDA))
		-- loc duy nhat
		if(@isAll = 1)
		begin
			select distinct *,'' as Parentid, '' as text from #AllMem
		end
		else
		begin
			insert into #KetQua
			select pp.PERNR as id,'' AS Parentid, ltrim(pp.NACHN + ' ' + pp.VORNA) AS text,ac.Username as Username 
			from VSII_Account ac
			left join HRM_PORTAL_Personal pp  on pp.PERNR = ac.PERNR
			where ((@edsta BETWEEN pp.BEGDA AND pp.ENDDA) or (@edend BETWEEN pp.BEGDA AND pp.ENDDA))
			and ac.PERNR in (select * from #AllMem)
			
			set @total = (select count(kq.id) from #KetQua kq where (@searchText = '' OR (text like'%'+ @searchText+'%') OR (Username like '%'+ @searchText+'%'))
			group by kq.id,kq.text,kq.Parentid,kq.Username)

			SELECT *, @total as total from #KetQua kq
			where (@searchText = '' OR (text like'%'+ @searchText+'%') OR (Username like '%'+ @searchText+'%'))
			group by kq.id,kq.text,kq.Parentid,kq.Username
			ORDER BY text
			offset @pageSize * (@page - 1) rows fetch next @pageSize rows only 
		end
	end

	drop table #LocationList
	drop TABLE #AllMem
	drop TABLE #KetQua
--END