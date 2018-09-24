if not exists(select * from sys.databases d where d.[name] = 'PrimarySchool')
begin
	create database PrimarySchool;
end;
GO

use PrimarySchool;
GO

if not exists(select * from sys.schemas s where s.[name] = 'ps')
begin
	execute('create schema ps;');
end;
GO

if exists(select * from sys.views t
              inner join sys.schemas s on s.schema_id = t.schema_id
          where t.[name] = 'vTeacher' and s.[name] = 'ps')
begin
	drop view ps.vTeacher;
end;

if exists(select * from sys.procedures p
              inner join sys.schemas s on s.schema_id = p.schema_id
          where p.[name] = 'sTeacherCreate' and s.[name] = 'ps')
begin
	drop procedure ps.sTeacherCreate;
end;

if exists(select * from sys.procedures p
              inner join sys.schemas s on s.schema_id = p.schema_id
          where p.[name] = 'sTeacherDestroy' and s.[name] = 'ps')
begin
	drop procedure ps.sTeacherDestroy;
end;

if exists(select * from sys.tables t
              inner join sys.schemas s on s.schema_id = t.schema_id
          where t.[name] = 'tStudent' and s.[name] = 'ps')
begin
	drop table ps.tStudent;
end;

if exists(select * from sys.tables t
              inner join sys.schemas s on s.schema_id = t.schema_id
          where t.[name] = 'tClass' and s.[name] = 'ps')
begin
	drop table ps.tClass;
end;

if exists(select * from sys.tables t
              inner join sys.schemas s on s.schema_id = t.schema_id
          where t.[name] = 'tTeacher' and s.[name] = 'ps')
begin
	drop table ps.tTeacher;
end;

create table ps.tTeacher
(
	TeacherId int identity(0, 1),
	FirstName nvarchar(32) not null,
	LastName  nvarchar(32) not null,

	constraint PK_ps_tTeacher primary key(TeacherId),
	constraint CK_ps_tTeacher_FirstName check(FirstName <> N''),
	constraint CK_ps_tTeacher_LastName check(LastName <> N''),
	constraint UK_ps_tTeacher_Name unique(LastName, FirstName)
);

insert into ps.tTeacher(FirstName, LastName) values(N'N.A.', N'N.A.');

create table ps.tClass
(
	ClassId   int identity(0, 1),
	[Name]    nvarchar(8) not null,
	[Level]   varchar(3) not null,
	TeacherId int not null,

	constraint PK_ps_tClass primary key(ClassId),
	constraint UK_ps_tClass_Name unique([Name]),
	constraint CK_ps_tClass_Level check([Level] in ('CP', 'CE1', 'CE2', 'CM1', 'CM2')),
	constraint FK_ps_tClass_TeacherId foreign key(TeacherId) references ps.tTeacher(TeacherId)
);

create unique index IX_ps_tClass_TeacherId on ps.tClass(TeacherId) where TeacherId <> 0;

insert into ps.tClass([Name], [Level], TeacherId) values(N'', 'CP', 0);

create table ps.tStudent
(
	StudentId int identity(0, 1),
	FirstName nvarchar(32) not null,
	LastName  nvarchar(32) not null,
	BirthDate datetime2 not null,
	ClassId   int not null,

	constraint PK_ps_tStudent primary key(StudentId),
	constraint CK_ps_tStudent_FirstName check(FirstName <> N''),
	constraint CK_ps_tStudent_LastName check(LastName <> N''),
	constraint CK_ps_tStudent_BirthDate check(BirthDate < getutcdate()),
	constraint FK_ps_tStudent_ClassId foreign key(ClassId) references ps.tClass(ClassId),
	constraint UK_ps_tStudent_Name unique(LastName, FirstName, BirthDate)
);

insert into ps.tStudent(FirstName, LastName, BirthDate, ClassId) values(N'N.A.', N'N.A.', '00010101', 0);
GO

create view ps.vTeacher
as
	select
		TeacherId = t.TeacherId,
		FirstName = t.FirstName,
		LastName = t.LastName,
		ClassId = coalesce(c.ClassId, 0),
		ClassName = coalesce(c.[Name], N''),
		ClassLevel = coalesce(c.[Level], '')
	from ps.tTeacher t
		left outer join ps.tClass c on c.TeacherId = t.TeacherId
	where t.TeacherId <> 0;
GO

create proc ps.sTeacherCreate
(
	@FirstName nvarchar(32),
	@LastName nvarchar(32),
	@TeacherId int out
)
as
begin
	set transaction isolation level serializable;
	begin tran;

	if @FirstName is null or @FirstName = N''
	begin
		rollback;
		return 1;
	end;

	if @LastName is null or @LastName = N''
	begin
		rollback;
		return 2;
	end;

	if exists (select * from ps.tTeacher t where t.FirstName = @FirstName and t.LastName = @LastName)
	begin
		rollback;
		return 3;
	end;

	insert into ps.tTeacher(FirstName, LastName) values(@FirstName, @LastName);
	set @TeacherId = scope_identity();
	commit;
	return 0;
end;
GO

create proc ps.sTeacherDestroy
(
	@TeacherId int
)
as
begin
	delete from ps.tTeacher where TeacherId = @TeacherId;
	return 0;
end;