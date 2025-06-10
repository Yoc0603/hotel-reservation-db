-- ==========================================
-- 1. DATABASE CREATION
-- ==========================================
CREATE DATABASE HotelReservationDB;
GO
USE HotelReservationDB;
GO

-- ==========================================
-- 2. TABLE CREATION
-- ==========================================

-- Customers table
CREATE TABLE Customers (
    CustomerID INT IDENTITY(1,1) PRIMARY KEY,
    FirstName NVARCHAR(50) NOT NULL,
    LastName NVARCHAR(50) NOT NULL,
    Email NVARCHAR(100),
    Phone NVARCHAR(20),
    IDNumber NVARCHAR(11) UNIQUE
);

-- RoomTypes table
CREATE TABLE RoomTypes (
    RoomTypeID INT IDENTITY(1,1) PRIMARY KEY,
    TypeName NVARCHAR(50) NOT NULL,
    Description NVARCHAR(255)
);

-- Rooms table
CREATE TABLE Rooms (
    RoomID INT IDENTITY(1,1) PRIMARY KEY,
    RoomNumber NVARCHAR(10) NOT NULL,
    Floor INT,
    PricePerNight DECIMAL(8,2) NOT NULL,
    RoomTypeID INT NOT NULL,
    IsAvailable BIT DEFAULT 1,
    FOREIGN KEY (RoomTypeID) REFERENCES RoomTypes(RoomTypeID)
);

-- Reservations table
CREATE TABLE Reservations (
    ReservationID INT IDENTITY(1,1) PRIMARY KEY,
    CustomerID INT NOT NULL,
    RoomID INT NOT NULL,
    CheckInDate DATE NOT NULL,
    CheckOutDate DATE NOT NULL,
    ReservationDate DATE DEFAULT GETDATE(),
    Status NVARCHAR(20) DEFAULT 'Pending',
    FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID),
    FOREIGN KEY (RoomID) REFERENCES Rooms(RoomID)
);

-- Payments table
CREATE TABLE Payments (
    PaymentID INT IDENTITY(1,1) PRIMARY KEY,
    ReservationID INT NOT NULL,
    Amount DECIMAL(10,2) NOT NULL,
    PaymentDate DATE DEFAULT GETDATE(),
    Method NVARCHAR(30),
    FOREIGN KEY (ReservationID) REFERENCES Reservations(ReservationID)
);

-- Services table
CREATE TABLE Services (
    ServiceID INT IDENTITY(1,1) PRIMARY KEY,
    Name NVARCHAR(50) NOT NULL,
    Price DECIMAL(7,2) NOT NULL
);

-- ReservationServices table (M:N relationship)
CREATE TABLE ReservationServices (
    ReservationID INT NOT NULL,
    ServiceID INT NOT NULL,
    Quantity INT DEFAULT 1,
    PRIMARY KEY (ReservationID, ServiceID),
    FOREIGN KEY (ReservationID) REFERENCES Reservations(ReservationID),
    FOREIGN KEY (ServiceID) REFERENCES Services(ServiceID)
);

-- Employees table
CREATE TABLE Employees (
    EmployeeID INT IDENTITY(1,1) PRIMARY KEY,
    FirstName NVARCHAR(50) NOT NULL,
    LastName NVARCHAR(50) NOT NULL,
    Role NVARCHAR(50) NOT NULL,
    Phone NVARCHAR(20)
);

-- ==========================================
-- 3. VIEWS
-- ==========================================

-- View 1: JOIN - Customer reservation info
CREATE VIEW vw_CustomerReservations AS
SELECT 
    C.FirstName + ' ' + C.LastName AS CustomerName,
    R.RoomID,
    R.CheckInDate,
    R.CheckOutDate,
    R.Status
FROM Customers C
JOIN Reservations R ON C.CustomerID = R.CustomerID;

-- View 2: UNION - Customers with/without email
CREATE VIEW vw_AllCustomersUnion AS
SELECT FirstName, LastName, Email FROM Customers
WHERE Email IS NOT NULL
UNION
SELECT FirstName, LastName, NULL AS Email FROM Customers
WHERE Email IS NULL;

-- View 3: Subquery - Upcoming reservations
CREATE VIEW vw_UpcomingReservations AS
SELECT * FROM Reservations
WHERE CheckInDate > (
    SELECT MAX(CheckOutDate) FROM Reservations WHERE Status = 'Cancelled'
);

-- ==========================================
-- 4. STORED PROCEDURES
-- ==========================================

-- Add new customer
CREATE PROCEDURE AddCustomer
    @FirstName NVARCHAR(50),
    @LastName NVARCHAR(50),
    @Email NVARCHAR(100),
    @Phone NVARCHAR(20),
    @IDNumber NVARCHAR(11)
AS
BEGIN
    INSERT INTO Customers (FirstName, LastName, Email, Phone, IDNumber)
    VALUES (@FirstName, @LastName, @Email, @Phone, @IDNumber);
END;

-- List reservations by customer
CREATE PROCEDURE GetReservationsByCustomer
    @CustomerID INT
AS
BEGIN
    SELECT ReservationID, RoomID, CheckInDate, CheckOutDate, Status
    FROM Reservations
    WHERE CustomerID = @CustomerID;
END;

-- Delete reservation by ID
CREATE PROCEDURE DeleteReservation
    @ReservationID INT
AS
BEGIN
    DELETE FROM Reservations WHERE ReservationID = @ReservationID;
END;

-- ==========================================
-- 5. TRIGGERS
-- ==========================================

-- Logging trigger table
CREATE TABLE ReservationLogs (
    LogID INT IDENTITY(1,1) PRIMARY KEY,
    ReservationID INT,
    LogDate DATETIME DEFAULT GETDATE(),
    Action NVARCHAR(100)
);

-- Trigger 1: Log new reservations
CREATE TRIGGER trg_LogNewReservation
ON Reservations
AFTER INSERT
AS
BEGIN
    INSERT INTO ReservationLogs (ReservationID, Action)
    SELECT ReservationID, 'New reservation created'
    FROM inserted;
END;

-- Trigger 2: Prevent deleting a room with existing reservations
CREATE TRIGGER trg_PreventDeleteRoom
ON Rooms
INSTEAD OF DELETE
AS
BEGIN
    IF EXISTS (
        SELECT 1 FROM Reservations R
        JOIN deleted D ON R.RoomID = D.RoomID
    )
    BEGIN
        RAISERROR ('Cannot delete room with existing reservations.', 16, 1);
        ROLLBACK;
    END
    ELSE
    BEGIN
        DELETE FROM Rooms WHERE RoomID IN (SELECT RoomID FROM deleted);
    END
END;

-- Trigger 3: Mark room unavailable after confirmed reservation
CREATE TRIGGER trg_UpdateRoomStatus
ON Reservations
AFTER UPDATE
AS
BEGIN
    IF EXISTS (
        SELECT 1 FROM inserted WHERE Status = 'Confirmed'
    )
    BEGIN
        UPDATE Rooms
        SET IsAvailable = 0
        FROM Rooms R
        JOIN inserted I ON R.RoomID = I.RoomID
        WHERE I.Status = 'Confirmed';
    END
END;

-- ==========================================
-- 6. SUBQUERY-BASED SELECTS
-- ==========================================

-- Max payment
SELECT * FROM Payments
WHERE Amount = (
    SELECT MAX(Amount) FROM Payments
);

-- Customers with at least one reservation
SELECT * FROM Customers
WHERE CustomerID IN (
    SELECT CustomerID FROM Reservations
);

-- Rooms with 'Deluxe' room type
SELECT * FROM Rooms
WHERE RoomTypeID = (
    SELECT RoomTypeID FROM RoomTypes
    WHERE TypeName = 'Deluxe'
);

-- ==========================================
-- 7. ROLE & USER PERMISSIONS
-- ==========================================

-- Create role
CREATE ROLE receptionist;

-- Create login and user
CREATE LOGIN user_john WITH PASSWORD = 'StrongP@ssword123';
CREATE USER user_john FOR LOGIN user_john;

-- Grant permission
GRANT SELECT ON Customers TO receptionist;
EXEC sp_addrolemember 'receptionist', 'user_john';

-- ==========================================
-- 8. SYSTEM STORED PROCEDURES (EXAMPLES)
-- ==========================================
EXEC sp_help 'Customers';
EXEC sp_columns 'Reservations';
EXEC sp_databases;
EXEC sp_helpindex 'Rooms';
EXEC sp_server_info;
EXEC sp_who;
EXEC sp_who2;
EXEC sp_helptext 'sp_help';
EXEC sp_tables;
EXEC sp_configure;

-- ==========================================
-- 9. SELECT COMMANDS WITH CONDITIONS
-- ==========================================
SELECT DISTINCT FirstName FROM Customers;
SELECT MIN(PricePerNight) FROM Rooms;
SELECT MAX(Price) FROM Services;
SELECT AVG(Amount) FROM Payments;
SELECT COUNT(*) FROM Reservations;

SELECT CustomerID, COUNT(*) AS ReservationCount
FROM Reservations
GROUP BY CustomerID
HAVING COUNT(*) > 1;

SELECT TOP 5 * FROM Payments ORDER BY PaymentDate DESC;

SELECT * FROM Customers C
WHERE EXISTS (
    SELECT 1 FROM Reservations R WHERE R.CustomerID = C.CustomerID
);

SELECT PaymentID, Amount, Method,
    CASE 
        WHEN Method = 'Credit Card' THEN 'Paid by card'
        WHEN Method = 'Cash' THEN 'Paid in cash'
        ELSE 'Other method'
    END AS PaymentInfo
FROM Payments;

-- ==========================================
-- 10. BACKUP SCRIPT
-- ==========================================

-- Backup the HotelReservationDB database to the Desktop
DECLARE @BackupPath NVARCHAR(255) = 'C:\\Users\\yavuz\\Desktop\\HotelReservationDB_' + 
    CONVERT(VARCHAR, GETDATE(), 112) + '.bak';

BACKUP DATABASE HotelReservationDB
TO DISK = @BackupPath
WITH FORMAT;
