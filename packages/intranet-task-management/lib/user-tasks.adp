<if @object_type_cnt@ gt 0>
<div id=@diagram_id@></div>
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
    'PO.Utilities',
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
    // Main store, defined in-line
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

    // Delete the last two entries (finished & undefined) if there are no references to them
    if (0 == pieArray[5]) { pieStore.removeAt(5); if (0 == pieArray[4]) { pieStore.removeAt(4); } }


    /* ***********************************************************************
     * A pie chart showing a legend and some custom display
     *
     * We "abuse" the pie chart and disable the display of pie segments.
     * We only use the Legend and create the rest of the display
     * using a custom renderer.
     *********************************************************************** */
    var pieChart = Ext.create('Ext.chart.Chart', {
        region: 'center',
        width: '100%',
        animate: true,
        store: pieStore,
        taskStore: taskStore,
        theme: 'TaskStatusTheme:gradients',          // custom theme
	style: { background: 'white' },
        series: [{
            type: 'pie',
            angleField: 'data',
            showInLegend: true,
            label: { field: 'name', display: 'none', contrast: true, font: '8px Arial' },
            renderer: function(sprite, record, attributes, index, store) {
                attributes.hidden = true;
                return attributes;
            }
        }],
        legend: { position: 'float', x: @diagram_width@ - @legend_width@ - 10},

        drawTasks: function() {
            var me = this;
            if (me.debug) console.log('taskListPanel.redraw: Starting');

            var surface = me.surface;
            var surfaceWidth = surface.width;
            var x = 0, y = 0;
            var taskTypeTextWidth = @task_type_text_width@;                                               // where do the task boxes start on X axis?

	    // horizontal space for each task
            var w = Math.floor(10.0 * ((surface.width - taskTypeTextWidth - @legend_width@ - 10)/ @max_tasks@)) / 10.0;

            var h = 20;
            var font = "12px Arial";

            var last_main_project_id = -1;
            var last_type = '';
            var lastY = -1;
            var boxY = 0;

            var nameHeight = <%= $name_height %>;
            var nameOffset = <%= $name_offset %>;
            var typeHeight = <%= $type_height %>;
            var typeOffset = <%= $type_offset %>;

            me.taskStore.each(function(model, idx, maxCount) {
                if (me.debug) console.log('taskListPanel.redraw.each:', model);

                // Draw a new "main" project. The store records are ordered by main project! 
                var main_project_id = model.get('main_project_id');    // integer!
                var main_project_name = model.get('main_project_name');
                if (last_main_project_id != main_project_id) {

                    // Draw the background box for the _last_ user
                    if (lastY >= 0) {
                        var serie = pieChart.series.first();
			var fillColor = serie.getLegendColor(10);
                        me.mixins.taskManagement.drawTaskBackground(surface, fillColor, last_main_project_id, '/intranet/projects/view?project_id=', lastY, y);
                    }

                    // Draw the name of the current user
                    var text = main_project_name;
                    var mainProjectText = surface.add({type: 'text', text: text, x: 0, y: y+nameOffset, font: "bold "+font}).show(true);
		    mainProjectText.project_id = main_project_id;
		    mainProjectText.on({
			click: function(sprite, event, fn) {
			    var pid = this.project_id;                                           // this is the project_id added above
			    var url = '/intranet/projects/view?project_id='+pid;
			    window.open(url);                       // Open project in new browser tab
			}
		    });


                    last_main_project_id = main_project_id;
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
                me.mixins.taskManagement.drawTaskBackground(surface, fillColor, last_main_project_id, '/intranet/projects/view?project_id=', lastY, y);
            }

            if (me.debug) console.log('taskListPanel.redraw: Finished');
        }
    });

    // Add mixin. Didn't work the way described somehow.
    pieChart.mixins.taskManagement = Ext.create('PO.view.task.TaskManagementMixin', {});


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
     * The main panel, with a split pane between the Pie chart and the histogram
     *********************************************************************** */
    Ext.create('widget.panel', {
        title: false,                          // '@diagram_title@',
        width: @diagram_width@,
        height: @diagram_height@,
        renderTo: '@diagram_id@',
        viewBox: true,
        layout: 'border',
        items: [
            pieChart
        ],
        tbar: [
	    { xtype: 'tbtext', text: '<b>@page_title;noquote@</b>'},
            '->',
            { text: 'Help',		icon: gifPath+'help.png',	menu: helpMenu}, 
            { text: 'This is Beta!',	icon: gifPath+'bug.png',	menu: alphaMenu}
        ]

    }).show();

    // Show the tasks in specific display
    pieChart.drawTasks();
    
});
</script>
</if>

