USE [SkiRentals]
GO

DECLARE	@return_value int,
		@model_name VARCHAR(30) = 'rxDTree',
		@trained_model varbinary(max)

EXEC	@return_value = [dbo].[usp_train_skirental_dtree]
		@rentaldata_outer = N'SELECT * FROM dbo.rental_data',
		@trained_model_outer = @trained_model OUTPUT

DELETE FROM dbo.rental_models
WHERE model_name = @model_name

INSERT INTO dbo.rental_models (model_name, model) VALUES(@model_name, @trained_model);

SELECT * FROM rental_models;

GO
