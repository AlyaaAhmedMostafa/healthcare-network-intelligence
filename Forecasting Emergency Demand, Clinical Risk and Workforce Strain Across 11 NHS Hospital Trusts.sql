/* ============================================================================
   CODE BLUE: PREDICTIVE CLINICAL INTELLIGENCE
   Forecasting Emergency Demand, Clinical Risk & Workforce Strain
   Across 11 NHS Hospital Trusts | 2024-2025

   Platform : Microsoft SQL Server (T-SQL)
   Scope    : Descriptive + Diagnostic clinical analysis, then predictive
              forecasting (linear trend regression, risk scoring, early
              warning indices) — no external ML engine required.
   Story    : PART A profiles what happened (flow, mortality, readmission,
              workforce, finance). PART B predicts what happens next
              (demand, risk, burnout, capacity strain), using only the
              patterns established in PART A. Every predictive model
              is traceable back to a diagnostic finding.
   ============================================================================ */

/* ============================================================================
   PART 0 — SCHEMA (star schema: 7 dimensions + 3 facts)
   ============================================================================ */
IF DB_ID('CodeBlue_Analytics') IS NULL
    CREATE DATABASE CodeBlue_Analytics;
GO
USE CodeBlue_Analytics;
GO

-- Dimensions -----------------------------------------------------------------
CREATE TABLE Dim_Region (
    Region_ID       NVARCHAR(10) PRIMARY KEY,
    Region_Name     NVARCHAR(100),
    Population_M    DECIMAL(6,2),
    Urban_Rural     NVARCHAR(20),
    Avg_Income_K    INT,
    Elderly_Pct     DECIMAL(5,2),
    Poverty_Rate    DECIMAL(5,3)
);

CREATE TABLE Dim_Hospital (
    Hospital_ID                 NVARCHAR(10) PRIMARY KEY,
    Hospital_Name               NVARCHAR(150),
    Archetype                   NVARCHAR(50),
    NHS_Trust_Type              NVARCHAR(50),
    Region_ID                   NVARCHAR(10) REFERENCES Dim_Region(Region_ID),
    City                        NVARCHAR(100),
    Beds                        INT,
    ICU_Beds                    INT,
    ED_Bays                     INT,
    Annual_Budget_M             INT,
    Staff_FTE                   INT,
    Founding_Year                INT,
    Teaching_Hospital            BIT,
    Trauma_Level                 INT,
    Private                      BIT,
    Avg_Daily_Admissions_Base    INT,
    Satisfaction_Base            INT,
    Efficiency_Score             DECIMAL(5,2),
    Cost_Index                   DECIMAL(5,2),
    Readmission_Rate_Base        DECIMAL(5,3),
    Staffing_Stress              NVARCHAR(20),
    Growth_Trend                 DECIMAL(6,3),
    Quality_Trend                DECIMAL(6,3),
    Special_Profile              NVARCHAR(50),
    Latitude                     DECIMAL(9,6),
    Longitude                    DECIMAL(9,6),
    Total_Beds                   INT
);

CREATE TABLE Dim_Department (
    Department_ID    NVARCHAR(10) PRIMARY KEY,
    Department_Name  NVARCHAR(100),
    Type             NVARCHAR(50),
    ICU_Capable      BIT
);

CREATE TABLE Dim_Date (
    Date_Key         INT PRIMARY KEY,
    Full_Date        DATE,
    [Year]           INT,
    Quarter          NVARCHAR(5),
    [Month]          INT,
    Month_Name       NVARCHAR(15),
    Week_Number      INT,
    Day_of_Week      NVARCHAR(15),
    Day_Number       INT,
    Is_Weekend       BIT,
    Is_Holiday       BIT,
    Season           NVARCHAR(10),
    Is_Winter        BIT,
    Is_Flu_Season    BIT
);

CREATE TABLE Dim_Patient (
    Patient_ID                 NVARCHAR(10) PRIMARY KEY,
    Age                        INT,
    Gender                     NVARCHAR(10),
    Insurance_Type             NVARCHAR(30),
    Chronic_Conditions         NVARCHAR(200),
    Chronic_Condition_Count    INT,
    Risk_Category              NVARCHAR(20)
);

CREATE TABLE Dim_Doctor (
    Doctor_ID              NVARCHAR(10) PRIMARY KEY,
    Doctor_Name             NVARCHAR(100),
    Specialty               NVARCHAR(50),
    Grade                    NVARCHAR(30),
    Years_Experience         INT,
    Primary_Hospital_ID      NVARCHAR(10) REFERENCES Dim_Hospital(Hospital_ID),
    Annual_Salary            INT,
    Part_Time_Flag           BIT,
    Burnout_Baseline         DECIMAL(5,2)
);

CREATE TABLE Dim_Diagnosis (
    Diagnosis_ID       NVARCHAR(10) PRIMARY KEY,
    Category           NVARCHAR(50),
    ICD_Chapter        NVARCHAR(50),
    Severity_Weight    DECIMAL(5,2),
    ICU_Probability    DECIMAL(5,3),
    Avg_LOS_Hours      INT,
    Readmission_Risk   NVARCHAR(10),
    Cost_Weight        DECIMAL(5,2)
);

-- Facts ------------------------------------------------------------------
CREATE TABLE Fact_Patient_Visits (
    Visit_ID                    NVARCHAR(15) PRIMARY KEY,
    Patient_ID                  NVARCHAR(10) REFERENCES Dim_Patient(Patient_ID),
    Hospital_ID                 NVARCHAR(10) REFERENCES Dim_Hospital(Hospital_ID),
    Department_ID                NVARCHAR(10) REFERENCES Dim_Department(Department_ID),
    Doctor_ID                    NVARCHAR(10) REFERENCES Dim_Doctor(Doctor_ID),
    Arrival_DateTime              DATETIME2,
    Triage_DateTime                DATETIME2,
    Treatment_Start_DateTime        DATETIME2,
    Discharge_DateTime               DATETIME2,
    Admission_Type                    NVARCHAR(20),
    Severity_Level                     INT,             -- 1 (low) .. 5 (critical)
    Diagnosis_Category                  NVARCHAR(10) REFERENCES Dim_Diagnosis(Diagnosis_ID),
    Length_of_Stay_Hours                 DECIMAL(8,1),
    Wait_Time_Minutes                     DECIMAL(8,1),
    Treatment_Delay_Minutes                INT,
    ICU_Required_Flag                       BIT,
    Outcome                                  NVARCHAR(20),  -- Discharged/Admitted/Transferred/AMA/Deceased
    Mortality_Flag                            BIT,
    Readmission_30_Days_Flag                   BIT,
    Insurance_Type                              NVARCHAR(30),
    Treatment_Cost                               DECIMAL(10,2),
    Revenue_Amount                                DECIMAL(10,2),
    Satisfaction_Score                             DECIMAL(5,1),
    Complaint_Flag                                  BIT,
    Ambulance_Arrival_Flag                           BIT,
    [Month]                                           INT,
    Hospital_Name                                     NVARCHAR(150),
    Latitude                                           DECIMAL(9,6),
    Longitude                                           DECIMAL(9,6)
);

CREATE TABLE Fact_Staffing (
    Shift_ID                NVARCHAR(15) PRIMARY KEY,
    Hospital_ID              NVARCHAR(10) REFERENCES Dim_Hospital(Hospital_ID),
    Department_ID             NVARCHAR(10) REFERENCES Dim_Department(Department_ID),
    Shift_Date                 DATE,
    Shift_Type                  NVARCHAR(20),
    Doctors_On_Duty              INT,
    Nurses_On_Duty                INT,
    Support_Staff_Count            INT,
    Staff_Absence_Count             INT,
    Overtime_Hours                   DECIMAL(6,1),
    Staff_Cost                        DECIMAL(10,2),
    Burnout_Risk_Index                 DECIMAL(5,3),
    [Month]                              INT,
    Hospital_Name                         NVARCHAR(150),
    Latitude                               DECIMAL(9,6),
    Longitude                               DECIMAL(9,6)
);

CREATE TABLE Fact_Financials (
    Financial_Record_ID       NVARCHAR(15) PRIMARY KEY,
    Hospital_ID                NVARCHAR(10) REFERENCES Dim_Hospital(Hospital_ID),
    [Year]                       INT,
    [Month]                        INT,
    Visit_Count                     INT,
    Operational_Cost                 DECIMAL(12,2),
    Staffing_Cost                     DECIMAL(12,2),
    Emergency_Department_Cost          DECIMAL(12,2),
    ICU_Cost                            DECIMAL(12,2),
    Revenue                              DECIMAL(12,2),
    Profit_Margin                         DECIMAL(6,3),
    Government_Funding                     DECIMAL(12,2),
    Equipment_Investment                    DECIMAL(12,2),
    Expansion_Projects_Flag                  BIT,
    Bed_Occupancy_Rate                        DECIMAL(5,3),
    Avg_Patient_Satisfaction                   DECIMAL(5,1),
    Readmission_Rate                            DECIMAL(5,3),
    Complaint_Rate                               DECIMAL(5,3),
    Mortality_Rate                                DECIMAL(5,3),
    Avg_Wait_Time_Minutes                          DECIMAL(6,1),
    Total_Overtime_Hours                            DECIMAL(8,1),
    Avg_Burnout_Index                                DECIMAL(5,3),
    Total_Staff_Absences                              INT,
    Hospital_Name                                      NVARCHAR(150),
    Latitude                                            DECIMAL(9,6),
    Longitude                                            DECIMAL(9,6)
);
GO

-- Load: import each sheet via SSMS Import Wizard / BULK INSERT into the
-- matching table above (Fact_Patient_Visits ~10K rows, Fact_Staffing ~10K,
-- Fact_Financials 264 = 11 hospitals x 24 months, Jan-2024 to Dec-2025).

/* ============================================================================
   PART A — CLINICAL & OPERATIONAL DIAGNOSTICS (what is happening, and why)
   ============================================================================ */

-- A1. Hospital scorecard: volume, flow, safety, satisfaction, cost in one view
CREATE OR ALTER VIEW vw_Hospital_Scorecard AS
SELECT
    h.Hospital_ID, 
    h.Hospital_Name, 
    h.Archetype, 
    h.Special_Profile,
    COUNT(*)                                         AS Total_Visits,
    AVG(v.Wait_Time_Minutes)                         AS Avg_Wait_Min,
    AVG(v.Treatment_Delay_Minutes)                   AS Avg_Delay_Min,
    AVG(v.Length_of_Stay_Hours)                      AS Avg_LOS_Hours,
    AVG(CAST(v.ICU_Required_Flag AS FLOAT))          AS ICU_Rate,
    AVG(CAST(v.Mortality_Flag AS FLOAT))             AS Mortality_Rate,
    AVG(CAST(v.Readmission_30_Days_Flag AS FLOAT))   AS Readmission_Rate,
    AVG(v.Satisfaction_Score)                        AS Avg_Satisfaction,
    AVG(CAST(v.Complaint_Flag AS FLOAT))             AS Complaint_Rate,
    SUM(v.Revenue_Amount)                            AS Total_Revenue,
    SUM(v.Treatment_Cost)                            AS Total_Cost
FROM dbo.Patient_Visits v
JOIN dbo.Hospital h ON h.Hospital_ID = v.Hospital_ID
GROUP BY h.Hospital_ID, h.Hospital_Name, h.Archetype, h.Special_Profile;
GO

-- A2. Patient-flow funnel by severity: where time is lost, arrival to discharge
SELECT
    Severity_Level,
    COUNT(*)                                     AS Visits,
    AVG(Wait_Time_Minutes)                         AS Avg_Wait_Min,
    AVG(Treatment_Delay_Minutes)                    AS Avg_Delay_Min,
    AVG(Length_of_Stay_Hours)                        AS Avg_LOS_Hours,
    AVG(CASE WHEN ICU_Required_Flag = 1 THEN 1.0 ELSE 0 END) AS ICU_Rate,
    AVG(CASE WHEN Mortality_Flag = 1 THEN 1.0 ELSE 0 END)     AS Mortality_Rate
FROM dbo.Patient_Visits
GROUP BY Severity_Level
ORDER BY Severity_Level;

-- A3. Mortality drivers: diagnosis x severity, ranked by risk-adjusted volume
SELECT
    d.Category                                      AS Diagnosis,
    v.Severity_Level,
    COUNT(*)                                          AS Visits,
    SUM(CAST(v.Mortality_Flag AS INT))                  AS Deaths,
    ROUND(AVG(CAST(v.Mortality_Flag AS FLOAT)), 4)        AS Mortality_Rate,
    AVG(v.Treatment_Delay_Minutes)                          AS Avg_Delay_Min
FROM dbo.Patient_Visits v
JOIN dbo.Diagnosis d ON d.Diagnosis_ID = v.Diagnosis_Category
GROUP BY d.Category, v.Severity_Level
HAVING COUNT(*) >= 15
ORDER BY Mortality_Rate DESC;

-- A4. 30-day readmission: patient risk factors vs actual rate (validates model in Part B)
SELECT
    p.Risk_Category,
    p.Chronic_Condition_Count,
    COUNT(*)                                       AS Visits,
    ROUND(AVG(CAST(v.Readmission_30_Days_Flag AS FLOAT)), 4) AS Readmission_Rate
FROM dbo.Patient_Visits v
JOIN dbo.Patient p ON p.Patient_ID = v.Patient_ID
GROUP BY p.Risk_Category, p.Chronic_Condition_Count
ORDER BY Readmission_Rate DESC;

-- A5. ICU capacity strain today: required vs beds available, by hospital
SELECT
    h.Hospital_Name, h.ICU_Beds,
    COUNT(*)                                          AS ICU_Visits,
    ROUND(COUNT(*) * 1.0 / NULLIF(h.ICU_Beds, 0), 2)     AS ICU_Visits_Per_Bed,
    ROUND(AVG(CAST(v.Mortality_Flag AS FLOAT)), 4)        AS ICU_Mortality_Rate
FROM dbo.Patient_Visits v
JOIN dbo.Hospital h ON h.Hospital_ID = v.Hospital_ID
WHERE v.ICU_Required_Flag = 1
GROUP BY h.Hospital_Name, h.ICU_Beds
ORDER BY ICU_Visits_Per_Bed DESC;

-- A6. Workforce strain vs clinical outcomes: does burnout correlate with delay/mortality?
SELECT
    h.Hospital_Name,
    ROUND(AVG(s.Burnout_Risk_Index), 3)          AS Avg_Burnout_Index,
    ROUND(AVG(s.Overtime_Hours), 1)                AS Avg_Overtime_Hrs,
    ROUND(AVG(CAST(v.Mortality_Flag AS FLOAT)), 4)   AS Mortality_Rate,
    ROUND(AVG(v.Treatment_Delay_Minutes), 1)           AS Avg_Delay_Min
FROM dbo.Staffing s
JOIN dbo.Hospital h ON h.Hospital_ID = s.Hospital_ID
JOIN dbo.Patient_Visits v ON v.Hospital_ID = s.Hospital_ID
    AND v.Month = s.Month
GROUP BY h.Hospital_Name
ORDER BY Avg_Burnout_Index DESC;

-- A7. Financial health vs quality: is cost efficiency traded for safety?
SELECT
    h.Hospital_Name,
    ROUND(AVG(f.Profit_Margin), 3)          AS Avg_Profit_Margin,
    ROUND(AVG(f.Bed_Occupancy_Rate), 3)       AS Avg_Bed_Occupancy,
    ROUND(AVG(f.Mortality_Rate), 4)             AS Avg_Mortality_Rate,
    ROUND(AVG(f.Readmission_Rate), 4)             AS Avg_Readmission_Rate
FROM dbo.Financials f
JOIN dbo.Hospital h ON h.Hospital_ID = f.Hospital_ID
GROUP BY h.Hospital_Name
ORDER BY Avg_Profit_Margin DESC;
GO

/* ============================================================================
   PART B — PREDICTIVE ANALYTICS (what happens next)
   Method: closed-form OLS trend regression (slope/intercept) computed in
   T-SQL, plus transparent weighted risk-scoring models. No black box —
   every score below is auditable to a formula.
   ============================================================================ */

-- B1. Monthly demand forecast per hospital: OLS trend, 3-month-ahead projection
CREATE OR ALTER VIEW vw_Forecast_Monthly_Admissions AS
WITH Trend AS (
    SELECT
        Hospital_ID,
        ROW_NUMBER() OVER (PARTITION BY Hospital_ID ORDER BY [Year], [Month]) AS t,
        Visit_Count
    FROM dbo.Financials
),
Agg AS (
    -- Standard OLS: slope = (n?xy - ?x?y) / (n?x² - (?x)²)
    SELECT
        Hospital_ID,
        COUNT(*)                              AS n,
        SUM(t)                                 AS sum_x,
        SUM(Visit_Count)                        AS sum_y,
        SUM(t * Visit_Count)                     AS sum_xy,
        SUM(t * t)                                AS sum_x2,
        MAX(t)                                     AS last_t
    FROM Trend
    GROUP BY Hospital_ID
),
Coef AS (
    SELECT *,
        (n * sum_xy - sum_x * sum_y) * 1.0
            / NULLIF((n * sum_x2 - sum_x * sum_x), 0)  AS slope,
        (sum_y - ((n * sum_xy - sum_x * sum_y) * 1.0
            / NULLIF((n * sum_x2 - sum_x * sum_x), 0)) * sum_x) / n AS intercept
    FROM Agg
)
SELECT
    h.Hospital_Name,
    c.slope                                             AS Monthly_Trend_Visits,
    ROUND(c.intercept + c.slope * (c.last_t + 1), 0)      AS Forecast_Month_Plus_1,
    ROUND(c.intercept + c.slope * (c.last_t + 2), 0)        AS Forecast_Month_Plus_2,
    ROUND(c.intercept + c.slope * (c.last_t + 3), 0)          AS Forecast_Month_Plus_3
FROM Coef c
JOIN dbo.Hospital h ON h.Hospital_ID = c.Hospital_ID;
GO

-- B2. Flu-season-adjusted ED surge forecast: winter uplift factor applied to trend
SELECT
    f.Forecast_Month_Plus_1,
    ROUND(f.Forecast_Month_Plus_1 *
        (SELECT AVG(CASE WHEN dd.Is_Flu_Season = 1 THEN 1.0 ELSE 0 END) * 0.15 + 1
         FROM dbo.Date dd), 0)                  AS Flu_Season_Adjusted_Forecast,
    f.Hospital_Name
FROM vw_Forecast_Monthly_Admissions f
ORDER BY Flu_Season_Adjusted_Forecast DESC;
GO

-- B3. Patient-level 30-day readmission risk score (weighted, 0-100 scale)
CREATE OR ALTER VIEW vw_Readmission_Risk_Score AS
SELECT
    v.Visit_ID, v.Patient_ID, h.Hospital_Name,
    -- Weights derived from A4 diagnostic: chronic count and diag risk dominate
    ROUND(
        (p.Chronic_Condition_Count * 8)
        + (CASE dg.Readmission_Risk WHEN 'HIGH' THEN 25 WHEN 'MEDIUM' THEN 12 ELSE 3 END)
        + (v.Severity_Level * 6)
        + (CASE WHEN v.ICU_Required_Flag = 1 THEN 10 ELSE 0 END)
        + (CASE WHEN p.Age >= 65 THEN 10 ELSE 0 END)
    , 1)                                                   AS Readmission_Risk_Score,
    CASE
        WHEN (p.Chronic_Condition_Count * 8)
            + (CASE dg.Readmission_Risk WHEN 'HIGH' THEN 25 WHEN 'MEDIUM' THEN 12 ELSE 3 END)
            + (v.Severity_Level * 6)
            + (CASE WHEN v.ICU_Required_Flag = 1 THEN 10 ELSE 0 END)
            + (CASE WHEN p.Age >= 65 THEN 10 ELSE 0 END) >= 60 THEN 'Critical'
        WHEN (p.Chronic_Condition_Count * 8)
            + (CASE dg.Readmission_Risk WHEN 'HIGH' THEN 25 WHEN 'MEDIUM' THEN 12 ELSE 3 END)
            + (v.Severity_Level * 6)
            + (CASE WHEN v.ICU_Required_Flag = 1 THEN 10 ELSE 0 END)
            + (CASE WHEN p.Age >= 65 THEN 10 ELSE 0 END) >= 40 THEN 'High'
        WHEN (p.Chronic_Condition_Count * 8)
            + (CASE dg.Readmission_Risk WHEN 'HIGH' THEN 25 WHEN 'MEDIUM' THEN 12 ELSE 3 END)
            + (v.Severity_Level * 6)
            + (CASE WHEN v.ICU_Required_Flag = 1 THEN 10 ELSE 0 END)
            + (CASE WHEN p.Age >= 65 THEN 10 ELSE 0 END) >= 20 THEN 'Medium'
        ELSE 'Low'
    END                                                     AS Risk_Tier
FROM dbo.Patient_Visits v
JOIN dbo.Patient p ON p.Patient_ID = v.Patient_ID
JOIN dbo.Diagnosis dg ON dg.Diagnosis_ID = v.Diagnosis_Category
JOIN dbo.Hospital h ON h.Hospital_ID = v.Hospital_ID;
GO

-- Model check: does predicted tier track actual readmission rate? (calibration)
SELECT Risk_Tier, COUNT(*) AS Patients,
    ROUND(AVG(CAST(v.Readmission_30_Days_Flag AS FLOAT)), 4) AS Actual_Readmission_Rate
FROM vw_Readmission_Risk_Score r
JOIN dbo.Patient_Visits v ON v.Visit_ID = r.Visit_ID
GROUP BY Risk_Tier
ORDER BY Actual_Readmission_Rate DESC;
GO

-- B4. Mortality risk stratification score (weighted, informed by A3 diagnostic)
CREATE OR ALTER VIEW vw_Mortality_Risk_Score AS
SELECT
    v.Visit_ID, h.Hospital_Name,
    ROUND(
        (v.Severity_Level * 12)
        + (dg.Severity_Weight * 10)
        + (CASE WHEN v.ICU_Required_Flag = 1 THEN 15 ELSE 0 END)
        + (v.Treatment_Delay_Minutes / 10.0)
        + (CASE WHEN p.Age >= 75 THEN 12 WHEN p.Age >= 65 THEN 6 ELSE 0 END)
    , 1)                                                    AS Mortality_Risk_Score
FROM dbo.Patient_Visits v
JOIN dbo.Patient p ON p.Patient_ID = v.Patient_ID
JOIN dbo.Diagnosis dg ON dg.Diagnosis_ID = v.Diagnosis_Category
JOIN dbo.Hospital h ON h.Hospital_ID = v.Hospital_ID;
GO

-- B5. ICU demand forecast vs physical capacity: next-month bed strain
WITH ICU_Trend AS (
    SELECT 
        Hospital_ID,
        ROW_NUMBER() OVER (PARTITION BY Hospital_ID ORDER BY x.[Year], x.[Month]) AS t,
        SUM(CAST(v.ICU_Required_Flag AS INT)) AS ICU_Visits
    FROM dbo.Patient_Visits v
    CROSS APPLY (SELECT [Year] = YEAR(v.Arrival_DateTime), [Month] = MONTH(v.Arrival_DateTime)) x
    GROUP BY Hospital_ID, x.[Year], x.[Month]
),
Agg AS (
    SELECT Hospital_ID, COUNT(*) n, SUM(t) sx, SUM(ICU_Visits) sy,
           SUM(t*ICU_Visits) sxy, SUM(t*t) sx2, MAX(t) last_t
    FROM ICU_Trend GROUP BY Hospital_ID
)
SELECT 
    h.Hospital_Name, h.ICU_Beds,
    ROUND(((sy - (((n*sxy - sx*sy)*1.0/NULLIF(n*sx2 - sx*sx,0))*sx))/n)
         + ((n*sxy - sx*sy)*1.0/NULLIF(n*sx2 - sx*sx,0)) * (last_t + 1), 0) AS Forecast_ICU_Demand_Next_Month,
    h.ICU_Beds * 30                                                         AS Approx_Monthly_ICU_Capacity,
    CASE WHEN ROUND(((sy - (((n*sxy - sx*sy)*1.0/NULLIF(n*sx2 - sx*sx,0))*sx))/n)
         + ((n*sxy - sx*sy)*1.0/NULLIF(n*sx2 - sx*sx,0)) * (last_t + 1), 0) > h.ICU_Beds * 30 * 0.85 
         THEN 'STRAIN RISK' ELSE 'OK' END                                   AS Capacity_Flag
FROM Agg a 
JOIN dbo.Hospital h ON h.Hospital_ID = a.Hospital_ID
ORDER BY Capacity_Flag DESC, Forecast_ICU_Demand_Next_Month DESC;
GO
-- B6. Staff burnout early-warning: trend regression on burnout index, department-level
CREATE OR ALTER VIEW vw_Burnout_Forecast AS
WITH Trend AS (
    SELECT
        Hospital_ID, Department_ID,
        ROW_NUMBER() OVER (PARTITION BY Hospital_ID, Department_ID ORDER BY Shift_Date) AS t,
        Burnout_Risk_Index
    FROM dbo.Staffing
),
Agg AS (
    SELECT Hospital_ID, Department_ID, COUNT(*) n, SUM(t) sx, SUM(Burnout_Risk_Index) sy,
           SUM(t*Burnout_Risk_Index) sxy, SUM(t*t) sx2, MAX(t) last_t
    FROM Trend GROUP BY Hospital_ID, Department_ID
    HAVING COUNT(*) >= 10
)
SELECT
    h.Hospital_Name, d.Department_Name,
    ROUND(((sy - (((n*sxy - sx*sy)*1.0/NULLIF(n*sx2 - sx*sx,0))*sx))/n)
        + ((n*sxy - sx*sy)*1.0/NULLIF(n*sx2 - sx*sx,0)) * (last_t + 30), 3) AS Forecast_Burnout_Index_30d,
    CASE WHEN ((sy - (((n*sxy - sx*sy)*1.0/NULLIF(n*sx2 - sx*sx,0))*sx))/n)
        + ((n*sxy - sx*sy)*1.0/NULLIF(n*sx2 - sx*sx,0)) * (last_t + 30) >= 0.7
        THEN 'ESCALATING - INTERVENE' ELSE 'STABLE' END                     AS Early_Warning
FROM Agg a
JOIN dbo.Hospital h ON h.Hospital_ID = a.Hospital_ID
JOIN dbo.Department d ON d.Department_ID = a.Department_ID;
GO

-- B7. Composite capacity-strain index: forecast demand + burnout + occupancy in one score
-- Blends B1 (demand growth), B5 (ICU strain), B6 (burnout) into a single next-month risk flag
CREATE OR ALTER VIEW vw_Capacity_Strain_Index AS
SELECT
    h.Hospital_Name,
    f.Monthly_Trend_Visits,
    bo.Avg_Bed_Occupancy,
    burn.Avg_Forecast_Burnout,
    ROUND(
        (CASE WHEN f.Monthly_Trend_Visits > 0 THEN 30 ELSE 0 END)
        + (bo.Avg_Bed_Occupancy * 40)
        + (burn.Avg_Forecast_Burnout * 30)
    , 1)                                                          AS Strain_Index_0_100,
    CASE WHEN
        (CASE WHEN f.Monthly_Trend_Visits > 0 THEN 30 ELSE 0 END)
        + (bo.Avg_Bed_Occupancy * 40)
        + (burn.Avg_Forecast_Burnout * 30) >= 65 THEN 'HIGH RISK NEXT MONTH'
        ELSE 'MANAGEABLE' END                                       AS Outlook
FROM vw_Forecast_Monthly_Admissions f
JOIN dbo.Hospital h ON h.Hospital_Name = f.Hospital_Name
JOIN (SELECT Hospital_ID, AVG(Bed_Occupancy_Rate) AS Avg_Bed_Occupancy
      FROM dbo.Financials GROUP BY Hospital_ID) bo ON bo.Hospital_ID = h.Hospital_ID
JOIN (SELECT Hospital_Name, AVG(Forecast_Burnout_Index_30d) AS Avg_Forecast_Burnout
      FROM vw_Burnout_Forecast GROUP BY Hospital_Name) burn ON burn.Hospital_Name = h.Hospital_Name;
GO

/* ============================================================================
   PART C — EXECUTIVE PREDICTIVE SUMMARY
   One row per hospital: current state (Part A) next to forecast state (Part B)
   ============================================================================ */
SELECT
    sc.Hospital_Name,
    sc.Total_Visits, sc.Mortality_Rate, sc.Readmission_Rate,
    fc.Forecast_Month_Plus_3                    AS Admissions_Forecast_Q_Ahead,
    csi.Strain_Index_0_100, csi.Outlook
FROM vw_Hospital_Scorecard sc
JOIN vw_Forecast_Monthly_Admissions fc ON fc.Hospital_Name = sc.Hospital_Name
JOIN vw_Capacity_Strain_Index csi ON csi.Hospital_Name = sc.Hospital_Name
ORDER BY csi.Strain_Index_0_100 DESC;