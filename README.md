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

### Machine Learning Templates
Microsoft has developed a number of templates for solving specific machine learning problems with SQL Server ML Services. These templates provides a higher starting point and aims to enable users to quickly build and deploy solutions. Each template includes the following components:

- Predefined *data schema* applicable to the specific domain
- Domain specific *data processing* and *feature engineering* steps
- Preselected *training *algorithms fit to the specific domain 
- Domain specific *evaluation metrics* where applicable
- *Prediction (scoring)* in production.  

The available templates are listed below.

| Template | Documentation |
| -------- | -------- |
|[Campaign Optimization](https://github.com/Microsoft/r-server-campaign-optimization)|[Website](https://microsoft.github.io/r-server-campaign-optimization/)|
|[Customer Churn](Churn)|[Repository](https://github.com/microsoft/SQL-Server-R-Services-Samples/)|
|[Energy Demand Forecasting](EnergyDemandForecasting)|[Repository](https://github.com/microsoft/SQL-Server-R-Services-Samples/)|
|[Fraud Detection](https://github.com/Microsoft/r-server-fraud-detection) |[Website](https://microsoft.github.io/r-server-fraud-detection/)|
|[Galaxy Classification](Galaxies)|[Repository](https://github.com/microsoft/SQL-Server-R-Services-Samples/)|
|[Length of Stay](https://github.com/Microsoft/r-server-hospital-length-of-stay)|[Website](https://microsoft.github.io/r-server-hospital-length-of-stay/)|
|[Loan Chargeoff Prediction](https://github.com/Microsoft/r-server-loan-chargeoff)|[Website](https://microsoft.github.io//r-server-loan-chargeoff/)|
|[Loan Credit Risk](https://github.com/Microsoft/r-server-loan-credit-risk)|[Website](https://microsoft.github.io/r-server-loan-credit-risk/)|
|[Predictive Maintenance (1)](PredictiveMaintenance)|[Repository](https://github.com/microsoft/SQL-Server-R-Services-Samples/)|
|[Predictive Maintenance (2)](PredictiveMaintenanceModelingGuide)|[Repository](https://github.com/microsoft/SQL-Server-R-Services-Samples/)|
|[Product Cross Sell](ProductCrossSell)|[Repository](https://github.com/microsoft/SQL-Server-R-Services-Samples/)|
|[Resume Matching](SQLOptimizationTips-Resume-Matching)|[Repository](https://github.com/microsoft/SQL-Server-R-Services-Samples/)|
|[Retail Forecasting](RetailForecasting)|[Repository](https://github.com/microsoft/SQL-Server-R-Services-Samples/)|
|[Ski Rental Prediction](SkiRentalPrediction)|[Repository](r-server-ski-rental-prediction)|
|[Text Classification](https://github.com/Microsoft/ml-server-text-classification)|[Website](https://microsoft.github.io/ml-server-text-classification/)|
