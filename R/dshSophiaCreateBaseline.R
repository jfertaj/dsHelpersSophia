#' Create a baseline data frame on the federated node
#'
#' Given a vector of valid measurement table Concept IDs the function creates a 'baseline' data frame on the federated node. Here, 'baseline' means the first measurement available, and as such may be different for different Concept IDs. The function also creates an approximate 'age_baseline' variable and merged the baseline data with gender if available in the person table.
#' @return A federated data frame named 'baseline'.
#' @examples
#' \dontrun{
#' # connect to the federated system
#' dshSophiaConnect()
#'
#' # load database resources
#' dshSophiaLoad()
#'
#' # create a 'baseline' data frame on the federated node
#' dshSophiaCreateBaseline(concept_id = c(3038553, 3025315, 37020574))
#' 
#' # check result
#' dsBaseClient::ds.summary("baseline")
#' }
#' @import DSOpal opalr httr DSI dsQueryLibrary dsResource dsBaseClient dplyr
#' @importFrom utils menu 
#' @export
dshSophiaCreateBaseline <- function(procedure_id = NULL, observation_id = NULL) {

    # ----------------------------------------------------------------------------------------------
    # if there is not an 'opals' or an 'nodes_and_cohorts' object in the Global environment,
    # the user probably did not run dshSophiaConnect() yet. Here the user may do so, after 
    # being prompted for username and password.
    # ----------------------------------------------------------------------------------------------
    
    if (exists("opals") == FALSE || exists("nodes_and_cohorts") == FALSE) {
        cat("")
        cat("No 'opals' and/or 'nodes_and_cohorts' object found\n")
        cat("You probably did not run 'dshSophiaConnect' yet, do you wish to do that now?\n")
        switch(menu(c("Yes", "No (abort)")) + 1,
               cat("Test"), 
               dshSophiaPrompt(),
               stop("Aborting..."))
    }
    
    # --------------------------------------------------------------------------------------------------
    # get year of birth and gender from person table
    # --------------------------------------------------------------------------------------------------
    
    # load person table
    dsQueryLibrary::dsqLoad(symbol = "baseline",
                            domain = "concept_name",
                            query_name = "person",
                            union = TRUE,
                            datasources = opals,
                            async = TRUE)
    
    # keep only columns we need
    dsSwissKnifeClient::dssSubset("baseline",
                                  "baseline",
                                  col.filter = "colnames(baseline) %in% c('person_id', 'gender', 'year_of_birth', 'birth_datetime')",
                                  datasources = opals)
    
    if (!is.null(procedure_id)) {
        
        for (i in procedure_id) {
            
            p_clause <- paste0("procedure_concept_id in ('", i, "')")
            
            dsQueryLibrary::dsqLoad(symbol = "p",
                                    domain = "concept_name",
                                    query_name = "procedure_occurrence",
                                    where_clause = p_clause,
                                    union = TRUE,
                                    datasources = opals)
            
            dsSwissKnifeClient::dssDeriveColumn("p",
                                                paste0("tmp_", i), 
                                                "1")

            dsSwissKnifeClient::dssSubset("p",
                                          "p",
                                          col.filter = paste0("c('person_id', 'tmp_", i, "')"),
                                          datasources = opals)
            
            # join into temporary data frame 'tmp'
            dsSwissKnifeClient::dssJoin(c("p", "baseline"),
                                        symbol = "tmp",
                                        by = "person_id",
                                        join.type = "full",
                                        datasources = opals)
            
            # change NAs into 0s
            dsBaseClient::ds.replaceNA(paste0("tmp$tmp_", i), 
                                       0, 
                                       paste0("tmp2_", i))
            
            dsBaseClient::ds.asFactor(paste0("tmp$tmp2_", i), "tmp2")
            
            dsSwissKnifeClient::dssDeriveColumn("tmp",
                                                paste0("has_", i), 
                                                "tmp2")
            
            dsSwissKnifeClient::dssSubset("tmp",
                                          "tmp",
                                          col.filter = paste0("c('person_id', 'has_", i, "')"),
                                          datasources = opals)
            
            # merge with 'baseline'
            dsSwissKnifeClient::dssJoin(c("tmp", "baseline"),
                                        symbol = "baseline",
                                        by = "person_id",
                                        join.type = "full",
                                        datasources = opals)
            
            dsBaseClient::ds.rm("tmp")
        }
    } 
    
    if (!is.null(observation_id)) {
        
        for (i in observation_id) {
            
            o_clause <- paste0("observation_concept_id in ('", i, "')")

            connection_name <- gsub("\\.", "_", DSI::datashield.resources(opals)[[1]])

            dsResource::dsrAssign(symbol = "o",
                                  table = "observation",
                                  where_clause = o_clause,
                                  db_connection = connection_name,
                                  datasources = opals)

            dsSwissKnifeClient::dssSubset("o",
                                          "o",
                                          row.filter = "!duplicated(person_id)",
                                          datasources = opals)
 
            dsSwissKnifeClient::dssSubset("o",
                                          "o",
                                          col.filter = paste0("c('person_id')"),
                                          datasources = opals)

            dsSwissKnifeClient::dssDeriveColumn("o",
                                                paste0("tmp_", i), 
                                                "1")

            dsSwissKnifeClient::dssSubset("o",
                                          "o",
                                          col.filter = paste0("c('person_id', 'tmp_", i, "')"),
                                          datasources = opals)

            
            # join into temporary data frame 'tmp'
            dsSwissKnifeClient::dssJoin(c("o", "baseline"),
                                        symbol = "tmp",
                                        by = "person_id",
                                        join.type = "full",
                                        datasources = opals)
            
            # change NAs into 0s
            dsBaseClient::ds.replaceNA(paste0("tmp$tmp_", i), 
                                       0, 
                                       paste0("tmp2_", i))
            
            dsBaseClient::ds.asFactor(paste0("tmp$tmp2_", i), "tmp2")
            
            dsSwissKnifeClient::dssDeriveColumn("tmp",
                                                paste0("has_", i), 
                                                "tmp2")
            
            dsSwissKnifeClient::dssSubset("tmp",
                                          "tmp",
                                          col.filter = paste0("c('person_id', 'has_", i, "')"),
                                          datasources = opals)
            
            # merge with 'baseline'
            dsSwissKnifeClient::dssJoin(c("tmp", "baseline"),
                                        symbol = "baseline",
                                        by = "person_id",
                                        join.type = "full",
                                        datasources = opals)
            
            # clean up
            dsBaseClient::ds.rm("tmp")
        }
    }
}
