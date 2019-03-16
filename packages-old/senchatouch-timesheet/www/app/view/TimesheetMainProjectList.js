/*
 * TimesheetMainProjectList.js
 *
 * Copyright (c) 2011 - 2014 ]project-open[ Business Solutions, S.L.
 * This file may be used under the terms of the GNU General Public 
 * License version 3.0 or alternatively unter the terms of the ]po[ 
 * FL or CL license as specified in www.project-open.com/en/license.
 *
 */

/**
 * A list of all active main projects for the user.
 * There may still be an issue with permissions and
 * the ]po[ configuration parameters:
 * <ul>
 * <li>TimesheetLogHoursOnPotentialProjectsP: Should the user log on potential projects?
 * <li>TimesheetTaskVisibilityScope: On which tasks should a user be able to log?
 * <li>TimesheetMaxHoursPerDay: Max hours per day
 * <li>PermissiveHourLogging: "permissive" means that we allow Employees to log their hours 
 *     basically on every project in the system. "restrictive" means that users can only log 
 *     to projects (and the project's Tasks) if they are a member of the project. 
 * </ul>
 */
Ext.define('PO.view.TimesheetMainProjectList', {
    extend: 'Ext.List',
    xtype: 'timesheetMainProjectList',
    requires: ['PO.store.TimesheetMainProjectStore'],
    config: {
	title: 'Main Projects',
	store: 'TimesheetMainProjectStore',
	iconCls: 'star',
	disclosure: true,
	sorted: true,
	grouped: true,
	indexBar: true,
	onItemDisclosure: true,
        itemTpl: '<div class="myContent">'+
            '<div><b>{project_name}</b></div>' +
            '</div>',

	// Show a date-picker at the bottom to select the day for logging
	items: [
	    {
		xtype: 'toolbar',
                docked: 'bottom',
		layout: {
		    pack: 'center',
		    type: 'hbox'
		},
                items: [
		    {
                        xtype: 'datepickerfield',
			id: 'timesheetDatePicker',
                        name: 'date',
                        label: 'Date',
                        value: new Date(),
			dateFormat: 'Y-m-d',
                        picker: { yearFrom: 2015 }
                    }
                ]
	    }
	]
    }
});
