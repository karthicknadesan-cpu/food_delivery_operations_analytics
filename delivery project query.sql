-- PROJECT: Food Delivery Operations & Performance Analytics
-- WORKFLOW: Raw Ingestion -> Cleansing -> Analytics -> BI Reporting

CREATE DATABASE IF NOT EXISTS food_delivery_db;
USE delivery_db;

-- STEP 1: RAW STAGING TABLE CREATION
-- (Stores raw uncurated CSV data as a VARCHAR for safe initial ingestion)

DROP TABLE IF EXISTS staging_food_delivery;

CREATE TABLE staging_food_delivery (
    ID VARCHAR(50),
    Delivery_person_ID VARCHAR(50),
    Delivery_person_Age VARCHAR(20),
    Delivery_person_Ratings VARCHAR(20),
    Restaurant_latitude VARCHAR(50),
    Restaurant_longitude VARCHAR(50),
    Delivery_location_latitude VARCHAR(50),
    Delivery_location_longitude VARCHAR(50),
    Order_Date VARCHAR(50),
    Time_Orderd VARCHAR(50),
    Time_Order_picked VARCHAR(50),
    Weather_conditions VARCHAR(50),
    Road_traffic_density VARCHAR(50),
    Vehicle_condition VARCHAR(20),
    Type_of_order VARCHAR(50),
    Type_of_vehicle VARCHAR(50),
    multiple_deliveries VARCHAR(20),
    Festival VARCHAR(20),
    City VARCHAR(50),
    Time_taken VARCHAR(50)
);

-- NOTE: Import the the raw csv file into this table via table data import vizard before proceeding.

-- STEP 2: DATA CLEANING & PERMANENT CLEANED TABLE CREATION
-- ( Handles string trimming,data type casting,and standardizes data/time)

DROP TABLE IF EXISTS cleaned_food_delivery;

CREATE TABLE cleaned_food_delivery AS
SELECT 
    TRIM(ID) AS order_id,
    TRIM(Delivery_person_ID) AS delivery_person_id,
    
    CAST(NULLIF(TRIM(Delivery_person_Age), 'NaN') AS UNSIGNED) AS delivery_person_age,
    CAST(NULLIF(TRIM(Delivery_person_Ratings), 'NaN') AS DECIMAL(3,2)) AS delivery_person_ratings,
    
    STR_TO_DATE(
        REPLACE(TRIM(Order_Date), '/', '-'), 
        '%d-%m-%Y'
    ) AS order_date,
    CAST(NULLIF(TRIM(Time_Orderd), 'NaN') AS TIME) AS order_time,
    CAST(NULLIF(TRIM(Time_Order_picked), 'NaN') AS TIME) AS order_picked_time,
    
    TIMESTAMPDIFF(
        MINUTE, 
        CAST(NULLIF(TRIM(Time_Orderd), 'NaN') AS TIME), 
        CAST(NULLIF(TRIM(Time_Order_picked), 'NaN') AS TIME)
    ) AS prep_time_min,
    
    NULLIF(TRIM(REPLACE(Weather_conditions, 'conditions ', '')), 'NaN') AS weather_conditions,
    NULLIF(TRIM(Road_traffic_density), 'NaN') AS road_traffic_density,
    NULLIF(TRIM(Type_of_order), 'NaN') AS type_of_order,
    NULLIF(TRIM(Type_of_vehicle), 'NaN') AS type_of_vehicle,
    NULLIF(TRIM(Festival), 'NaN') AS festival,
    NULLIF(TRIM(City), 'NaN') AS city,

    CAST(REGEXP_SUBSTR(TRIM(Time_taken), '[0-9]+') AS UNSIGNED) AS delivery_time_min

FROM staging_food_delivery;

-- STEP 3: BUSINESS ANALYTICS & INSIGHT QUERIES

-- 1. delivery duration breakdown by weather conditions

SELECT
    weather_conditions,
    COUNT(*) AS total_orders,
    ROUND(AVG(delivery_time_min), 2) AS avg_delivery_time,
    MIN(delivery_time_min) AS min_delivery_time,
    MAX(delivery_time_min) AS max_delivery_time
FROM cleaned_food_delivery
WHERE weather_conditions IS NOT NULL 
  AND weather_conditions NOT IN ('', 'NaN')
GROUP BY weather_conditions
ORDER BY avg_delivery_time DESC;


-- 2. Operational delays driven by traffic congestion levels

SELECT 
    road_traffic_density,
    COUNT(*) AS total_orders,
    ROUND(AVG(delivery_time_min), 2) AS avg_delivery_time,
    MIN(delivery_time_min) AS min_delivery_time,
    MAX(delivery_time_min) AS max_delivery_time
FROM cleaned_food_delivery
WHERE road_traffic_density IS NOT NULL 
  AND road_traffic_density NOT IN ('', 'NaN')
GROUP BY road_traffic_density
ORDER BY avg_delivery_time DESC;

-- 3. weekly demand distribution and delivery performance

SELECT
    DAYNAME(order_date) AS order_day,
    COUNT(*) AS total_orders,
    ROUND(AVG(delivery_time_min), 2) AS avg_delivery_time
FROM cleaned_food_delivery
WHERE order_date IS NOT NULL
GROUP BY DAYNAME(order_date), DAYOFWEEK(order_date)
ORDER BY DAYOFWEEK(order_date);

-- 4. kitchen turnaround by food category with midnight rollover correction

SELECT
    type_of_order,
    COUNT(*) AS total_orders,
    ROUND(AVG(
        CASE
            WHEN prep_time_min < 0 THEN prep_time_min + 1440
            ELSE prep_time_min
        END
    ), 2) AS avg_prep_time,
    MIN(
        CASE
            WHEN prep_time_min < 0 THEN prep_time_min + 1440
            ELSE prep_time_min
        END
    ) AS min_prep_time,
    MAX(
        CASE
            WHEN prep_time_min < 0 THEN prep_time_min + 1440 
            ELSE prep_time_min 
        END
    ) AS max_prep_time
FROM cleaned_food_delivery
WHERE type_of_order IS NOT NULL
  AND type_of_order NOT IN ('', 'NaN')
  AND prep_time_min IS NOT NULL
GROUP BY type_of_order
ORDER BY avg_prep_time DESC;

-- 5. Delivery fleet speed an efficiency comparison
SELECT 
    type_of_vehicle,
    COUNT(*) AS total_deliveries,
    ROUND(AVG(delivery_time_min), 2) AS avg_delivery_time,
    MIN(delivery_time_min) AS min_delivery_time,
    MAX(delivery_time_min) AS max_delivery_time
FROM cleaned_food_delivery
WHERE type_of_vehicle IS NOT NULL 
  AND type_of_vehicle NOT IN ('', 'NaN')
GROUP BY type_of_vehicle
ORDER BY avg_delivery_time ASC;

-- STEP 4: PRODUCTION BI VIEW CREATION (FOR POWER BI)

CREATE OR REPLACE VIEW food_delivery_bi_summary AS 
SELECT
    order_id,
    delivery_person_id,
    delivery_person_age,
    delivery_person_ratings,
    order_date,
    DAYNAME(order_date) AS order_day,
    order_time,
    order_picked_time,
    CASE 
        WHEN prep_time_min < 0 THEN prep_time_min + 1440
        ELSE prep_time_min
    END AS prep_time_min,
    weather_conditions,
    road_traffic_density,
    type_of_order,
    type_of_vehicle,
    festival,
    city,
    delivery_time_min
FROM cleaned_food_delivery
WHERE weather_conditions NOT IN ('', 'NaN')
  AND road_traffic_density NOT IN ('', 'NaN')
  AND type_of_order NOT IN ('', 'NaN');

-- Preview sanitized reporting view
SELECT * FROM food_delivery_bi_summary LIMIT 10;