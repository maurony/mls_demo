CREATE PROCEDURE usp_score_skirental_dtree
  @rx_model_outer varbinary(max),
  @new_rentaldata_outer nvarchar(max)
AS
BEGIN TRY
exec sp_execute_external_script
@language = N'R',
@script = N'func <- function (rx_model, new_rentaldata) 
{
    new_rentaldata$Holiday <- factor(new_rentaldata$Holiday)
    new_rentaldata$Snow <- factor(new_rentaldata$Snow)
    new_rentaldata$WeekDay <- factor(new_rentaldata$WeekDay)
    rental_model = unserialize(rx_model)
    rental_predictions = rxPredict(rental_model, new_rentaldata, 
        writeModelVars = TRUE)
    rental_predictions <- rental_predictions[c("Month", "Day", 
        "RentalCount_Pred")]
    return(rental_predictions)
}
result <- func(rx_model = rx_model, new_rentaldata = new_rentaldata)
if (is.data.frame(result)) {
  OutputDataSet <- result
}',
@input_data_1 = @new_rentaldata_outer,
@input_data_1_name = N'new_rentaldata',
@params = N'@rx_model varbinary(max)',
@rx_model = @rx_model_outer
END TRY
BEGIN CATCH
THROW;
END CATCH;

