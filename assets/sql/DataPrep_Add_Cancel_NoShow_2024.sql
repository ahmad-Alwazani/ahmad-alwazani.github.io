USE [StudioManagementDB_New];
SET NOCOUNT ON;

BEGIN TRAN;

IF OBJECT_ID('tempdb..#all2024')     IS NOT NULL DROP TABLE #all2024;
IF OBJECT_ID('tempdb..#pick_cancel') IS NOT NULL DROP TABLE #pick_cancel;
IF OBJECT_ID('tempdb..#pick_noshow') IS NOT NULL DROP TABLE #pick_noshow;

IF OBJECT_ID(N'dbo.Bookings', N'U') IS NULL
BEGIN
    RAISERROR('dbo.Bookings not found in this database.',16,1);
    ROLLBACK TRAN;
    RETURN;
END;

UPDATE dbo.Bookings
SET    Status = 'Completed'
WHERE  BookingDate >= '2024-01-01'
   AND BookingDate <  '2025-01-01'
   AND Status IN ('Cancelled','No-Show');

SELECT BookingID
INTO   #all2024
FROM   dbo.Bookings
WHERE  BookingDate >= '2024-01-01'
  AND  BookingDate <  '2025-01-01'
  AND  Status = 'Completed';

SELECT TOP (5) PERCENT BookingID
INTO   #pick_cancel
FROM   #all2024
ORDER  BY NEWID();

SELECT TOP (2) PERCENT a.BookingID
INTO   #pick_noshow
FROM   #all2024 a
LEFT   JOIN #pick_cancel c ON c.BookingID = a.BookingID
WHERE  c.BookingID IS NULL
ORDER  BY NEWID();

UPDATE b
SET    b.Status = 'Cancelled'
FROM   dbo.Bookings AS b
JOIN   #pick_cancel c ON c.BookingID = b.BookingID;

UPDATE b
SET    b.Status = 'No-Show'
FROM   dbo.Bookings AS b
JOIN   #pick_noshow n ON n.BookingID = b.BookingID;

SELECT Status, COUNT(*) AS Cnt
FROM   dbo.Bookings
WHERE  BookingDate >= '2024-01-01'
  AND  BookingDate <  '2025-01-01'
GROUP  BY Status
ORDER  BY Status;

COMMIT;
