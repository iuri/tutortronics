/*
 * TimesheetTaskStore.js
 *
 * Copyright (c) 2011 - 2014 ]project-open[ Business Solutions, S.L.
 * This file may be used under the terms of the GNU General Public 
 * License version 3.0 or alternatively unter the terms of the ]po[ 
 * FL or CL license as specified in www.project-open.com/en/license.
 */

/**
 * Returns a list of tasks for a specific "main_project" (top-level
 * project), plus the sum of hours logged by a user total and today.
 */
Ext.define('PO.store.TimesheetTaskStore', {
    extend: 'Ext.data.Store',
    storeId: 'timesheetTaskStore',
    config: {
	model: 'PO.model.Project',
	autoLoad: true,
	pageSize: 10000,
	sorters: [{
	    property: 'tree_sortkey',
	    direction: 'ASC'
	}],
	proxy: {
	    type: 'rest',
            url: '/intranet-reporting/view',
            appendId: true,
            extraParams: {
                format: 'json',
		report_code: 'rest_main_project_tasks_with_hours',
		main_project_id: 0,				// overwritten when loading
		date: Ext.Date.format(new Date(), 'Y-m-d')	// overwritten when loading
            },
            reader: {
		type: 'json', 
		rootProperty: 'data' 
	    }
        }	
    }
});

