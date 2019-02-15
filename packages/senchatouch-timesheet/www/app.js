/*
 * app.js
 *
 * Copyright (c) 2011 - 2014 ]project-open[ Business Solutions, S.L.
 * This file may be used under the terms of the GNU General Public 
 * License version 3.0 or alternatively unter the terms of the ]po[ 
 * FL or CL license as specified in www.project-open.com/en/license.
 */
Ext.application({
    name: 'PO',
    models: [
	'Category',				// Represents states and types of objects
	'Hour',					// Logged timesheet hours
	'Note',					// A simple text note that can be attached to projects or users
	'Project'				// Project or task
    ],
    stores: [
	'ProjectStatusStore',			// List of project states
	'ProjectTypeStore',			// List of project types
	'HourStore',				// Generic store of hours retreived
	'NoteStore',				// List of global notes
	'TimesheetMainProjectStore',		// List of main projects projects
	'TimesheetTaskStore'			// List of tasks of a single main project
    ],
    views: [
	'HourForm',				// Edit/Create page for hours
	'SplashPage',				// Initial screen with ]po[ logo
	'NoteForm',				// Note edite/create form
	'NoteNavigationView',			// Container for navigation between NoteList and NoteForm
	'TaskForm',				// Note edite/create form
	'TimesheetMainProjectList',
	'TimesheetMainProjectListNavigationView',	// Navigation container for Timesheet sub-application
	'TimesheetTaskList',			// Edit/Create page for hours
	'TimesheetDateSelectForm'		// Small panel showing the current date to log hours
    ],
    controllers: [
	'NoteNavigationController',
	'TimesheetMainProjectListController',	// Timesheet: Controller for 1st level (main projects)
	'TimesheetTaskListController'		// Timesheet: Controller for 2nd level (tasks)
    ],

    viewport: {
	autoMaximize: false			// set to false for iOS 9
    },

    // Main function: Load the various panels
    launch: function() {
	Ext.create("Ext.tab.Panel", {
	    fullscreen: true,
	    tabBarPosition: 'bottom',
	    xtype: 'tabPanel',
	    items: [
		// The application consists of three indenpendent sections:
		{xtype: 'splashPage'}, 
		{xtype: 'timesheetMainProjectListNavigationView'},
		{xtype: 'noteNavigationView'}
	    ]
	});
    }
});
