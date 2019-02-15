<if @object_type_cnt@ gt 0>
<div id="@diagram_id@" style="height: @diagram_height@px; width: @diagram_width@px"></div>
<script type='text/javascript'>

Ext.Loader.setPath('PO', '/sencha-core');
Ext.Loader.setPath('GanttEditor', '/intranet-gantt-editor');
Ext.require([
    'Ext.chart.*',
    'Ext.chart.theme.Base',
    'Ext.data.*',
    'Ext.grid.*',
    'Ext.tree.*',
    'Ext.Window', 
    'Ext.fx.target.Sprite', 
    'Ext.layout.container.Fit',
    'PO.view.menu.AlphaMenu',
    'PO.view.menu.HelpMenu',
    'PO.view.theme.TaskStatusTheme',
    'PO.view.task.TaskManagementMixin',
]);

Ext.onReady(function () {

    var debug = 1;
    var gifPath = "/intranet/images/navbar_default/";

    /* ***********************************************************************
     * Define the data to be shown
     *********************************************************************** */
    // Main store, defined in-line. Move user_id=0 to end of store
    var taskStore = @store_json;noquote@

    // Calculate derived store for pie chart with aggregated values
    var pieArray = [0,0,0,0,0,0,0];
    taskStore.each(function(row) {
        var colorCode = row.get('color_code');
        pieArray[colorCode] = pieArray[colorCode] + 1;
    });

    var pieStore = Ext.create('Ext.data.JsonStore', {
        fields: ['name', 'data'],
        data: [
            { 'name': 'Not started yet',  'data':  pieArray[0] },
            { 'name': 'In process (OK)',  'data':  pieArray[1] },
            { 'name': 'In process (late)',  'data':  pieArray[2] },
            { 'name': 'Late',  'data':  pieArray[3] },
            { 'name': 'Finished',  'data':  pieArray[4] },
            { 'name': 'Undefined',  'data':  pieArray[5]}
        ]
    });

    // Delete the last two entries (finished and undefined)
    // if there are no references to them
    if (0 == pieArray[5]) { 
        pieStore.removeAt(5);
        if (0 == pieArray[4]) { 
            pieStore.removeAt(4); 
        }
    }

    /* ***********************************************************************
     * A pie chart showing summary information and a legend
     *********************************************************************** */
    var pieChart = Ext.create('Ext.chart.Chart', {
        region: 'east',
        width: '40%',
        animate: true,
        store: pieStore,
        theme: 'TaskStatusTheme:gradients',          // custom theme
	style: { background: 'white' },
	insetPadding: 22,                            // fixes an issue that highlighted segments get cut off
        series: [{
            type: 'pie',
	    donut: 60,
            angleField: 'data',
            showInLegend: true,
            tips: {
                trackMouse: true,
                width: 140,
                height: 28,
                renderer: function(storeItem, item) {
                    var total = 0;
                    storeItem.store.each(function(rec) { total += rec.get('data'); });
                    this.setTitle(storeItem.get('name') + ': ' + Math.round(storeItem.get('data') / total * 100) + '%');
                }
            },
            highlight: { segment: { margin: 20 }},
            label: { field: 'name', display: 'none', contrast: true, font: '10px Arial' }
        }],
        legend: { 
	    position: 'float', 
	    x: 70
	}
    });



    /* ***********************************************************************
     * Help + Alpha Menu
     * Small menus showing open issues + help
     *********************************************************************** */
    var alphaMenu = Ext.create('PO.view.menu.AlphaMenu', {alphaComponent: 'User Task Portlet', slaId: 1785912}); // Bug tracker ID
    var helpMenu = Ext.create('Ext.menu.Menu', {
        items: [
	    {
		text: 'Task Management General Help',
		href: 'http://www.project-open.net/en/package-intranet-task-management',
		hrefTarget: '_blank'
            }, {
		text: 'Task Status Help',
		href: 'http://www.project-open.net/en/package-intranet-task-management#task_status',
		hrefTarget: '_blank'
            }
	]
    });

    
    /* ***********************************************************************
     * The component showing assigned tasks per project
     *********************************************************************** */

    var taskListPanel = new Ext.draw.Component({
        region: 'west',
        width: '60%',
        store: taskStore,
        debug: debug,
	style: { background: 'white' },

        redraw: function() {
            var me = this;
            if (me.debug) console.log('taskListPanel.redraw: Starting');

            var surface = me.surface;
            var surfaceWidth = surface.width;
            var x = 0, y = 0;
            var taskTypeTextWidth = @task_type_text_width@;
	    // horizontal space for each task
	    var w = Math.floor(10.0 * ((surface.width - taskTypeTextWidth - 10)/ @max_tasks@)) / 10.0;
            var h = 20;
            var font = "12px Arial";

            var last_user_id = -1;
            var last_type = '';
            var lastY = -1;
            var boxY = 0;

            var nameHeight = <%= $name_height %>;
            var nameOffset = <%= $name_offset %>;
            var typeHeight = <%= $type_height %>;
            var typeOffset = <%= $type_offset %>;

            me.store.each(function(model, idx, maxCount) {
                if (me.debug) console.log('taskListPanel.redraw.each:', model);

                // Draw a new "main" project. The store records are ordered by main project! 
                var user_id = model.get('user_id');                                // integer!
                var user_name = model.get('user_name');
                if (last_user_id != user_id) {

                    // Draw the background box for the _last_ user
                    if (lastY >= 0) {
                        var serie = pieChart.series.first();
			var fillColor = serie.getLegendColor(10);
                        me.mixins.taskManagement.drawTaskBackground(surface, fillColor, last_user_id, '/intranet/users/view?user_id=', lastY, y);
                    }

                    // Draw the name of the current user
                    if (0 == user_id) { user_name = 'unassigned'; }
                    var text = user_name;
		    var color = "black";
		    if ("1" == model.get('deleted_p')) { color = "red"; }
                    var mainProjectText = surface.add({
			type: 'text', 
			text: text, 
			x: 0, 
			y: y+nameOffset, 
			font: "bold "+font,
			fill: color
		    }).show(true);
		    mainProjectText.uid = user_id;
		    mainProjectText.on({
			click: function(sprite, event, fn) {
			    var url = '/intranet/users/view?user_id='+this.uid;
			    window.open(url);                       // Open project in new browser tab
			}
		    });

                    last_user_id = user_id;
                    last_type = "";
                    lastY = y;

                    y = y + nameHeight;
                    x = 0;
                }

                // Add a title for a type of task
                var type = model.get('type').replace("Ticket", "");   // "Generic Problem Ticket" => "Generic Problem"
                if (last_type != type) {
                    var objectTypeText = surface.add({type: 'text', text: type, x: 0, y: y+typeOffset, font: font}).show(true);
                    boxY = y;                                         // Save the current Y for drawing the task boxes
                    y = y + typeHeight;
                    x = taskTypeTextWidth;
                    last_type = type;
                }
                
                // Draw a box for each task of a certain type
                var serie = pieChart.series.first();
		var colorCode = model.get('color_code');
                var fillColor = serie.getLegendColor(colorCode);
		me.mixins.taskManagement.drawTaskBox(surface, fillColor, model, x, boxY-h/4, w, h);
                x = x + w;
            });

            // Draw the background box for the _last_ user
            if (lastY >= 0) {
                var serie = pieChart.series.first();
		var fillColor = serie.getLegendColor(10);
                me.mixins.taskManagement.drawTaskBackground(surface, fillColor, last_user_id, '/intranet/users/view?user_id=', lastY, y);
            }

            if (me.debug) console.log('taskListPanel.redraw: Finished');
        }
    });

    // Add mixin. Didn't work the way described somehow.
    taskListPanel.mixins.taskManagement = Ext.create('PO.view.task.TaskManagementMixin', {});

    /* ***********************************************************************
     * The main panel, with a split pane between the Pie chart and the histogram
     *********************************************************************** */
    Ext.create('widget.panel', {
        title: false,                         // '@diagram_title@',
        width: @diagram_width@,
        height: @diagram_height@,
        renderTo: '@diagram_id@',
        viewBox: true,
        layout: 'border',
        items: [
            taskListPanel,
            pieChart
        ],
        tbar: [
	    { xtype: 'tbtext', text: '<b>@page_title@</b>'},
            '->',
            { text: 'Help',		icon: gifPath+'help.png',	menu: helpMenu}, 
            { text: 'This is Beta!',	icon: gifPath+'bug.png',	menu: alphaMenu}
        ]

    }).show();

    taskListPanel.redraw();
    
});
</script>
</if>

