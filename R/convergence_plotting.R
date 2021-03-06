#' @title Create a path to a tempory XML file for plotting with Cytoscape
#' @description An internal function that creates a temporary directory to hold
#' the XML file for a Cytoscape network diagram. The directory created is only
#' intended to hold the XML, and no other files, because in order for
#' htmlwidgets to make the XML available in the HTML it copies the entire parent
#' directory.
#' @return A filepath that can be used to save a XML.
#' @keywords internal
convergence_xml_path <- function() {
  # Create a temp dir for the XML file
  convergence_xml_tmpdir <- tempfile("", tmpdir=tempdir(), fileext="")
  dir.create(convergence_xml_tmpdir)  # htmlwidgets copies entire dir to browser
  
  xml_file <- tempfile(pattern="convergence_xml-",
                       tmpdir=convergence_xml_tmpdir,
                       fileext=".xml")
}


#' @title Create a XML file to plot with Cytoscape
#' @description An internal function that parses the output of the convergence
#' tool and creates an XML file to represent a specific row (cluster) in the
#' file.
#' @param convergence_obj An object of class
#' \code{\link{convergenceGroups-class}}, typically returned by
#' \code{\link{run_convergence}}.
#' @param row_num An integer indicating which row number in 
#' \code{convergenceGroups@groups} to graph.
#' Each row should correspond to a single cluster.
#' @param labels \code{TRUE} or \code{FALSE}, depending on whether or not node
#' labels should be written to the XML and therefore displayed in Cytoscape.
#' @param verbose \code{TRUE} or \code{FALSE}. If \code{TRUE} the XML file is
#' copied to the \code{verbose_dir}.
#' @template -verbose_dir
#' @return A path to the Cytoscape XML file.
#' @keywords internal
cytoscape_xml <- function(convergence_obj, row_num, labels, verbose,
                          verbose_dir) {
  groups <- convergence_obj@groups
  xml_file <- convergence_xml_path()
  
  # Get cluster group's nodes, label, and size
  num_cols <- ncol(groups)
  cluster <- groups[row_num, c(3:num_cols)]
  nodes <- na.omit(cluster[cluster != ""])
  cluster_label <- groups[row_num, 2]
  num_nodes <- groups[row_num, 1]
  # Ensure you have the correct number of nodes
  if (num_nodes != length(nodes)) {
    stop("Number of nodes parsed does not match expected number of nodes.",
         call.=FALSE)
  }
  
  # Get the network info so you can determine what connections to make
  network <- unique(convergence_obj@network)
  # Filter out singletons, leaving only 'local' and 'global' connections
  network <- network[which(network["type"] != "singleton"), ]
  # Subset by nodes in this cluster group
  network <- network[which(network[["node1"]] %in% nodes &
                           network[["node2"]] %in% nodes), ]
  
  # Create the XML tree
  schema_location <- paste0(
    c("http://graphml.graphdrawing.org/xmlns",
      "http://graphml.graphdrawing.org/xmlns/1.0/graphml.xsd"
      ), collapse=" "
  )
  root <- XML::newXMLNode(
    "graphml",
    namespaceDefinitions=c(
      "http://graphml.graphdrawing.org/xmlns",
      "xsi"="http://www.w3.org/2001/XMLSchema-instance"
    ),
    attrs=c("xsi:schemaLocation"=schema_location)
  )
  label_key <- XML::newXMLNode("key", 
                               attrs=c(id="label", "for"="all",
                                       "attr.name"="label",
                                       "atr.type"="string"),
                               parent=root)
  weight_key <- XML::newXMLNode("key",
                                attrs=c(id="weight", "for"="edge",
                                        "attr.name"="weight",
                                        "attr.type"="double"),
                                parent=root)
  graph_node <- XML::newXMLNode("graph",
                                attrs=c(id="0", "edgedefault"="directed",
                                        "label"=cluster_label),
                                parent=root)

  # If 'labels' is FALSE, don't show labels by using empty string for labels
  node_labels <- nodes  # Duplicate nodes so you don't overwrite them
  if (!labels) {
    node_labels <- rep("", length(nodes))
  }
  
  # Add cluster nodes into the XML tree as children of graph_node, <graph>
  lapply(c(1:num_nodes), function(x) {
    single_node <- XML::newXMLNode("node", attrs=c(id=nodes[[x]]),
                                   parent=graph_node)
    XML::newXMLNode("data", node_labels[[x]], attrs=c("key"="label"),
                    parent=single_node)
  })
  
  # Use the network to connect the relevant nodes
  if (num_nodes != 1) {
    lapply(c(1:num_nodes), function(x) {
      connections <- network[network["node1"] == nodes[[x]], ]
      num_connections <- nrow(connections)
      if (num_connections > 0) {
        lapply(c(1:num_connections), function(y) {
          edge <- XML::newXMLNode("edge",
                                  attrs=c("source"=connections[y, "node1"],
                                          "target"=connections[y, "node2"]),
                                  parent=graph_node)
          XML::newXMLNode("data", 10, attrs=c("key"="weight"), parent=edge)
          edge
        })
      }
    })
  }
  
  # Write XML to file
  XML::saveXML(root, file=xml_file,
               prefix="<?xml version=\"1.0\" encoding=\"UTF-8\"?>",
               indent=FALSE)
  
  # Copy XML file to verbose dir if user wants it
  if (verbose && file.exists(xml_file)) {
    file.copy(xml_file, verbose_dir)
  }
  xml_file
}


#' @title Create an interactive convergence group network diagram
#' @description Creates a JavaScript-based network diagram in RStudio or a
#' browser window. This visualization plots groups of functionally similar
#' complementary determining regions (CDRs) of antibody or T-cell receptors.
#' These groups should first be created by the \code{\link{convergence}}
#' function.
#' @param convergence_obj An object of class
#' \code{\link{convergenceGroups-class}}, generated by the function
#' \code{\link{convergence}}.
#' @param group_num A row number corresponding to the convergence group to
#' visualize. Specifically, this is a row number in the
#' \code{convergence_obj@groups} data frame, which contains all the groups
#' resulting from the convergence analysis. For more information on selecting
#' a group, see the \code{\link{convergence}} documentation.
#' @param background_color A valid hex color code as a string for the canvas
#' color.
#' @param node_shape A string indicating what shape to use for the nodes. One of
#' \code{"ELLIPSE"}, \code{"RECTANGLE"}, \code{"TRIANGLE"}, \code{"DIAMOND"},
#' \code{"HEXAGON"}, \code{"OCTAGON"}, \code{"PARALLELOGRAM"},
#' \code{"ROUNDRECT"}, \code{"VEE"}.
#' @param border_width An integer border width for the nodes.
#' @param border_color A valid hex color code as a string for the border color
#' of the nodes.
#' @param node_color A valid hex color code as a string for the node color.
#' @param node_size An integer representing node size.
#' @param labels A logical indicating whether or not node labels should be
#' displayed. If \code{TRUE}, labels will be the sequences used for analysis in
#' the convergence pipeline.
#' @param label_vertical_pos A string indicating the vertical position of node
#' labels. Must be one of \code{"top"}, \code{"middle"}, or \code{"bottom"}.
#' Ignored if \code{label=FALSE}.
#' @param label_horizontal_pos  A string indicating the horizontal position of
#' node labels. Must be one of \code{"left"}, \code{"center"}, or
#' \code{"right"}. Ignored if \code{label=FALSE}.
#' @param edge_width An integer representing the thickness of edges, or the
#' lines that connect nodes.
#' @param edge_color A valid hex color code as a string for the edge lines.
#' @template -browser
#' @param verbose \code{TRUE} or \code{FALSE}. If \code{TRUE}, the XML file for
#' Cytoscape is written to a folder in the working directory.
#' @import htmlwidgets
#' @examples
#' data(tcr)  # Packaged data set, a data.frame from a CSV file
#' tcr_reduced <- tcr[1:100, ]
#' converged <- convergence(tcr_reduced, seqs_col='seqs')
#' # Plot the group with the largest size
#' convergence_plot(converged, group_num=1)
#' @export
convergence_plot <- function(convergence_obj, group_num=NULL,
                             background_color="#FFFFFF", node_shape="ELLIPSE",
                             border_width=2, border_color="#161616",
                             node_color="#0B94B1", node_size=30, labels=TRUE,
                             label_vertical_pos="middle",
                             label_horizontal_pos="center", edge_width=3,
                             edge_color="#2D2D2D", browser=FALSE,
                             verbose=FALSE) {
  validate_not_null(list(convergence_obj=convergence_obj,
                         group_num=group_num, browser=browser,
                         verbose=verbose))  
  validate_convergence_clust(convergence_obj)
  tryCatch({
      validate_single_pos_num(group_num)
  },
  error=function(e) {
    stop("Argument 'group_num' must be a positive integer", call.=FALSE)
  }
  )
  # Ensure 'group_num' is an actual row number in convergence_obj@groups
  if (group_num > nrow(convergence_obj@groups)) {
    err <- paste0(c("Argument 'group_num' must be a row number in",
                    "'convergence_obj@groups'"),
                  sep=" ")
    stop(err, call.=FALSE)
  }
          
  
  # Not necessary to have as func parameters; these will get set automatically
  width <- NULL
  height <- NULL
  
  # Create verbose dir
  if (verbose) {
    verbose_dir <- tempfile("convergence-plot-", tmpdir=getwd(), fileext="")
    dir.create(verbose_dir)
  }
  
  # Step 1: Save a specific cluster (row) to XML to send to Cytoscape
  xml_file <- cytoscape_xml(convergence_obj, row_num=group_num, labels,
                            verbose, verbose_dir)
  
  xml <- XML::xmlRoot(XML::xmlTreeParse(xml_file))
  xml_string <- XML::toString.XMLNode(xml)
  
  # Forward options and the XML string to convergence.js using 'x'
  x <- list(
    xml_string=xml_string,
    background_color=background_color,
    node_shape=node_shape,
    border_width=border_width,
    border_color=border_color,
    node_color=node_color,
    node_size=node_size,
    label_vertical_pos=label_vertical_pos,
    label_horizontal_pos=label_horizontal_pos,
    edge_width=edge_width,
    edge_color=edge_color
  )
  
  # Add the XML file as an HTML dependency so it can get loaded in the browser.
  # The Cytoscape visualization doesn't use this (it uses the xml_string above),
  # but it can be useful to debug by simply looking at this file in the browser.
  convergence_xml <- htmltools::htmlDependency(
    name = "convergence_xml",
    version = "1.0",
    src = c(file=dirname(xml_file)),
    attachment = list(xml=basename(xml_file))
  )
  
  # Create widget
  htmlwidgets::createWidget(
    name = "convergence",
    x,
    width = width,
    height = height,
    htmlwidgets::sizingPolicy(
      padding = 22,
      viewer.suppress = browser,
      browser.fill = TRUE
    ),
    package = "receptormarker",
    dependencies = convergence_xml
  )
}

#' @title Shiny bindings for convergence plots
#' @description Output and render functions for using
#' \code{\link{convergence_plot}} within Shiny applications and interactive Rmd
#' documents.
#' @param outputId The output variable to read from.
#' @param width,height A valid CSS unit, such as \code{"100\%"},
#' \code{"600px"}, \code{"auto"}, or a number (which will be coerced to a string
#' and have \code{"px"} appended to it).
#' @param expr An expression that generates a convergence plot.
#' @param env The environment in which to evaluate \code{expr}.
#' @param quoted Is \code{expr} a quoted expression (with \code{quote()})? This
#' is useful if you want to save an expression in a variable.
#' @name convergence_plot_shiny
#' @export
# nolint start
convergence_plotOutput <- function(outputId, width = "100%", height = "400px"){
  shinyWidgetOutput(outputId, "convergence_plot", width, height,
                    package = "receptormarker")
# nolint end
}

#' @rdname convergence_plot_shiny
#' @export
# nolint start
renderConvergence_plot <- function(expr, env = parent.frame(), quoted = FALSE) {
  # force quoted
  if (!quoted) { 
    expr <- substitute(expr)
  }
  shinyRenderWidget(expr, convergence_plotOutput, env, quoted = TRUE)
# nolint end
}
