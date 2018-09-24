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