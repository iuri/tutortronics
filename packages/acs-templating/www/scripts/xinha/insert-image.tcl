ad_page_contract {
  @author Guenter Ernst guenter.ernst@wu-wien.ac.at, 
  @author Gustaf Neumann neumann@wu-wien.ac.at
  @creation-date 13.07.2004
  @cvs-id $Id: insert-image.tcl,v 1.5 2015/12/04 13:50:18 cvs Exp $
} {
  {fs_package_id:naturalnum,optional}
  {folder_id:naturalnum,optional}
}
 
set selector_type "image"
set file_selector_link [export_vars -base file-selector \
			    {fs_package_id folder_id selector_type}]
set fs_found 1

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
