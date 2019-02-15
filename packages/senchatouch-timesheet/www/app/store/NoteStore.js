/*
 * NoteStore.js 
 *
 * Copyright (c) 2011 - 2014 ]project-open[ Business Solutions, S.L.
 * This file may be used under the terms of the GNU General Public 
 * License version 3.0 or alternatively unter the terms of the ]po[ 
 * FL or CL license as specified in www.project-open.com/en/license.
 *
 */

/**
 *
 */
Ext.define('PO.store.NoteStore', {
        extend: 'Ext.data.Store',
	storeId: 'noteStore',
	config: {
	    model: 'PO.model.Note',
	    autoLoad: true,

	    grouper: {
		groupFn: function(record) { 
		    var fn = record.get('note');
		    if (fn == null) { fn = 'a'; }
		    return fn.toLowerCase()[0]; 
		}
	    },

	    sorters: [{
		property: 'note',
		direction: 'ASC'
	    }],

	    proxy: {
			type: 'rest',
                	url: '/intranet-rest/im_note',
                	appendId: true,
                	extraParams: {
                        	format: 'json'
                	},
                	reader: { 
				type: 'json', 
				rootProperty: 'data' 
			}
            }

	}
});

