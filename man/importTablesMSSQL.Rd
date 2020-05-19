\name{importTablesMSSQL}
\alias{importTablesMSSQL}
\title{importTablesMSSQL}
\description{
\code{importTablesMSSQL} imports tables from Microsoft SQL Server into the R global environment. It's intended for multi-table pulls in such cases that render individual queries unwieldy, but it pulls single tables just fine, too.
}
\usage{
importTablesMSSQL(
	conn,
	tables=NA,
	refresh=FALSE,
	silent=FALSE
)
}
\arguments{
  \item{conn}{
  A DBIConnection object returned by \code{\link[DBI]{dbConnect}()}.
  }
  \item{tables}{
  A string or vector of strings representing tables to be pulled. Accepts table names formatted as either \code{database.schema.table}, \code{schema.table}, or \code{table}. If \code{tables = NA} (the default), all tables will be pulled.
  }
  \item{refresh}{
  Logical value representing whether to pull tables that have already been pulled previously. \code{FALSE} by default to prevent unnecessary refreshing. For convenience, the \code{database.manifest} variable lists all tables on the target server as they appear in the global environment.
  }
  \item{silent}{
  Logical value representing whether to display the progress bar. \code{FALSE} by default. Pulling progress is calculated on number of cells pulled against total number of cells expected.
  }
}
\details{
%%  ~~ If necessary, more details than the description above ~~
}
\value{
\code{NULL}. Rather than return a value, \code{importTablesMSSQL} imports the following directly into the global environment:
\itemize{
	\item{
	Each target table as a dataframe, named \code{database.schema.table}
	}
	\item{
	A character vector of the names of all imported tables, named \code{database.manifest}
	}
}
}
\references{
%% ~put references to the literature/web site here ~
}
\author{
\href{https://www.linkedin.com/in/jonathan-dayley-371398102}{Jonathan Dayley}
}
\note{
%%  ~~further notes~~
}

%% ~Make other sections like Warning with \section{Warning }{....} ~

\seealso{
\code{\link[DBI]{dbConnect}()}
}
\examples{
# Clear environment except for imported tables ----
tryCatch(
	expr=rm(list=ls()[!ls()\%in\%AdventureWorks.manifest]),
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
}
