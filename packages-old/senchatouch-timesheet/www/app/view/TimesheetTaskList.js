/*
 * TimesheetTaskList.js 
 *
 * Copyright (c) 2011 - 2014 ]project-open[ Business Solutions, S.L.
 * This file may be used under the terms of the GNU General Public 
 * License version 3.0 or alternatively unter the terms of the ]po[ 
 * FL or CL license as specified in www.project-open.com/en/license.
 *
 */

/**
 * Shows a list of tasks plus their logged hours.
 */
Ext.define('PO.view.TimesheetTaskList', {
	extend: 'Ext.List',
	xtype: 'timesheetTaskList',
	requires: ['PO.store.TimesheetTaskStore'],

	config: {
	    title: 'Task Projects',
	    store: 'TimesheetTaskStore',
	    iconCls: 'star',	    
	    itemTpl: new Ext.XTemplate(
		'<div class="myButton"><input type="button" name="{project_id}" value="',
		    '<tpl if="hours_for_user_date &gt; 0">',
		        '{hours_for_user_date}',
		    '<tpl else>',
		        'Log',
		    '</tpl>',
		    '" style="padding:1px; width:70px;">' +
		'</div>' +
		'<div class="myContent">'+
		'<div><b><nobr>{indent}{project_name}</nobr></b>' +
		'</div>'
	    ),

	    inline: { wrap: false },
	    // scrollable: { direction: 'both', directionLock: true },
	    scrollable: 'both',

	    disclosure: true,
	    grouped: false,
	    indexBar: false,
	    onItemDisclosure: false
	}
});
