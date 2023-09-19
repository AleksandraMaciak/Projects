
--Apartment Prices in the 15 biggest cities in Poland in Q3 2023 -  Data Exploration 
--Skills used: Joins, CTE's, Subqueries, Temp Tables, Window Functions, Aggregate Functions, Creating Views, Converting Data Types

--I've previously verified if there are no duplicates and all the values come in lowercase


-- Selecting Data that I'm going to be using 

SELECT *
FROM ApartmentsInfo

-- Checking the number of available apartments for sale in each city

SELECT 
	city, 
	COUNT(DISTINCT flatid) AS NumOfApartments
FROM ApartmentsInfo
GROUP BY city
ORDER BY NumOfApartments DESC

--Checking the average price for an apartment in each city 

SELECT 
	city, 
	AVG(CAST(price AS BIGINT)) AS AvgPrice 
FROM ApartmentsInfo
GROUP BY city
ORDER BY AvgPrice ASC


--Checking which of the avg prices calculated above are smaller than 500 000 (using CTE)

WITH CTE_AvgPrice
AS
(
SELECT 
	city, 
	AVG(CAST(price AS BIGINT)) AS AvgPrice 
FROM ApartmentsInfo
GROUP BY city
)

SELECT *
FROM CTE_AvgPrice
WHERE AvgPrice<500000

-- Checking what % of all apartments in each city costs 800 000zł or less

SELECT
	city,
	(COUNT(CASE WHEN price<= 800000 THEN 1 END) * 100.0) / (COUNT(flatid))  AS PercentageOfFlatsBelow800000
FROM ApartmentsInfo
GROUP BY city
ORDER BY PercentageOfFlatsBelow800000 DESC

-- Checking a minimum price for an apartment built in the year 2000 or after with at least 50 square meters, in each city, sorted from the cheapest one

SELECT
	city, 
	MIN(CAST(price AS INT)) AS MinPriceAfter2000
FROM ApartmentsInfo
WHERE buildYear >= 2000 and squareMeters >= 50
GROUP BY city
ORDER BY MinPriceAfter2000  ASC



-- Checking the number of apartments built in the year 2000 or after with at least 50 square meters, in each city, divided by an apartment type (for the purpose of this example we're simply not taking into consideration those with an empty cell in a 'type' column)

SELECT 
	city, 
	rooms,
	buildYear, 
	price, 
	squareMeters, 
	type, 
	COUNT(type) OVER (PARTITION BY type, city) AS NumberOfApartmentsPerType
FROM ApartmentsInfo
WHERE buildYear >= 2000 and squareMeters >= 50 and type <> ''


-- Checking the prices of apartments in Warsaw over 50 square meters, on the 2nd floor or above, with an elevator and with at least 3 rooms

SELECT 
	flatid, 
	city, 
	squareMeters,
	rooms, 
	floor,
	hasElevator, 
	CAST(price AS BIGINT) AS PriceInt
FROM ApartmentsInfo
WHERE city = 'warszawa' AND floor>=2 AND squareMeters >= 50 AND rooms>= 3 AND hasElevator = 'yes'
ORDER BY PriceInt ASC

-- Checking the prices of the flats above per square meter 

SELECT 
	flatid,
    city,	
	squareMeters,
	rooms,
	floor,
	hasElevator,
	CAST(price AS BIGINT) AS PriceInt,
	((CAST(price AS BIGINT))/(CAST(squareMeters AS BIGINT))) AS PricePerSquareMeter
FROM ApartmentsInfo
WHERE city = 'warszawa' AND floor>=2 AND squareMeters >= 50 AND rooms>= 3 AND hasElevator = 'yes'
ORDER BY PricePerSquareMeter ASC

-- Joining our second table with distances from various points based on the flatid and selecting apartments located no more than 5km from the city center and no more than 0,5 km from a kindergarten

SELECT
	ApartmentsInfo.flatid,
	city,
	CAST(squareMeters AS DECIMAL(10,2)) AS SquareMeter,
	rooms,
	floor,
	hasElevator, 
	CAST(price AS BIGINT) AS PriceInt,
	((CAST(price AS BIGINT))/(CAST(squareMeters AS BIGINT))) AS PricePerSquareMeter,
	CAST(centreDistance AS DECIMAL(10,2)) AS CentreDistance,
	CAST(kindergartenDistance AS DECIMAL(10,2)) AS KindergartenDistance
FROM ApartmentsInfo
JOIN ApartmentsDistances
ON ApartmentsInfo.flatid = ApartmentsDistances.flatid
WHERE city = 'warszawa' AND floor>=2 AND squareMeters >= 50 AND rooms>= 3 AND hasElevator = 'yes' AND (cast(centreDistance AS DECIMAL(10,2))) <= 5 AND (CAST(kindergartenDistance AS DECIMAL(10,2))) <= 0.5
ORDER BY PricePerSquareMeter ASC

-- Creating a Temp Table (based on the table obove)

CREATE TABLE #GoodLocationApartments
(
flatid int,
city nvarchar(255),
squareMeters int,
rooms int,
floor int,
PriceInt bigint, 
PricePerSquareMeter decimal(10,2),
CentreDistance decimal(10,2),
KindergartenDistance decimal(10,2)
)

-- Inserting data to the Temp Table above

INSERT INTO #GoodLocationApartments
SELECT
	CAST(ApartmentsInfo.flatid AS INT),
	city,
	CAST(squareMeters AS DECIMAL(10,2)),
	CAST(rooms AS INT),
	CAST(floor AS INT), 
	CAST(price AS BIGINT) as PriceInt,
	((CAST(price AS BIGINT))/(CAST(squareMeters AS BIGINT))) AS PricePerSquareMeter,
	CAST(centreDistance AS DECIMAL(10,2)) AS CentreDistance,
	CAST(kindergartenDistance AS DECIMAL(10,2)) AS KindergartenDistance
FROM ApartmentsInfo
JOIN ApartmentsDistances
ON ApartmentsInfo.flatid = ApartmentsDistances.flatid
WHERE city = 'warszawa' AND floor>=2 AND squareMeters >= 50 AND rooms>= 3 AND hasElevator = 'yes' AND (CAST(centreDistance  AS DECIMAL(10,2)))<= 5 AND (CAST(KINDERGARTENdISTANCE AS DECIMAL(10,2)))<=0.5
ORDER BY PricePerSquareMeter ASC

--Selecting values from the Temp Table

SELECT 
	city,
	PriceInt, 
	PricePerSquareMeter, 
	CentreDistance, 
	KindergartenDistance
FROM #GoodLocationApartments
ORDER BY PricePerSquareMeter

-- Checking what percentage of the available flats in Warsaw are those that have at least 50 aquare meters with at least 3 rooms and on at least 2nd floor. I rounded it up as the exact result is 33.8%

SELECT 
	CEILING((COUNT(CASE WHEN CAST(squareMeters AS DECIMAL(10,2)) >=50 AND floor >=2 AND rooms >= 3 THEN 1 END) * 100.0) / (COUNT(flatid)))  AS PercentageOfFlats
FROM ApartmentsInfo
WHERE city = 'warszawa'


-- Creating a View to store data for visualisations 
CREATE VIEW AvgPricePerCity
AS
SELECT 
	city,
    avg(cast(price AS BIGINT)) AS AvgPrice 
FROM ApartmentsInfo
GROUP BY city

CREATE VIEW InfoDistances
AS
SELECT 
	ApartmentsInfo.flatid,
    city,
	squareMeters,
	rooms,
	floor,
	hasElevator,
	CAST(price AS BIGINT) AS PriceInt,
	((CAST(price as BIGINT))/(CAST(squareMeters AS BIGINT))) AS PricePerSquareMeter,
	CAST(centreDistance AS DECIMAL(10,2)) AS CentreDistance
FROM ApartmentsInfo
JOIN ApartmentsDistances
ON ApartmentsInfo.flatid = ApartmentsDistances.flatid


-- Getting average price per square meter from the View I've created above

SELECT 
	city,
	AVG(PricePerSquareMeter) AS AvgSquareMeter
FROM InfoDistances
GROUP BY city
ORDER BY AvgSquareMeter ASC

-- Checking the difference from the avg price of apartments in Warsaw over 50 square meters (using window function)

SELECT 
	city,
	CAST(price AS BIGINT) AS Price,
	CAST(squareMeters AS INT) as SquareMeters,
	ROUND(AVG(CAST(price AS BIGINT)) OVER(), 2) AS AvgPrice,
	ROUND((CAST(price AS BIGINT) - AVG(CAST(price AS BIGINT)) OVER()),2) AS PriceDiffFromAvg
FROM ApartmentsInfo
WHERE city = 'warszawa' and CAST(squareMeters AS INT) >= 50
ORDER BY PriceDiffFromAvg ASC

-- Giving price ranks for the apartments (from the most expensive to the cheapest one)


SELECT 
	city,
	CAST(price AS BIGINT) AS Price,
	CAST(squareMeters AS INT) AS SquareMeters,
	ROW_NUMBER() OVER(ORDER BY CAST(price AS BIGINT) DESC) AS OverallPriceRank
FROM ApartmentsInfo

-- Giving price ranks for the apartments by city

SELECT 
	city,
	CAST(price AS bigint) as Price,
	CAST(squareMeters as int) as SquareMeters,
	ROW_NUMBER() over(order by CAST(price as bigint) desc) as OverallPriceRank,
	ROW_NUMBER() over(Partition by city order by CAST(price as bigint) desc) as CityPriceRank
FROM ApartmentsInfo

-- Giving price ranks so that the same price values have the same rank positions

SELECT 
	city,
	CAST(price AS BIGINT) AS Price,
	CAST(squareMeters AS INT) AS SquareMeters,
	ROW_NUMBER() OVER (ORDER BY CAST(price as BIGINT) DESC) AS OverallPriceRank,
	RANK() OVER (ORDER BY CAST(price AS BIGINT) DESC) AS OverallPriceRankWithRank,
	ROW_NUMBER() OVER (PARTITION BY city ORDER BY CAST(price AS BIGINT) DESC) AS CityPriceRank,
	RANK() OVER (PARTITION BY city ORDER BY CAST(price AS BIGINT) DESC) AS CityRankWithRank
FROM ApartmentsInfo


-- Selecting 3 most expensive offers from each city (using case statement and subquery)

SELECT * FROM (
	SELECT 
		city,
		CAST(price AS BIGINT) as Price,
		CAST(squareMeters AS INT) AS SquareMeters,
		ROW_NUMBER() OVER(ORDER BY CAST(price AS BIGINT) DESC) AS OverallPriceRank,
		ROW_NUMBER() OVER(PARTITION BY city ORDER BY CAST(price AS BIGINT) DESC) AS CityPriceRank,
		CASE
			WHEN ROW_NUMBER() OVER(PARTITION BY city ORDER BY CAST(price AS BIGINT) DESC) <= 3 THEN 'Yes'
			ELSE 'No'
			END AS Top3Apartments
	FROM ApartmentsInfo
	) a
WHERE Top3Apartments = 'Yes'

