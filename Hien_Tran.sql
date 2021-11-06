drop table FUPIRP_SITES
go

create table FUPIRP_SITES (
    SiteNumber int primary key nonclustered,
    SiteName nvarchar(100),
    XCoordinate int check (XCoordinate between -50 and 50),
    YCoordinate int check (YCoordinate between -50 and 50)
)
go

-- DO NOT ALTER THIS PROCEDURE.  It builds your data set for testing.
drop procedure GENERATE_FUPIRP_SITES
go

create procedure GENERATE_FUPIRP_SITES
as begin
    delete from FUPIRP_SITES

    insert into FUPIRP_SITES select 0, 'Original Position', 0, 0

    declare @siteNumber int
    set @siteNumber = 1

    while @siteNumber <= 5 begin
        insert into FUPIRP_SITES 
        select @siteNumber, 'Site #' + convert(nvarchar, @siteNumber),
               50 - floor(rand()*100), 50 - floor(rand()*100)
        
        set @siteNumber = @siteNumber + 1
    end
end
go

exec GENERATE_FUPIRP_SITES
go


-- HERE'S YOUR STUFF.  You should only put stuff where the comments are.

drop view FUPIRP_PATHS
go

create view FUPIRP_PATHS (StartSite, EndSite, Distance) as
    select  a.SiteNumber, b.SiteNumber,
			ceiling(sqrt(power(b.XCoordinate - a.Xcoordinate, 2) + power(b.YCoordinate - a.Ycoordinate, 2)))
	from FUPIRP_SITES a, FUPIRP_SITES b
	where a.SiteNumber != b.SiteNumber
go

select * from FUPIRP_PATHS

drop procedure GET_SHORTEST_FUPIRP_PATH
go

create procedure GET_SHORTEST_FUPIRP_PATH
as begin
    declare @Count int = (select count(*)-1 from FUPIRP_SITES) -- to stop iteration! 
	;with Reachable as (
		select EndSite, 1 HOPS, Distance, 
		convert(varchar(max), '(' + convert(varchar(max),StartSite) + ') => (' + convert (varchar(max),EndSite) +')') thePath
		from FUPIRP_PATHS  where StartSite = 0

		union all

		select A.EndSite, R.HOPS+1, R.Distance+A.Distance, 
		convert(varchar(max), R.thePath + ' => (' + convert(varchar(max),A.EndSite) + ')')
		from Reachable R, FUPIRP_PATHS A
		where R.EndSite = A.StartSite
		and R.HOPS < @Count
		and R.ThePath not like '%' + convert(varchar(max),A.EndSite) + '%'
		
	) 
	select Distance,thePath  
	from Reachable
	where  HOPS = @Count
	and Distance= (
		select min(Distance) from Reachable
		where HOPS = @Count
	)
end
go
exec GET_SHORTEST_FUPIRP_PATH
go