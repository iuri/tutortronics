/*
 * Note.js
 *
 * Copyright (c) 2011 - 2014 ]project-open[ Business Solutions, S.L.
 * This file may be used under the terms of the GNU General Public 
 * License version 3.0 or alternatively unter the terms of the ]po[ 
 * FL or CL license as specified in www.project-open.com/en/license.
 */

/**
 *
 */
Ext.define('PO.model.Note', {
    extend: 'Ext.data.Model',
    config: {
	fields: [
		'id',
		'note',
		'object_id',
		'note_status_id',
		'note_type_id'
	],
	proxy: {
		type:		'rest',
		url:		'/intranet-rest/im_note',
		appendId:	true,			// Append the object_id: ../im_ticket/<object_id>
		timeout:	300000,

		extraParams: {
			format:		'json',		// Tell the ]po[ REST to return JSON data.
			deref_p:	'1',
			columns:	'note,note_type_id'
		},
		reader: {
			type:	'json',			// Tell the Proxy Reader to parse JSON
			root:	'data',			// Where do the data start in the JSON file?
			totalProperty:  'total'		// Total number of tickets for pagination
		},
		writer: {
			type:	'json'			// Allow Sencha to write ticket changes
		}
	    }
    }

});

