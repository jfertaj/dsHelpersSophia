% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/dshSophiaGetBeta.R
\name{dshSophiaGetBeta}
\alias{dshSophiaGetBeta}
\title{Merge a (longitudinal) measurement table variable with the federated 'baseline' data frame}
\usage{
dshSophiaGetBeta(
  outcome,
  predictor,
  coviariate,
  subset_procedure = FALSE,
  standardized = TRUE
)
}
\value{
Nothing, the federated 'baseline' data frame is appended.
}
\description{
Given a valid measurement table Concept ID, the function merges that variable (in wide format) with the 'baseline' data frame on the federated node. Note that the 'baseline' data frame must already exist. If the variable is available across several time points, all time points are included, and the raw difference plus percentage change from time point 1 to timepoint X is calculated.
}
\examples{
\dontrun{
# connect to the federated system
dshSophiaConnect()

# load database resources
dshSophiaLoad()

# create a 'baseline' data frame on the federated node
dshSophiaCreateBaseline(concept_id = c(4111665, 3004410, 3001308))

# add a longitudinal measure
dshSophiaMergeLongMeas(concept_id = 3038553)

# check result
dsBaseClient::ds.summary("baseline")
}
}
