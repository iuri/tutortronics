/*
 * TimesheetMainProjectListController.js
 *
 * Copyright (c) 2011 - 2014 ]project-open[ Business Solutions, S.L.
 * This file may be used under the terms of the GNU General Public 
 * License version 3.0 or alternatively unter the terms of the ]po[ 
 * FL or CL license as specified in www.project-open.com/en/license.
 */

/**
 * Controller for the list of main projects.
 * Tapping: Shows project details
 * Disclose: Shows the list of tasks for hour logging
 */
Ext.define('PO.controller.TimesheetMainProjectListController', {
    extend: 'Ext.app.Controller',
    xtype: 'timesheetMainProjectListController',
    config: {
        profile: Ext.os.deviceType.toLowerCase(),
        refs: {
            timesheetMainProjectListNavigationView: 'timesheetMainProjectListNavigationView',
            timesheetMainProjectList: 'timesheetMainProjectList',
            timesheetDatePicker: '#timesheetDatePicker',
	    tabPanel: 'tabPanel'
        },
        control: {
            'timesheetMainProjectList': {
                activate: 'onActivate',
                itemtap: 'onItemTap',
                disclose: 'onDisclose'
            }
        }
    },
    
    onActivate: function() {
        console.log('TimesheetMainProjectListController.onActivate');
    },

    // Tap on MainList - same as Disclose at the moment
    onItemTap: function(view, index, target, record, event) {
        console.log('TimesheetMainProjectListController.onItemTap');
        this.onDisclose(null, record);
    },
 
    /**
     * Pressed the -> button on the TimesheetMainProjectList-
     * Show the TimesheetTaskList with the specified project.
     */
    onDisclose: function(list, record) {
        console.log('TimesheetMainProjectListController.onDisclose');
        var navView = this.getTimesheetMainProjectListNavigationView();
        var project_name = record.get('project_name');
        var taskList = Ext.create("PO.view.TimesheetTaskList", {
            title: project_name + ' Tasks and Hours'
        });
        
        // Load the right data into the store
        var store = Ext.data.StoreManager.lookup('TimesheetTaskStore');
        var today = this.getTimesheetDatePicker().getValue();
        
        store.load({
            params : {
                'main_project_id': record.get('project_id'),
                'date': Ext.Date.format(today, 'Y-m-d')
            }
        });

        // Push the task list 
        taskList.setStore(store);
        var list = navView.push(taskList);
    }
});

