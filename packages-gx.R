# Set our default repo
# http://stackoverflow.com/questions/8475102/set-default-cran-mirror-permanent-in-r
options(repos=structure(c(CRAN="https://cran.rstudio.com/")))
# Update installed packages
#update.packages(ask=FALSE, checkBuilt=TRUE)
# Install some packages
source("https://bioconductor.org/biocLite.R")
biocLite()
biocLite("impute")
biocLite("preprocessCore")
biocLite("GO.db")
biocLite("AnnotationDbi")
install.packages(c('devtools','shiny','WGCNA'))
library(devtools)
devtools::install_github("greenelab/TDM")
install("/tmp/GalaxyConnector")
