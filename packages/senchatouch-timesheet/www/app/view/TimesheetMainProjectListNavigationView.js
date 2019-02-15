/*
 * TimesheetMainProjectListNavigationView.js
 *
 * Copyright (c) 2011 - 2014 ]project-open[ Business Solutions, S.L.
 * This file may be used under the terms of the GNU General Public 
 * License version 3.0 or alternatively unter the terms of the ]po[ 
 * FL or CL license as specified in www.project-open.com/en/license.
 */

/**
 * Top of the timesheet sub-application
 */
Ext.define('PO.view.TimesheetMainProjectListNavigationView', {
    extend: 'Ext.navigation.View',
    xtype: 'timesheetMainProjectListNavigationView',
    config: {
	title: 'Timesheet',
	iconCls: 'time',
	items: [
	    { xtype: 'timesheetMainProjectList' }
	]
    }
});
