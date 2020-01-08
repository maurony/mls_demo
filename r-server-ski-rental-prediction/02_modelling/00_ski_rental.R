# load packages or install them if they do not exist.
setwd("~/mls_demo/r-server-ski-rental-prediction")

source('01_installation/dependencies.R')

#########################################################
# Connecting to sql server                              #
#########################################################

connectionString <- sqlmlutils::connectionInfo(
  driver = 'SQL Server',
  server = 'localhost\\MSSQLSERVER01',
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


#Let's see the structure of the data and the top rows
# Ski rental data, giving the number of ski rentals on a given date
head(rentaldata)
str(rentaldata)

#Changing the three factor columns to factor types
#This helps when building the model because we are explicitly saying that these values are categorical
rentaldata$Holiday <- factor(rentaldata$Holiday)
rentaldata$Snow <- factor(rentaldata$Snow)
rentaldata$WeekDay <- factor(rentaldata$WeekDay)

#Visualize the dataset after the change
str(rentaldata)

#Now let's split the dataset into 2 different sets
#One set for training the model and the other for validating it
train_data = rentaldata[rentaldata$Year < 2015,]
test_data = rentaldata[rentaldata$Year == 2015,]

#Use this column to check the quality of the prediction against actual values
actual_counts <- test_data$RentalCount

#Model 1: Use rxLinMod to create a linear regression model. We are training the data using the training data set
model_linmod <- rxLinMod(
  formula = RentalCount ~  Month + Day + WeekDay + Snow + Holiday, 
  data = train_data
)

#Model 2: Use rxDTree to create a decision tree model. We are training the data using the training data set
model_dtree <- rxDTree(
  formula = RentalCount ~ Month + Day + WeekDay + Snow + Holiday, 
  data = train_data
)

# model 3: Use rxNeuralNet to create a nerual network 
model_nn <- rxNeuralNet(
  formula = RentalCount ~ Month + Day + WeekDay + Snow + Holiday,
  data = train_data, 
  type='regression'
)

#Use the models we just created to predict using the test data set.
#That enables us to compare actual values of RentalCount from the two models and compare to the actual values in the test data set
predict_linmod <- rxPredict(model_linmod, test_data, writeModelVars = TRUE, extraVarsToWrite = c("Year"))

predict_dtree <- rxPredict(model_dtree, test_data, writeModelVars = TRUE, extraVarsToWrite = c("Year"))

predict_nn <- rxPredict(model_nn, test_data, writeModelVars = TRUE, extraVarsToWrite = c("Year"))

#Look at the top rows of the two prediction data sets.
head(predict_linmod)
head(predict_dtree)

# Check the results, "residual diagnositcs"
preds <- tibble(
  index = seq.int(from = 1, to = NROW(predict_nn), by = 1),
  true = predict_linmod$RentalCount,
  linear_model = predict_linmod$RentalCount_Pred,
  dtree = predict_dtree$RentalCount_Pred,
  neuralnet = predict_nn$Score,
)

# prepare data for plotting
plot_data <- preds %>% 
  gather(key = 'Model', value = "Pred", linear_model, dtree, neuralnet) %>% 
  mutate(
    error = true - Pred,
    ae = abs(true - Pred),
    sape = 200 * (abs(true - Pred) / abs(true + Pred))
  )

# plot residuals
ggplot(plot_data, aes(x = index, y = error, colour = ae)) +
  geom_point() +
  scale_color_gradient(low = 'grey50', high = 'red') +
  facet_wrap(.~Model, ncol = 1) +
  theme_bw()

# check error metrics
plot_data %>% 
  group_by(Model) %>% 
  summarise(
    me = mean(error),
    mae = mean(ae),
    smape = mean(sape),
    mdae = median(ae),
    smdape = median(sape)
  )

# the decision tree seems to be the best; lets operationalize it...