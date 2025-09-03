

USE [StudioManagementDB_New];
GO

SET NOCOUNT ON;
GO

IF OBJECT_ID('dbo.FK_Payments_Booking', 'F') IS NOT NULL
    ALTER TABLE dbo.Payments DROP CONSTRAINT FK_Payments_Booking;
GO

IF OBJECT_ID('dbo.FK_Payments_Date', 'F') IS NOT NULL
    ALTER TABLE dbo.Payments DROP CONSTRAINT FK_Payments_Date;
GO

IF OBJECT_ID('dbo.FK_Bookings_Client', 'F') IS NOT NULL
    ALTER TABLE dbo.Bookings DROP CONSTRAINT FK_Bookings_Client;
GO

IF OBJECT_ID('dbo.FK_Bookings_Session', 'F') IS NOT NULL
    ALTER TABLE dbo.Bookings DROP CONSTRAINT FK_Bookings_Session;
GO

IF OBJECT_ID('dbo.FK_Bookings_Date', 'F') IS NOT NULL
    ALTER TABLE dbo.Bookings DROP CONSTRAINT FK_Bookings_Date;
GO

IF OBJECT_ID('dbo.FK_Sessions_ClassType', 'F') IS NOT NULL
    ALTER TABLE dbo.Sessions DROP CONSTRAINT FK_Sessions_ClassType;
GO

IF OBJECT_ID('dbo.FK_Sessions_Date', 'F') IS NOT NULL
    ALTER TABLE dbo.Sessions DROP CONSTRAINT FK_Sessions_Date;
GO

IF OBJECT_ID('dbo.FK_Sessions_Studio', 'F') IS NOT NULL
    ALTER TABLE dbo.Sessions DROP CONSTRAINT FK_Sessions_Studio;
GO

IF OBJECT_ID('dbo.FK_Sessions_Trainer', 'F') IS NOT NULL
    ALTER TABLE dbo.Sessions DROP CONSTRAINT FK_Sessions_Trainer;
GO

-- Drop Tables (in reverse dependency order)
IF OBJECT_ID(N'dbo.DimDate', N'U') IS NOT NULL DROP TABLE dbo.DimDate;
GO

IF OBJECT_ID(N'dbo.Clients', N'U') IS NOT NULL DROP TABLE dbo.Clients;
GO

IF OBJECT_ID(N'dbo.ClassTypes', N'U') IS NOT NULL DROP TABLE dbo.ClassTypes;
GO

IF OBJECT_ID(N'dbo.Studios', N'U') IS NOT NULL DROP TABLE dbo.Studios;
GO

IF OBJECT_ID(N'dbo.Trainers', N'U') IS NOT NULL DROP TABLE dbo.Trainers;
GO

IF OBJECT_ID(N'dbo.Sessions', N'U') IS NOT NULL DROP TABLE dbo.Sessions;
GO

IF OBJECT_ID(N'dbo.Bookings', N'U') IS NOT NULL DROP TABLE dbo.Bookings;
GO

IF OBJECT_ID(N'dbo.Payments', N'U') IS NOT NULL DROP TABLE dbo.Payments;
GO

CREATE TABLE dbo.DimDate
(
    DateKey      int           NOT NULL,
    [Date]       date          NOT NULL,
    [Year]       int           NOT NULL,
    Quarter      tinyint       NOT NULL,
    MonthNumber  tinyint       NOT NULL,
    MonthName    nvarchar(12)  NOT NULL,
    [Day]        tinyint       NOT NULL,
    DayName      nvarchar(12)  NOT NULL,
    IsWeekend    bit           NOT NULL,
    CONSTRAINT PK_DimDate      PRIMARY KEY CLUSTERED (DateKey),
    CONSTRAINT UQ_DimDate_Date UNIQUE ([Date])
);
GO

-- Clients
CREATE TABLE dbo.Clients
(
    ClientID   int IDENTITY(1,1) NOT NULL,
    FirstName  nvarchar(50)  NOT NULL,
    LastName   nvarchar(50)  NOT NULL,
    Email      nvarchar(100) NULL,
    Phone      nvarchar(25)  NULL,
    Gender     char(1)       NULL,
    BirthDate  date          NULL,
    JoinDate   date          NOT NULL,
    IsActive   bit           NOT NULL CONSTRAINT DF_Clients_IsActive DEFAULT (1),
    CONSTRAINT PK_Clients PRIMARY KEY CLUSTERED (ClientID)
);
GO

CREATE TABLE dbo.ClassTypes
(
    ClassTypeID int IDENTITY(1,1) NOT NULL,
    ClassName   nvarchar(80) NOT NULL,
    Difficulty  tinyint      NOT NULL,
    BasePrice   decimal(10,2) NOT NULL,
    IsActive    bit          NOT NULL CONSTRAINT DF_ClassTypes_IsActive DEFAULT (1),
    CONSTRAINT PK_ClassTypes PRIMARY KEY CLUSTERED (ClassTypeID)
);
GO

CREATE TABLE dbo.Studios
(
    StudioID   int IDENTITY(1,1) NOT NULL,
    StudioName nvarchar(100) NOT NULL,
    Location   nvarchar(100) NULL,
    Capacity   int NOT NULL,
    CONSTRAINT PK_Studios PRIMARY KEY CLUSTERED (StudioID)
);
GO

CREATE TABLE dbo.Trainers
(
    TrainerID   int IDENTITY(1,1) NOT NULL,
    TrainerName nvarchar(100) NOT NULL,
    Specialty   nvarchar(50)  NULL,
    HireDate    date          NOT NULL,
    IsActive    bit           NOT NULL CONSTRAINT DF_Trainers_IsActive DEFAULT (1),
    CONSTRAINT PK_Trainers PRIMARY KEY CLUSTERED (TrainerID)
);
GO

CREATE TABLE dbo.Sessions
(
    SessionID        int IDENTITY(1,1) NOT NULL,
    ClassTypeID      int       NOT NULL,
    TrainerID        int       NOT NULL,
    StudioID         int       NOT NULL,
    StartDate        date      NOT NULL,
    StartTime        time(7)   NOT NULL,
    StartDateTime    datetime2(0) NOT NULL,
    DurationMinutes  int       NOT NULL,
    MaxCapacity      int       NOT NULL,
    [Status]         nvarchar(20) NOT NULL,
    AttendeesCount   int       NULL,
    CONSTRAINT PK_Sessions PRIMARY KEY CLUSTERED (SessionID)
);
GO

CREATE TABLE dbo.Bookings
(
    BookingID      int IDENTITY(1,1) NOT NULL,
    ClientID       int       NOT NULL,
    SessionID      int       NOT NULL,
    BookingDate    date      NOT NULL,
    [Status]       nvarchar(20) NOT NULL,
    PriceAtBooking decimal(10,2) NOT NULL,
    CONSTRAINT PK_Bookings PRIMARY KEY CLUSTERED (BookingID)
);
GO

CREATE TABLE dbo.Payments
(
    PaymentID   int IDENTITY(1,1) NOT NULL,
    BookingID   int       NOT NULL,
    PaymentDate date      NOT NULL,
    Amount      decimal(10,2) NOT NULL,
    [Method]    nvarchar(20) NOT NULL,
    [Status]    nvarchar(20) NOT NULL,
    Purpose     nvarchar(30) NOT NULL,
    CONSTRAINT PK_Payments PRIMARY KEY CLUSTERED (PaymentID)
);
GO


ALTER TABLE dbo.Bookings  ADD CONSTRAINT FK_Bookings_Client
    FOREIGN KEY (ClientID) REFERENCES dbo.Clients (ClientID);
GO

ALTER TABLE dbo.Bookings  ADD CONSTRAINT FK_Bookings_Session
    FOREIGN KEY (SessionID) REFERENCES dbo.Sessions (SessionID);
GO

ALTER TABLE dbo.Bookings  ADD CONSTRAINT FK_Bookings_Date
    FOREIGN KEY (BookingDate) REFERENCES dbo.DimDate ([Date]);
GO

ALTER TABLE dbo.Payments  ADD CONSTRAINT FK_Payments_Booking
    FOREIGN KEY (BookingID) REFERENCES dbo.Bookings (BookingID);
GO

ALTER TABLE dbo.Payments  ADD CONSTRAINT FK_Payments_Date
    FOREIGN KEY (PaymentDate) REFERENCES dbo.DimDate ([Date]);
GO

ALTER TABLE dbo.Sessions  ADD CONSTRAINT FK_Sessions_ClassType
    FOREIGN KEY (ClassTypeID) REFERENCES dbo.ClassTypes (ClassTypeID);
GO

ALTER TABLE dbo.Sessions  ADD CONSTRAINT FK_Sessions_Date
    FOREIGN KEY (StartDate) REFERENCES dbo.DimDate ([Date]);
GO

ALTER TABLE dbo.Sessions  ADD CONSTRAINT FK_Sessions_Studio
    FOREIGN KEY (StudioID) REFERENCES dbo.Studios (StudioID);
GO

ALTER TABLE dbo.Sessions  ADD CONSTRAINT FK_Sessions_Trainer
    FOREIGN KEY (TrainerID) REFERENCES dbo.Trainers (TrainerID);
GO

PRINT 'Schema deployed successfully.';
GO