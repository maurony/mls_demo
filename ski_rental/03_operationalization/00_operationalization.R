# load packages or install them if they do not exist.
setwd("~/mls_demo/ski_rental")

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


train_skirental_dtree <- function(rentaldata) {
  #Changing the three factor columns to factor types
  #This helps when building the model because we are explicitly saying that these values are categorical
  rentaldata$Holiday <- factor(rentaldata$Holiday)
  rentaldata$Snow <- factor(rentaldata$Snow)
  rentaldata$WeekDay <- factor(rentaldata$WeekDay)
  
  #Model 2: Use rxDTree to create a decision tree model. We are training the data using the training data set
  model_dtree <- rxDTree(
    formula = RentalCount ~ Month + Day + WeekDay + Snow + Holiday, 
    data = rentaldata
  )
  
  trained_model <- as.raw(serialize(model_dtree, connection=NULL));
  
  return(trained_model)
}


# ---------------------------------------
# Get SqlConnectionString to connect to sql server
# and drop stored procedure if it already exists
#dropSproc(connectionString, "usp_train_skirental_dtree")

# ---------------------------------------
# Then create new stored procedure
sp_script <- createSprocFromFunction(
  connectionString, 
  name = "usp_train_skirental_dtree",
  func = train_skirental_dtree, 
  inputParams = list(rentaldata="dataframe"),
  outputParams = list( trained_model="raw")
)

write(sp_script, file = './03_operationalization/_sp_train_starting_point.sql')

score_skirental_dtree <- function(rx_model, new_rentaldata) {
  #Changing the three factor columns to factor types
  #This helps when building the model because we are explicitly saying that these values are categorical
  new_rentaldata$Holiday <- factor(new_rentaldata$Holiday)
  new_rentaldata$Snow <- factor(new_rentaldata$Snow)
  new_rentaldata$WeekDay <- factor(new_rentaldata$WeekDay)
  
  #Model 2: Use rxDTree to create a decision tree model. We are training the data using the training data set
  #Before using the model to predict, we need to unserialize it
  rental_model = unserialize(rx_model)
  
  #Call prediction function
  rental_predictions = rxPredict(rental_model, new_rentaldata, writeModelVars = TRUE)
  
  rental_predictions <- rental_predictions[c('Month', 'Day', 'RentalCount_Pred')]
  
  return(rental_predictions)
}


# ---------------------------------------
# Get SqlConnectionString to connect to sql server
# and drop stored procedure if it already exists
#dropSproc(connectionString, "usp_score_skirental_dtree")

# ---------------------------------------
# Then create new stored procedure
sp_script <- createSprocFromFunction(
  connectionString, 
  name = "usp_score_skirental_dtree",
  func = score_skirental_dtree, 
  inputParams = list(rx_model="raw", new_rentaldata="dataframe"),
  getScript = T
)

write(sp_script, file = './03_operationalization/_sp_score_starting_point.sql')



skirental_dtree_model <- train_skirental_dtree(rentaldata = rentaldata)
scores <- score_skirental_dtree(rx_model = skirental_dtree_model, new_rentaldata = rentaldata)

str(scores)
