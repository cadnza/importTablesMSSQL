# importTablesMSSQL

Simple R package to import tables from Microsoft SQL Server.

## Description

Really a very simple package. `importTablesMSSQL` includes one function of the same name, and it imports tables from SQL Server into the R global environment using the `DBI` package. It's intended for multi-table pulls in such cases that render individual queries unwieldy, but it pulls single tables just fine, too.

## Installation

To install, run the following command in the R console after installing the `devtools` package:
```
devtools::install_github("cadnza/importTablesMSSQL")
```
If you don't have `devtools`, you can get it here:
```
install.packages("devtools")
```

## Use

`importTablesMSSQL` includes standard documentation that can be called from the R console:
```
?importTablesMSSQL
```

## Example

```
# Clear environment except for imported tables ----
tryCatch(
	expr=rm(list=ls()[!ls()%in%AdventureWorks.manifest]),
	error=function(x)invisible()
)

# Get connection info ----
server <- "192.168.0.0"
database <- "AdventureWorks"
username <- keyring::key_list(server)$username

# Open connection ----
conn <- DBI::dbConnect(
	drv = odbc::odbc(),
	Driver = "SQL Server",
	Port = 1433,
	Server=server,
	Database=database,
	UID=username,
	PWD=keyring::key_get(server,username)
)

# Import tables ----
importTablesMSSQL(
	conn,
	tables=c("Sales.vSalesPerson","Person.vAdditionalContactInfo")
)

# View SalesPerson dataframe ----
View(AdventureWorks.Sales.vSalesPerson)
```
