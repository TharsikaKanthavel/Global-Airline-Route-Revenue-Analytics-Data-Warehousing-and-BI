-- IT3101 - Data Warehousing & Business Intelligence (DWBI)
-- Project: Global Airline Route & Revenue Analytics Solution (2010-2026)

-- Create Database 
CREATE DATABASE Airline_DW;
GO
USE Airline_DW;
GO



-- Drop existing tables to ensure idempotent recreation
DROP TABLE IF EXISTS Fact_Flight_Operations;
DROP TABLE IF EXISTS Fact_Route_Performance;
DROP TABLE IF EXISTS Dim_Aircraft;
DROP TABLE IF EXISTS Dim_Airline;
DROP TABLE IF EXISTS Dim_Route;
DROP TABLE IF EXISTS Dim_Airport;
DROP TABLE IF EXISTS Dim_Date;

-- =============================================================================
-- 1. DIMENSION TABLES
-- =============================================================================

-- Date Dimension
CREATE TABLE Dim_Date (
    Date_Key INT NOT NULL PRIMARY KEY,            -- e.g. YYYYMMDD or Year*10000
    Full_Date DATE NOT NULL,
    Year INT NOT NULL,
    Quarter CHAR(2) NOT NULL,                     -- Q1, Q2, Q3, Q4
    Quarter_Name VARCHAR(10) NOT NULL,            -- e.g. '2024 Q1'
    Month_Number INT NOT NULL,                    -- 1 to 12
    Month_Name VARCHAR(15) NOT NULL,              -- January to December
    Day_Of_Month INT NOT NULL,
    Day_Of_Week VARCHAR(15) NOT NULL,             -- Monday to Sunday
    Is_Weekend CHAR(1) NOT NULL DEFAULT 'N',      -- 'Y' or 'N'
    Peak_Season_Flag VARCHAR(15) NOT NULL         -- 'Peak', 'Shoulder', 'Low'
);

-- Airport Dimension (Conformed, supports Role-Playing for Origin & Destination)
CREATE TABLE Dim_Airport (
    Airport_Key INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    Airport_ID INT NULL,                          -- Original OLTP Source ID
    IATA_Code VARCHAR(10) NOT NULL,               -- e.g. 'LHR', 'JFK', 'DXB'
    ICAO_Code VARCHAR(10) NULL,                   -- e.g. 'EGLL', 'KJFK', 'OMDB'
    Airport_Name VARCHAR(150) NOT NULL,
    City VARCHAR(100) NOT NULL,
    Country VARCHAR(100) NOT NULL,
    Country_ISO3 VARCHAR(10) NULL,
    Global_Region VARCHAR(50) NOT NULL,           -- e.g. 'Europe', 'North America', 'Asia'
    Latitude DECIMAL(9,6) NULL,
    Longitude DECIMAL(9,6) NULL,
    Altitude_FT INT NULL,
    Timezone_Offset DECIMAL(4,2) NULL
);

-- Route Dimension
CREATE TABLE Dim_Route (
    Route_Key INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    Route_Code VARCHAR(20) NOT NULL,              -- e.g. 'LHR-JFK', 'DXB-ORD'
    Route_Name VARCHAR(150) NOT NULL,             -- e.g. 'London to New York'
    Origin_IATA VARCHAR(10) NOT NULL,
    Destination_IATA VARCHAR(10) NOT NULL,
    Distance_KM INT NOT NULL,
    Route_Category VARCHAR(30) NOT NULL,          -- 'Long Haul', 'Medium Haul', 'Short Haul'
    Corridor_Region VARCHAR(50) NOT NULL,         -- 'North Atlantic', 'Intra-Asia', etc.
    Is_International CHAR(1) NOT NULL DEFAULT 'Y' -- 'Y' or 'N'
);

-- Airline Carrier Dimension
CREATE TABLE Dim_Airline (
    Airline_Key INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    Airline_ID INT NULL,                          -- Original OLTP Source ID
    IATA_Code VARCHAR(10) NOT NULL,               -- e.g. 'BA', 'EK', 'DL'
    ICAO_Code VARCHAR(10) NULL,                   -- e.g. 'BAW', 'UAE', 'DAL'
    Airline_Name VARCHAR(100) NOT NULL,
    Callsign VARCHAR(50) NULL,
    Country_Origin VARCHAR(100) NOT NULL,
    Business_Model VARCHAR(30) NOT NULL,          -- 'legacy', 'low_cost', 'hybrid'
    Global_Alliance VARCHAR(30) NOT NULL DEFAULT 'Independent', -- 'Star Alliance', 'SkyTeam', 'Oneworld'
    Active_Status CHAR(1) NOT NULL DEFAULT 'Y'
);

-- Aircraft Fleet Dimension
CREATE TABLE Dim_Aircraft (
    Aircraft_Key INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    Aircraft_Model_Name VARCHAR(80) NOT NULL,     -- e.g. 'Boeing 777-300ER', 'Airbus A380'
    Manufacturer VARCHAR(50) NOT NULL,            -- 'Boeing', 'Airbus', 'Embraer'
    Aircraft_Family VARCHAR(30) NOT NULL,         -- 'B777', 'A380', 'A350', 'A320'
    Body_Type VARCHAR(20) NOT NULL,               -- 'Wide-Body', 'Narrow-Body'
    Typical_Seating_Capacity INT NOT NULL,
    Fuel_Efficiency_Class VARCHAR(20) NOT NULL    -- 'High', 'Standard', 'Legacy'
);

-- =============================================================================
-- 2. FACT TABLES
-- =============================================================================

-- Primary Enterprise Fact: Route Annual Revenue & Operational Performance (2015-2026)
CREATE TABLE Fact_Route_Performance (
    Performance_Fact_ID BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    Date_Key INT NOT NULL,
    Route_Key INT NOT NULL,
    Origin_Airport_Key INT NOT NULL,
    Destination_Airport_Key INT NOT NULL,
    Airline_Key INT NOT NULL,
    
    -- Measures
    Annual_Revenue_USD_M DECIMAL(12,2) NOT NULL,  -- Additive: Gross Annual Revenue ($ Millions)
    Annual_Passengers_M DECIMAL(10,3) NOT NULL,   -- Additive: Passenger Volume ($ Millions)
    Weekly_Frequency_Est INT NOT NULL,            -- Semi-Additive: Flights per week
    Avg_Fare_USD DECIMAL(8,2) NOT NULL,           -- Non-Additive: Average Fare ($)
    Distance_KM INT NOT NULL,                     -- Non-Additive: Route Length
    
    -- Derived Measures (Calculated during ETL)
    Operating_Cost_USD_M DECIMAL(12,2) NOT NULL,  -- Additive: Total Operating Cost ($ Millions)
    Net_Profit_USD_M DECIMAL(12,2) NOT NULL,      -- Additive: Net Route Profit ($ Millions)
    Profit_Margin_PCT DECIMAL(6,2) NOT NULL,      -- Non-Additive: Profit Margin %

    -- Constraints
    CONSTRAINT FK_FRP_Date FOREIGN KEY (Date_Key) REFERENCES Dim_Date(Date_Key),
    CONSTRAINT FK_FRP_Route FOREIGN KEY (Route_Key) REFERENCES Dim_Route(Route_Key),
    CONSTRAINT FK_FRP_OriginAirport FOREIGN KEY (Origin_Airport_Key) REFERENCES Dim_Airport(Airport_Key),
    CONSTRAINT FK_FRP_DestAirport FOREIGN KEY (Destination_Airport_Key) REFERENCES Dim_Airport(Airport_Key),
    CONSTRAINT FK_FRP_Airline FOREIGN KEY (Airline_Key) REFERENCES Dim_Airline(Airline_Key)
);

-- Secondary Granular Fact: Daily Flight Operations & Cost Breakdown
CREATE TABLE Fact_Flight_Operations (
    Flight_Fact_ID BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    Flight_Number VARCHAR(15) NOT NULL,
    Date_Key INT NOT NULL,
    Route_Key INT NOT NULL,
    Origin_Airport_Key INT NOT NULL,
    Destination_Airport_Key INT NOT NULL,
    Aircraft_Key INT NOT NULL,
    
    -- Operational Counts
    Aircraft_Capacity INT NOT NULL,
    Passengers_Booked INT NOT NULL,
    Load_Factor DECIMAL(5,4) NOT NULL,
    Flight_Hours DECIMAL(4,1) NOT NULL,
    
    -- Revenue Measures
    Ticket_Revenue DECIMAL(12,2) NOT NULL,
    Ancillary_Revenue DECIMAL(12,2) NOT NULL,
    Total_Revenue DECIMAL(12,2) NOT NULL,
    
    -- Itemized Direct Operating Costs
    Fuel_Cost DECIMAL(12,2) NOT NULL,
    Maintenance_Cost DECIMAL(12,2) NOT NULL,
    Crew_Cost DECIMAL(12,2) NOT NULL,
    Airport_Fees DECIMAL(12,2) NOT NULL,
    Handling_Cost DECIMAL(12,2) NOT NULL,
    Navigation_Fees DECIMAL(12,2) NOT NULL,
    Catering_Cost DECIMAL(12,2) NOT NULL,
    Overhead_Cost DECIMAL(12,2) NOT NULL,
    Total_Cost DECIMAL(12,2) NOT NULL,
    
    -- Profit Measures
    Profit DECIMAL(12,2) NOT NULL,
    Profit_Margin_PCT DECIMAL(6,2) NOT NULL,

    -- Constraints
    CONSTRAINT FK_FFO_Date FOREIGN KEY (Date_Key) REFERENCES Dim_Date(Date_Key),
    CONSTRAINT FK_FFO_Route FOREIGN KEY (Route_Key) REFERENCES Dim_Route(Route_Key),
    CONSTRAINT FK_FFO_OriginAirport FOREIGN KEY (Origin_Airport_Key) REFERENCES Dim_Airport(Airport_Key),
    CONSTRAINT FK_FFO_DestAirport FOREIGN KEY (Destination_Airport_Key) REFERENCES Dim_Airport(Airport_Key),
    CONSTRAINT FK_FFO_Aircraft FOREIGN KEY (Aircraft_Key) REFERENCES Dim_Aircraft(Aircraft_Key)
);

-- =============================================================================
-- 3. PERFORMANCE INDEXES
-- =============================================================================

-- Non-Clustered Indexes on Fact Table Foreign Keys for Optimal Analytical Join Speed
CREATE NONCLUSTERED INDEX IX_FRP_Date ON Fact_Route_Performance(Date_Key);
CREATE NONCLUSTERED INDEX IX_FRP_Route ON Fact_Route_Performance(Route_Key);
CREATE NONCLUSTERED INDEX IX_FRP_Origin ON Fact_Route_Performance(Origin_Airport_Key);
CREATE NONCLUSTERED INDEX IX_FRP_Dest ON Fact_Route_Performance(Destination_Airport_Key);
CREATE NONCLUSTERED INDEX IX_FRP_Airline ON Fact_Route_Performance(Airline_Key);

CREATE NONCLUSTERED INDEX IX_FFO_Date ON Fact_Flight_Operations(Date_Key);
CREATE NONCLUSTERED INDEX IX_FFO_Route ON Fact_Flight_Operations(Route_Key);
CREATE NONCLUSTERED INDEX IX_FFO_Aircraft ON Fact_Flight_Operations(Aircraft_Key);

-- Unique Business Key Indexes on Dimensions
CREATE UNIQUE NONCLUSTERED INDEX UQ_Airport_IATA ON Dim_Airport(IATA_Code);
CREATE UNIQUE NONCLUSTERED INDEX UQ_Route_Code ON Dim_Route(Route_Code);
