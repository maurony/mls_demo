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

rollDice <- function()
{
  result <- NULL
  point <- NULL
  count <- 1
  while (is.null(result))
  {
    roll <- sum(sample(6, 2, replace=TRUE))
    
    if (is.null(point))
    { point <- roll }
    if (count == 1 && (roll == 7 || roll == 11))
    {  result <- "Win" }
    else if (count == 1 && (roll == 2 || roll == 3 || roll == 12))
    { result <- "Loss" }
    else if (count > 1 && roll == 7 )
    { result <- "Loss" }
    else if (count > 1 && point == roll)
    { result <- "Win" }
    else { count <- count + 1 }
  }
  result
}

sqlServerExec <- rxExec(rollDice, timesToRun=20, RNGseed="auto")
length(sqlServerExec)