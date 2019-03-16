/*
 * NoteForm.js
 *
 * Copyright (c) 2011 - 2014 ]project-open[ Business Solutions, S.L.
 * This file may be used under the terms of the GNU General Public 
 * License version 3.0 or alternatively unter the terms of the ]po[ 
 * FL or CL license as specified in www.project-open.com/en/license.
 */

/**
 * Form for editing/creating a note. 
 * The form consists of a number of fields and the logic for
 * creating/updating/deleting a note.
 */
Ext.define('PO.view.NoteForm', {
    extend: 'Ext.form.Panel',
    xtype: 'noteForm',
    config: {
        title: 'Note Detail',
        layout: 'vbox',
        items: [
	    {
                xtype: 'fieldset',
                title: 'Edit Note',
                items: [
		    {
			xtype: 'selectfield',
			name: 'note_type_id',
			label: 'Type',
			options: [
			    {text: 'Address', value: '11500'},
			    {text: 'Email', value: '11502'},
			    {text: 'Http', value: '11504'},
			    {text: 'Ftp', value: '11506'},
			    {text: 'Phone', value: '11508'},
			    {text: 'Fax', value: '11510'},
			    {text: 'Mobile', value: '11512'},
			    {text: 'Other', value: '11514'}
			]
                    }, {
                        xtype: 'textareafield',
			name: 'note',
                        label: 'Note'
                    }, {
                        xtype: 'hiddenfield',
			name: 'id'
                    }, {
                        xtype: 'hiddenfield',
			name: 'note_status_id',
			value: 11400
                    }, {
                        xtype: 'hiddenfield',
			name: 'object_id',
			label: 'Object ID',
			value: 0		// Magic value: 0 is the ID of the "guest" object
                    }
                ]
            }, {
                xtype: 'button',
                text: 'Save',
                ui: 'confirm',
		itemID: 'noteSaveButton',
		handler: function(button, event) {
		    console.log('NoteListController: Button "Save" pressed');
		    
		    // Save the form values to the record.
		    // The record was set by the NoteNavigationController
		    var noteStore = Ext.data.StoreManager.lookup('NoteStore');
		    var form = button.up('formpanel');
		    var values = form.getValues();
		    var rec = form.getRecord();
		    
		    // Check if we are about to create a new note
		    if (typeof rec === "undefined" || rec == null) {
			// Create a new note and set values
			rec = Ext.ModelManager.create(values, 'PO.model.Note');
			rec.set(values);
		    }
		    rec.save({                // Save the model - generates PUT or POST to REST backend
			success: function(record, operation) {
			    console.log('Successfully updated im_note object');
			    // Retrieve the new server-side Oid (object ID) of the new note and store into the model
			    if (record.get('id') == '') {
				var restResponseText = operation._response.responseText;
				var restResponseObject = Ext.JSON.decode(restResponseText);
				var restOid = '' + restResponseObject.data[0].rest_oid; // new object_id as string
				record.set('id', restOid+'');                      // set the ID of the note_id
				noteStore.add(rec);                                // Add the note to the store.
			    }
			},
			failure: function(record, operation) {
			    Ext.Msg.alert('Failed', operation.request.scope.reader.jsonData["message"], Ext.emptyFn);
			}
		    });
		    
		    // Return to the list of notes page
		    var navView = button.up('noteNavigationView');
		    navView.pop();
		}
		
            }, {
                xtype: 'button',
                text: 'Delete',
                ui: 'decline',
		itemID: 'noteDeleteButton',
		handler: function(button, event) {
		    console.log('NoteListController: Button "Delete" pressed');
		    
		    // Save the form values to the record.
		    // The record was set by the NoteNavigationController
		    var noteStore = Ext.data.StoreManager.lookup('NoteStore');
		    var form = button.up('formpanel');
		    var values = form.getValues();
		    var rec = form.getRecord();
		    
		    // Did we create a completely new note?
		    if (typeof rec === "undefined" || rec == null) {
			return;	            // The record was new - no need to delete then...
		    }
		    
		    noteStore.remove(rec);      // Remove the note from the store
		    rec.erase();                // Generates DELETE call to REST backend
		    
		    // Return to the list of notes page
		    var navView = button.up('noteNavigationView');
		    navView.pop();
		}

            }
        ]
    }
});
