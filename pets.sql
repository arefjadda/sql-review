-- checking our schemas
SHOW TABLES;

SELECT * FROM owners LIMIT 10;
SELECT * FROM pets LIMIT 10;
SELECT * FROM procedures_history LIMIT 10;
SELECT * FROM procedures_details LIMIT 10;

-- checking the unique states to see if it is relevant here
SELECT DISTINCT State
FROM owners;

-- dropping the state columns since it gives no extra information (1NF normalization)
ALTER TABLE owners
DROP COLUMN State,
DROP COLUMN StateFull;

-- correct the dates datatype
ALTER TABLE procedures_history
MODIFY COLUMN Date DATE;

-- create a list all of each owner's pets for owners that their first name is 3 letters long
CREATE VIEW owners_pets_3
AS SELECT o.Name, o.Surname, GROUP_CONCAT(p.Name, ' (', p.Kind, ')')
FROM owners AS o
LEFT OUTER JOIN pets AS p
ON o.OwnerID = p.OwnerID
GROUP BY o.Name, o.Surname
HAVING o.Name like '___';

SELECT * FROM owners_pets_3;

-- getting a list of dog names that start with 'D' or 'S'
 SELECT DISTINCT Name
 FROM pets
 WHERE Kind = 'Dog' AND (Name like 'D%' OR Name like 'S%')
 ORDER BY Name;
 
 -- get the first 3 letters of each owners first and last name
 SELECT substring(Name, 1, 3), left(Surname, 3)
 FROM owners
 ORDER BY Name, Surname;
 
 -- check if the owners table has an index and set one if it doesn't
 SHOW INDEX FROM owners;
 
 CREATE UNIQUE INDEX ID
 ON owners(OwnerID);
 
 -- create a new table of the pets and all procedures they have had and create a new primary key index for it
 -- NOTE: MySQL doesn't use the select * into syntax
CREATE TABLE pet_procedures (ind INT NOT NULL AUTO_INCREMENT PRIMARY KEY)
AS SELECT p.PetID, p.Name, p.Kind, GROUP_CONCAT(' ', h.ProcedureType) AS Procedures
FROM pets AS p
LEFT OUTER JOIN procedures_history AS h
ON p.PetID = h.PetID
GROUP BY p.PetID
ORDER BY p.Name;

SELECT * FROM pet_procedures;
DESCRIBE pet_procedures; 

-- delete the rows with no procedures
DELETE FROM pet_procedures
WHERE Procedures IS NULL;

-- delete the rest of the rows and then drop the table
TRUNCATE TABLE pet_procedures;
DROP TABLE pet_procedures;

-- a table to compare pets to the average age of their kind in the records (self-join)
SELECT p.*, a.AvgKindAge
FROM pets as p
JOIN (
	SELECT Kind, AVG(Age) As AvgKindAge
	FROM pets
	GROUP BY Kind) AS a
ON p.Kind = a.Kind
ORDER BY p.Age;

-- lets create a table that shows exactly how many of each pet each owner has, 0 if none
SELECT o.Name, o.Surname, ucase(a.Kind), ifnull(b.Count, 0) AS Count
FROM owners AS o
CROSS JOIN (
	SELECT Kind
    FROM pets
    GROUP BY Kind) AS a
LEFT OUTER JOIN (
	SELECT OwnerID, Kind , COUNT(*) AS Count
    FROM pets
    GROUP BY OwnerID, Kind) AS b
ON o.OwnerID = b.OwnerID AND a.Kind = b.Kind
ORDER BY o.Name, o.Surname, a.Kind;

-- get a list of all owners present in both the owners and pets tables
-- NOTE: MySQL doesn't have the INTERSECT command
SELECT o.OwnerID 
FROM owners as o
INNER JOIN pets as p
ON o.OwnerID = p.OwnerID
LIMIT 10;

-- get a row-numbered list of procedures that happened in jan, feb and mar ordered by the date it happened
SELECT ROW_NUMBER() OVER(PARTITION BY ProcedureType ORDER BY Date) AS RowNum, ProcedureType, Date
FROM procedures_history
WHERE month(Date) = 1 OR month(Date) = 2 OR month(Date) = 3;

-- query a table of the percentages of each procedure type by month, and the percent of total procedures for each month
SET @total_procedures = 0;
SELECT COUNT(*) INTO @total_procedures
FROM procedures_history;

CREATE TEMPORARY TABLE procedures_pct AS
SELECT monthname(Date) AS Month_Name, ProcedureType,
COUNT(*) OVER (PARTITION BY monthname(Date), ProcedureType) AS ProcedureCnt,
COUNT(*) OVER (PARTITION BY monthname(Date)) AS MonthTotalProcedures,
COUNT(*) OVER (PARTITION BY monthname(Date), ProcedureType) / COUNT(*) OVER (PARTITION BY monthname(Date)) *100 AS ProcedurePct
FROM procedures_history
ORDER BY month(Date);

SELECT *, MonthTotalProcedures / @total_procedures *100 AS MonthActivityPct
FROM procedures_pct
GROUP BY Month_Name, ProcedureType;

-- query a list of all female cats and male dogs
-- NOTE: union will keep distinct values, but union all will also keep the duplicates
SELECT Name, concat(Gender, ' ', lcase(Kind)) AS Kind FROM pets WHERE Kind = "Dog" AND Gender = "male"
UNION
SELECT Name, concat(Gender, ' ', lcase(Kind)) As Kind FROM pets WHERE Kind = "Cat" AND Gender = "female"
ORDER BY Name;

-- get a list of all owners excluding owners with postal codes starting with 49 and remove the house number from the street addresses
-- NOTE: MySQL doesn't support the minus operator
SELECT Name, Surname, REGEXP_SUBSTR(StreetAddress, '\\s(.*)') AS Street, City, ZipCode  FROM owners
WHERE ZipCode NOT IN (
	SELECT ZipCode FROM owners
    WHERE ZipCode LIKE '49___');
 
 -- create a procedure that updates a table where each row is an introduction where the owners introduce themselves and call it
 DROP PROCEDURE IF EXISTS introduce;
 
 CREATE TABLE IF NOT EXISTS intros (
	Intro VARCHAR(100) UNIQUE
);
 
DELIMITER $$
 
CREATE PROCEDURE introduce()
BEGIN
	INSERT INTO intros(Intro)
	SELECT concat("Hello, my name is ", Name, " ", Surname, "and I'm from ", City, "!")
	FROM owners;
END $$

DELIMITER ;

CALL introduce();
SELECT * FROM intros;

-- create a function that determines the relative proceduredural activity (busy/not busy) and use it
DELIMITER $$

CREATE FUNCTION activity_level (pct SMALLINT(2))
RETURNS VARCHAR(10) 
DETERMINISTIC
BEGIN
	DECLARE temp VARCHAR(10);
    
    IF pct >= 10
		THEN SET temp = "BUSY";
	ELSEIF pct >= 8
		THEN SET temp = "AVERAGE";
	ELSE
		SET temp = "NOT BUSY";
	END IF;
    RETURN (temp);
END$$

DELIMITER ;

SELECT *, activity_level(round(MonthTotalProcedures / @total_procedures *100)) AS MonthActivity
FROM procedures_pct
GROUP BY Month_Name, ProcedureType;

-- update dog to doggie in the pets kind column
UPDATE pets
SET Kind = 'Doggie'
WHERE Kind = 'Dog';
