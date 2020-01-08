# load packages or install them if they do not exist.
setwd("~/mls_demo/r-server-ski-rental-prediction")

source('01_installation/dependencies.R')

#########################################################
# Connecting to sql server                              #
#########################################################

connectionString <- sqlmlutils::connectionInfo(
  driver = 'SQL Server',
  server = 'localhost',
  database = 'SkiRentals',
  uid = 'ruser', 
  pwd = 'ruser'
)


#Get the data from SQL Server Table
SQL_rentaldata <- RxSqlServerData(
  table = "dbo.rental_data",
  connectionString = connectionString,
  returnDataFrame = TRUE
)


#Import the data into a data frame
rentaldata <- rxImport(SQL_rentaldata)


train_skirental_model <- function(rental_train_data, model_type='dtree') {
  #Changing the three factor columns to factor types
  #This helps when building the model because we are explicitly saying that these values are categorical
  rental_train_data$Holiday = factor(rental_train_data$Holiday);
  rental_train_data$Snow = factor(rental_train_data$Snow);
  rental_train_data$WeekDay = factor(rental_train_data$WeekDay);
  
  if(model_type == "linear") {
    #Create a dtree model and train it using the training data set
    model <- rxDTree(RentalCount ~ Month + Day + WeekDay + Snow + Holiday, data = rental_train_data);
    trained_model <- rxSerializeModel(model, realtimeScoringOnly = TRUE);
  }
  
  if(model_type == "dtree") {
    model <- rxLinMod(RentalCount ~ Month + Day + WeekDay + Snow + Holiday, data = rental_train_data);
    #Before saving the model to the DB table, we need to serialize it. This time, as a native scoring model
    trained_model <- rxSerializeModel(model, realtimeScoringOnly = TRUE);
  }
  
  if(model_type == 'nn') {
    model <- rxNeuralNet(
      formula = RentalCount ~ Month + Day + WeekDay + Snow + Holiday,
      data = rental_train_data, 
      type='regression'
    )
  }
  
  trained_model <- rxSerializeModel(model, realtimeScoringOnly = TRUE);
  
  return(trained_model)
}


sp_script <- createSprocFromFunction(
  connectionString, 
  name = "usp_train_skirental_model",
  func = train_skirental_model, 
  inputParams = list(rental_train_data="dataframe", model_type='character'),
  outputParams = list(trained_model='raw'),
  getScript = T
)

write(sp_script, file = './04_native_scoring/_usp_train_skirental_model.sq', append = F)

