/* =====================================================================
   CODE BLUE — PREDICTIVE FINANCIAL ANALYSIS
   EMERGENCY OPERATIONS & PATIENT FLOW NETWORK
   T-SQL SCRIPT (MS SQL Server)

   Story arc: start at the network level, drill into hospitals, break
   cost down, look at it over time, check capital spend, check funding
   reliance, link it back to operations, build a standing risk view —
   then turn that diagnosis into a forward-looking forecast so finance
   knows not just where the network stands today, but where it's headed.
   ===================================================================== */


/* ---------------------------------------------------------------------
    1 — NETWORK-WIDE FINANCIAL POSITION
   The starting point of the story: is the network, taken as a whole,
   making money? What does its overall cost structure look like?
   --------------------------------------------------------------------- */
SELECT
    ROUND(SUM(Revenue), 0) AS Total_Revenue,
    ROUND(SUM(Operational_Cost), 0) AS Total_Operational_Cost,
    ROUND(SUM(Revenue) - SUM(Operational_Cost), 0) AS Net_Result,
    ROUND(SUM(Government_Funding), 0) AS Total_Government_Funding,
    ROUND(SUM(Equipment_Investment), 0)  AS Total_Equipment_Investment,
    ROUND(AVG(Profit_Margin), 3) AS Avg_Profit_Margin,
    ROUND(100.0 * SUM(Staffing_Cost) / SUM(Operational_Cost), 1) AS Staffing_Pct_of_Cost,
    ROUND(100.0 * SUM(Emergency_Department_Cost) / SUM(Operational_Cost), 1) AS ED_Pct_of_Cost,
    ROUND(100.0 * SUM(ICU_Cost) / SUM(Operational_Cost), 1)      AS ICU_Pct_of_Cost
FROM dbo.Financials;


/* ---------------------------------------------------------------------
   2 — HOSPITAL-LEVEL FINANCIAL SUMMARY
   Now that we know the network overall is healthy, find out whether
   that health is evenly spread, or whether it's hiding weak
   individual sites. Sorted weakest margin first.
   --------------------------------------------------------------------- */
SELECT h.Hospital_Name,
       ROUND(SUM(f.Revenue), 0) AS Revenue,
       ROUND(SUM(f.Operational_Cost), 0) AS OpCost,
       ROUND(SUM(f.Revenue) - SUM(f.Operational_Cost), 0)  AS Net_Result,
       ROUND(AVG(f.Profit_Margin), 3) AS Avg_Margin,
       ROUND(SUM(f.Government_Funding), 0) AS Gov_Funding,
       ROUND(SUM(f.Equipment_Investment), 0) AS Equipment_Investment
FROM dbo.Financials f
JOIN dbo.Hospital h ON f.Hospital_ID = h.Hospital_ID
GROUP BY h.Hospital_Name
ORDER BY Avg_Margin;


/* ---------------------------------------------------------------------
   3 — COST & REVENUE STRUCTURE BY HOSPITAL
   We know margins vary by hospital — now break each hospital's cost
   base down by category (staffing, ED, ICU) to see WHERE the money
   is actually going, and whether weak-margin hospitals share a
   common cost pattern.
   --------------------------------------------------------------------- */
SELECT h.Hospital_Name,
       ROUND(SUM(f.Revenue), 0) AS Total_Revenue,
       ROUND(SUM(f.Operational_Cost), 0) AS Total_OpCost,
       ROUND(SUM(f.Staffing_Cost), 0) AS Total_StaffCost,
       ROUND(SUM(f.Emergency_Department_Cost), 0) AS Total_EDCost,
       ROUND(SUM(f.ICU_Cost), 0) AS Total_ICUCost,
       ROUND(SUM(f.Government_Funding), 0) AS Total_GovFunding,
       ROUND(SUM(f.Equipment_Investment), 0)AS Total_Equipment,
       ROUND(AVG(f.Profit_Margin), 3) AS Avg_Margin,
       ROUND(100.0 * SUM(f.Staffing_Cost) / SUM(f.Operational_Cost), 1) AS StaffCost_Pct_OpCost,
       ROUND(SUM(f.Government_Funding) / SUM(f.Revenue), 3)  AS Gov_Dependency_Ratio
FROM dbo.Financials f
JOIN dbo.Hospital h ON f.Hospital_ID = h.Hospital_ID
GROUP BY h.Hospital_Name
ORDER BY Avg_Margin;


/* ---------------------------------------------------------------------
    4 — PROFITABILITY TREND OVER TIME (QUARTERLY)
   Cost structure is one dimension — time is another. Check whether
   margin is stable across the year or whether the network depends
   on a particular season to stay profitable. A CTE is used so the
   quarter mapping is written once and referenced by name in
   GROUP BY / ORDER BY (T-SQL won't let you reuse a SELECT-list
   alias in GROUP BY directly).
   --------------------------------------------------------------------- */
WITH Quarterly AS (
    SELECT Year,
           CASE WHEN Month <= 3 THEN 'Q1' WHEN Month <= 6 THEN 'Q2'
                WHEN Month <= 9 THEN 'Q3' ELSE 'Q4' END AS Quarter,
           Profit_Margin, Revenue, Operational_Cost
    FROM dbo.Financials
)
SELECT Year, Quarter,
       ROUND(AVG(Profit_Margin), 3) AS Avg_Margin,
       ROUND(SUM(Revenue), 0) AS Revenue,
       ROUND(SUM(Operational_Cost), 0) AS Cost
FROM Quarterly
GROUP BY Year, Quarter
ORDER BY Year, Quarter;


/* ---------------------------------------------------------------------
    5 — CAPITAL ALLOCATION ISSUES
   Margin and seasonality explain operating performance — equipment
   spend tests whether the network is investing in its own future
   consistently, or whether some hospitals are being starved of
   capital while others get expansion funding.
   --------------------------------------------------------------------- */
SELECT Expansion_Projects_Flag,
       COUNT(*) AS Months,
       ROUND(AVG(Profit_Margin), 3) AS Avg_Margin,
       ROUND(AVG(Equipment_Investment), 0) AS Avg_Equipment_Spend
FROM dbo.Financials
GROUP BY Expansion_Projects_Flag;


/* ---------------------------------------------------------------------
   6 — GOVERNMENT FUNDING DEPENDENCY
   With capital allocation in view, check which hospitals lean most
   heavily on government funding relative to their own revenue — a
   proxy for the weakest independent financial engines, separate
   from how big their absolute funding number is.
   --------------------------------------------------------------------- */
SELECT h.Hospital_Name,
       ROUND(SUM(f.Government_Funding) / SUM(f.Revenue), 3) AS Gov_Dependency_Ratio,
       ROUND(SUM(f.Government_Funding), 0) AS Total_Gov_Funding
FROM dbo.Financials f
JOIN dbo.Hospital h ON f.Hospital_ID = h.Hospital_ID
GROUP BY h.Hospital_Name
ORDER BY Gov_Dependency_Ratio DESC;


/* ---------------------------------------------------------------------
   7 — CORRELATING FINANCIAL PERFORMANCE WITH OPERATIONAL METRICS
   The financial picture is now clear — connect it back to operations
   (occupancy, wait times, readmissions, burnout) to test whether
   weak-margin hospitals are also operationally weak, or whether the
   two stories are independent.
   --------------------------------------------------------------------- */
SELECT h.Hospital_Name,
       ROUND(AVG(f.Profit_Margin), 3) AS Avg_Margin,
       ROUND(AVG(f.Bed_Occupancy_Rate), 3)  AS Avg_Occupancy,
       ROUND(AVG(f.Avg_Wait_Time_Minutes), 1) AS Avg_Wait,
       ROUND(AVG(f.Readmission_Rate), 3) AS Avg_Readmit,
       ROUND(AVG(f.Avg_Burnout_Index), 3) AS Avg_Burnout,
       ROUND(SUM(f.Government_Funding) / SUM(f.Revenue), 3) AS Gov_Dependency
FROM dbo.Financials f
JOIN dbo.Hospital h ON f.Hospital_ID = h.Hospital_ID
GROUP BY h.Hospital_Name;


/* ---------------------------------------------------------------------
    8 — STANDING RISK-MONITORING VIEW (CURRENT-STATE)
   Turn the historical diagnosis into something reusable: a view that
   always reflects current data and classifies each hospital as
   STABLE, WATCH, or HIGH RISK based on margin and government-funding
   dependency together (run once to create; query it afterwards).
   --------------------------------------------------------------------- */
CREATE VIEW vw_Hospital_Financial_Risk AS
SELECT h.Hospital_Name,
       AVG(f.Profit_Margin)AS Margin,
       AVG(f.Bed_Occupancy_Rate) AS Occupancy,
       SUM(f.Government_Funding) /SUM(f.Revenue)AS Gov_Dependency,
       AVG(f.Readmission_Rate) AS Readmit_Rate,
       AVG(f.Avg_Burnout_Index) AS Burnout,
       CASE WHEN AVG(f.Profit_Margin) < 0.16
             AND SUM(f.Government_Funding) / SUM(f.Revenue) > 0.12
            THEN 'HIGH RISK'
            WHEN AVG(f.Profit_Margin) < 0.18 THEN 'WATCH'
            ELSE 'STABLE' END AS Risk_Flag
FROM dbo.Financials f
JOIN dbo.Hospital h ON f.Hospital_ID = h.Hospital_ID
GROUP BY h.Hospital_Name;
GO


/* ---------------------------------------------------------------------
    9 — CURRENT-STATE MONITORING QUERY
   A simple, repeatable query finance can re-run each reporting period
   to see which hospitals need a priority review or are
   under-capitalized, based on where things stand TODAY. This closes
   the diagnostic half of the story — everything from here forward
   looks ahead instead of back.
   --------------------------------------------------------------------- */
SELECT h.Hospital_Name,
       ROUND(AVG(f.Profit_Margin), 3) AS Margin,
       ROUND(SUM(f.Government_Funding) / SUM(f.Revenue), 3) AS Gov_Dependency,
       ROUND(SUM(f.Equipment_Investment), 0) AS Equipment_Spend,
       CASE WHEN AVG(f.Profit_Margin) < 0.16 THEN 'PRIORITY REVIEW'
            WHEN SUM(f.Equipment_Investment) < 1000000 THEN 'UNDER-CAPITALIZED'
            ELSE 'STABLE' END  AS Flag
FROM dbo.Financials f
JOIN dbo.Hospital h ON f.Hospital_ID = h.Hospital_ID
GROUP BY h.Hospital_Name
ORDER BY Margin;


/* =====================================================================
   PART 2 — PREDICTIVE FORECAST
   Steps 1-9 diagnosed where the network stands today. From here, we
   fit a per-hospital trend line to the monthly actuals and project it
   6 months forward, so risk can be flagged BEFORE it shows up in next
   quarter's actuals.

   Method: least-squares linear regression on Fact_Financials, run
   separately for Revenue and Operational_Cost, then Profit_Margin is
   derived from the two forecasts (not regressed directly, which would
   compound noise from both inputs).
   ===================================================================== */

-- ---------------------------------------------------------------
--  10 — BUILD THE FORECAST INPUT SERIES
-- Period = months since Jan 2024, so gaps in reporting don't distort
-- the time axis. This feeds the regression in Step 11.
-- ---------------------------------------------------------------
IF OBJECT_ID('tempdb..#Monthly') IS NOT NULL DROP TABLE #Monthly;

SELECT
    Hospital_ID,
    [Year],
    [Month],
    (([Year] - 2024) * 12) + [Month]      AS Period,      -- x-axis for regression
    Revenue,
    Operational_Cost,
    Profit_Margin
INTO #Monthly
FROM dbo.Financials;
GO


-- ---------------------------------------------------------------
--  11 — FIT THE TREND LINES (LEAST-SQUARES REGRESSION)
-- Standard formulas: slope = (nΣxy - ΣxΣy) / (nΣx² - (Σx)²)
--                     intercept = (Σy - slope*Σx) / n
-- ---------------------------------------------------------------
IF OBJECT_ID('tempdb..#RegressionStats') IS NOT NULL DROP TABLE #RegressionStats;

SELECT
    Hospital_ID,
    COUNT(*)                                AS N,
    MAX(Period)                             AS LastPeriod,
    SUM(Period)                             AS SumX,
    SUM(Period * 1.0 * Period)              AS SumX2,
    SUM(Revenue)                            AS SumY_Rev,
    SUM(Period * 1.0 * Revenue)             AS SumXY_Rev,
    SUM(Operational_Cost)                   AS SumY_Cost,
    SUM(Period * 1.0 * Operational_Cost)    AS SumXY_Cost
INTO #RegressionStats
FROM #Monthly
GROUP BY Hospital_ID;
GO

IF OBJECT_ID('tempdb..#Coefficients') IS NOT NULL DROP TABLE #Coefficients;

SELECT
    Hospital_ID,
    LastPeriod,
    -- Revenue trend line
    (N * SumXY_Rev - SumX * SumY_Rev) * 1.0 / NULLIF((N * SumX2 - SumX * SumX), 0)        AS Rev_Slope,
    (SumY_Rev - ((N * SumXY_Rev - SumX * SumY_Rev) * 1.0 / NULLIF((N * SumX2 - SumX * SumX), 0)) * SumX) / N AS Rev_Intercept,
    -- Cost trend line
    (N * SumXY_Cost - SumX * SumY_Cost) * 1.0 / NULLIF((N * SumX2 - SumX * SumX), 0)       AS Cost_Slope,
    (SumY_Cost - ((N * SumXY_Cost - SumX * SumY_Cost) * 1.0 / NULLIF((N * SumX2 - SumX * SumX), 0)) * SumX) / N AS Cost_Intercept
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
--  13 — THE FORECAST: 6-MONTH REVENUE, COST & MARGIN PER HOSPITAL
-- Applies the trend lines from Step 11, derives margin, and flags
-- hospitals moving toward financial risk before it hits the actuals.
-- ---------------------------------------------------------------
SELECT
    h.Hospital_Name,
    fp.Hospital_ID,
    fp.Forecast_Year,
    fp.Forecast_Month,
    ROUND(c.Rev_Intercept  + c.Rev_Slope  * fp.Period, 0)              AS Forecast_Revenue,
    ROUND(c.Cost_Intercept + c.Cost_Slope * fp.Period, 0)              AS Forecast_Operational_Cost,
    ROUND(
        (c.Rev_Intercept  + c.Rev_Slope  * fp.Period
       - (c.Cost_Intercept + c.Cost_Slope * fp.Period))
       / NULLIF(c.Rev_Intercept + c.Rev_Slope * fp.Period, 0)
    , 4)                                                                AS Forecast_Profit_Margin,
    CASE
        WHEN c.Cost_Slope > c.Rev_Slope
            THEN 'At Risk: costs growing faster than revenue'
        WHEN (c.Rev_Intercept + c.Rev_Slope * fp.Period
            - (c.Cost_Intercept + c.Cost_Slope * fp.Period)) < 0
            THEN 'At Risk: forecast net loss'
        ELSE 'Healthy trend'
    END                                                                 AS Risk_Flag
FROM #FuturePeriods fp
JOIN #Coefficients c  ON c.Hospital_ID = fp.Hospital_ID
JOIN dbo.Hospital h   ON h.Hospital_ID = fp.Hospital_ID
ORDER BY fp.Hospital_ID, fp.Period;
GO


-- ---------------------------------------------------------------
--  14 — CLOSING SUMMARY: WHO NEEDS ATTENTION NEXT
-- The final beat of the story: a one-row-per-hospital ranking, worst
-- forecast trend first, so finance knows exactly where to intervene.
-- ---------------------------------------------------------------
SELECT
    h.Hospital_Name,
    c.Hospital_ID,
    ROUND(c.Rev_Slope, 0) AS Monthly_Revenue_Trend,    
    ROUND(c.Cost_Slope, 0) AS Monthly_Cost_Trend,      
    CASE WHEN c.Cost_Slope > c.Rev_Slope THEN 'Yes' ELSE 'No' END AS Cost_Outpacing_Revenue
FROM #Coefficients c
JOIN dbo.Hospital h ON h.Hospital_ID = c.Hospital_ID
ORDER BY ROUND(c.Cost_Slope, 0) - ROUND(c.Rev_Slope, 0) DESC;
GO
