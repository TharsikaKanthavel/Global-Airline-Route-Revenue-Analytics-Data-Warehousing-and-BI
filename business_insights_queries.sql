-- =============================================================================
-- IT3101 - Data Warehousing & Business Intelligence (DWBI)
-- Project: Global Airline Route & Revenue Analytics Solution (2010-2026)
-- File: business_insights_queries.sql
-- Description: Complete 20-Query Enterprise Analytical Suite covering Macro
--              Route Trends, Micro Flight Cost Drivers, Fleet Economics,
--              Ancillary Revenues, and Seasonal Pricing Elasticity.
-- =============================================================================

USE Airline_DW;
GO

PRINT '======================================================================';
PRINT '      AIRLINE DATA WAREHOUSE: 20 ENTERPRISE BUSINESS INSIGHTS SUITE   ';
PRINT '======================================================================';
GO

-- =============================================================================
-- PART 1: ROUTE NETWORK & FINANCIAL MACRO INSIGHTS (QUERIES 1 - 10)
-- =============================================================================

-- INSIGHT 1: TOP 10 REVENUE & PROFIT GENERATING "GOLDEN CORRIDORS" (2024-2026)
SELECT TOP 10
    r.Route_Code,
    r.Route_Name,
    r.Corridor_Region,
    r.Route_Category,
    ROUND(SUM(f.Annual_Revenue_USD_M), 2) AS Total_Revenue_USD_M,
    ROUND(SUM(f.Operating_Cost_USD_M), 2) AS Total_Cost_USD_M,
    ROUND(SUM(f.Net_Profit_USD_M), 2) AS Total_Profit_USD_M,
    ROUND((SUM(f.Net_Profit_USD_M) / NULLIF(SUM(f.Annual_Revenue_USD_M), 0)) * 100.0, 2) AS Overall_Margin_PCT,
    ROUND(SUM(f.Annual_Passengers_M), 2) AS Total_Passengers_M,
    ROUND(AVG(f.Avg_Fare_USD), 2) AS Avg_Ticket_Fare_USD
FROM Fact_Route_Performance f
JOIN Dim_Route r ON f.Route_Key = r.Route_Key
JOIN Dim_Date d ON f.Date_Key = d.Date_Key
WHERE d.Year >= 2024
GROUP BY r.Route_Code, r.Route_Name, r.Corridor_Region, r.Route_Category
ORDER BY Total_Profit_USD_M DESC;
GO

-- INSIGHT 2: REGIONAL PROFITABILITY & MARGIN HIERARCHY
SELECT 
    r.Corridor_Region,
    COUNT(DISTINCT r.Route_Key) AS Active_Corridors_Count,
    ROUND(SUM(f.Annual_Revenue_USD_M), 2) AS Regional_Revenue_M,
    ROUND(SUM(f.Net_Profit_USD_M), 2) AS Regional_Profit_M,
    ROUND((SUM(f.Net_Profit_USD_M) / NULLIF(SUM(f.Annual_Revenue_USD_M), 0)) * 100.0, 2) AS Weighted_Margin_PCT,
    ROUND(SUM(f.Annual_Passengers_M), 2) AS Total_Regional_Pax_M,
    ROUND(AVG(f.Avg_Fare_USD), 2) AS Avg_Regional_Fare_USD
FROM Fact_Route_Performance f
JOIN Dim_Route r ON f.Route_Key = r.Route_Key
GROUP BY r.Corridor_Region
ORDER BY Regional_Revenue_M DESC;
GO

-- INSIGHT 3: 11-YEAR HISTORICAL RECOVERY & EXPANSION TRAJECTORY (2015-2026)
SELECT 
    d.Year,
    ROUND(SUM(f.Annual_Revenue_USD_M), 2) AS Global_Revenue_USD_M,
    ROUND(SUM(f.Operating_Cost_USD_M), 2) AS Global_Cost_USD_M,
    ROUND(SUM(f.Net_Profit_USD_M), 2) AS Global_Net_Profit_USD_M,
    ROUND((SUM(f.Net_Profit_USD_M) / NULLIF(SUM(f.Annual_Revenue_USD_M), 0)) * 100.0, 2) AS Systemwide_Margin_PCT,
    ROUND(SUM(f.Annual_Passengers_M), 2) AS Total_Passengers_M,
    ROUND(AVG(f.Avg_Fare_USD), 2) AS Avg_Ticket_Fare_USD
FROM Fact_Route_Performance f
JOIN Dim_Date d ON f.Date_Key = d.Date_Key
GROUP BY d.Year
ORDER BY d.Year ASC;
GO

-- INSIGHT 4: ROUTE HAUL CATEGORY ECONOMICS (SHORT vs MEDIUM vs LONG HAUL)
SELECT 
    r.Route_Category,
    COUNT(DISTINCT r.Route_Key) AS Number_Of_Corridors,
    ROUND(AVG(r.Distance_KM), 0) AS Avg_Distance_KM,
    ROUND(SUM(f.Annual_Revenue_USD_M), 2) AS Total_Revenue_M,
    ROUND(SUM(f.Net_Profit_USD_M), 2) AS Total_Profit_M,
    ROUND((SUM(f.Net_Profit_USD_M) / NULLIF(SUM(f.Annual_Revenue_USD_M), 0)) * 100.0, 2) AS Category_Profit_Margin_PCT,
    ROUND(SUM(f.Annual_Passengers_M), 2) AS Total_Passengers_M,
    ROUND(AVG(f.Avg_Fare_USD), 2) AS Avg_Fare_USD
FROM Fact_Route_Performance f
JOIN Dim_Route r ON f.Route_Key = r.Route_Key
GROUP BY r.Route_Category
ORDER BY Total_Revenue_M DESC;
GO

-- INSIGHT 5: FARE INELASTICITY AUDIT (FARE INCREASES vs PASSENGER DEMAND)
SELECT 
    d.Year,
    ROUND(AVG(f.Avg_Fare_USD), 2) AS Avg_Fare_USD,
    ROUND(SUM(f.Annual_Passengers_M), 2) AS Total_Passengers_M,
    ROUND(SUM(f.Annual_Revenue_USD_M), 2) AS Total_Revenue_M,
    ROUND(AVG(f.Weekly_Frequency_Est), 1) AS Avg_Weekly_Frequency
FROM Fact_Route_Performance f
JOIN Dim_Date d ON f.Date_Key = d.Date_Key
WHERE d.Year IN (2018, 2019, 2021, 2023, 2024, 2025, 2026)
GROUP BY d.Year
ORDER BY d.Year ASC;
GO

-- INSIGHT 6: UNDERPERFORMING & VULNERABLE ROUTES EARLY WARNING WATCHLIST
-- Business Value: Pinpoints corridors with historical losses or lowest current margins (<= 5.0%).
SELECT TOP 15
    Year,
    Route_Code,
    Route_Name,
    Corridor_Region,
    Annual_Revenue_USD_M,
    Operating_Cost_USD_M,
    Net_Profit_USD_M,
    Profit_Margin_PCT,
    Route_Performance_Tier
FROM DM_Route_Profitability_Summary
WHERE Net_Profit_USD_M < 0 OR Profit_Margin_PCT <= 5.0
ORDER BY Profit_Margin_PCT ASC, Year DESC;
GO

-- INSIGHT 7: FLIGHT FREQUENCY LEVERAGE & UNIT ECONOMICS
SELECT 
    CASE 
        WHEN Weekly_Frequency_Est >= 25 THEN 'High Frequency (25+ flights/wk)'
        WHEN Weekly_Frequency_Est >= 15 THEN 'Medium Frequency (15-24 flights/wk)'
        ELSE 'Low Frequency (< 15 flights/wk)'
    END AS Frequency_Tier,
    COUNT(Performance_Fact_ID) AS Total_Route_Observations,
    ROUND(AVG(Annual_Revenue_USD_M), 2) AS Avg_Annual_Revenue_M,
    ROUND(AVG(Net_Profit_USD_M), 2) AS Avg_Annual_Profit_M,
    ROUND(AVG(Profit_Margin_PCT), 2) AS Avg_Profit_Margin_PCT,
    ROUND(AVG(Avg_Fare_USD), 2) AS Avg_Fare_USD
FROM Fact_Route_Performance
GROUP BY 
    CASE 
        WHEN Weekly_Frequency_Est >= 25 THEN 'High Frequency (25+ flights/wk)'
        WHEN Weekly_Frequency_Est >= 15 THEN 'Medium Frequency (15-24 flights/wk)'
        ELSE 'Low Frequency (< 15 flights/wk)'
    END
ORDER BY Avg_Annual_Profit_M DESC;
GO

-- INSIGHT 8: TOP ORIGIN AIRPORT HUBS BY GENERATED OUTBOUND REVENUE
SELECT TOP 10
    orig.IATA_Code AS Origin_Airport,
    orig.Airport_Name,
    orig.City,
    orig.Country,
    orig.Global_Region,
    ROUND(SUM(f.Annual_Revenue_USD_M), 2) AS Total_Outbound_Revenue_M,
    ROUND(SUM(f.Net_Profit_USD_M), 2) AS Total_Outbound_Profit_M,
    ROUND(SUM(f.Annual_Passengers_M), 2) AS Total_Departing_Pax_M
FROM Fact_Route_Performance f
JOIN Dim_Airport orig ON f.Origin_Airport_Key = orig.Airport_Key
GROUP BY orig.IATA_Code, orig.Airport_Name, orig.City, orig.Country, orig.Global_Region
ORDER BY Total_Outbound_Revenue_M DESC;
GO

-- INSIGHT 9: ROUTE PERFORMANCE TIER DISTRIBUTION (PORTFOLIO HEALTH)
SELECT 
    Route_Performance_Tier,
    COUNT(*) AS Corridors_Count,
    ROUND((COUNT(*) * 100.0) / (SELECT COUNT(*) FROM DM_Route_Profitability_Summary), 2) AS Portfolio_Share_PCT,
    ROUND(SUM(Annual_Revenue_USD_M), 2) AS Total_Tier_Revenue_M,
    ROUND(SUM(Net_Profit_USD_M), 2) AS Total_Tier_Profit_M,
    ROUND(AVG(Profit_Margin_PCT), 2) AS Avg_Tier_Margin_PCT
FROM DM_Route_Profitability_Summary
GROUP BY Route_Performance_Tier
ORDER BY Total_Tier_Profit_M DESC;
GO

-- INSIGHT 10: 2026 FUTURE EXPANSION FORECAST SUMMARY
SELECT 
    r.Corridor_Region,
    COUNT(DISTINCT r.Route_Key) AS Active_Corridors_2026,
    ROUND(SUM(f.Annual_Revenue_USD_M), 2) AS Projected_Revenue_2026_M,
    ROUND(SUM(f.Net_Profit_USD_M), 2) AS Projected_Profit_2026_M,
    ROUND((SUM(f.Net_Profit_USD_M) / NULLIF(SUM(f.Annual_Revenue_USD_M), 0)) * 100.0, 2) AS Projected_Margin_2026_PCT,
    ROUND(SUM(f.Annual_Passengers_M), 2) AS Projected_Pax_2026_M
FROM Fact_Route_Performance f
JOIN Dim_Route r ON f.Route_Key = r.Route_Key
JOIN Dim_Date d ON f.Date_Key = d.Date_Key
WHERE d.Year = 2026
GROUP BY r.Corridor_Region
ORDER BY Projected_Profit_2026_M DESC;
GO


-- =============================================================================
-- PART 2: ADVANCED OPERATIONAL, FLEET & ANCILLARY INSIGHTS (QUERIES 11 - 20)
-- =============================================================================

-- INSIGHT 11: ANCILLARY REVENUE CONTRIBUTION (BAGGAGE, SEATS, ONBOARD RETAIL)
-- Evaluates the percentage of revenue generated by ancillary sales.
SELECT 
    d.Year,
    ROUND(SUM(f.Ticket_Revenue), 2) AS Total_Ticket_Revenue,
    ROUND(SUM(f.Ancillary_Revenue), 2) AS Total_Ancillary_Revenue,
    ROUND(SUM(f.Total_Revenue), 2) AS Gross_Revenue,
    ROUND((SUM(f.Ancillary_Revenue) / NULLIF(SUM(f.Total_Revenue), 0)) * 100.0, 2) AS Ancillary_Revenue_Share_PCT
FROM Fact_Flight_Operations f
JOIN Dim_Date d ON f.Date_Key = d.Date_Key
GROUP BY d.Year;
GO

-- INSIGHT 12: BREAK-EVEN SEAT LOAD FACTOR ANALYSIS
-- Determines at what seat occupancy percentage flights cross into net profitability.
SELECT 
    CASE 
        WHEN Load_Factor >= 0.90 THEN '90% - 100% (High Utilization)'
        WHEN Load_Factor >= 0.80 THEN '80% - 89% (Optimal Band)'
        WHEN Load_Factor >= 0.70 THEN '70% - 79% (Break-Even Frontier)'
        ELSE 'Under 70% (Loss Territory)'
    END AS Load_Factor_Tier,
    COUNT(Flight_Fact_ID) AS Total_Flights,
    ROUND(AVG(Load_Factor) * 100.0, 2) AS Avg_Load_Factor_PCT,
    ROUND(SUM(Total_Revenue), 2) AS Revenue,
    ROUND(SUM(Total_Cost), 2) AS Cost,
    ROUND(SUM(Profit), 2) AS Net_Profit,
    ROUND((SUM(Profit) / NULLIF(SUM(Total_Revenue), 0)) * 100.0, 2) AS Margin_PCT
FROM Fact_Flight_Operations
GROUP BY 
    CASE 
        WHEN Load_Factor >= 0.90 THEN '90% - 100% (High Utilization)'
        WHEN Load_Factor >= 0.80 THEN '80% - 89% (Optimal Band)'
        WHEN Load_Factor >= 0.70 THEN '70% - 79% (Break-Even Frontier)'
        ELSE 'Under 70% (Loss Territory)'
    END
ORDER BY Margin_PCT DESC;
GO

-- INSIGHT 13: FUEL BURN VS OPERATING EXPENSE SHARE ACROSS AIRCRAFT FLEET
-- Evaluates how fuel volatility hits different aircraft families.
SELECT 
    ac.Manufacturer,
    ac.Aircraft_Model_Name,
    ac.Body_Type,
    ac.Typical_Seating_Capacity,
    COUNT(f.Flight_Fact_ID) AS Total_Legs_Flown,
    ROUND(AVG(f.Fuel_Cost), 2) AS Avg_Fuel_Cost_Per_Flight,
    ROUND(AVG(f.Total_Cost), 2) AS Avg_Total_Cost_Per_Flight,
    ROUND((SUM(f.Fuel_Cost) / NULLIF(SUM(f.Total_Cost), 0)) * 100.0, 2) AS Fuel_Expense_Share_PCT
FROM Fact_Flight_Operations f
JOIN Dim_Aircraft ac ON f.Aircraft_Key = ac.Aircraft_Key
GROUP BY ac.Manufacturer, ac.Aircraft_Model_Name, ac.Body_Type, ac.Typical_Seating_Capacity
ORDER BY Fuel_Expense_Share_PCT DESC;
GO

-- INSIGHT 14: SEASONAL VOLATILITY ANALYSIS (PEAK vs SHOULDER vs LOW SEASONS)
-- Compares ticket yields and load factors across seasonal travel waves.
SELECT 
    d.Peak_Season_Flag AS Travel_Season,
    COUNT(f.Flight_Fact_ID) AS Total_Flights,
    ROUND(AVG(f.Load_Factor) * 100.0, 2) AS Avg_Seat_Occupancy_PCT,
    ROUND(AVG(f.Ticket_Revenue), 2) AS Avg_Ticket_Revenue_Per_Flight,
    ROUND(AVG(f.Ancillary_Revenue), 2) AS Avg_Ancillary_Per_Flight,
    ROUND(SUM(f.Profit), 2) AS Total_Seasonal_Profit,
    ROUND((SUM(f.Profit) / NULLIF(SUM(f.Total_Revenue), 0)) * 100.0, 2) AS Seasonal_Margin_PCT
FROM Fact_Flight_Operations f
JOIN Dim_Date d ON f.Date_Key = d.Date_Key
GROUP BY d.Peak_Season_Flag
ORDER BY Total_Seasonal_Profit DESC;
GO

-- INSIGHT 15: AIRPORT LANDING, GATE & NAVIGATION FEES BURDEN
-- Quantifies which operational hubs impose the highest third-party airport charges.
SELECT TOP 10
    dest.IATA_Code AS Destination_Hub,
    dest.Airport_Name,
    dest.City,
    dest.Country,
    COUNT(f.Flight_Fact_ID) AS Inbound_Flights,
    ROUND(SUM(f.Airport_Fees), 2) AS Total_Landing_Fees_Paid,
    ROUND(SUM(f.Handling_Cost), 2) AS Total_Ground_Handling_Paid,
    ROUND(AVG(f.Airport_Fees), 2) AS Avg_Fee_Per_Landing
FROM Fact_Flight_Operations f
JOIN Dim_Airport dest ON f.Destination_Airport_Key = dest.Airport_Key
GROUP BY dest.IATA_Code, dest.Airport_Name, dest.City, dest.Country
ORDER BY Total_Landing_Fees_Paid DESC;
GO

-- INSIGHT 16: WEEKEND VS WEEKDAY DEMAND & YIELD DYNAMICS
-- Compares business weekday travelers against leisure weekend travelers.
SELECT 
    CASE WHEN d.Is_Weekend = 'Y' THEN 'Weekend (Leisure / Family)' ELSE 'Weekday (Corporate / Business)' END AS Travel_Category,
    COUNT(f.Flight_Fact_ID) AS Flights_Operated,
    ROUND(AVG(f.Load_Factor) * 100.0, 2) AS Avg_Load_Factor_PCT,
    ROUND(AVG(f.Total_Revenue), 2) AS Avg_Revenue_Per_Leg,
    ROUND(AVG(f.Profit), 2) AS Avg_Profit_Per_Leg,
    ROUND((SUM(f.Profit) / NULLIF(SUM(f.Total_Revenue), 0)) * 100.0, 2) AS Segment_Profit_Margin_PCT
FROM Fact_Flight_Operations f
JOIN Dim_Date d ON f.Date_Key = d.Date_Key
GROUP BY d.Is_Weekend;
GO

-- INSIGHT 17: CREW & MAINTENANCE DIRECT OPERATING EXPENSE RATIOS
-- Measures maintenance reserves and cockpit/cabin crew compensation ratios.
SELECT 
    ac.Aircraft_Family,
    ac.Body_Type,
    ROUND(SUM(f.Crew_Cost), 2) AS Total_Crew_Cost,
    ROUND(SUM(f.Maintenance_Cost), 2) AS Total_Maintenance_Cost,
    ROUND(SUM(f.Total_Cost), 2) AS Total_Operating_Cost,
    ROUND((SUM(f.Crew_Cost) / NULLIF(SUM(f.Total_Cost), 0)) * 100.0, 2) AS Crew_Cost_PCT,
    ROUND((SUM(f.Maintenance_Cost) / NULLIF(SUM(f.Total_Cost), 0)) * 100.0, 2) AS Maint_Cost_PCT
FROM Fact_Flight_Operations f
JOIN Dim_Aircraft ac ON f.Aircraft_Key = ac.Aircraft_Key
GROUP BY ac.Aircraft_Family, ac.Body_Type
ORDER BY Total_Maintenance_Cost DESC;
GO

-- INSIGHT 18: FLIGHT DURATION TIERS AND HOURLY REVENUE GENERATION
-- Analyzes revenue earned per block flight hour across duration categories.
SELECT 
    CASE 
        WHEN Flight_Hours >= 12.0 THEN 'Ultra Long (12+ hrs)'
        WHEN Flight_Hours >= 6.0  THEN 'Long Haul (6 - 11.9 hrs)'
        WHEN Flight_Hours >= 3.0  THEN 'Medium Haul (3 - 5.9 hrs)'
        ELSE 'Short Haul (< 3 hrs)'
    END AS Duration_Tier,
    COUNT(Flight_Fact_ID) AS Total_Flights,
    ROUND(AVG(Flight_Hours), 1) AS Avg_Hours_Per_Flight,
    ROUND(SUM(Total_Revenue), 2) AS Total_Revenue,
    ROUND(SUM(Total_Revenue) / NULLIF(SUM(Flight_Hours), 0), 2) AS Revenue_Per_Block_Hour_USD,
    ROUND(SUM(Profit) / NULLIF(SUM(Flight_Hours), 0), 2) AS Profit_Per_Block_Hour_USD
FROM Fact_Flight_Operations
GROUP BY 
    CASE 
        WHEN Flight_Hours >= 12.0 THEN 'Ultra Long (12+ hrs)'
        WHEN Flight_Hours >= 6.0  THEN 'Long Haul (6 - 11.9 hrs)'
        WHEN Flight_Hours >= 3.0  THEN 'Medium Haul (3 - 5.9 hrs)'
        ELSE 'Short Haul (< 3 hrs)'
    END
ORDER BY Profit_Per_Block_Hour_USD DESC;
GO

-- INSIGHT 19: REVENUE PER PASSENGER (AVERAGE YIELD SPREAD ACROSS CORRIDORS)
-- Ranks routes by pure revenue yield per individual passenger booked.
SELECT TOP 10
    Route_Code,
    Route_Name,
    Corridor_Region,
    Route_Category,
    Distance_KM,
    Annual_Revenue_USD_M,
    Annual_Passengers_M,
    Derived_Yield_Per_Pax AS Yield_Per_Passenger_USD,
    Profit_Margin_PCT
FROM DM_Route_Profitability_Summary
WHERE Year = 2026
ORDER BY Derived_Yield_Per_Pax DESC;
GO

-- INSIGHT 20: FLEET GAUGE MISMATCH & SEAT SPILLOVER/WASTE IDENTIFICATION
-- Detects flights where aircraft capacity was wasted (Load Factor < 70% and negative profit).
SELECT 
    r.Route_Code,
    r.Route_Name,
    ac.Aircraft_Model_Name,
    ac.Typical_Seating_Capacity,
    COUNT(f.Flight_Fact_ID) AS Unprofitable_Legs_Count,
    ROUND(AVG(f.Load_Factor) * 100.0, 2) AS Avg_Depressed_Load_Factor_PCT,
    ROUND(SUM(f.Profit), 2) AS Total_Operating_Loss_USD
FROM Fact_Flight_Operations f
JOIN Dim_Route r ON f.Route_Key = r.Route_Key
JOIN Dim_Aircraft ac ON f.Aircraft_Key = ac.Aircraft_Key
WHERE f.Load_Factor < 0.70 AND f.Profit < 0
GROUP BY r.Route_Code, r.Route_Name, ac.Aircraft_Model_Name, ac.Typical_Seating_Capacity
ORDER BY Total_Operating_Loss_USD ASC;
GO

PRINT '======================================================================';
PRINT 'SUCCESS: All 20 Enterprise Business Insights Executed Successfully!';
PRINT '======================================================================';
GO
