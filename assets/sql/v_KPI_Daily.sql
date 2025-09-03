USE [StudioManagementDB_New];
SET NOCOUNT ON;

-- 1) Does the view exist?
SELECT name AS ViewName, create_date
FROM sys.views
WHERE name = 'v_KPI_Daily';

-- 2) Row-count should equal DimDate (you seeded 2024-01-01 .. 2025-12-31)
SELECT 
  DimDateRows = COUNT(*) 
FROM dbo.DimDate;

SELECT 
  ViewRows = COUNT(*) 
FROM dbo.v_KPI_Daily;

-- 3) Date range visible in the view (min/max)
SELECT MIN([Date]) AS MinDate, MAX([Date]) AS MaxDate
FROM dbo.v_KPI_Daily;

-- 4) Quick sample – latest 7 days
SELECT TOP (7) *
FROM dbo.v_KPI_Daily
ORDER BY [Date] DESC;

-- 5) Reconcile revenue total (cash view) against Payments (excluding Refunded)
SELECT 
  ViewRevenue   = SUM(v.TotalRevenue),
  PaymentsTotal = (SELECT SUM(p.Amount) FROM dbo.Payments p WHERE p.Status <> 'Refunded')
FROM dbo.v_KPI_Daily v;

-- 6) Basic boundaries – rates should be between 0 and 1; flag any outliers
SELECT *
FROM dbo.v_KPI_Daily
WHERE CancellationRate < 0 OR CancellationRate > 1
   OR UtilizationRate < 0 OR UtilizationRate > 1;

-- 7) Spot-check a specific day (change @d if you like)
DECLARE @d date = '2024-06-15';

SELECT 'View row' AS What, v.*
FROM dbo.v_KPI_Daily v
WHERE v.[Date] = @d;

-- Manual recompute from base tables for the same @d
SELECT 'Manual – bookings' AS What,
       COUNT(*)                                  AS TotalBookings,
       SUM(CASE WHEN b.Status='Cancelled' THEN 1 ELSE 0 END) AS CancelledBookings,
       COUNT(DISTINCT b.ClientID)                AS DistinctBookers,
       CAST(1.0 * COUNT(*) / NULLIF(COUNT(DISTINCT b.ClientID),0) AS DECIMAL(10,2)) AS AvgSessionsPerClient,
       CAST(1.0 * SUM(b.PriceAtBooking) / NULLIF(COUNT(*),0)      AS DECIMAL(18,2)) AS AvgPricePerBooking
FROM dbo.Bookings b
WHERE b.BookingDate = @d;

SELECT 'Manual – payments' AS What,
       SUM(p.Amount) AS TotalRevenue,
       CAST(1.0 * SUM(p.Amount) / NULLIF(COUNT(*),0) AS DECIMAL(18,2)) AS AvgRevenuePerPayment
FROM dbo.Payments p
WHERE p.PaymentDate = @d AND p.Status <> 'Refunded';

SELECT 'Manual – sessions' AS What,
       COUNT(*) AS SessionsCount,
       SUM(s.MaxCapacity) AS TotalCapacity,
       CAST(1.0 * SUM(ISNULL(s.AttendeesCount,0)) / NULLIF(SUM(s.MaxCapacity),0) AS DECIMAL(8,4)) AS UtilizationRate
FROM dbo.Sessions s
WHERE s.StartDate = @d;
