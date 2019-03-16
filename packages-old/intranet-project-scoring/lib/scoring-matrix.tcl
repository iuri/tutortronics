# /packages/intranet-project-scoring/www/scoring-matrix.tcl
#
# Copyright (C) 2014 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

# ----------------------------------------------------------------------
# 
# ---------------------------------------------------------------------

# The following variables are expected in the environment
# defined by the calling /tcl/*.tcl libary:
#	diagram_width
#	diagram_height
#       diagram_caption

if {![info exists project_id]} {
    ad_page_contract {
	Simple 2x2 matrix with drag-and-drop.
	Used as a template for other small DnD portlets.
	
	@project_id A project with a few tasks or sub-projects
    } {
	project_id:integer
	{diagram_width 400}
	{diagram_height 400}
	{diagram_caption ""}
	{show_master_p 1}
    }
} else {
    set show_master_p 0
}

# Load libraries, create a random ID and make sure parameters exist
im_sencha_extjs_load_libraries
set diagram_id "scoring_matrix_[expr {round(rand() * 100000000.0)}]"
if {![info exists diagram_width]} { set diagram_width 400 }
if {![info exists diagram_height]} { set diagram_height 400 }
if {![info exists diagram_caption]} { set diagram_caption "Scoring" }


# Create a random ID for the diagram
set diagram_id "sales_pipeline_[expr {round(rand() * 100000000.0)}]"

set default_currency [im_parameter -package_id [im_package_cost_id] "DefaultCurrency" "" "EUR"]
set value_l10n [lang::message::lookup "" intranet-project-scoring.Value Value]
set prob_l10n [lang::message::lookup "" intranet-project-scoring.Probability Probability]
set priority_l10n [lang::message::lookup "" intranet-project-scoring.Priority Priority]
set strategic_l10n [lang::message::lookup "" intranet-project-scoring.Strategic Strategic]
set npv_l10n [lang::message::lookup "" intranet-project-scoring.NPV NPV]
set customer_l10n [lang::message::lookup "" intranet-project-scoring.Customer Customer]
set cost_l10n [lang::message::lookup "" intranet-project-scoring.Cost Cost]

# set _l10n [lang::message::lookup "" intranet-project-scoring.]


set x_axis 0
set y_axis 0
set color "yellow"
set diameter 5
set title ""
