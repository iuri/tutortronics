/*
 * Hour.js
 *
 * Copyright (c) 2011 - 2014 ]project-open[ Business Solutions, S.L.
 * This file may be used under the terms of the GNU General Public 
 * License version 3.0 or alternatively unter the terms of the ]po[ 
 * FL or CL license as specified in www.project-open.com/en/license.
 */

/**
 * Model with fields for im_hour ]po[ business object.
 */
Ext.define('PO.model.Hour', {
    extend: 'Ext.data.Model',
    config: {
	fields: [
	    'id',					// Same as hour_id
	    'hour_id',					// Unique ID taken from im_hours_seq

	    'user_id',					// Who logged the hours?
	    'project_id',				// On which project or task?
	    'day',					// Which day (format: date, not timestamptz)

	    'hours',					// How many hours were logged?
	    'note',					// Comment for the logged hours
	    'internal_note',				// Comment hidden from customers (rarely used)

	    'cost_id',					// Link to cost item created to represent the internal cost of providing hours
	    'invoice_id',				// Invoice where hours have been billed to customer (optional)
	    'conf_object_id',				// Workflow "confirmation object" for timesheet approval (optional)
	    'material_id',				// Type of service provided during hours (rarely used)
	    'days',    					// Hours converted into days for daily invoicing (rarely used)

//          ----------------                            // Special fields that are not part of the ]po[ data-model
	    'day_date'                                  // Used temporarily when entering hours for date conversion

	],
	proxy: {
	    type:		'rest',
	    url:		'/intranet-rest/im_hour',
	    appendId:		true,			// Append the object_id: ../im_ticket/<object_id>
	    timeout:		300000,
	    extraParams: {
		format:		'json'			// Tell the ]po[ REST to return JSON data.
	    },
	    reader: {
		type:		'json',			// Tell the Proxy Reader to parse JSON
		root:		'data',			// Where do the data start in the JSON file?
		totalProperty:  'total'			// Total number of tickets for pagination
	    },
	    writer: {
		type:		'json'			// Allow Sencha to write ticket changes
	    }
	}
    } 
});





/*	    {                                           // Not sure where this is used
		name: 'date',
                convert: function(value, record) {
		    var day = record.get('day');
		    if (!day) { return null; }
		    return day.substring(0,10);
                }
            }
*/
