USE master;
GO
RESTORE DATABASE SkiRentals
   FROM DISK = 'C:\Program Files\Microsoft SQL Server\MSSQL13.MSSQLSERVER\MSSQL\Backup\TutorialDB.bak'
   WITH
	MOVE 'TutorialDB' TO 'C:\Program Files\Microsoft SQL Server\MSSQL13.MSSQLSERVER\MSSQL\DATA\TutorialDB.mdf',
	MOVE 'TutorialDB_log' TO 'C:\Program Files\Microsoft SQL Server\MSSQL13.MSSQLSERVER\MSSQL\DATA\TutorialDB.ldf';
GO