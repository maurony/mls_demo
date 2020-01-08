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

sqlRowsPerRead <- 500

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


ProcessChunk <- function( dataList) {
  # Convert the input list to a data frame and compute contingency table
  chunkTable <- data.frame(time = Sys.time(), count = NROW(as.data.frame(dataList)))
  
  # Return the data frame, which has a single row
  return( chunkTable )
}

#target
rowCountDS = RxSqlServerData(
  table = "coutntResults",   
  connectionString = connectionString
)

# process each chunk
rxDataStep(
  inData = sqlOutScoreDS2, 
  outFile = rowCountDS, 
  transformFunc = ProcessChunk, 
  overwrite = TRUE
)


results <- rxImport(rowCountDS)
results

sum(results$count)


rxSqlServerDropTable(
  table = "coutntResults", 
  connectionString = connectionString)
