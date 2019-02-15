/*
 * TimesheetDateSelectForm.js
 *
 * Copyright (c) 2011 - 2014 ]project-open[ Business Solutions, S.L.
 * This file may be used under the terms of the GNU General Public 
 * License version 3.0 or alternatively unter the terms of the ]po[ 
 * FL or CL license as specified in www.project-open.com/en/license.
 */

/**
 * A small form with only one DataPicker for selecting the current
 * date for timesheet entry.
 */
Ext.define('PO.view.TimesheetDateSelectForm', {
    extend: 'Ext.form.Panel',
    xtype: 'timesheetDateSelectForm',
    config: {
        layout: 'vbox',
        items: [
	    {
                xtype: 'datepicker',
		label: 'Today',
		name: 'today',
		dateFormat: 'Y-m-d'
            }
        ]
    }
});
