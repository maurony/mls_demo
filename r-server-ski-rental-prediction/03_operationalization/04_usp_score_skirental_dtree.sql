USE [SkiRentals]
GO
/****** Object:  StoredProcedure [dbo].[usp_score_skirental_dtree]    Script Date: 1/8/2020 12:14:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[usp_score_skirental_dtree]
  @rx_model_outer varbinary(max),
  @new_rentaldata_outer nvarchar(max)
AS
BEGIN TRY
EXEC sp_execute_external_script
	@language = N'R',
	@script = N'
		score_skirental_dtree <- function (rx_model, new_rentaldata) {
			new_rentaldata$Holiday <- factor(new_rentaldata$Holiday)
			new_rentaldata$Snow <- factor(new_rentaldata$Snow)
			new_rentaldata$WeekDay <- factor(new_rentaldata$WeekDay)
			rental_model = unserialize(rx_model)
			rental_predictions = rxPredict(rental_model, new_rentaldata)
			return(rental_predictions)
		}
		result <- score_skirental_dtree(rx_model = rx_model, new_rentaldata = new_rentaldata)
		if (is.data.frame(result)) {
		  OutputDataSet <- result
		}',
	@input_data_1 = @new_rentaldata_outer,
	@input_data_1_name = N'new_rentaldata',
	@params = N'@rx_model varbinary(max)',
	@rx_model = @rx_model_outer
	WITH RESULT SETS (
		(
			"RentalCount_Predicted" FLOAT
		)
	);
END TRY
BEGIN CATCH
	THROW;
END CATCH;
