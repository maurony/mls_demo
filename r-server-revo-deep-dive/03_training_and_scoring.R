# load packages or install them if they do not exist.
setwd("~/mls_demo/r-server-ski-rental-prediction")

source('01_installation/dependencies.R')

#########################################################
# Connecting to sql server                              
#########################################################

connectionString <- sqlmlutils::connectionInfo(
  driver = 'SQL Server',
  server = 'localhost',
  database = 'RevoDeepDive',
  uid = 'ruser', 
  pwd = 'ruser'
)

#########################################################
# Compute summary statistics in Compute context
#########################################################

# sql compute context
sqlCompute <- RxInSqlServer(  
  connectionString = connectionString,
  wait = T,
  consoleOutput = F
)

# set sql compute context
rxSetComputeContext(sqlCompute)

# get sql compute context
rxGetComputeContext()


#########################################################
# Compute summary statistics in Compute context
#########################################################

# -------------------------------------------------------
# remote compute context
# -------------------------------------------------------

stateAbb <- c("AK", "AL", "AR", "AZ", "CA", "CO", "CT", "DC",
              "DE", "FL", "GA", "HI","IA", "ID", "IL", "IN", "KS", "KY", "LA",
              "MA", "MD", "ME", "MI", "MN", "MO", "MS", "MT", "NB", "NC", "ND",
              "NH", "NJ", "NM", "NV", "NY", "OH", "OK", "OR", "PA", "RI","SC",
              "SD", "TN", "TX", "UT", "VA", "VT", "WA", "WI", "WV", "WY")

ccColInfo <- list(
  gender = list(
    type = "factor",
    levels = c("1", "2"),
    newLevels = c("Male", "Female")
  ),
  cardholder = list(
    type = "factor",
    levels = c("1", "2"),
    newLevels = c("Principal", "Secondary")
  ),
  state = list(
    type = "factor",
    levels = as.character(1:51),
    newLevels = stateAbb # use previously defined states abbreviations
  ),
  balance = list(type = "numeric")
)

sqlFraudDS <- RxSqlServerData(
  connectionString = connectionString,
  table = "ccFraudSmall",
  colInfo = ccColInfo,
  rowsPerRead = 10000
)


# linear model 
linModObj <- rxLinMod(balance ~ gender + creditLine,  data = sqlFraudDS)

# summary
summary(linModObj)

# logistic model 
logitObj <- rxLogit(fraudRisk ~ state + gender + cardholder + balance + numTrans + numIntlTrans + creditLine, data = sqlFraudDS, dropFirst = TRUE)

# summmary
summary(logitObj)



# score datasource
sqlScoreDS <- RxSqlServerData(
  connectionString = connectionString,
  table = 'ccFraudScoreSmall',
  colInfo = ccColInfo,
  rowsPerRead = 5000
)

# run the prediction in the remote compute context
sqlServerOutDS <- RxSqlServerData(
  table = "ccScoreOutput",
  connectionString = connectionString,
  rowsPerRead = 5000
)


if (rxSqlServerTableExists("ccScoreOutput"))
  rxSqlServerDropTable("ccScoreOutput")


rxPredict(
  modelObject = logitObj,
  data = sqlScoreDS,
  outData = sqlServerOutDS,
  predVarNames = "ccFraudLogitScore",
  type = "link",
  writeModelVars = TRUE,
  extraVarsToWrite = "custID",
  overwrite = TRUE
)
