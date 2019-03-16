/*
 * HourStore.js
 *
 * Copyright (c) 2011 - 2014 ]project-open[ Business Solutions, S.L.
 * This file may be used under the terms of the GNU General Public 
 * License version 3.0 or alternatively unter the terms of the ]po[ 
 * FL or CL license as specified in www.project-open.com/en/license.
 */

/*
 * General/temporary store for hours retreived from the server.
 * Used by TimesheetTaskListController to retreive single hours
 * per task, user and day.
 * The store is designed to be scripted and filtered by a controller. 
 */
Ext.define('PO.store.HourStore', {
    extend: 'Ext.data.Store',
    storeId: 'hourStore',
    config: {
	model: 'PO.model.Hour',
	autoLoad: false,
	sorters: [{
            property: 'date',
            direction: 'ASC'
        }],
        grouper: {
            groupFn: function(record) {
                return record.get('date');
            }
        },
	proxy: {
	    type: 'rest',
	    url: '/intranet-rest/im_hour',
	    appendId: true,
	    extraParams: {
		format: 'json',
		user_id: '0',           // to be specified when loading
		project_id: '0'         // to be specified when loading
	    },
	    reader: {
		type: 'json', 
		rootProperty: 'data' 
	    }
	}
    }
});

