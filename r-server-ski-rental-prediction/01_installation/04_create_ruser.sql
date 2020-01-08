USE [master]
GO
CREATE LOGIN [ruser] 
	WITH PASSWORD=N'ruser', 
	DEFAULT_DATABASE=[SkiRentals], 
	DEFAULT_LANGUAGE=[us_english], 
	CHECK_EXPIRATION=OFF, 
	CHECK_POLICY=OFF
GO

USE [SkiRentals]
GO
CREATE USER [ruser] FOR LOGIN [ruser]
GO
USE [SkiRentals]
GO
ALTER ROLE [db_owner] ADD MEMBER [ruser]
GO



