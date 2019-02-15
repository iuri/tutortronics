/*
 * NoteList.js
 *
 * Copyright (c) 2011 - 2014 ]project-open[ Business Solutions, S.L.
 * This file may be used under the terms of the GNU General Public 
 * License version 3.0 or alternatively unter the terms of the ]po[ 
 * FL or CL license as specified in www.project-open.com/en/license.
 */

/**
 *
 */
Ext.define('PO.view.NoteList', {
    extend: 'Ext.List',
    xtype: 'noteList',
    requires: ['PO.store.NoteStore'],
    
    config: {
	title: 'Note List',
	iconCls: 'star',
	itemTpl: '<div class="contact2">{note}</div>',
	disclosure: true,
	grouped: true,
	indexBar: true,
	store: 'NoteStore',
	onItemDisclosure: true
    }
});

