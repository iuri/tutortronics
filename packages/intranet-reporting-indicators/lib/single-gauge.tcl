# /packages/intranet-reporting-indicators/lib/single-gauge.tcl
#
# Copyright (c) 2016 Project Open Business Solutions S.L.
# All rights reserved
#

ad_page_contract {
    Create JS for single gauge
    @author klaus.hofeditz@project-open.com
}

set current_user_id [auth::require_login]
