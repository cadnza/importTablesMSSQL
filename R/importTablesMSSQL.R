importTablesMSSQL <- function(
	conn,
	tables=NA,
	refresh=FALSE,
	silent=FALSE
){

	# Check connection argument ----
	if(conn@info[["dbms.name"]]!="Microsoft SQL Server")
		stop("importTablesMSSQL only accepts connections to Microsoft SQL Server.")

	# Get tables ----
	allNameVersionsQuery <-
		"
		SELECT
			TABLE_CATALOG	+'.'+
			TABLE_SCHEMA	+'.'+
			TABLE_NAME long,
			TABLE_SCHEMA	+'.'+
			TABLE_NAME medium,
			TABLE_NAME short
		FROM
			information_schema.tables
		WHERE
			TABLE_TYPE = 'BASE TABLE'
		ORDER BY 1
		"
	allNameVersions <- DBI::dbGetQuery(
		conn,
		allNameVersionsQuery
	)
	workingTables <- allNameVersions[,1]

	# Get manifest of tables ----
	manifest <- workingTables
	eval(bquote(.(paste0("manifest.",conn@info[["dbname"]])) <<- manifest))

	# Check table argument for existence ----
	if(length(tables)>1|!is.na(tables[1])){
		allNameVersions <- c(
			allNameVersions[,1],
			allNameVersions[,2],
			allNameVersions[,3]
		)
		notFound <- tables[!tables%in%allNameVersions]
		if(length(notFound))
			stop(
				paste(
					paste0("The following tables aren't in ",conn@info[["dbname"]],":"),
					paste(notFound,collapse="\n\t"),sep="\n\t")
			)
		indexes <- c()
		for(i in tables)
			indexes <- c(indexes,which(allNameVersions==i))
		indexes <- indexes%%length(workingTables)
		indexes[indexes==0] <- length(workingTables)
		workingTables <- workingTables[indexes]
	}

	# Refresh according to argument ----
	if(!refresh)
		workingTables <- workingTables[!workingTables%in%ls(envir=.GlobalEnv)]

	# Condition running on table length ----
	if(length(workingTables)){

		# Get total expected cell count ----
		ncellQuery <-
			"
			SELECT
				SUM(cells)
			FROM
				(
					SELECT
						t.name,
						i.rows,
						c.cols,
						i.rows*c.cols cells
					FROM
						sys.tables t
					INNER JOIN
						sys.sysindexes i
						ON t.object_id=i.id
					INNER JOIN
						(
							SELECT
								TABLE_NAME name,
								COUNT(*) cols
							FROM INFORMATION_SCHEMA.COLUMNS
							GROUP BY TABLE_NAME
						) c
						ON t.name=c.name
					WHERE i.indid<2
					AND t.name IN TableColsHere
				) a
			"
		tableIncluded <- paste0(
			"(",
			paste(
				paste0("'",gsub("^.*\\.","",workingTables),"'"),
				collapse=","
			),
			")"
		)
		ncellQuery <- gsub(
			"TableColsHere",
			tableIncluded,
			ncellQuery
		)
		ncells <- DBI::dbGetQuery(conn,ncellQuery)[1,1]

		# Start progress bar if not silent ----
		if(!silent){
			cat("\n")
			cat(paste0("Querying ",conn@info[["dbname"]],"..."))
			cat("\n")
			cat("\n")
			pbData <- txtProgressBar(
				min=0,
				max=max(ncells,1),
				style=3
			)
		}

		# Set tracker for progress bar ----
		totalCells <- 0

		# Start data pulling loop ----
		for(i in workingTables){

			# Pull data ----
			query <- DBI::dbSendQuery(conn,paste("SELECT * FROM",i))
			data <- DBI::dbColumnInfo(query)
			DBI::dbClearResult(query)
			colsData <- data$name
			data <- data[order(data$type,decreasing=TRUE),]
			data$name <- paste0("[",data$name,"]")
			colsQuery <- paste(data$name,collapse=", ")
			queryText <- paste("SELECT",colsQuery,"FROM",i)

			# Run query and format data ----
			returned <- DBI::dbGetQuery(conn,queryText)
			if(ncol(returned)>1)
				returned <- returned[,colsData]

			# Save data ----
			eval(bquote(.(i) <<- returned))

			# Update total cell count ----
			totalCells <- totalCells+nrow(returned)*ncol(returned)

			# Update progress bar if not silent ----
			if(!silent)
				setTxtProgressBar(pbData,max(totalCells,1))
		}

		# Add a new line if not silent ----
		if(!silent)
			cat("\n\n")
	}

}