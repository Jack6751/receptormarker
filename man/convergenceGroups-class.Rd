% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/classes.R
\docType{class}
\name{convergenceGroups-class}
\alias{convergenceGroups-class}
\title{An S4 class to hold the results of convergence analysis}
\description{
An S4 class to hold the results of convergence analysis
}
\section{Slots}{

\describe{
\item{\code{groups}}{A \code{data.frame} of parsed cluster groups generated by
\code{\link{convergence}}. Each row corresponds to a single convergence
group. The rows are orderd by convergence group size, in descending order.
The columns correspond to:
\describe{
  \item{num_items}{the number of items in each convergence group}
  \item{group_name}{a name for each group}
  \item{X1...X2...etc.}{each additional column can contain a sequence in that
  convergence group, or it will be blank if there are no additional items in
  a convergence group}
}}

\item{\code{network}}{A \code{data.frame} of parsed network information generated
by \code{\link{convergence}}. The data contains three columns:
\describe{
  \item{node1}{a node that can be found in a cluster group in \code{@groups}}
  \item{node2}{another node in a group}
  \item{type}{either 'singleton', 'local', or 'global'}
}
In a given row, \code{node1} and \code{node2} could be different nodes, in
which case they should be connected in a network graph. If they are the
same node then it is a singleton and has no connections.}
}}

