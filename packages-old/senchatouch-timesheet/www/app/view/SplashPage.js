/*
 * SplashPage.js
 *
 * Copyright (c) 2011 - 2014 ]project-open[ Business Solutions, S.L.
 * This file may be used under the terms of the GNU General Public 
 * License version 3.0 or alternatively unter the terms of the ]po[ 
 * FL or CL license as specified in www.project-open.com/en/license.
 */

/**
 *
 */
Ext.define('PO.view.SplashPage', {
	extend: 'Ext.Panel',
	xtype: 'splashPage',
	config: {
		title: 'Home',
		iconCls: 'home',
		scrollable: 'vertical',
		//	    styleHtmlContent: true,
		html: [
			'<br>&nbsp;<br>&nbsp;<br>',
			'<center>',
			'<img src="/senchatouch-timesheet/resources/startup/project_open.250x91.gif"/>',
			'<br>&nbsp;<br>',
			'<h1>]po[ Sencha Touch Timesheet</h1>',
			'<br>&nbsp;<br>',
			'</center>',
		].join("")
	}
});



