# Hotel Reservation System Database Project

This project was developed as part of a university database course by **Yavuz Orhan Candemir**.

## Description

A fully normalized relational database system designed for managing hotel reservations, including customers, rooms, payments, services, and employees.

Built using **SQL Server 2022 Developer Edition** and implemented via SQL scripts. All database objects comply with **Third Normal Form (3NF)**.

---

## Project Features

- 8+ Tables (Normalized)
- Primary & Foreign Keys, 1:N & M:N Relationships
- Views (JOIN, UNION, SUBQUERY)
- ⚙Stored Procedures
- Triggers
- Role & User Permissions
- Sample SELECT queries with `DISTINCT`, `CASE`, `EXISTS`, `AVG`, etc.
- Backup Script with retention logic

---

## Files

| File | Description |
|------|-------------|
| `HotelReservationProject_YavuzCandemir.sql` | All SQL scripts: tables, views, procedures, triggers, queries |
| `HotelReservationDB.bak` | Full backup of the project database |

---

## Tools Used

- Microsoft SQL Server 2022 Developer Edition
- SQL Server Management Studio (SSMS)

---

## Getting Started

To restore the backup:
1. Open SSMS
2. Right-click on `Databases > Restore Database`
3. Select the `.bak` file and restore

To run from scratch:
1. Open the `.sql` file in SSMS
2. Execute step-by-step (or entire script) to create the database and all components

---

## Diagram

ER Diagram is included in the report showing all tables and relationships clearly.

---

## Author

**Yavuz Orhan Candemir**  

---

## License

This project is for academic purposes. Free to use, reference, or build upon with credit.
****
