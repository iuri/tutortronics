# /packages/intranet-reporting-indicators/lib/single-timeline.tcl
#
# Copyright (c) 2016 ]project-open[
# All rights reserved
#

ad_page_contract {
    @author klaus.hofeditz@project-open.com
}

set query_str "query=$periodic_where and result_date>'$initial_date' and result_date>'$start_date' and result_date<'$end_date' and result_indicator_id=$report_id"
regsub -all {'} $query_str {\'} query_str
set url "/intranet-rest/im_indicator_result/?format=json&$query_str"
