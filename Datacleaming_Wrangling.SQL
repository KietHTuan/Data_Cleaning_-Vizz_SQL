/* Create new databse named CustomerDemo and import Customer and Geolocation tables  
   using SQL Wizard */
CREATE DATABASE CustomerDemo;
USE CustomerDemo;


--Remove unecessary columns
BEGIN transaction 
ALTER TABLE [dbo].[Customer]
DROP COLUMN CustomerAlternatekey, Title, NameStyle, Suffix, NumberChildrenAtHome, 
			HouseOwnerFlag, Addressline1, Addressline2, DateFirstPurchase
COMMIT transaction


--Check for nulls 
SELECT* FROM Customer
WHERE BirthDate is null or GeographyKey is null or MaritalStatus is null or Gender is null or 
	  TotalChildren is null or Occupation is null or CommuteDistance is null or NumberCarsOwned is null or 
	  CustomerKey is null
         /* I observe that we have 30 null values for GeographyKey. I decided to keep these records 
		    as they only impact the customer location map. Further directions from the stakeholders/dba are needed */
	

--Check for duplicates 
SELECT CustomerKey, EmailAddress, Phone, COUNT(*) AS counts
FROM [dbo].[Customer]
GROUP BY CustomerKey, EmailAddress, Phone
HAVING COUNT (*) > 1;  
				--I observe no duplicate values 


--The stakeholder wants Phone number to be without 1(11), dash '-', and space ' ' 
BEGIN transaction
UPDATE [dbo].[Customer]
SET Phone = REPLACE(REPLACE(REPLACE (Phone, '1 (11)', ''), '-', ''), ' ', '')
FROM [dbo].[Customer]
COMMIT transaction

--Now check if the phone numbers are 10 digits 
SELECT Phone FROM Customer
WHERE LEN(Phone) <> 10;
			--All good


--Add a customer Age column 
BEGIN transaction
ALTER TABLE [dbo].[Customer]
ADD  Age smallint
COMMIT transaction;

BEGIN transaction
UPDATE [dbo].[Customer]
SET Age = 2024 - Year(BirthDate); 
COMMIT transaction;

/* Add an age classification: 
                        35-50
						50-65
						65-80
						80+
*/

SELECT  MIN(Age) AS Min_Age, MAX(Age) AS Max_Age from customer 
 --Min age is 38 and max age is 108 

 BEGIN transaction 
 ALTER TABLE [dbo].[Customer]
 ADD Age_Group VARCHAR(10);
 COMMIT transaction;

 BEGIN transaction
 UPDATE [dbo].[Customer]
 SET Age_Group = CASE
	WHEN Age BETWEEN 35 AND 50 THEN '35-50'
	WHEN Age BETWEEN 50 AND 65 THEN '50-65'
	WHEN Age BETWEEN 65 AND 80 THEN '65-80'
	WHEN Age > 80 THEN '80+'
END;
COMMIT transaction;

--The stakeholder wants a full name column 
SELECT 
	Customerkey, 
	FirstName,
	MiddleName, 
	LastName,
	CONCAT (Firstname, ' ', MiddleName, ' ', LastName) AS FullName

FROM[dbo].[Customer]
ORDER BY CustomerKey

--The stakeholder also wants to extract the name from customer email domain. 
SELECT 
	Customerkey, 
	FirstName,
	MiddleName, 
	LastName,
	EmailAddress,
	REPLACE (EmailAddress, '@awari.com.au' , ' ' ) AS Email_Name

FROM[dbo].[Customer]
ORDER BY CustomerKey

--Reference the location for each customer using Geolocation table 
BEGIN transaction
ALTER TABLE [dbo].[Customer]
ADD City VARCHAR(50),
    StateProvince VARCHAR(50),
	Country VARCHAR(50)
COMMIT transaction;

BEGIN transaction
UPDATE [dbo].[Customer]
SET City = Geo.City,
	StateProvince = Geo.StateProvinceName,
	Country = Geo.CountryRegionName

FROM Customer cs INNER JOIN GeoLocation Geo ON
	cs.GeographyKey = Geo.GeographyKey;

COMMIT transaction;

--Copy the data to Excel for data visualization
SELECT
	MaritalStatus, Gender, Age_Group, Age, YearlyIncome, TotalChildren,
	NumberCarsOwned, Occupation, CommuteDistance, City, StateProvince, Country

FROM [dbo].[Customer]
ORDER BY CustomerKey

