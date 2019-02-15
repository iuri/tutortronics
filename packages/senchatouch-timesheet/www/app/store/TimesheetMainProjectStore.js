/*
 * TimesheetMainProjectStore
 *
 * Copyright (c) 2011 - 2014 ]project-open[ Business Solutions, S.L.
 * This file may be used under the terms of the GNU General Public 
 * License version 3.0 or alternatively unter the terms of the ]po[ 
 * FL or CL license as specified in www.project-open.com/en/license.
 */

/**
 * Returns a list of "main projects" (top-level project), together 
 * with the number of total hours logged by the current user, and
 * the hours for a specific day.
 */
Ext.define('PO.store.TimesheetMainProjectStore', {
    extend: 'Ext.data.Store',
    storeId: 'timesheetMainProjectStore',
    config: {
	model: 'PO.model.Project',
	autoLoad: true,
	pageSize: 10000,
	sorters: [
	    {
		property: 'company_name',
		direction: 'ASC'
	    }, {
		property: 'project_name',
		direction: 'ASC'
	    }
	],
	grouper: {
	    groupFn: function(record) {
//		return record.get('project_name').substring(0,1);
		return record.get('company_name');
	    }
	},
	proxy: {
	    type: 'rest',
            url: '/intranet-reporting/view',
            extraParams: {
                format: 'json',
		report_code: 'rest_main_projects_with_hours',
		date: Ext.Date.format(new Date(), 'Y-m-d')
            },
            reader: {
		type: 'json', 
		rootProperty: 'data' 
	    }
        }	
	
    }
});

