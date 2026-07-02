USE Hospital;
GO
SET NOCOUNT ON;
GO

PRINT '═══════════════════════════════════════════════════════════════';
PRINT '  1. EXISTS (два запроса)';
PRINT '═══════════════════════════════════════════════════════════════';
GO

-- 1.1 Врачи, проводившие хотя бы одно обследование
SELECT '1.1 EXISTS' AS Query, Surname, Name
FROM Doctors d
WHERE EXISTS (
    SELECT 1
    FROM DoctorsExaminations de
    WHERE de.DoctorId = d.Id
);
GO

-- 1.2 Отделения, получавшие пожертвования от спонсора «БФ "Добро"»
SELECT '1.2 EXISTS' AS Query, Name AS DepartmentName
FROM Departments dep
WHERE EXISTS (
    SELECT 1
    FROM Donations don
    JOIN Sponsors s ON don.SponsorId = s.Id
    WHERE don.DepartmentId = dep.Id
      AND s.Name = 'БФ "Добро"'
);
GO

PRINT '═══════════════════════════════════════════════════════════════';
PRINT '  2. ANY';
PRINT '═══════════════════════════════════════════════════════════════';
GO

-- Врачи с зарплатой > любой зарплаты врачей из отделения с Id = 1
SELECT '2. ANY' AS Query, Surname, Name, Salary
FROM Doctors
WHERE Salary > ANY (
    SELECT Salary
    FROM Doctors d
    JOIN DoctorsExaminations de ON d.Id = de.DoctorId
    JOIN Wards w ON de.WardId = w.Id
    WHERE w.DepartmentId = 1
);
GO

PRINT '═══════════════════════════════════════════════════════════════';
PRINT '  3. SOME';
PRINT '═══════════════════════════════════════════════════════════════';
GO

-- Обследования, проводившиеся в палатах с количеством мест > 3
SELECT '3. SOME' AS Query, Name AS ExaminationName
FROM Examinations e
WHERE e.Id = SOME (
    SELECT ExaminationId
    FROM DoctorsExaminations de
    JOIN Wards w ON de.WardId = w.Id
    WHERE w.Places > 3
);
GO

PRINT '═══════════════════════════════════════════════════════════════';
PRINT '  4. ALL';
PRINT '═══════════════════════════════════════════════════════════════';
GO

-- Врачи с зарплатой > всех зарплат врачей из отделения с Id = 2
SELECT '4. ALL' AS Query, Surname, Name, Salary
FROM Doctors
WHERE Salary > ALL (
    SELECT Salary
    FROM Doctors d
    JOIN DoctorsExaminations de ON d.Id = de.DoctorId
    JOIN Wards w ON de.WardId = w.Id
    WHERE w.DepartmentId = 2
);
GO

PRINT '═══════════════════════════════════════════════════════════════';
PRINT '  5. ANY + ALL (совместно)';
PRINT '═══════════════════════════════════════════════════════════════';
GO

-- Суммы пожертвований, которые > минимальной и < максимальной
SELECT '5. ANY+ALL' AS Query, s.Name AS SponsorName, don.Amount
FROM Donations don
JOIN Sponsors s ON don.SponsorId = s.Id
WHERE don.Amount > ANY (SELECT Amount FROM Donations)
  AND don.Amount < ALL (SELECT Amount FROM Donations)
ORDER BY don.Amount;
GO

PRINT '═══════════════════════════════════════════════════════════════';
PRINT '  6. UNION (исправлено)';
PRINT '═══════════════════════════════════════════════════════════════';
GO

-- Уникальные названия отделений и обследований
SELECT '6. UNION' AS Query, Name AS Title FROM Departments
UNION
SELECT '6. UNION' AS Query, Name AS Title FROM Examinations  -- добавлен столбец Query
ORDER BY Title;
GO

PRINT '═══════════════════════════════════════════════════════════════';
PRINT '  7. UNION ALL (исправлено)';
PRINT '═══════════════════════════════════════════════════════════════';
GO

-- Все врачи (ФИО) и все спонсоры (названия) без удаления дубликатов
SELECT '7. UNION ALL' AS Query, Surname + ' ' + Name AS FullName FROM Doctors
UNION ALL
SELECT '7. UNION ALL' AS Query, Name AS FullName FROM Sponsors  -- добавлен столбец Query
ORDER BY FullName;
GO

PRINT '═══════════════════════════════════════════════════════════════';
PRINT '  8. JOIN: INNER, LEFT, RIGHT, LEFT+RIGHT, FULL';
PRINT '═══════════════════════════════════════════════════════════════';
GO

-- 8.1 INNER JOIN – полная информация о каждом обследовании
SELECT '8.1 INNER JOIN' AS Query,
    d.Surname + ' ' + d.Name AS Doctor,
    e.Name AS Examination,
    de.StartTime,
    de.EndTime,
    w.Name AS Ward,
    dep.Name AS Department
FROM DoctorsExaminations de
INNER JOIN Doctors d ON de.DoctorId = d.Id
INNER JOIN Examinations e ON de.ExaminationId = e.Id
INNER JOIN Wards w ON de.WardId = w.Id
INNER JOIN Departments dep ON w.DepartmentId = dep.Id
ORDER BY de.StartTime;
GO

-- 8.2 LEFT JOIN – все врачи с количеством проведённых обследований (включая 0)
SELECT '8.2 LEFT JOIN' AS Query,
    d.Surname + ' ' + d.Name AS Doctor,
    COUNT(de.Id) AS ExaminationsCount
FROM Doctors d
LEFT JOIN DoctorsExaminations de ON d.Id = de.DoctorId
GROUP BY d.Surname, d.Name
ORDER BY ExaminationsCount DESC;
GO

-- 8.3 RIGHT JOIN – все палаты с информацией об обследованиях (включая палаты без обследований)
SELECT '8.3 RIGHT JOIN' AS Query,
    w.Name AS Ward,
    dep.Name AS Department,
    e.Name AS Examination,
    de.StartTime,
    de.EndTime
FROM DoctorsExaminations de
RIGHT JOIN Wards w ON de.WardId = w.Id
LEFT JOIN Departments dep ON w.DepartmentId = dep.Id
LEFT JOIN Examinations e ON de.ExaminationId = e.Id
ORDER BY w.Name;
GO

-- 8.4 LEFT + RIGHT через UNION (исправлено)
SELECT '8.4 LEFT+RIGHT UNION' AS Query,
    d.Surname + ' ' + d.Name AS Person,
    w.Name AS Ward,
    'Doctor' AS Type
FROM Doctors d
LEFT JOIN DoctorsExaminations de ON d.Id = de.DoctorId
LEFT JOIN Wards w ON de.WardId = w.Id
UNION
SELECT '8.4 LEFT+RIGHT UNION' AS Query,   -- добавлен столбец Query
    d.Surname + ' ' + d.Name AS Person,
    w.Name AS Ward,
    'Ward' AS Type
FROM DoctorsExaminations de
RIGHT JOIN Wards w ON de.WardId = w.Id
LEFT JOIN Doctors d ON de.DoctorId = d.Id
WHERE d.Id IS NOT NULL
ORDER BY Person, Ward;
GO

-- 8.5 FULL OUTER JOIN – все пары врач–палата с отметкой о наличии обследования
SELECT '8.5 FULL OUTER JOIN' AS Query,
    d.Surname + ' ' + d.Name AS Doctor,
    w.Name AS Ward,
    CASE WHEN de.Id IS NOT NULL THEN 'Yes' ELSE 'No' END AS HasExamination
FROM Doctors d
FULL OUTER JOIN DoctorsExaminations de ON d.Id = de.DoctorId
FULL OUTER JOIN Wards w ON de.WardId = w.Id
ORDER BY Doctor, Ward;
GO

SET NOCOUNT OFF;
GO

PRINT '═══════════════════════════════════════════════════════════════';
PRINT '  Все запросы выполнены успешно.';
PRINT '═══════════════════════════════════════════════════════════════';
GO