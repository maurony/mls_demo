#########################################################
# installation of r packages                            #
#########################################################
# install r tools 
# https://cran.r-project.org/bin/windows/Rtools/

# install devtools (optional, but recommended)
# install.packages('devtools')

# install sqlmlutils (optinal, but recommended)
# download it here: https://github.com/microsoft/sqlmlutils/tree/master/R/dist
# install.packages('../Downloads/sqlmlutils_0.7.1.zip', repos = NULL, type="binary")

#########################################################
# Loading / Installing additonal packages (open source) #
#########################################################

# dependencies
package_dependencies <- c(
  'sqlmlutils',
  'tidyverse',
  'ggplot2',
  'RevoScaleR'
)

# establish which packages are new
new_packages <- package_dependencies[!(package_dependencies %in% installed.packages()[, 'Package'])]

# install packages that are not installed yet
if (length(new_packages))
  install.packages(new_packages)

# load libraries
lapply(package_dependencies, require, character.only = TRUE)
