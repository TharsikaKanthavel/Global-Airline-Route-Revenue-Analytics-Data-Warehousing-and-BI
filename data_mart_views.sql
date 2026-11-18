-- =============================================================================
-- IT3101 - Data Warehousing & Business Intelligence (DWBI)
-- Task 6: Departmental Data Mart Implementation (SQL Server T-SQL Compatible)
-- Data Mart: Route Profitability & Commercial Revenue Management Data Mart
-- =============================================================================

USE Airline_DW;
GO

-- View 1: Annual Route Profitability & Margin Ranking
DROP VIEW IF EXISTS DM_Route_Profitability_Summary;
GO

CREATE VIEW DM_Route_Profitability_Summary AS
SELECT 
    d.Year,
    r.Route_Code,
    r.Route_Name,
    r.Corridor_Region,
    r.Route_Category,
    r.Distance_KM,
    orig.City AS Origin_City,
    orig.Country AS Origin_Country,
    dest.City AS Destination_City,
    dest.Country AS Destination_Country,
    f.Annual_Revenue_USD_M,
    f.Operating_Cost_USD_M,
    f.Net_Profit_USD_M,
    f.Profit_Margin_PCT,
    f.Annual_Passengers_M,
    f.Avg_Fare_USD,
    f.Weekly_Frequency_Est,
    ROUND((f.Annual_Revenue_USD_M * 1000000.0) / NULLIF(f.Annual_Passengers_M * 1000000.0, 0), 2) AS Derived_Yield_Per_Pax,
    CASE 
        WHEN f.Profit_Margin_PCT >= 15.0 THEN 'High Margin Star'
        WHEN f.Profit_Margin_PCT >= 5.0  THEN 'Stable Contributor'
        WHEN f.Profit_Margin_PCT >= 0.0  THEN 'Low Margin Volume'
        ELSE 'Loss Making / Under Review'
    END AS Route_Performance_Tier
FROM Fact_Route_Performance f
JOIN Dim_Date d ON f.Date_Key = d.Date_Key
JOIN Dim_Route r ON f.Route_Key = r.Route_Key
JOIN Dim_Airport orig ON f.Origin_Airport_Key = orig.Airport_Key
JOIN Dim_Airport dest ON f.Destination_Airport_Key = dest.Airport_Key;
GO


-- View 2: Regional Corridor Performance Mart
DROP VIEW IF EXISTS DM_Regional_Corridor_Performance;
GO

CREATE VIEW DM_Regional_Corridor_Performance AS
SELECT 
    d.Year,
    r.Corridor_Region,
    COUNT(DISTINCT r.Route_Key) AS Total_Active_Routes,
    ROUND(SUM(f.Annual_Revenue_USD_M), 2) AS Regional_Revenue_USD_M,
    ROUND(SUM(f.Operating_Cost_USD_M), 2) AS Regional_Operating_Cost_USD_M,
    ROUND(SUM(f.Net_Profit_USD_M), 2) AS Regional_Net_Profit_USD_M,
    ROUND((SUM(f.Net_Profit_USD_M) / NULLIF(SUM(f.Annual_Revenue_USD_M), 0)) * 100.0, 2) AS Weighted_Regional_Margin_PCT,
    ROUND(SUM(f.Annual_Passengers_M), 2) AS Total_Regional_Passengers_M,
    ROUND(AVG(f.Avg_Fare_USD), 2) AS Avg_Regional_Ticket_Fare_USD
FROM Fact_Route_Performance f
JOIN Dim_Date d ON f.Date_Key = d.Date_Key
JOIN Dim_Route r ON f.Route_Key = r.Route_Key
GROUP BY d.Year, r.Corridor_Region;
GO


-- View 3: Underperforming Routes Watchlist
DROP VIEW IF EXISTS DM_Underperforming_Routes_Watchlist;
GO

CREATE VIEW DM_Underperforming_Routes_Watchlist AS
SELECT 
    d.Year,
    r.Route_Code,
    r.Route_Name,
    r.Corridor_Region,
    f.Annual_Revenue_USD_M,
    f.Operating_Cost_USD_M,
    f.Net_Profit_USD_M,
    f.Profit_Margin_PCT,
    f.Annual_Passengers_M,
    f.Avg_Fare_USD
FROM Fact_Route_Performance f
JOIN Dim_Date d ON f.Date_Key = d.Date_Key
JOIN Dim_Route r ON f.Route_Key = r.Route_Key
WHERE f.Net_Profit_USD_M < 0 OR f.Profit_Margin_PCT < 2.0;
GO


-- View 4: Aircraft Fleet Operational Efficiency Mart
DROP VIEW IF EXISTS DM_Aircraft_Fleet_Efficiency;
GO

CREATE VIEW DM_Aircraft_Fleet_Efficiency AS
SELECT 
    ac.Manufacturer,
    ac.Aircraft_Model_Name,
    ac.Body_Type,
    COUNT(f.Flight_Fact_ID) AS Total_Flights_Operated,
    ROUND(AVG(f.Load_Factor) * 100.0, 2) AS Avg_Load_Factor_PCT,
    ROUND(SUM(f.Total_Revenue), 2) AS Total_Fleet_Revenue,
    ROUND(SUM(f.Total_Cost), 2) AS Total_Fleet_Cost,
    ROUND(SUM(f.Profit), 2) AS Total_Fleet_Net_Profit,
    ROUND((SUM(f.Profit) / NULLIF(SUM(f.Total_Revenue), 0)) * 100.0, 2) AS Fleet_Profit_Margin_PCT,
    ROUND(SUM(f.Fuel_Cost), 2) AS Total_Fuel_Expense,
    ROUND((SUM(f.Fuel_Cost) / NULLIF(SUM(f.Total_Cost), 0)) * 100.0, 2) AS Fuel_Cost_Share_PCT
FROM Fact_Flight_Operations f
JOIN Dim_Aircraft ac ON f.Aircraft_Key = ac.Aircraft_Key
GROUP BY ac.Manufacturer, ac.Aircraft_Model_Name, ac.Body_Type;
GO
