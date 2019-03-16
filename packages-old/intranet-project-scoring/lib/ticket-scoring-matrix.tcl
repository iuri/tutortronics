# /packages/intranet-project-scoring/lib/ticket-scoring-matrix.tcl
#
# Copyright (C) 2017 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

# ----------------------------------------------------------------------
# 
# ---------------------------------------------------------------------

# The following variables are expected in the environment
# defined by the calling /tcl/*.tcl libary:
#	project_id
#	diagram_width
#	diagram_height
#       diagram_caption


# Create a random ID for the diagram
set diagram_id "scoring_matrix_[expr {round(rand() * 100000000.0)}]"

set default_currency [im_parameter -package_id [im_package_cost_id] "DefaultCurrency" "" "EUR"]
set value_l10n [lang::message::lookup "" intranet-core.Value Value]
set prob_l10n [lang::message::lookup "" intranet-core.Probability Probability]

set priority_l10n [lang::message::lookup "" intranet-project-scoring.Priority "Priority"]
set strategic_l10n [lang::message::lookup "" intranet-project-scoring.Strategic_Score "Strategic"]
set npv_l10n [lang::message::lookup "" intranet-project-scoring.Finance_NPV_Score "NPV"]
set customer_l10n [lang::message::lookup "" intranet-project-scoring.Customer_Score "Customers"]

set x_axis 0
set y_axis 0
set color "yellow"
set diameter 5
set title ""
