USE [SkiRentals]
GO

--Line of code to empty table with models
--TRUNCATE TABLE rental_models;

----------------------------------------------------------------------------
--Save Linear model to table

DECLARE 
	@model_name varchar(30) = 'dtree',
	@trained_model varbinary(max)

EXEC [dbo].[usp_train_skirental_model]
	@rental_train_data_outer = N'SELECT * FROM [dbo].[rental_data] WHERE Year <= 2015',
	@model_type_outer = @model_name,
	@trained_model_outer = @trained_model OUTPUT

DELETE FROM dbo.rental_models
WHERE model_name = @model_name

INSERT INTO rental_models (
	model_name,
	native_model,
	lang
) VALUES(
	@model_name, 
	@trained_model, 
	'R'
);
