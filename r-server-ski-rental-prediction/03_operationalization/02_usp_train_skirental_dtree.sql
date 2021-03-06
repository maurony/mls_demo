USE [SkiRentals]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_train_skirental_dtree]
  @rentaldata_outer nvarchar(max),
  @trained_model_outer varbinary(max) output
AS
BEGIN TRY
	EXEC sp_execute_external_script
		@language = N'R',
		@script = N'
			train_rental_model <- function (rentaldata) {
				rentaldata$Holiday <- factor(rentaldata$Holiday)
				rentaldata$Snow <- factor(rentaldata$Snow)
				rentaldata$WeekDay <- factor(rentaldata$WeekDay)
				model_dtree <- rxDTree(formula = RentalCount ~ Month + Day + 
					WeekDay + Snow + Holiday, data = rentaldata)
				trained_model <- as.raw(serialize(model_dtree, connection = NULL))
				return(trained_model)
			}
			trained_model <- train_rental_model(rentaldata = rentaldata)
		',
		@input_data_1 = @rentaldata_outer,
		@input_data_1_name = N'rentaldata',
		@params = N'@trained_model varbinary(max) output',
		@trained_model = @trained_model_outer output
END TRY
BEGIN CATCH
	THROW;
END CATCH;
