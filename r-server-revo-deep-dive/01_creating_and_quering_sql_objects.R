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
# Create SQL Server data objects using RxSqlServerData
#########################################################

# -------------------------------------------------------
# training table object
# -------------------------------------------------------
sqlFraudTable <- "ccFraudSmall"

sqlRowsPerRead = 5000

sqlFraudDS <- RxSqlServerData(
    connectionString = connectionString,
    table = sqlFraudTable,
    rowsPerRead = sqlRowsPerRead
)

# -------------------------------------------------------
# scoring table object
# -------------------------------------------------------

sqlScoreTable <- "ccFraudScoreSmall"


sqlScoreDS <- RxSqlServerData(
  connectionString = connectionString,
  table = sqlScoreTable, 
  rowsPerRead = sqlRowsPerRead
)

# -------------------------------------------------------
# load data into tables
# -------------------------------------------------------

# defining source
ccFraudCsv <- file.path(rxGetOption("sampleDataDir"), "ccFraudSmall.csv")

# defining columns
inTextData <- RxTextData(
    file = ccFraudCsv,
    colClasses = c(
      "custID" = "integer",
      "gender" = "integer",
      "state" = "integer",
      "cardholder" = "integer",
      "balance" = "integer",
      "numTrans" = "integer",
      "numIntlTrans" = "integer", 
      "creditLine" = "integer",
      "fraudRisk" = "integer"
    )
)

# load data from ccFraudSmall.csv to sqlFraudDS table object
rxDataStep(
  inData = inTextData, # source csv file
  outFile = sqlFraudDS, # target sql table
  overwrite = TRUE
)


# same for scoring
ccScoreCsv <- file.path(rxGetOption("sampleDataDir"), "ccFraudScoreSmall.csv")

inTextData <- RxTextData(
  file = ccScoreCsv,
  colClasses = c(
    "custID" = "integer",
    "gender" = "integer",
    "state" = "integer",
    "cardholder" = "integer",
    "balance" = "integer",
    "numTrans" = "integer",
    "numIntlTrans" = "integer",
    "creditLine" = "integer")
)

rxDataStep(
  inData = inTextData,
  sqlScoreDS,
  overwrite = TRUE
)


#########################################################
# Query and modify the SQL Server data
#########################################################

# check data types coming from sql server
rxGetVarInfo(data = sqlFraudDS)


# define state abbreviations for later
stateAbb <- c("AK", "AL", "AR", "AZ", "CA", "CO", "CT", "DC",
              "DE", "FL", "GA", "HI","IA", "ID", "IL", "IN", "KS", "KY", "LA",
              "MA", "MD", "ME", "MI", "MN", "MO", "MS", "MT", "NB", "NC", "ND",
              "NH", "NJ", "NM", "NV", "NY", "OH", "OK", "OR", "PA", "RI","SC",
              "SD", "TN", "TX", "UT", "VA", "VT", "WA", "WI", "WV", "WY")


# lets change them for R
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

# update table object 
sqlFraudDS <- RxSqlServerData(
  connectionString = connectionString,
  table = sqlFraudTable, 
  colInfo = ccColInfo,
  rowsPerRead = sqlRowsPerRead
)

# check vars again
rxGetVarInfo(data = sqlFraudDS)
