USE SkiRentals;

-- Look at the models in the table
SELECT * FROM rental_models;

GO
-- STEP 4  - Use the native PREDICT (native scoring) to predict number of rentals for both models
--Now lets predict using native scoring with linear model
DECLARE 
	@model_name VARCHAR(30) = 'linear';

DECLARE 
	@model VARBINARY(MAX) = (
	SELECT TOP(1) 
		native_model 
		FROM dbo.rental_models 
		WHERE 
			model_name = @model_name 
			AND lang = 'R'
		);

SELECT d.*, p.* 
FROM PREDICT(
	MODEL = @model, 
	DATA = dbo.rental_data AS d
) WITH (
	RentalCount_Pred float
) AS p;
GO
