-- ============================================================
-- ЧАСТЬ 1: ПРИВЕДЕНИЕ К 3-Й НОРМАЛЬНОЙ ФОРМЕ
-- ============================================================

-- ACADEMY - добавление связей
use Academy;
go
if not exists (select * from sys.foreign_keys where name = 'FK_Students_Groups')
    alter table Students add constraint FK_Students_Groups foreign key (GroupId) references Groups(Id);
if not exists (select * from sys.foreign_keys where name = 'FK_Teachers_Departments')
    alter table Teachers add constraint FK_Teachers_Departments foreign key (DepartmentID) references Departments(Id);
if not exists (select * from sys.foreign_keys where name = 'FK_TeachersSubjects_Teachers')
    alter table TeachersSubjects add constraint FK_TeachersSubjects_Teachers foreign key (TeacherId) references Teachers(Id);
if not exists (select * from sys.foreign_keys where name = 'FK_TeachersSubjects_Subjects')
    alter table TeachersSubjects add constraint FK_TeachersSubjects_Subjects foreign key (SubjectId) references Subjects(Id);
if not exists (select * from sys.foreign_keys where name = 'FK_Achievements_Students')
    alter table Achievements add constraint FK_Achievements_Students foreign key (StudentId) references Students(Id);
if not exists (select * from sys.foreign_keys where name = 'FK_Achievements_Subjects')
    alter table Achievements add constraint FK_Achievements_Subjects foreign key (SubjectId) references Subjects(Id);
go

-- HOSPITAL - добавление связей и исправление опечаток
use Hospital;
go
if not exists (select * from sys.columns where object_name(object_id) = 'Doctors' and name = 'DepartmentId')
    alter table Doctors add DepartmentId int null;
if not exists (select * from sys.foreign_keys where name = 'FK_Doctors_Departments')
    alter table Doctors add constraint FK_Doctors_Departments foreign key (DepartmentId) references Departments(Id);
if not exists (select * from sys.foreign_keys where name = 'FK_Wards_Departments')
    alter table Wards add constraint FK_Wards_Departments foreign key (DepartmentId) references Departments(Id);
if not exists (select * from sys.foreign_keys where name = 'FK_DoctorsExaminations_Doctors')
    alter table DoctorsExaminations add constraint FK_DoctorsExaminations_Doctors foreign key (DoctorId) references Doctors(Id);
if not exists (select * from sys.foreign_keys where name = 'FK_DoctorsExaminations_Examinations')
    alter table DoctorsExaminations add constraint FK_DoctorsExaminations_Examinations foreign key (ExaminationId) references Examinations(Id);
if not exists (select * from sys.foreign_keys where name = 'FK_DoctorsExaminations_Wards')
    alter table DoctorsExaminations add constraint FK_DoctorsExaminations_Wards foreign key (WardId) references Wards(Id);
if exists (select * from sys.columns where object_name(object_id) = 'Donations' and name = 'SponsordId')
    exec sp_rename 'Donations.SponsordId', 'SponsorId', 'COLUMN';
if not exists (select * from sys.foreign_keys where name = 'FK_Donations_Departments')
    alter table Donations add constraint FK_Donations_Departments foreign key (DepartmentId) references Departments(Id);
if not exists (select * from sys.foreign_keys where name = 'FK_Donations_Sponsors')
    alter table Donations add constraint FK_Donations_Sponsors foreign key (SponsorId) references Sponsors(Id);
go

-- VEGETABLESANDFRUITS - нормализация
use VegetablesAndFruits;
go
if exists (select * from sys.tables where name = 'VegetablesFruits')
begin
    if not exists (select * from sys.tables where name = 'Categories')
        create table Categories (Id int primary key identity(1,1), CategoryName nvarchar(50) not null unique, Description nvarchar(200));
    if not exists (select * from sys.tables where name = 'Types')
        create table Types (Id int primary key identity(1,1), TypeName nvarchar(50) not null unique, CategoryId int not null, constraint FK_Types_Categories foreign key (CategoryId) references Categories(Id));
    if not exists (select * from sys.tables where name = 'Products')
        create table Products (Id int primary key identity(1,1), ProductName nvarchar(100) not null, TypeId int not null, Color nvarchar(30), Calories int, Description nvarchar(max), constraint FK_Products_Types foreign key (TypeId) references Types(Id));

    insert into Categories (CategoryName, Description)
    select distinct 
        case when Type = 'Фрукт' then 'Фрукты' when Type = 'Овощ' then 'Овощи' else 'Ягоды' end,
        case when Type = 'Фрукт' then 'Сладкие плоды растений' when Type = 'Овощ' then 'Съедобные части растений' else 'Мелкие сочные плоды' end
    from VegetablesFruits
    where not exists (select 1 from Categories where CategoryName = case when Type = 'Фрукт' then 'Фрукты' when Type = 'Овощ' then 'Овощи' else 'Ягоды' end);

    insert into Types (TypeName, CategoryId)
    select distinct v.Type, c.Id
    from VegetablesFruits v
    join Categories c on case when v.Type = 'Фрукт' then 'Фрукты' when v.Type = 'Овощ' then 'Овощи' else 'Ягоды' end = c.CategoryName
    where not exists (select 1 from Types where TypeName = v.Type);

    insert into Products (ProductName, TypeId, Color, Calories, Description)
    select v.Name, t.Id, v.Color, v.Calories, v.Description
    from VegetablesFruits v
    join Types t on v.Type = t.TypeName
    where not exists (select 1 from Products where ProductName = v.Name);

    drop table VegetablesFruits;
end
go

-- ============================================================
-- ЧАСТЬ 2: ЗАПРОСЫ (по 5 для каждой БД)
-- ============================================================

-- ACADEMY - 5 запросов
use Academy;
go
select '=== ACADEMY: 1. Студенты с группами ===' as Query;
select top 1000 s.LastName + ' ' + s.FirstName as Student, g.GroupName, d.Department as Faculty
from Students s left join Groups g on s.GroupId = g.Id left join Departments d on g.FacultyID = d.Id;

select '=== ACADEMY: 2. Оценки студентов ===' as Query;
select top 1000 s.LastName + ' ' + s.FirstName as Student, sub.SubjectName, a.Assesment as Grade
from Achievements a join Students s on a.StudentId = s.Id join Subjects sub on a.SubjectId = sub.Id
order by a.Assesment desc;

select '=== ACADEMY: 3. Группы и количество студентов ===' as Query;
select top 1000 g.GroupName, count(s.Id) as StudentCount
from Groups g left join Students s on g.Id = s.GroupId
group by g.GroupName order by StudentCount desc;

select '=== ACADEMY: 4. Преподаватели и предметы ===' as Query;
select top 1000 t.LastName + ' ' + t.FirstName as Teacher, sub.SubjectName
from Teachers t join TeachersSubjects ts on t.Id = ts.TeacherId join Subjects sub on ts.SubjectId = sub.Id;

select '=== ACADEMY: 5. Средний балл студентов ===' as Query;
select top 1000 s.LastName + ' ' + s.FirstName as Student, avg(cast(a.Assesment as float)) as AvgGrade
from Students s join Achievements a on s.Id = a.StudentId
group by s.LastName, s.FirstName order by AvgGrade desc;

-- HOSPITAL - 5 запросов
use Hospital;
go
select '=== HOSPITAL: 1. Врачи и отделения ===' as Query;
select top 1000 d.Surname + ' ' + d.Name as Doctor, dep.Name as Department
from Doctors d left join Departments dep on d.DepartmentId = dep.Id;

select '=== HOSPITAL: 2. Палаты и отделения ===' as Query;
select top 1000 w.Name as Ward, dep.Name as Department, w.Places
from Wards w join Departments dep on w.DepartmentId = dep.Id;

select '=== HOSPITAL: 3. Обследования с врачами ===' as Query;
select top 1000 e.Name as Examination, d.Surname + ' ' + d.Name as Doctor, de.StartTime, de.EndTime
from DoctorsExaminations de
join Doctors d on de.DoctorId = d.Id
join Examinations e on de.ExaminationId = e.Id;

select '=== HOSPITAL: 4. Пожертвования по отделениям ===' as Query;
select top 1000 dep.Name as Department, s.Name as Sponsor, don.Amount, don.Date
from Donations don
join Departments dep on don.DepartmentId = dep.Id
join Sponsors s on don.SponsorId = s.Id
order by don.Amount desc;

select '=== HOSPITAL: 5. Статистика зарплат по отделениям ===' as Query;
select top 1000 dep.Name as Department, count(d.Id) as DoctorsCount, avg(d.Salary) as AvgSalary
from Doctors d join Departments dep on d.DepartmentId = dep.Id
group by dep.Name;

-- VEGETABLESANDFRUITS - 5 запросов
use VegetablesAndFruits;
go
select '=== VEGETABLES: 1. Продукты с категориями ===' as Query;
select top 1000 p.ProductName, c.CategoryName, t.TypeName, p.Color, p.Calories
from Products p join Types t on p.TypeId = t.Id join Categories c on t.CategoryId = c.Id;

select '=== VEGETABLES: 2. Продукты с калорийностью выше 50 ===' as Query;
select top 1000 p.ProductName, c.CategoryName, p.Calories
from Products p join Types t on p.TypeId = t.Id join Categories c on t.CategoryId = c.Id
where p.Calories > 50 order by p.Calories desc;

select '=== VEGETABLES: 3. Количество продуктов по категориям ===' as Query;
select c.CategoryName, count(p.Id) as ProductCount
from Categories c left join Types t on c.Id = t.CategoryId left join Products p on t.Id = p.TypeId
group by c.CategoryName;

select '=== VEGETABLES: 4. Самые калорийные продукты ===' as Query;
select top 10 p.ProductName, c.CategoryName, p.Calories
from Products p join Types t on p.TypeId = t.Id join Categories c on t.CategoryId = c.Id
order by p.Calories desc;

select '=== VEGETABLES: 5. Продукты по цветам ===' as Query;
select p.Color, count(p.Id) as ProductCount
from Products p where p.Color is not null
group by p.Color order by ProductCount desc;
go