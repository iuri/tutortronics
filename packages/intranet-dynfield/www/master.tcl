#    @author Matthew Geddert openacs@geddert.com
#    @creation-date 2005-05-09
#    @cvs-id $Id: master.tcl,v 1.5 2016/02/18 19:09:33 cvs Exp $

# Set up links in the navbar that the user has access to
set package_url [ad_conn package_url]
set page_url [ad_conn url]
set page_query [ad_conn query]

if {![info exists left_navbar]} { set left_navbar "" }
if {![info exists title] && [info exists doc(title)]} { set title $doc(title) }
if {![info exists title] || "" eq $title} { set title "DynField" }

set navbar [list]
