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
# Transform
#########################################################

sqlRowsPerRead <- 5000

# source
sqlOutScoreDS <- RxSqlServerData( 
  table =  "ccScoreOutput",  
  connectionString = connectionString, 
  rowsPerRead = sqlRowsPerRead 
)

# target
sqlOutScoreDS2 <- RxSqlServerData( 
  table =  "ccScoreOutput2",  
  connectionString = connectionString,
  rowsPerRead = sqlRowsPerRead 
)


if (rxSqlServerTableExists("ccScoreOutput2"))
  rxSqlServerDropTable("ccScoreOutput2")

# inverse logit
rxDataStep(
  inData = sqlOutScoreDS,
  outFile = sqlOutScoreDS2,
  transforms = list(ccFraudProb = inv.logit(ccFraudLogitScore)),
  transformPackages = "boot",
  overwrite = TRUE
)

#########################################################
# import into r session (data.frame)
#########################################################

sqlServerProbDS <- RxSqlServerData(
  sqlQuery = paste("SELECT * FROM ccScoreOutput2",
                   "WHERE (ccFraudProb > .99)"),
  connectionString = connectionString)

highRisk <- rxImport(sqlServerProbDS)


