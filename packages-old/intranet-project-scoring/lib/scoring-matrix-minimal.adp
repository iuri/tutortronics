<master>
<property name="doc(title)">Scoring Matrix</property>
<property name="context">context</property>
<property name="main_navbar_label">projects</property>

<%
    ad_page_contract {
        Simple 2x2 matrix with drag-and-drop.
        Used as a template for other small DnD portlets.

	@project_id A project with a few tasks or sub-projects
    } {
        project_id:integer
        {diagram_width 400}
        {diagram_height 400}
    }

# Load libraries, create a random ID and make sure parameters exist
im_sencha_extjs_load_libraries
set diagram_id "scoring_matrix_[expr {round(rand() * 100000000.0)}]"
if {![info exists diagram_width]} { set diagram_width 400 }
if {![info exists diagram_height]} { set diagram_height 400 }
%>

<div id="@diagram_id@" style="height: @diagram_height@px; width: @diagram_width@px; overflow: hidden; -webkit-user-select: none; -moz-user-select: none; -khtml-user-select: none; -ms-user-select: none; ">

<script type='text/javascript'>
Ext.Loader.setPath('PO', '/sencha-core');
Ext.require([
    'Ext.data.*', 'Ext.grid.*', 'Ext.tree.*',
    'PO.store.project.ProjectMainStore'
]);


/**
 * ------------------------------------------------------------------
 * Drag-and-drop: We will drag a "shadow" along with the mouse
 * that contains the information of the initial sprite being clicked.
 */
Ext.define('dndScatterChartController', {
    extend: 'Ext.app.Controller',
    debug: false,
    store: null,
    chart: null,
    dndSpriteShadow: null,

    /**
     * Connect all event sources with DnD functions.
     * The chart is loaded in multiple stages:
     * <ul>
     * <li>The chart itself is launched with an empty store
     * <li>The store load is initialized.
     * <li>The store has received it's data.
     * <li>transformStore calculates x&y axis values.
     * <li>The chart displays sets up the visual sprites
     * <li>We attach DnD listeners to sprites.
     * <li>Now a MouseDown on a sprite will start DnD.
     * </ul>
     * Drag-and-drop itself is organized in three steps:
     * <ul>
     * <li>MouseDown: Starts the DnD by initializing the "shadow"
     * <li>MouseMove: The mouse drags the shadow along
     * <li>MouseUp: Update values and end the DnD
     * </ul>
     */
    init: function() {
        var me = this;
        if (me.debug) console.log('dndScatterChartController: init: Starting');

	var surface = me.chart.surface;
	surface.on("mousemove", me.onSurfaceMouseMove, me);
	surface.on("mouseup", me.onSurfaceMouseUp, me);
	surface.on("mouseleave", me.onSurfaceMouseLeave, me);

	// calculate X and Y axis after the store has loaded it's data
	me.store.on("load", me.transformStore, me);

	// Add listeners to sprites once all sprites are displayed
	me.chart.on("refresh", function() {
	    var items = surface.items.items;
	    for (var i = 0, ln = items.length; i < ln; i++) {
		var sprite = items[i];
		if (sprite.type != "circle") { continue; }		// only add listeners to circles
		sprite.on("mousedown", me.onSpriteMouseDown, me);
	    }
	}, me);

        if (me.debug) console.log('dndScatterChartController.init: Finished');
    },

    /**
     * Start the DnD gesture by creating a "shadow"
     */
    onSpriteMouseDown: function(sprite, event, eOpts) {
        var me = this;
        if (me.debug) console.log('dndScatterChartController: MouseDown');

        // Create a copy of the sprite configuration "attr"
        var attrs = Ext.clone(sprite.attr);
        delete attrs.fill;
        attrs.type = sprite.type;
        me.dndSpriteShadow = sprite.surface.add(attrs).show(true);	// Create the shadow

        // Add DnD tracking values.
        me.dndSpriteShadow.dndOrgSprite = sprite;			// The sprite being dnd'ed
        me.dndSpriteShadow.dndStartXY = event.getXY();		// Mouse coordinates when dnd
    },

    /**
     * The shadow is being draged around
     */
    onSurfaceMouseMove: function(event, eOpts) {
        var me = this;
        if (me.dndSpriteShadow == null) { return; }

        var xy = event.getXY();					// Current mouse pos
        var startXY = me.dndSpriteShadow.dndStartXY;		// Mouse pos when starting
        me.dndSpriteShadow.setAttributes({				// move the shadow with mouse
	    x: xy[0] - startXY[0],
	    y: xy[1] - startXY[1]
        }, true);
    },

    /**
     * End the DnD gesture and update store and chart
     */
    onSurfaceMouseUp: function(event, eOpts) {
        var me = this;
        if (me.dndSpriteShadow == null) { return; }		// No shadow -> no DnD...
        if (me.debug) console.log('dndScatterChartController: MouseUp');

        // Get the axis of the chart
        var xAxis = me.chart.axes.get('bottom');
        var yAxis = me.chart.axes.get('left');

        // Relative mouse x/y movement of sprite from original position
	// We don't know where exactly the mouse clicked in the sprite...
        var xy = event.getXY();
        var relX = (xy[0] - me.dndSpriteShadow.dndStartXY[0]);
        var relY = (xy[1] - me.dndSpriteShadow.dndStartXY[1]) * -1;

        // Transform x/y to relative scoring value changed using the axes
        var relValueX = relX * (xAxis.to - xAxis.from) / xAxis.length;
        var relValueY = relY * (yAxis.to - yAxis.from) / yAxis.length;

        // Write updated values into server store
        var rec = me.store.getById(""+me.dndSpriteShadow.attr.oid);

        var v = parseFloat(rec.get('score_strategic'));
        if (!v || v < 0) v = 0; if (v > 10.0) v = 10.0;
        v = Math.round((v + relValueY) * 10.0) / 10.0;
        if (!v || v < 0) v = 0; if (v > 10.0) v = 10.0;
        rec.set('y_axis', v);
        rec.set('score_strategic', ""+v);

        var v = parseFloat(rec.get('score_finance_npv'));
        if (!v || v < 0) v = 0; if (v > 10.0) v = 10.0;
        v = Math.round((v + relValueX) * 10.0) / 10.0;
        if (!v || v < 0) v = 0; if (v > 10.0) v = 10.0;
        rec.set('x_axis', v);
        rec.set('score_finance_npv', ""+v);

        // Close the DnD operation
        rec.save();						// Write changes back to server
        me.chart.surface.remove(me.dndSpriteShadow, true);			// Remove shadow from drawing surface
        me.dndSpriteShadow = null;	     				// delete shadow object
    },

    /**
     * Abort the DnD gesture, because the shadow is being draged outside the surface
     */
    onSurfaceMouseLeave: function(event, eOpts) {
        var me = this;
        if (me.dndSpriteShadow == null) { return; }
        if (me.debug) console.log('dndScatterChartController: MouseLeave');
        me.chart.surface.remove(me.dndSpriteShadow, true);
        me.dndSpriteShadow = null;
    },

    /**
     * Convert a store of business objects to a store for a chart.
     * Calculate x_axis, y_axis, radius and color attributes based
     * on object attributes.
     */
    transformStore: function() {
	var me = this;
        if (me.debug) console.log('dndScatterChartController: transformStore: Starting');

	me.store.each(function(rec) {
	    var v = parseFloat(rec.get('score_strategic'));
	    if (!v || v < 0) v = 0; if (v > 10.0) v = 10.0;
	    rec.set('y_axis', v);
	    
	    var v = parseFloat(rec.get('score_finance_npv'));
	    if (!v || v < 0) v = 0; if (v > 10.0) v = 10.0;
	    rec.set('x_axis', v);
	    
	    var v = 3.0 * parseFloat(rec.get('score_finance_cost'));
	    if (!v || v < 3) v = 3; if (v > 10.0) v = 10.0;
	    rec.set('radius', v);
	    
	    rec.set('color', 'green');
	});
        if (me.debug) console.log('dndScatterChartController: transformStore: Finished');
    }

});


Ext.onReady(function() {
    // ProjectStore needs parameters before load
    var projectMainStore = Ext.create('PO.store.project.ProjectMainStore');
   
    var chart = new Ext.chart.Chart({
        width: @diagram_width@,
        height: @diagram_height@,
        title: 'Scoring Matrix',
        renderTo: '@diagram_id@',
        animate: false,
        store: projectMainStore,
        axes: [{
            type: 'Numeric',
            title: 'Strategic',
            position: 'left', 
            fields: ['x_axis'], 
            minimum: 0.0,
            maximum: 10
        }, {
            type: 'Numeric', 
            title: 'NPV',
            position: 'bottom', 
            fields: ['y_axis'],
            minimum: 0,
            maximum: 10
        }],
        series: [{
            type: 'scatter',
            axis: 'left',
            xField: 'x_axis',
            yField: 'y_axis',
            highlight: true,
            markerConfig: { type: 'circle' },
            label: {
                display: 'under',
                field: 'project_name',
                'text-anchor': 'left'
            },

            // Set the properties of the sprite.
            // This is the only way to pass the "model" to the sprite
            renderer: function(sprite, model, attr, index, store) {
                var newAttr = Ext.apply(attr, {
                    radius: model.get('radius'),
                    fill: model.get('color'),
                    oid: model.get('id'),
		    model: model				// attach model to sprite, not used yet
                });
                return newAttr;
            }
        }]
    });


    var dndController = Ext.create('dndScatterChartController', {
	debug: true,
	store: projectMainStore,
	chart: chart
    }).init();

    projectMainStore.getProxy().extraParams = { 
        format: "json",
        query: "parent_id = @project_id@ and project_status_id in (76)"
    };
    projectMainStore.load();

});
</script>
</div>
