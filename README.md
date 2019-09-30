

# Working SQL ML Services

This document demonstrates how to use SQL ML Services, essentially illustrating how to easily operationalize R code in SQL Server.

## Requirements

In the following, a guidance for installing and enabling the necessary features in SQL Server is given.

### Machine Learning Services

The scripts are meant to run in parallel using [Microsoft Machine Learning Services (MLS)](https://docs.microsoft.com/en-us/sql/advanced-analytics/what-is-sql-server-machine-learning?view=sql-server-2017). To add this feature to an existing SQL Server instance or to install a new standalone Machine Learning Server, please follow the respective [installation instructions](https://docs.microsoft.com/en-us/sql/advanced-analytics/install/sql-machine-learning-services-windows-install?view=sql-server-2017).

Please note that MLS is likely to use an older version of R than available on the web; the current package uses the latest R version supported by [SQL Server 2017](https://docs.microsoft.com/en-us/sql/advanced-analytics/r/use-sqlbindr-exe-to-upgrade-an-instance-of-sql-server?view=sql-server-2017); more precisely:

```{R}
> version
               _                           
platform       x86_64-w64-mingw32          
arch           x86_64                      
os             mingw32                     
system         x86_64, mingw32             
status                                     
major          3                           
minor          5.2                         
year           2018                        
month          12                          
day            20                          
svn rev        75870                       
language       R                           
version.string R version 3.5.2 (2018-12-20)
nickname       Eggshell Igloo 
```

Please note, that code implemented using a newer version of Microsoft R Open might not work on the MLS (SQL Server 2017).

Furthermore, you need to reconfigure the SQL Server to allow external scripts. To do this, please execute the following command on the instance:

```{SQL}
sp_configure 'external scripts enabled', 1;
RECONFIGURE WITH OVERRIDE;  
```

Sometimes the server instance has to be restarted to change the `run_config`; to do this, go to `Services` and restart the corresponding SQL Server Instance.

### MRO Client

To work from a client workstation with SQL Server ML Services, you can download the Microsoft R Client. To do this, please make sure you follow the [official installation instructions of Microsoft](https://docs.microsoft.com/en-us/machine-learning-server/r-client/install-on-windows) that best fit your needs (online/offline/dev). After successful installation, please verify that you have installed all the packages necessary to work with ML Services (RevoScaleR etc). 

### R development environment

Additionally, you need an R development environment, such as e.g. [RStudio](https://rstudio.com/products/rstudio/), [R Tools for VS](https://visualstudio.microsoft.com/vs/features/rtvs/) or any other. Please also make sure that your IDE is pointing to the correct R version, especially if you have installed multiple versions of R on you system. 

## Package Management

There are several ways of installing new R or Python packages on the SQL Server; please see the [official documentation of Microsoft](https://docs.microsoft.com/en-us/machine-learning-server/operationalize/configure-manage-r-packages) to get an overview of the different options.

### Option 1: Offline installation

It is suggested, that a simple workflow is established to install packages on production systems. At this point and after discussions with the internal it, the following workflow seems to fit best the current needs:

1. The data scientist connects to the SQL Server and gets data or a subset of the data and starts developing machine learning algorithms. Additionally, the data scientist installs packages needed for this task in a miniCRAN repository.
2. Once the algorithm is developed, tested and ready for production; the data scientist provides the miniCRAN to the server admin, which installs the packages manually on the server. For a detailed example, please see the following example.

#### Example

A simple way how you can iYou can create a local R package repository of the R packages you need using the R package `miniCRAN`. You can then copy this repository to all compute nodes and then install directly from this repository.

This production-safe approach provides an excellent way to:

- Keep a standard, sanctioned library of R packages for production use
- Allow packages to be installed in an offline environment

**To use the miniCRAN method:**

1. On the machine with Internet access:

   1. Launch your preferred R IDE or an R tool such as Rgui.exe.

   2. At the R prompt, install the `miniCRAN` package on a computer that has Internet access.	 

      ```R
      if(!require("miniCRAN")) install.packages("miniCRAN")
      if(!require("igraph")) install.packages("igraph")
      library(miniCRAN)
      ```

   3. To point to a different snapshot, set the `CRAN_mirror` value. By default, the CRAN mirror specified by your version of Microsoft R Open is used. For example, for Microsoft R Client 3.5.2 that date is 2019-02-10. 

      ```R
      # Define the package source: a CRAN mirror, or an MRAN snapshot
      CRAN_mirror <- c(CRAN = "https://mran.microsoft.com/snapshot/2019-02-10")
      ```

   4. Create a miniCRAN repository in which the packages are downloaded and installed.  This repository creates the folder structure that you need to copy the packages to each compute node later.

      ```R
      # Define the local download location
      local_repo <- "~/my-miniCRAN-repo"
      ```

   5. Download and install the packages you need to this computer.	 

      ```R
      # List the packages you need 
      # Do not specify dependencies
      pkgs_needed <- c("tidyverse")
      ```

2. On each compute node:

   1. Copy the miniCRAN repository from the machine with Internet connectivity to the R_SERVICES library on the SQL Server instance.

   2. Launch your preferred R IDE or an R tool such as Rgui.exe.

   3. At the R prompt, run the R command install.packages().

   4. At the prompt, specify a repository and specify the directory containing the files you copied. That is, the local miniCRAN repository.

      ```R
      pkgs_needed <- c("tidyverse")
      local_repo  <- "~/my-miniCRAN-repo"
      
      install.packages(pkgs_needed, 
              repos = file.path("file://", normalizePath(local_repo, winslash = "/")),
              dependencies = TRUE
      )
      ```

   5. Run the following R command and reviewing the list of installed packages:

      ```R
      installed.packages()
      ```

Fore more details, see [official documentation of Microsoft](https://docs.microsoft.com/en-us/machine-learning-server/operationalize/configure-manage-r-packages).

### Option 2: Online installation

If you do not have hardened environment without access to the internet, another - possibly easier option - is that packages are installed directly via `install.packages('package_1')`. The workflow would be as follows:

1. The data scientist connects to the SQL Server and gets data or a subset of the data and starts developing machine learning algorithms. Additionally, the data scientist provides an installation script, listing each library that is necessary for the script to run.
2. Once the algorithm is developed, tested and ready for production; the data scientist provides this installation script to the server admin, which installs the packages manually. For a detailed example, please see the following example.

#### Example

As mentioned before, it is imperative that the right set of R package versions are installed and accessible to all users. This options uses a _master_ R script containing the list of specific package versions to install across the configuration on behalf of your users. Using a master script ensures that the same packages (along with all its required package dependency) are installed each time.

This allows to

- Keep a standard (and sanctioned) library of R packages for production use.
- Manage R package dependencies and package versions.
- Schedule timely updates to R packages.

**To use a master script to install packages:**

1. Create the master list of packages (and versions) in an R script format. For example:

   ```R
   pkgs <- c(
   	"tidyverse"
   )
   install.packages(pkgs)
   ```

2. Manually run this R script on each compute node.

> Update and manually rerun this script on each compute node each time a new package or version is needed in the server environment.

If you keep you ML Server and/or ML Services R Version in sync with your MRO Client R Version, different versions of the individual R packages should be handled.

## ML Services Example

This is a simple example workflow of how connect to an existing database with ML Services installed, read data, build a model and create a stores procedure that runs this on the server.

In this example, we use the online installation method to install new packages on the server. Thus, we define a `dependencies.R` file that contains all the packages needed to run the script successfully; which looks as follows:

`dependencies.R`

```R
# ---------------------------------------
# dependencies
pkgs <- c(
    'tidyverse'
)

# ---------------------------------------
# install dependencies
install.packages(pkgs)
```

Having defined the packages needed to run the script on the server, we can now proceed to the (or possibly multiple) R script that trains a model and directly computes predictions. 

> Note that usually you have multiple scripts or functions, such as e.g. a train script that trains a model and stores it in a table, and a score script that takes this model and computes predictions. However, for illustration purposes, we only use one script that directly performs the predictions.

The script might be structured as follows, essentially sourcing `dependencies.R` defined earlier to load the important packages, then we might also use packages to e.g. explore the data or some other utility functions, that are not necessary to run the model on the server but are needed during the development phase. 

`score.R` (library installation)

```R
# ---------------------------------------
# source dependencies
source('dependencies.R')

# ---------------------------------------
# source additional dependencies
pkgs <- c(
    'sqlmlutils', # used to deploy functions to SQL server
    'ggplot2', # used for plotting
    'viridis' # used for fancy coloring
)
# check, whether these packages are not installed yet
new_pkgs <- pkgs[!(pkgs %in% installed.packages()[,"Package"])]

# if there are new packages, install them
if(length(new_pkgs)) 
  install.packages(new_pkgs)

# ---------------------------------------
# import packages
library(tidyverse)
library(sqlmlutils)
library(ggplot2)
library(viridis)

```

After successful package installation with a subsequent import of the same, we can now proceed with connecting to the server. The previously loaded package, makes it very easy to construct a correctly formatted connection string that connects to an existing database server. In [R Tools for VS](https://visualstudio.microsoft.com/vs/features/rtvs/) you can also directly import the connection, essentially creating a settings.R file that creates list containing all the connections etc. To keep tool agnostic, lets use the functionality of `sqlmlutils`:

`score.R` (import data from sql server)

```R
# ---------------------------------------
# set the compute context
rxSetComputeContext("local")

# ---------------------------------------
# define connection string
SqlConnectionString <- connectionInfo(
  server= "your server",
  database = "your database"
)

# ---------------------------------------
# define which table you want to use as a dataset
table <- 'dbo.Payments' # not included as confidential

# ---------------------------------------
# create an SQL Server data object
# query can be used to subset the data
sqlServerDS <- RxSqlServerData(
  sqlQuery = paste("SELECT * FROM", table),
  connectionString = SqlConnectionString)

# ---------------------------------------
# Import data from sql server into a tibble
payment <- rxImport(sqlServerDS) %>% 
  as_tibble()

```

Once imported into R, you can explore the data normally; such as e.g. exploring the data with plots etc.

`score.R` (data exploration, plotting)

```R
# ---------------------------------------
# define simple plot function used in the preceding plots
plot <- function(.){
  p <- ggplot(., aes(x = key, y = value, fill = value)) +
    scale_fill_viridis(option = 'magma', begin = 0.2, end = 0.8) +
    geom_bar(stat = 'identity') +
    facet_wrap(~grouping) +
    coord_flip() +
    theme_bw() +
    theme(legend.position = 'none',
          axis.title.y = element_blank(),
          axis.title.x = element_blank(),
          text = element_text(size = 16),
          plot.title = element_text(size = 28))
  return(p)
}  


# ---------------------------------------
# Analyse data by subsegment
payment %>% 
  mutate(
    grouping = substr(SubSegment, 1, 4)
  ) %>% 
  group_by(grouping) %>% 
  summarise(
    AVG_Anz_Rechnungen = mean(Anzahl_Rechnungen),
    AVG_MIN_DSO = mean(MIN_DSO),
    AVG_MAX_DSO = mean(MAX_DSO),
    AVG_AVG_DSO = mean(AVG_DSO),
    AVG_AVG_LAST_3 = mean(AVG_DSO_LAST3),
    AVG_STDEV_DSO = mean(STDEV_DSO)
  ) %>% 
  gather(., ... = starts_with('AVG')) %>% 
  plot()

# ---------------------------------------
# Analyse data by Zahlungsbedingungen
payment %>% 
  mutate(
    grouping = Zahlungsbedingungen
  ) %>% 
  group_by(grouping) %>% 
  summarise(
    AVG_Anz_Rechnungen = mean(Anzahl_Rechnungen),
    AVG_MIN_DSO = mean(MIN_DSO),
    AVG_MAX_DSO = mean(MAX_DSO),
    AVG_AVG_DSO = mean(AVG_DSO),
    AVG_AVG_LAST_3 = mean(AVG_DSO_LAST3),
    AVG_STDEV_DSO = mean(STDEV_DSO)
  ) %>% 
  gather(., ... = starts_with('AVG')) %>% 
  plot()

```

Then we might assume a normal distribution of the DSO per client, essentially using the mean and standard deviation to estimate the distribution to get the probability of a late payment per user.

> Note that this is a simplistic example without properly testing other alternative approaches of modelling the problem. Also, we did not have access to the data to compute additional features.

`score.R` (data exploration, estimating distributions and more plotting)

```R
# ---------------------------------------
# Compute probabilities
payment_attributes <- payment %>% 
  select(AVG_DSO, STDEV_DSO, Anzahl_Rechnungen, PRECID, Zahlungsbedingungen) %>% 
  mutate(
    Zahlungsbedingung = ifelse(grepl('TN', Zahlungsbedingungen), gsub("TN", "", Zahlungsbedingungen), 0)
  ) %>% 
  transmute(
    customer_id = PRECID,
    sample_size = Anzahl_Rechnungen,
    sigma = STDEV_DSO,
    mu = AVG_DSO,
    threshold = as.numeric(Zahlungsbedingung)
  ) %>%
  mutate(
    prob_late = 1 - pnorm(q = threshold, mean = mu, sd = sigma),
    prob_5T = 1 - pnorm(q = 5, mean = mu, sd = sigma),
    prob_10T = 1 - pnorm(q = 10, mean = mu, sd = sigma),
    prob_15T = 1 - pnorm(q = 15, mean = mu, sd = sigma),
    prob_30T = 1 - pnorm(q = 30, mean = mu, sd = sigma),
    prob_60T = 1 - pnorm(q = 60, mean = mu, sd = sigma),
    prob_90T = 1 - pnorm(q = 90, mean = mu, sd = sigma),
    sample_size_large_enough = ifelse(sample_size > 29, 1, 0)
  ) 

# ---------------------------------------
# define function to plot a sample
plot_sample <- function(PRECID) {
  sample <- payment_attributes %>% 
    filter(customer_id == PRECID) 
  
  p <- ggplot(data = data.frame(x = c(0, 100)), aes(x)) +
    stat_function(fun = dnorm, n = 101, args = list(mean = sample$mu, sd = sample$sigma)) + ylab("") +
    scale_y_continuous(breaks = NULL) +
    geom_vline(xintercept = sample$threshold, color = 'red') +
    theme_bw()
  
  return(p)
}

# ---------------------------------------
# Plot PRECID = 5637540588
plot_sample(PRECID = 5637540588)

# ---------------------------------------
# Get values of this sample
payment_attributes %>% 
  filter(customer_id == 5637540588)

```

Then you might choose to operationalize this model, essentially planning to create a stored procedure on SQL Server that can be used by the DWH developer to get these probabilities. The package `sqlmlutils` provides handy functions that allow us to directly create a skeleton of a stored procedure and execute it directly on the SQL Server. To do this, simply need to do the following:

```R
# ---------------------------------------
# Create a function, with input parameters and a result.

#' Get probabilities form gaussian distribution
#' 
#' Your description
#'
#' @param payment_data Sample data.frame
#'
#' @return data frame with probabilities
#' @export
#'
#' @examples
get_probabilities <- function(payment_data) {
  require(tidyverse)
  require(stats)
  probs <- payment_data %>% 
    select(AVG_DSO, STDEV_DSO, Anzahl_Rechnungen, PRECID, Zahlungsbedingungen) %>% 
    mutate(
      Zahlungsbedingung = ifelse(grepl('TN', Zahlungsbedingungen), gsub("TN", "", Zahlungsbedingungen), 0)
    ) %>% 
    transmute(
      customer_id = PRECID,
      sample_size = Anzahl_Rechnungen,
      sigma = STDEV_DSO,
      mu = AVG_DSO,
      threshold = as.numeric(Zahlungsbedingung)
    ) %>%
    mutate(
      prob_late = 1 - pnorm(q = threshold, mean = mu, sd = sigma),
      prob_5T = 1 - pnorm(q = 5, mean = mu, sd = sigma),
      prob_10T = 1 - pnorm(q = 10, mean = mu, sd = sigma),
      prob_15T = 1 - pnorm(q = 15, mean = mu, sd = sigma),
      prob_30T = 1 - pnorm(q = 30, mean = mu, sd = sigma),
      prob_60T = 1 - pnorm(q = 60, mean = mu, sd = sigma),
      prob_90T = 1 - pnorm(q = 90, mean = mu, sd = sigma),
      sample_size_large_enough = ifelse(sample_size > 29, 1, 0)
    ) 
  
  return(probs)
}

# ---------------------------------------
# Get SqlConnectionString to connect to sql server
# and drop stored procedure if it already exists
dropSproc(SqlConnectionString, "usp_GetProbabilities")

# ---------------------------------------
# Then create new stored procedure
createSprocFromFunction(
  SqlConnectionString, 
  name = "usp_GetProbabilities",
  func = get_probabilities, 
  inputParams = list(payment_data="dataframe")
)
```

This will create a stored procedure on the server you have defined in the connection string at the beginning of the example; which can be called as follows:

```sql
USE [yourdb]
GO

DECLARE	@return_value int

EXEC	@return_value = [dbo].[usp_GetProbabilities]
		@payment_data_outer = N'Select * From dbo.Payments'

SELECT	'Return Value' = @return_value

GO
```

## Conclusion

This was a very simple example illustrating how you can operationalize your R Scripts on SQL Server Machine Learning Services 2017. Keep in mind that there MRO provides much more functionality than illustrated in this example; to explore these functionality, please consult e.g. the function reference of [Microsoft](https://docs.microsoft.com/en-us/machine-learning-server/r-reference/revoscaler/revoscaler).

