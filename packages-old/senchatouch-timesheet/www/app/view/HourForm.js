/*
 * HourForm.js
 *
 * Copyright (c) 2011 - 2014 ]project-open[ Business Solutions, S.L.
 * This file may be used under the terms of the GNU General Public 
 * License version 3.0 or alternatively unter the terms of the ]po[ 
 * FL or CL license as specified in www.project-open.com/en/license.
 */

/**
 * Form for editing/creating an im_hour object.
 * The form consists of a number of fields and the logic for
 * creating/updating/deleting.
 */
Ext.define('PO.view.HourForm', {
    extend: 'Ext.form.Panel',
    xtype: 'hourForm',
    config: {
        title: 'Hour Details',
        layout: 'vbox',
        items: [
            {
                xtype: 'fieldset',
                items: [
                    {
                        xtype: 'numberfield',
                        name: 'hours',
                        label: 'Hours'
                    }, {
                        xtype: 'textfield',
                        name: 'note',
                        label: 'Description'
                    }, {
                        xtype: 'selectfield',
                        name: 'project_id',
                        label: 'Task',
                        store: 'TimesheetTaskStore'	// recycle the store of the TimesheetTaskList
                    }, {
                        xtype: 'hiddenfield',
                        name: 'id'
                    }, {
                        xtype: 'hiddenfield',
                        name: 'user_id'
                    }, {
                        xtype: 'hiddenfield',		// This is the main data field as string
                        name: 'day'			// in YYYY-MM-DD string(!) format
                    }, {
                        xtype: 'datepickerfield',	// DatePicker requires a date format.
                        name: 'day_date',		// We convert to day before and after edit.
			label: 'Date',
			dateFormat: 'Y-m-d'
                    }
                ]
            }, {
                xtype: 'button',
                text: 'Save',
                ui: 'confirm',
                itemID: 'hourSaveButton',
                handler: function(button, event) {
                    console.log('HourForm: "Save"');

		    var form = button.up('formpanel');
		    var rec = form.getRecord();		    // Get the Hour model

		    // Create a model if necessary
		    if (typeof rec === "undefined" || rec == null) {
			rec = Ext.ModelManager.create(values, 'PO.model.Hour');
		    }

		    // Save the form avalues into the model
		    var values = form.getValues();
		    rec.set(values);
		    rec.set('day', Ext.Date.format(values.day_date, 'Y-m-d'));

		    rec.save({                              // Save the model - generates PUT or POST to REST backend
			success: function(record, operation) {
			    console.log('Successfully updated im_hour object');
			},
			failure: function(record, operation) {
			    Ext.Msg.alert('Failed', operation);
			}
		    });

		    // Update the logged hours in the TaskListStore 
		    var timesheetTaskStore = Ext.data.StoreManager.lookup('TimesheetTaskStore');
		    var taskId = rec.get('project_id');
		    var taskModel = timesheetTaskStore.getById(taskId);
		    taskModel.set('hours_for_user_date', rec.get('hours'));

		    // Return to the list of hours page
		    var projView = button.up('timesheetMainProjectListNavigationView');
		    projView.pop('timesheetTaskList');	
		    
/*
		    Ext.Function.defer(function(){
			var projView = button.up('timesheetMainProjectListNavigationView');
			projView.pop(1, false);	
		    }, 100);
*/


                }
            }, {
                xtype: 'button',
                text: 'Delete',
                ui: 'decline',
                itemID: 'hourDeleteButton',
                handler: function(button, event) {
                    console.log('HourForm: "Delete"');

		    var form = button.up('formpanel');
		    var rec = form.getRecord();		    // Get the Hour model
		    
		    // Reset the logged hours in the TimesheetTaskStore
		    var timesheetTaskStore = Ext.data.StoreManager.lookup('TimesheetTaskStore');
		    var taskId = rec.get('project_id');
		    var taskModel = timesheetTaskStore.getById(taskId);
		    taskModel.set('hours_for_user_date', 0);

		    rec.erase();                // Generates DELETE call to REST backend
		    
		    // Return to the list of hours page
		    var projView = button.up('timesheetMainProjectListNavigationView');
		    projView.pop();
                }
            }
        ]
    }
});

