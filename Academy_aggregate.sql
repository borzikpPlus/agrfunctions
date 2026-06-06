/* =====================================================================
   Домашнее задание: Агрегатные функции (БД «Academy»)

   13 запросов с использованием COUNT, AVG, MIN, MAX и GROUP BY.

   Скрипт самодостаточный: создаёт полноценную схему БД «Academy»
   со всеми связями, наполняет её данными и выполняет 13 запросов.

   Схема (8 таблиц):
     Faculties      — факультеты
     Departments    — кафедры        (FK -> Faculties)
     Teachers       — преподаватели  (FK -> Departments)
     Groups         — группы         (FK -> Departments)
     Students       — студенты       (FK -> Groups)
     Subjects       — дисциплины
     Lectures       — лекции         (FK -> Subjects, Teachers; аудитория, день недели)
     GroupsLectures — связь «группа ↔ лекция» (многие-ко-многим)

   СУБД: Microsoft SQL Server (T-SQL)
   ===================================================================== */

-- 1. СОЗДАНИЕ БД И ТАБЛИЦ -----------------------------------------------

DROP DATABASE IF EXISTS AcademyDB;
GO
CREATE DATABASE AcademyDB;
GO
USE AcademyDB;
GO

CREATE TABLE Faculties (
    Id   INT IDENTITY(1,1) PRIMARY KEY,
    Name NVARCHAR(100) NOT NULL
);

CREATE TABLE Departments (
    Id        INT IDENTITY(1,1) PRIMARY KEY,
    Name      NVARCHAR(100) NOT NULL,
    Financing MONEY        NOT NULL DEFAULT 0,
    FacultyId INT          NOT NULL REFERENCES Faculties(Id)
);

CREATE TABLE Teachers (
    Id           INT IDENTITY(1,1) PRIMARY KEY,
    Name         NVARCHAR(50) NOT NULL,
    Surname      NVARCHAR(50) NOT NULL,
    Salary       MONEY        NOT NULL,   -- ставка
    Premium      MONEY        NOT NULL DEFAULT 0,
    DepartmentId INT          NOT NULL REFERENCES Departments(Id)
);

CREATE TABLE Groups (
    Id           INT IDENTITY(1,1) PRIMARY KEY,
    Name         NVARCHAR(50) NOT NULL,
    Year         INT          NOT NULL,
    Rating       INT          NULL,
    DepartmentId INT          NOT NULL REFERENCES Departments(Id)
);

CREATE TABLE Students (
    Id      INT IDENTITY(1,1) PRIMARY KEY,
    Name    NVARCHAR(50) NOT NULL,
    Surname NVARCHAR(50) NOT NULL,
    GroupId INT          NOT NULL REFERENCES Groups(Id)
);

CREATE TABLE Subjects (
    Id   INT IDENTITY(1,1) PRIMARY KEY,
    Name NVARCHAR(100) NOT NULL
);

CREATE TABLE Lectures (
    Id          INT IDENTITY(1,1) PRIMARY KEY,
    SubjectId   INT          NOT NULL REFERENCES Subjects(Id),
    TeacherId   INT          NOT NULL REFERENCES Teachers(Id),
    LectureRoom NVARCHAR(20) NOT NULL,   -- аудитория, напр. «D201»
    DayOfWeek   INT          NOT NULL    -- день недели 1..7
);

CREATE TABLE GroupsLectures (
    GroupId   INT NOT NULL REFERENCES Groups(Id),
    LectureId INT NOT NULL REFERENCES Lectures(Id),
    CONSTRAINT PK_GroupsLectures PRIMARY KEY (GroupId, LectureId)
);
GO

-- 2. ЗАПОЛНЕНИЕ ДАННЫМИ -------------------------------------------------

INSERT INTO Faculties (Name) VALUES
    (N'Computer Science'),
    (N'Engineering'),
    (N'Mathematics');

INSERT INTO Departments (Name, Financing, FacultyId) VALUES
    (N'Software Development',    50000, (SELECT Id FROM Faculties WHERE Name=N'Computer Science')),
    (N'Data Science',           45000, (SELECT Id FROM Faculties WHERE Name=N'Computer Science')),
    (N'Cybersecurity',          40000, (SELECT Id FROM Faculties WHERE Name=N'Computer Science')),
    (N'Mechanical Engineering', 30000, (SELECT Id FROM Faculties WHERE Name=N'Engineering')),
    (N'Applied Mathematics',    25000, (SELECT Id FROM Faculties WHERE Name=N'Mathematics'));

INSERT INTO Teachers (Name, Surname, Salary, Premium, DepartmentId) VALUES
    (N'Dave',   N'McQueen',   1500, 300, (SELECT Id FROM Departments WHERE Name=N'Software Development')),
    (N'Jack',   N'Underhill', 1700, 400, (SELECT Id FROM Departments WHERE Name=N'Software Development')),
    (N'Anna',   N'Smith',     1600, 350, (SELECT Id FROM Departments WHERE Name=N'Data Science')),
    (N'Emily',  N'Clark',     1550, 300, (SELECT Id FROM Departments WHERE Name=N'Data Science')),
    (N'Robert', N'Brown',     1400, 200, (SELECT Id FROM Departments WHERE Name=N'Cybersecurity')),
    (N'John',   N'Davis',     1250, 150, (SELECT Id FROM Departments WHERE Name=N'Mechanical Engineering')),
    (N'Maria',  N'Garcia',    1300, 250, (SELECT Id FROM Departments WHERE Name=N'Applied Mathematics'));

INSERT INTO Groups (Name, Year, Rating, DepartmentId) VALUES
    (N'SD-101', 2, 80, (SELECT Id FROM Departments WHERE Name=N'Software Development')),
    (N'SD-102', 2, 75, (SELECT Id FROM Departments WHERE Name=N'Software Development')),
    (N'DS-201', 3, 90, (SELECT Id FROM Departments WHERE Name=N'Data Science')),
    (N'CY-301', 1, 60, (SELECT Id FROM Departments WHERE Name=N'Cybersecurity')),
    (N'AM-101', 1, 70, (SELECT Id FROM Departments WHERE Name=N'Applied Mathematics'));

-- Студенты: в группах разное количество (для запроса 7 MIN/MAX)
INSERT INTO Students (Name, Surname, GroupId) VALUES
    (N'Alice',   N'Johnson', (SELECT Id FROM Groups WHERE Name=N'SD-101')),
    (N'Bob',     N'Williams',(SELECT Id FROM Groups WHERE Name=N'SD-101')),
    (N'Carol',   N'Jones',   (SELECT Id FROM Groups WHERE Name=N'SD-101')),
    (N'Daniel',  N'Miller',  (SELECT Id FROM Groups WHERE Name=N'SD-101')),
    (N'Eve',     N'Wilson',  (SELECT Id FROM Groups WHERE Name=N'SD-102')),
    (N'Frank',   N'Moore',   (SELECT Id FROM Groups WHERE Name=N'SD-102')),
    (N'Grace',   N'Taylor',  (SELECT Id FROM Groups WHERE Name=N'DS-201')),
    (N'Henry',   N'Anderson',(SELECT Id FROM Groups WHERE Name=N'DS-201')),
    (N'Ivy',     N'Thomas',  (SELECT Id FROM Groups WHERE Name=N'DS-201')),
    (N'Jake',    N'Jackson', (SELECT Id FROM Groups WHERE Name=N'CY-301')),
    (N'Kate',    N'White',   (SELECT Id FROM Groups WHERE Name=N'CY-301')),
    (N'Liam',    N'Harris',  (SELECT Id FROM Groups WHERE Name=N'AM-101'));

INSERT INTO Subjects (Name) VALUES
    (N'Databases'),
    (N'Web Development'),
    (N'Algorithms'),
    (N'Machine Learning'),
    (N'Networks'),
    (N'Calculus'),
    (N'Operating Systems');

-- Лекции: предмет, преподаватель, аудитория, день недели
INSERT INTO Lectures (SubjectId, TeacherId, LectureRoom, DayOfWeek) VALUES
    ((SELECT Id FROM Subjects WHERE Name=N'Databases'),        (SELECT Id FROM Teachers WHERE Surname=N'McQueen'),   N'D201', 1),
    ((SELECT Id FROM Subjects WHERE Name=N'Databases'),        (SELECT Id FROM Teachers WHERE Surname=N'McQueen'),   N'D201', 3),
    ((SELECT Id FROM Subjects WHERE Name=N'Algorithms'),       (SELECT Id FROM Teachers WHERE Surname=N'McQueen'),   N'A101', 2),
    ((SELECT Id FROM Subjects WHERE Name=N'Web Development'),   (SELECT Id FROM Teachers WHERE Surname=N'Underhill'), N'D201', 1),
    ((SELECT Id FROM Subjects WHERE Name=N'Web Development'),   (SELECT Id FROM Teachers WHERE Surname=N'Underhill'), N'B202', 4),
    ((SELECT Id FROM Subjects WHERE Name=N'Algorithms'),       (SELECT Id FROM Teachers WHERE Surname=N'Underhill'), N'D201', 2),
    ((SELECT Id FROM Subjects WHERE Name=N'Machine Learning'), (SELECT Id FROM Teachers WHERE Surname=N'Smith'),     N'A101', 2),
    ((SELECT Id FROM Subjects WHERE Name=N'Machine Learning'), (SELECT Id FROM Teachers WHERE Surname=N'Smith'),     N'A101', 5),
    ((SELECT Id FROM Subjects WHERE Name=N'Machine Learning'), (SELECT Id FROM Teachers WHERE Surname=N'Clark'),     N'A101', 5),
    ((SELECT Id FROM Subjects WHERE Name=N'Networks'),         (SELECT Id FROM Teachers WHERE Surname=N'Brown'),     N'C303', 3),
    ((SELECT Id FROM Subjects WHERE Name=N'Operating Systems'),(SELECT Id FROM Teachers WHERE Surname=N'Davis'),     N'C303', 4),
    ((SELECT Id FROM Subjects WHERE Name=N'Calculus'),         (SELECT Id FROM Teachers WHERE Surname=N'Garcia'),    N'B202', 1);
GO

-- Связь «группа ↔ лекция»: какие группы посещают какую лекцию.
-- Лекции пронумерованы по порядку вставки (Id = 1..12).
INSERT INTO GroupsLectures (GroupId, LectureId) VALUES
    ((SELECT Id FROM Groups WHERE Name=N'SD-101'), 1),
    ((SELECT Id FROM Groups WHERE Name=N'SD-102'), 1),
    ((SELECT Id FROM Groups WHERE Name=N'SD-101'), 2),
    ((SELECT Id FROM Groups WHERE Name=N'SD-101'), 3),
    ((SELECT Id FROM Groups WHERE Name=N'SD-101'), 4),   -- лекция Underhill
    ((SELECT Id FROM Groups WHERE Name=N'DS-201'), 4),   -- лекция Underhill
    ((SELECT Id FROM Groups WHERE Name=N'SD-102'), 5),   -- лекция Underhill
    ((SELECT Id FROM Groups WHERE Name=N'CY-301'), 6),   -- лекция Underhill
    ((SELECT Id FROM Groups WHERE Name=N'DS-201'), 7),
    ((SELECT Id FROM Groups WHERE Name=N'DS-201'), 8),
    ((SELECT Id FROM Groups WHERE Name=N'DS-201'), 9),
    ((SELECT Id FROM Groups WHERE Name=N'CY-301'), 10),
    ((SELECT Id FROM Groups WHERE Name=N'AM-101'), 12);
GO

/* =====================================================================
   3. ЗАПРОСЫ (агрегатные функции)
   ===================================================================== */

-- 1. Количество преподавателей кафедры «Software Development»
SELECT COUNT(*) AS TeachersCount
FROM Teachers t
JOIN Departments d ON d.Id = t.DepartmentId
WHERE d.Name = N'Software Development';

-- 2. Количество лекций, которые читает преподаватель «Dave McQueen»
SELECT COUNT(*) AS LecturesCount
FROM Lectures l
JOIN Teachers t ON t.Id = l.TeacherId
WHERE t.Name = N'Dave' AND t.Surname = N'McQueen';

-- 3. Количество занятий, проводимых в аудитории «D201»
SELECT COUNT(*) AS ClassesInD201
FROM Lectures
WHERE LectureRoom = N'D201';

-- 4. Названия аудиторий и количество лекций, проводимых в них
SELECT LectureRoom, COUNT(*) AS LecturesCount
FROM Lectures
GROUP BY LectureRoom;

-- 5. Количество студентов, посещающих лекции преподавателя «Jack Underhill»
SELECT COUNT(DISTINCT s.Id) AS StudentsCount
FROM Students s
JOIN GroupsLectures gl ON gl.GroupId = s.GroupId
JOIN Lectures l        ON l.Id = gl.LectureId
JOIN Teachers t        ON t.Id = l.TeacherId
WHERE t.Name = N'Jack' AND t.Surname = N'Underhill';

-- 6. Средняя ставка преподавателей факультета «Computer Science»
SELECT AVG(t.Salary) AS AvgSalary
FROM Teachers t
JOIN Departments d ON d.Id = t.DepartmentId
JOIN Faculties f   ON f.Id = d.FacultyId
WHERE f.Name = N'Computer Science';

-- 7. Минимальное и максимальное количество студентов среди всех групп
SELECT MIN(cnt) AS MinStudents, MAX(cnt) AS MaxStudents
FROM (
    SELECT COUNT(*) AS cnt
    FROM Students
    GROUP BY GroupId
) AS g;

-- 8. Средний фонд финансирования кафедр
SELECT AVG(Financing) AS AvgFinancing
FROM Departments;

-- 9. Полные имена преподавателей и количество читаемых ими дисциплин
SELECT t.Name + N' ' + t.Surname AS Teacher,
       COUNT(DISTINCT l.SubjectId) AS SubjectsCount
FROM Teachers t
LEFT JOIN Lectures l ON l.TeacherId = t.Id
GROUP BY t.Id, t.Name, t.Surname;

-- 10. Количество лекций в каждый день недели
SELECT DayOfWeek, COUNT(*) AS LecturesCount
FROM Lectures
GROUP BY DayOfWeek
ORDER BY DayOfWeek;

-- 11. Номера аудиторий и количество кафедр, чьи лекции в них читаются
SELECT l.LectureRoom,
       COUNT(DISTINCT t.DepartmentId) AS DepartmentsCount
FROM Lectures l
JOIN Teachers t ON t.Id = l.TeacherId
GROUP BY l.LectureRoom;

-- 12. Названия факультетов и количество дисциплин, которые на них читаются
SELECT f.Name AS Faculty,
       COUNT(DISTINCT l.SubjectId) AS SubjectsCount
FROM Faculties f
JOIN Departments d ON d.FacultyId = f.Id
JOIN Teachers t    ON t.DepartmentId = d.Id
JOIN Lectures l    ON l.TeacherId = t.Id
GROUP BY f.Id, f.Name;

-- 13. Количество лекций для каждой пары «преподаватель — аудитория»
SELECT t.Name + N' ' + t.Surname AS Teacher,
       l.LectureRoom,
       COUNT(*) AS LecturesCount
FROM Lectures l
JOIN Teachers t ON t.Id = l.TeacherId
GROUP BY t.Id, t.Name, t.Surname, l.LectureRoom
ORDER BY Teacher, l.LectureRoom;
GO
