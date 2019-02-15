/*
 * TaskForm.js
 *
 * Copyright (c) 2011 - 2014 ]project-open[ Business Solutions, S.L.
 * This file may be used under the terms of the GNU General Public 
 * License version 3.0 or alternatively unter the terms of the ]po[ 
 * FL or CL license as specified in www.project-open.com/en/license.
 */

/**
 * Timesheet entry page for a single task, sub-project or main project.
 * Allows the user to log a single timesheet entry.
 */
Ext.define('PO.view.TaskForm', {
    extend: 'Ext.form.Panel',
    xtype: 'taskForm',
    config: {
        title: 'Task Form',
        layout: 'vbox',
        items: [
	    {
		xtype: 'fieldset',
		title: 'Information',
		items: [
		    {
			xtype: 'textfield',
			name: 'project_name',
			label: 'Project'
		    }, {
			xtype: 'selectfield',
			name: 'project_status_id',
			label: 'Status',
			store: 'ProjectStatusStore'
		    }, {
			xtype: 'selectfield',
			name: 'project_type_id',
			label: 'Type',
			store: 'ProjectTypeStore'
		    }, {
			xtype: 'hiddenfield',
			name: 'id'
		    }, {
			xtype: 'hiddenfield',
			name: 'object_id',
			label: 'Object ID',
			value: 0		// Magic value: 0 is the ID of the "guest" object
		    }
		]
            }
/*	    , {
		xtype: 'button',
		text: 'Save',
		ui: 'confirm',
		handler: function() {
		    console.log('TaskForm: Button "Save" pressed:');
		    
		    // Save the form values to the record.
		    var form = this.up('formpanel');
		    var values = form.getValues();
		    var rec = form.getRecord();
		    
		    // Did we create a completely new project?
		    if (typeof rec === "undefined" || rec == null) {
			rec = Ext.ModelManager.create(values, 'PO.model.Project');
		    }
		    
		    // Save the model - generates PUT or POST to REST backend
		    rec.set(values);
		    rec.save();
		    
		    // reload the store
		    var projectStore = Ext.data.StoreManager.lookup('ProjectStore');
		    projectStore.load();
		    
		    // Return to the list of projects page
		    var navView = this.up('projectNavigationView');
		    navView.pop();
		}
            }
*/
        ]
    }
});

