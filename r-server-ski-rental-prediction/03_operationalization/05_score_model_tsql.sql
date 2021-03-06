USE [SkiRentals]
GO

DECLARE	@model varbinary(max) = (
	SELECT 
		model 
	FROM 
		rental_models 
	WHERE 
		model_name = 'rxDTree'
);

DROP TABLE IF EXISTS dbo.Predictions

CREATE TABLE dbo.Predictions(
	[Month] INT,
	[Day] INT,
	[RentalCount_Predicted] FLOAT
)


INSERT INTO dbo.Predictions(
	[Month],
	[Day],
	[RentalCount_Predicted]
)
EXEC [dbo].[usp_score_skirental_dtree]
		@rx_model_outer = @model,
		@new_rentaldata_outer = N'
			SELECT 
				[Month], [Day], [WeekDay], [Snow], [Holiday]
			FROM dbo.rental_data
			WHERE [Year] >= 2015'


SELECT [Month], [Day], SUM(RentalCount_Predicted) Predicted_Rentals
FROM dbo.Predictions 
GROUP BY
	[Month], [Day]
ORDER BY 1, 2


