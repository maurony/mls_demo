USE [SkiRentals]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[usp_train_skirental_model]
  @rental_train_data_outer nvarchar(max),
  @model_type_outer nvarchar(max),
  @trained_model_outer varbinary(max) output
AS
BEGIN TRY
	exec sp_execute_external_script
	@language = N'R',
	@script = N'
		train_skirental_model <- function (rental_train_data, model_type = "dtree") {

			rental_train_data$Holiday = factor(rental_train_data$Holiday)
			rental_train_data$Snow = factor(rental_train_data$Snow)
			rental_train_data$WeekDay = factor(rental_train_data$WeekDay)

			if (model_type == "linear") {
				model <- rxDTree(
					RentalCount ~ Month + Day + WeekDay + Snow + Holiday, 
					data = rental_train_data
				)
				trained_model <- rxSerializeModel(model, realtimeScoringOnly = TRUE)
			} else if (model_type == "dtree") {
				model <- rxLinMod(
					RentalCount ~ Month + Day + WeekDay + Snow + Holiday, 
					data = rental_train_data
				)
				trained_model <- rxSerializeModel(model, realtimeScoringOnly = TRUE)
			} else {
				stop("model not supported")
			}

			trained_model <- rxSerializeModel(model, realtimeScoringOnly = TRUE)
			return(trained_model)
		}
		trained_model <- train_skirental_model(rental_train_data = rental_train_data, model_type = model_type)
	',
	@input_data_1 = @rental_train_data_outer,
	@input_data_1_name = N'rental_train_data',
	@params = N'@model_type nvarchar(max), @trained_model varbinary(max) output',
	@model_type = @model_type_outer,
	@trained_model = @trained_model_outer output
END TRY
BEGIN CATCH
	THROW;
END CATCH;

GO


