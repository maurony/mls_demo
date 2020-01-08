CREATE PROCEDURE usp_train_skirental_model
  @rental_train_data_outer nvarchar(max),
  @model_type_outer nvarchar(max)
AS
BEGIN TRY
exec sp_execute_external_script
@language = N'R',
@script = N'func <- function (rental_train_data, model_type = "dtree") 
{
    rental_train_data$Holiday = factor(rental_train_data$Holiday)
    rental_train_data$Snow = factor(rental_train_data$Snow)
    rental_train_data$WeekDay = factor(rental_train_data$WeekDay)
    if (model_type == "linear") {
        model <- rxDTree(RentalCount ~ Month + Day + WeekDay + 
            Snow + Holiday, data = rental_train_data)
        trained_model <- rxSerializeModel(model, realtimeScoringOnly = TRUE)
    }
    if (model_type == "dtree") {
        model <- rxLinMod(RentalCount ~ Month + Day + WeekDay + 
            Snow + Holiday, data = rental_train_data)
        trained_model <- rxSerializeModel(model, realtimeScoringOnly = TRUE)
    }
    if (model_type == "nn") {
        model <- rxNeuralNet(formula = RentalCount ~ Month + 
            Day + WeekDay + Snow + Holiday, data = train_data, 
            type = "regression")
    }
    trained_model <- rxSerializeModel(model, realtimeScoringOnly = TRUE)
    return(trained_model)
}
result <- func(rental_train_data = rental_train_data, model_type = model_type)
if (is.data.frame(result)) {
  OutputDataSet <- result
}',
@input_data_1 = @rental_train_data_outer,
@input_data_1_name = N'rental_train_data',
@params = N'@model_type nvarchar(max)',
@model_type = @model_type_outer
END TRY
BEGIN CATCH
THROW;
END CATCH;

