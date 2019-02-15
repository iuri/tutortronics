/*
 * NoteNavigationController.js
 *
 * Copyright (c) 2011 - 2014 ]project-open[ Business Solutions, S.L.
 * This file may be used under the terms of the GNU General Public 
 * License version 3.0 or alternatively unter the terms of the ]po[ 
 * FL or CL license as specified in www.project-open.com/en/license.
 */

/**
 * Main controller for the note sub-application
 */
Ext.define('PO.controller.NoteNavigationController', {
    extend: 'Ext.app.Controller',
    xtype: 'noteNavigationController',
    config: {
	refs: {
	    noteNavigationView: 'noteNavigationView'
	},
	control: {
	    'noteNavigationView': { initialize:	'onInitializeNavigationView' },
	    'noteList': { disclose: 'onNoteListDisclose' }
	}
    },

    // Initialization of the Container - add a button
    // The NavigationView itself doesn't seem to allow for this type of customization
    onInitializeNavigationView: function(navView) {
	var navBar = Ext.ComponentQuery.query('noteNavigationView')[0].getNavigationBar();
	navBar.add({
	    xtype: 'button',
	    text: 'New Note',
	    align: 'right',
	    handler: function() {
		console.log('NoteListController: New Note button pressed');
		navView.push({
		    xtype: 'noteForm',
		    title: 'New Note'
		});
	    }
	});
    },

    // "Disclose" Event - somebody pressed on the -> button at the list
    // Create a new instance of the noteForm page and push on the top
    // of the stack
    onNoteListDisclose: function(list, record) { 
	var navigationView = this.getNoteNavigationView();
	navigationView.push({
	    xtype: 'noteForm',
	    record: record
	});
    }
});

