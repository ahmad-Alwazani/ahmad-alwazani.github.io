

USE [StudioManagementDB_New];
GO

IF OBJECT_ID('dbo.FactSessions','V') IS NOT NULL DROP VIEW dbo.FactSessions;
IF OBJECT_ID('dbo.FactBookings','V') IS NOT NULL DROP VIEW dbo.FactBookings;
IF OBJECT_ID('dbo.DimStudio','V')   IS NOT NULL DROP VIEW dbo.DimStudio;
IF OBJECT_ID('dbo.DimClass','V')    IS NOT NULL DROP VIEW dbo.DimClass;
IF OBJECT_ID('dbo.DimTrainer','V')  IS NOT NULL DROP VIEW dbo.DimTrainer;
IF OBJECT_ID('dbo.DimClient','V')   IS NOT NULL DROP VIEW dbo.DimClient;
GO

CREATE VIEW dbo.DimClient AS
SELECT
  c.ClientID,
  c.Gender,
  CASE
    WHEN c.BirthDate IS NULL THEN NULL
    WHEN DATEDIFF(year, c.BirthDate, GETDATE()) < 25 THEN '<25'
    WHEN DATEDIFF(year, c.BirthDate, GETDATE()) BETWEEN 25 AND 34 THEN '25-34'
    WHEN DATEDIFF(year, c.BirthDate, GETDATE()) BETWEEN 35 AND 44 THEN '35-44'
    WHEN DATEDIFF(year, c.BirthDate, GETDATE()) BETWEEN 45 AND 54 THEN '45-54'
    ELSE '55+'
  END AS AgeBand,
  c.JoinDate,
  CASE WHEN c.IsActive = 1 THEN 'Active' ELSE 'Inactive' END AS [Status]
FROM dbo.Clients c;
GO

CREATE VIEW dbo.DimTrainer AS
SELECT
  t.TrainerID,
  t.TrainerName,
  t.Specialty
FROM dbo.Trainers t;
GO

CREATE VIEW dbo.DimClass AS
SELECT
  ct.ClassTypeID AS ClassID,
  ct.ClassName,
 
  CAST(NULL AS nvarchar(50)) AS Category,
 
  MAX(ISNULL(s.MaxCapacity, 0)) AS Capacity
FROM dbo.ClassTypes ct
LEFT JOIN dbo.Sessions s
  ON s.ClassTypeID = ct.ClassTypeID
GROUP BY ct.ClassTypeID, ct.ClassName;
GO

CREATE VIEW dbo.DimStudio AS
SELECT
  st.StudioID,
  st.StudioName,
  
  st.Location AS City,
  CAST(NULL AS nvarchar(50)) AS Region
FROM dbo.Studios st;
GO


CREATE VIEW dbo.FactBookings AS
SELECT
  b.BookingID,
  b.ClientID,
  s.ClassTypeID AS ClassID,
  s.StudioID,
  s.TrainerID,
  (YEAR(b.BookingDate) * 10000) + (MONTH(b.BookingDate) * 100) + DAY(b.BookingDate) AS BookingDateKey,
  b.PriceAtBooking         AS Price,
  CAST(0.00 AS decimal(10,2)) AS Discount,  
  ISNULL((
    SELECT SUM(p.Amount)
    FROM dbo.Payments p
    WHERE p.BookingID = b.BookingID
      AND (p.[Status] IN ('Paid','Completed') OR p.[Status] IS NULL)
  ), 0.00) AS Revenue,
  
  CASE WHEN b.[Status] = 'Completed' THEN 1 ELSE 0 END AS AttendanceFlag
FROM dbo.Bookings b
JOIN dbo.Sessions s ON s.SessionID = b.SessionID;
GO


CREATE VIEW dbo.FactSessions AS
SELECT
  s.SessionID,
  s.ClassTypeID AS ClassID,
  s.StudioID,
  s.TrainerID,
  (YEAR(s.StartDate) * 10000) + (MONTH(s.StartDate) * 100) + DAY(s.StartDate) AS StartDateKey,
  ISNULL(s.AttendeesCount, 0) AS Attendees,
  s.MaxCapacity               AS Capacity,
  s.[Status]
FROM dbo.Sessions s;
GO
