-- checking the table contents 
SELECT * FROM house_prices LIMIT 10;

-- checking how many rows of data we have
SELECT COUNT(*) FROM house_prices;

-- check the lot area average for the houses in the city
SELECT AVG(LotArea) FROM house_prices;

-- check the average price for a house in the city
SELECT AVG(SalePrice) FROM house_prices;

-- check year range of the houses sales
SELECT MIN(YrSold), MAYearX(YrSold) FROM house_prices;

-- check the details of the cheapest and the most expensive houses sold
SELECT *
FROM house_prices
WHERE SalePrice = (SELECT MIN(SalePrice) FROM house_prices);

SELECT *
FROM house_prices
WHERE SalePrice = (SELECT MAX(SalePrice) FROM house_prices);

-- finding the most expensive neighborhoods in the city
SELECT Neighborhood, AVG(SalePrice)
FROM house_prices
GROUP BY Neighborhood
ORDER BY AVG(SalePrice) DESC;

-- finding the neighborhoods with the newer houses
SELECT Neighborhood, AVG(YearBuilt)
FROM house_prices
GROUP BY Neighborhood
HAVING AVG(YearBuilt) > 1990
ORDER BY AVG(YearBuilt) DESC;





