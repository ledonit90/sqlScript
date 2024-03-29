USE [HRM_Portal_DB]
GO
/****** Object:  UserDefinedFunction [dbo].[Split]    Script Date: 5/26/2019 6:25:53 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create FUNCTION [dbo].[Split_TableInt](@String varchar(8000), @Delimiter char(1))
returns @temptable TABLE (items int)
as
begin
	declare @idx int
	declare @slice int
	set @idx = 1
	if len(@String)<1 or @String is null  return

	while @idx!= 0
	begin
		set @idx = charindex(@Delimiter,@String)
		if @idx != 0
			set @slice = left(@String,@idx - 1)
		else
			set @slice = @String
		if(len(@slice) > 0)
			insert into @temptable(Items) values(@slice)
		set @String = right(@String,len(@String) - @idx)
		if len(@String) = 0 break
	end
return
end


create table #temp(
	test int
)
create table #temptest(
	testx varchar(100)
)
insert into #temp(test) values(1),(2),(3),(4)
insert into #temptest(testx) values('1'),('2'),('3'),('4'),('abc'),('sgg'),('4')

select * from #temp t 
join #temptest tt 
on t.test = 
(case when IsNumeric(tt.testx) = 1 then convert(int,tt.testx) 
when IsNumeric(tt.testx) = 0 then -1)

drop table #temp
drop table #temptest

select IsNumeric('1564')

SELECT CONVERT(int, '123d')
