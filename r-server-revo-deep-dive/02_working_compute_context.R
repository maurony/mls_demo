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
# Define and use compute contexts
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

# move back to local compute context
rxSetComputeContext("local")


# tracing
#sqlComputeTrace <- RxInSqlServer(
#  connectionString = sqlConnString,
#  #shareDir = sqlShareDir,
#  wait = sqlWait,
#  consoleOutput = sqlConsoleOutput,
#  traceEnabled = TRUE,
#  traceLevel = 7
#)

# rxSetComputeContext(sqlComputeTrace)


#########################################################
# Compute summary statistics in Compute context
#########################################################

# -------------------------------------------------------
# remote compute context
# -------------------------------------------------------

# set sql compute context
rxSetComputeContext(sqlCompute)

# define table
sqlFraudDS <- RxSqlServerData(
  connectionString = connectionString,
  table = "ccFraudSmall",
  rowsPerRead = 5000
)

# summary 
sumOut <- rxSummary(
  formula = ~gender + balance + numTrans + numIntlTrans + creditLine, 
  data = sqlFraudDS
)

# -------------------------------------------------------
# remote compute context, same as 
# -------------------------------------------------------

rxSetComputeContext ("local")

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

sqlServerDS1 <- RxSqlServerData(
  connectionString = connectionString,
  table = "ccFraudSmall",
  colInfo = ccColInfo,
  rowsPerRead = 10000
)


rxSummary(
  formula = ~gender + balance + numTrans + numIntlTrans + creditLine, 
  data = sqlServerDS1
)
