/* =====================================================================
   CODE BLUE — PREDICTIVE WORKFORCE ANALYSIS
   EMERGENCY OPERATIONS & PATIENT FLOW NETWORK
   T-SQL SCRIPT (MS SQL Server)

   Story arc: start at the network level, drill into hospitals, break
   staffing down by department and shift, look at the doctor pipeline
   behind the shifts, connect strain to patient-facing outcomes, build
   a standing risk view — then turn that diagnosis into a forward
   forecast so workforce risk can be caught before it becomes a
   staffing crisis.
   ===================================================================== */


/* ---------------------------------------------------------------------
    1 — NETWORK-WIDE WORKFORCE SNAPSHOT
   The starting point: how much is the network spending on staff,
   how much overtime is it running on, and how strained is it overall?
   --------------------------------------------------------------------- */
SELECT
    COUNT(*)                                    AS Total_Shifts,
    ROUND(SUM(Staff_Cost), 0)                   AS Total_Staff_Cost,
    ROUND(SUM(Overtime_Hours), 0)                AS Total_Overtime_Hours,
    ROUND(SUM(CAST(Staff_Absence_Count AS FLOAT)), 0) AS Total_Absences,
    ROUND(AVG(Burnout_Risk_Index), 3)             AS Avg_Burnout_Index,
    ROUND(AVG(Doctors_On_Duty), 1)                AS Avg_Doctors_Per_Shift,
    ROUND(AVG(Nurses_On_Duty), 1)                 AS Avg_Nurses_Per_Shift,
    ROUND(100.0 * SUM(Overtime_Hours) /
          NULLIF(SUM(Doctors_On_Duty + Nurses_On_Duty + Support_Staff_Count) * 8, 0), 2)
                                                    AS Overtime_Pct_of_Rostered_Hours
FROM dbo.Staffing;


/* ---------------------------------------------------------------------
    2 — HOSPITAL-LEVEL WORKFORCE SUMMARY
   Now check whether that network picture is even, or whether it's
   hiding hospitals under real staffing strain. Sorted worst burnout
   first.
   --------------------------------------------------------------------- */
SELECT h.Hospital_Name,
       COUNT(*)                                  AS Shifts,
       ROUND(SUM(s.Staff_Cost), 0)                AS Total_Staff_Cost,
       ROUND(SUM(s.Overtime_Hours), 0)             AS Total_Overtime_Hours,
       ROUND(AVG(s.Burnout_Risk_Index), 3)          AS Avg_Burnout,
       ROUND(SUM(CAST(s.Staff_Absence_Count AS FLOAT)), 0) AS Total_Absences
FROM dbo.Staffing s
JOIN dbo.Hospital h ON s.Hospital_ID = h.Hospital_ID
GROUP BY h.Hospital_Name
ORDER BY Avg_Burnout DESC;


/* ---------------------------------------------------------------------
    3 — DEPARTMENT-LEVEL STAFFING STRUCTURE
   We know burnout varies by hospital — now check whether it's
   concentrated in specific department types (e.g. ICU vs general
   wards), which points to where the actual pressure is coming from.
   --------------------------------------------------------------------- */
SELECT d.Department_Name, d.Type, d.ICU_Capable,
       COUNT(*)                                  AS Shifts,
       ROUND(AVG(s.Doctors_On_Duty), 1)            AS Avg_Doctors,
       ROUND(AVG(s.Nurses_On_Duty), 1)             AS Avg_Nurses,
       ROUND(SUM(s.Overtime_Hours), 0)             AS Total_Overtime_Hours,
       ROUND(AVG(s.Burnout_Risk_Index), 3)         AS Avg_Burnout
FROM dbo.Staffing s
JOIN dbo.Department d ON s.Department_ID = d.Department_ID
GROUP BY d.Department_Name, d.Type, d.ICU_Capable
ORDER BY Avg_Burnout DESC;


/* ---------------------------------------------------------------------
    4 — WORKFORCE STRAIN OVER TIME (QUARTERLY)
   Department gives one dimension — time is another. Check whether
   strain is stable year-round or spikes seasonally (e.g. winter/flu
   pressure), which changes how the network should staff ahead of it.
   --------------------------------------------------------------------- */
WITH Quarterly AS (
    SELECT YEAR(Shift_Date) AS Yr,
           CASE WHEN MONTH(Shift_Date) <= 3 THEN 'Q1'
                WHEN MONTH(Shift_Date) <= 6 THEN 'Q2'
                WHEN MONTH(Shift_Date) <= 9 THEN 'Q3' ELSE 'Q4' END AS Quarter,
           Overtime_Hours, Burnout_Risk_Index, Staff_Absence_Count
    FROM dbo.Staffing
)
SELECT Yr, Quarter,
       ROUND(SUM(Overtime_Hours), 0)              AS Total_Overtime_Hours,
       ROUND(AVG(Burnout_Risk_Index), 3)           AS Avg_Burnout,
       ROUND(SUM(CAST(Staff_Absence_Count AS FLOAT)), 0) AS Total_Absences
FROM Quarterly
GROUP BY Yr, Quarter
ORDER BY Yr, Quarter;


/* ---------------------------------------------------------------------
    5 — SHIFT-PATTERN PRESSURE
   Seasonality is one axis of time — shift pattern is another. Check
   whether night shifts carry a disproportionate share of the
   overtime and burnout load compared to mornings and afternoons.
   --------------------------------------------------------------------- */
SELECT Shift_Type,
       COUNT(*)                                   AS Shifts,
       ROUND(AVG(Doctors_On_Duty), 1)               AS Avg_Doctors,
       ROUND(AVG(Nurses_On_Duty), 1)                AS Avg_Nurses,
       ROUND(AVG(Overtime_Hours), 2)                AS Avg_Overtime_Hours,
       ROUND(AVG(Burnout_Risk_Index), 3)            AS Avg_Burnout
FROM dbo.Staffing
GROUP BY Shift_Type
ORDER BY Avg_Burnout DESC;


/* ---------------------------------------------------------------------
   6 — DOCTOR WORKFORCE COMPOSITION (THE PIPELINE BEHIND THE SHIFTS)
   Shift-level strain is a symptom — this checks the underlying supply:
   grade mix, experience, and part-time ratio per hospital, which
   determines how much flexibility a hospital actually has to absorb
   pressure without burning out its senior staff.
   --------------------------------------------------------------------- */
SELECT h.Hospital_Name,
       COUNT(*)                                   AS Doctor_Headcount,
       ROUND(AVG(doc.Years_Experience), 1)          AS Avg_Experience_Years,
       ROUND(AVG(CAST(doc.Annual_Salary AS FLOAT)), 0) AS Avg_Salary,
       ROUND(100.0 * SUM(CASE WHEN doc.Part_Time_Flag = 1 THEN 1 ELSE 0 END) / COUNT(*), 1) AS Pct_Part_Time,
       ROUND(100.0 * SUM(CASE WHEN doc.Grade IN ('Foundation Year 1','Foundation Year 2') THEN 1 ELSE 0 END) / COUNT(*), 1) AS Pct_Junior_Grade,
       ROUND(AVG(doc.Burnout_Baseline), 3)           AS Avg_Burnout_Baseline
FROM dbo.Doctor doc
JOIN dbo.Hospital h ON doc.Primary_Hospital_ID = h.Hospital_ID
GROUP BY h.Hospital_Name
ORDER BY Pct_Junior_Grade DESC;


/* ---------------------------------------------------------------------
   7 — CONNECTING WORKFORCE STRAIN TO PATIENT-FACING OUTCOMES
   The workforce picture is now clear — link it back to what patients
   experience (wait time, satisfaction) and to cost, to test whether
   the most strained hospitals are also the ones patients feel it in.
   --------------------------------------------------------------------- */
SELECT h.Hospital_Name,
       ROUND(AVG(f.Avg_Burnout_Index), 3)           AS Avg_Burnout,
       ROUND(SUM(f.Total_Overtime_Hours), 0)         AS Total_Overtime_Hours,
       ROUND(SUM(CAST(f.Total_Staff_Absences AS FLOAT)), 0) AS Total_Absences,
       ROUND(AVG(f.Avg_Wait_Time_Minutes), 1)        AS Avg_Wait,
       ROUND(AVG(f.Avg_Patient_Satisfaction), 1)     AS Avg_Satisfaction,
       ROUND(AVG(f.Staffing_Cost), 0)                AS Avg_Monthly_Staffing_Cost
FROM dbo.Financials f
JOIN dbo.Hospital h ON f.Hospital_ID = h.Hospital_ID
GROUP BY h.Hospital_Name
ORDER BY Avg_Burnout DESC;


/* ---------------------------------------------------------------------
    8 — STANDING WORKFORCE RISK-MONITORING VIEW (CURRENT-STATE)
   Turn the diagnosis into something reusable: a view that always
   reflects current data and classifies each hospital as STABLE,
   WATCH, or HIGH RISK based on burnout and overtime load together
   (run once to create; query it afterwards).
   --------------------------------------------------------------------- */
CREATE VIEW vw_Hospital_Workforce_Risk AS
SELECT h.Hospital_Name,
       AVG(s.Burnout_Risk_Index)                    AS Avg_Burnout,
       SUM(s.Overtime_Hours) / COUNT(*)              AS Overtime_Hours_Per_Shift,
       SUM(CAST(s.Staff_Absence_Count AS FLOAT)) / COUNT(*) AS Absences_Per_Shift,
       CASE WHEN AVG(s.Burnout_Risk_Index) > 0.55
             AND SUM(s.Overtime_Hours) / COUNT(*) > 3
            THEN 'HIGH RISK'
            WHEN AVG(s.Burnout_Risk_Index) > 0.50 THEN 'WATCH'
            ELSE 'STABLE' END                        AS Risk_Flag
FROM dbo.Staffing s
JOIN dbo.Hospital h ON s.Hospital_ID = h.Hospital_ID
GROUP BY h.Hospital_Name;
GO


/* ---------------------------------------------------------------------
   9 — CURRENT-STATE MONITORING QUERY
   A simple, repeatable query HR/Ops can re-run each reporting period
   to see which hospitals need priority staffing intervention today.
   This closes the diagnostic half of the story — everything from
   here forward looks ahead instead of back.
   --------------------------------------------------------------------- */
SELECT h.Hospital_Name,
       ROUND(AVG(s.Burnout_Risk_Index), 3)           AS Avg_Burnout,
       ROUND(SUM(s.Overtime_Hours) / COUNT(*), 2)     AS Overtime_Hours_Per_Shift,
       ROUND(SUM(CAST(s.Staff_Absence_Count AS FLOAT)) / COUNT(*), 2) AS Absences_Per_Shift,
       CASE WHEN AVG(s.Burnout_Risk_Index) > 0.55 THEN 'PRIORITY REVIEW'
            WHEN SUM(s.Overtime_Hours) / COUNT(*) > 3 THEN 'OVERTIME WATCH'
            ELSE 'STABLE' END                         AS Flag
FROM dbo.Staffing s
JOIN dbo.Hospital h ON s.Hospital_ID = h.Hospital_ID
GROUP BY h.Hospital_Name
ORDER BY Avg_Burnout DESC;


/* =====================================================================
   PART 2 — PREDICTIVE FORECAST
    1-9 diagnosed where workforce strain stands today. From here,
   we fit a per-hospital trend line to the monthly staffing actuals
   and project it 6 months forward, so burnout and overtime risk can
   be flagged BEFORE they show up in next quarter's shift data.

   Method: least-squares linear regression, run separately on Overtime
   Hours and Burnout Risk Index per hospital (kept independent so one
   metric's noise doesn't distort the other's trend line).
   ===================================================================== */

-- ---------------------------------------------------------------
--  10 — BUILD THE FORECAST INPUT SERIES
-- Aggregate shifts to one row per hospital per month. Period = months
-- since Jan 2024, so any gaps in shift coverage don't distort the
-- time axis used by the regression in Step 11.
-- ---------------------------------------------------------------
IF OBJECT_ID('tempdb..#Monthly') IS NOT NULL DROP TABLE #Monthly;

SELECT
    Hospital_ID,
    YEAR(Shift_Date)                                          AS [Year],
    MONTH(Shift_Date)                                          AS [Month],
    ((YEAR(Shift_Date) - 2024) * 12) + MONTH(Shift_Date)       AS Period,   -- x-axis for regression
    SUM(Overtime_Hours)                                        AS Overtime_Hours,
    AVG(Burnout_Risk_Index)                                    AS Burnout_Risk_Index
INTO #Monthly
FROM dbo.Staffing
GROUP BY Hospital_ID, YEAR(Shift_Date), MONTH(Shift_Date);
GO


-- ---------------------------------------------------------------
-- 11 — FIT THE TREND LINES (LEAST-SQUARES REGRESSION)
-- Standard formulas: slope = (n?xy - ?x?y) / (n?x² - (?x)²)
-- intercept = (?y - slope*?x) / n
-- ---------------------------------------------------------------
IF OBJECT_ID('tempdb..#RegressionStats') IS NOT NULL DROP TABLE #RegressionStats;

SELECT
    Hospital_ID,
    COUNT(*)                                     AS N,
    MAX(Period)                                  AS LastPeriod,
    SUM(Period)                                  AS SumX,
    SUM(Period * 1.0 * Period)                   AS SumX2,
    SUM(Overtime_Hours)                          AS SumY_OT,
    SUM(Period * 1.0 * Overtime_Hours)           AS SumXY_OT,
    SUM(Burnout_Risk_Index)                      AS SumY_Burn,
    SUM(Period * 1.0 * Burnout_Risk_Index)       AS SumXY_Burn
INTO #RegressionStats
FROM #Monthly
GROUP BY Hospital_ID;
GO

IF OBJECT_ID('tempdb..#Coefficients') IS NOT NULL DROP TABLE #Coefficients;

SELECT
    Hospital_ID,
    LastPeriod,
    -- Overtime-hours trend line
    (N * SumXY_OT - SumX * SumY_OT) * 1.0 / NULLIF((N * SumX2 - SumX * SumX), 0)          AS OT_Slope,
    (SumY_OT - ((N * SumXY_OT - SumX * SumY_OT) * 1.0 / NULLIF((N * SumX2 - SumX * SumX), 0)) * SumX) / N AS OT_Intercept,
    -- Burnout-index trend line
    (N * SumXY_Burn - SumX * SumY_Burn) * 1.0 / NULLIF((N * SumX2 - SumX * SumX), 0)      AS Burn_Slope,
    (SumY_Burn - ((N * SumXY_Burn - SumX * SumY_Burn) * 1.0 / NULLIF((N * SumX2 - SumX * SumX), 0)) * SumX) / N AS Burn_Intercept
INTO #Coefficients
FROM #RegressionStats;
GO


-- ---------------------------------------------------------------
--  12 — PROJECT THE NEXT 6 MONTHS PER HOSPITAL
-- ---------------------------------------------------------------
IF OBJECT_ID('tempdb..#FuturePeriods') IS NOT NULL DROP TABLE #FuturePeriods;

;WITH Steps AS (               -- 1..6 month-ahead offsets
    SELECT 1 AS StepNum
    UNION ALL
    SELECT StepNum + 1 FROM Steps WHERE StepNum < 6
)
SELECT
    c.Hospital_ID,
    s.StepNum,
    c.LastPeriod + s.StepNum                                          AS Period,
    2024 + ((c.LastPeriod + s.StepNum - 1) / 12)                      AS Forecast_Year,
    ((c.LastPeriod + s.StepNum - 1) % 12) + 1                         AS Forecast_Month
INTO #FuturePeriods
FROM #Coefficients c
CROSS JOIN Steps s
OPTION (MAXRECURSION 10);
GO


-- ---------------------------------------------------------------
--  13 — THE FORECAST: 6-MONTH OVERTIME & BURNOUT PER HOSPITAL
-- Applies the trend lines from Step 11 and flags hospitals heading
-- toward unsustainable workforce strain before it hits the rosters.
-- ---------------------------------------------------------------
SELECT
    h.Hospital_Name,
    fp.Hospital_ID,
    fp.Forecast_Year,
    fp.Forecast_Month,
    ROUND(c.OT_Intercept   + c.OT_Slope   * fp.Period, 1)              AS Forecast_Overtime_Hours,
    ROUND(c.Burn_Intercept + c.Burn_Slope * fp.Period, 3)              AS Forecast_Burnout_Index,
    CASE
        WHEN (c.Burn_Intercept + c.Burn_Slope * fp.Period) > 0.65
            THEN 'At Risk: burnout trending into critical range'
        WHEN c.Burn_Slope > 0 AND c.OT_Slope > 0
            THEN 'At Risk: burnout and overtime rising together'
        ELSE 'Healthy trend'
    END                                                                 AS Risk_Flag
FROM #FuturePeriods fp
JOIN #Coefficients c  ON c.Hospital_ID = fp.Hospital_ID
JOIN dbo.Hospital h   ON h.Hospital_ID = fp.Hospital_ID
ORDER BY fp.Hospital_ID, fp.Period;
GO


-- ---------------------------------------------------------------
-- 14 — CLOSING SUMMARY: WHO NEEDS WORKFORCE ATTENTION NEXT
-- The final beat of the story: a one-row-per-hospital ranking, worst
-- burnout trend first, so HR/Ops knows exactly where to intervene.
-- ---------------------------------------------------------------
SELECT
    h.Hospital_Name,
    c.Hospital_ID,
    ROUND(c.OT_Slope, 2)    AS Monthly_Overtime_Trend,     
    ROUND(c.Burn_Slope, 4)  AS Monthly_Burnout_Trend,       
    CASE WHEN c.Burn_Slope > 0 THEN 'Yes' ELSE 'No' END AS Burnout_Rising
FROM #Coefficients c
JOIN dbo.Hospital h ON h.Hospital_ID = c.Hospital_ID
ORDER BY c.Burn_Slope DESC;
GO