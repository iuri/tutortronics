<if "1" eq @show_master_p@>
<master>
<property name="doc(title)">Scoring Matrix</property>
<property name="context">context</property>
<property name="main_navbar_label">projects</property>
</if>
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
    debug: true,
    store: null,					// To be filled during init
    chart: null,					// To be filled during init
    config: null,					// To be filled during init

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

	var div = Ext.get('@diagram_id@');
	// div.on("mousemove", me.onSurfaceMouseLeave, me);

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
     * Convert a store of business objects to a store for a chart.
     * Calculate x_axis, y_axis, radius and color attributes based
     * on object attributes.
     */
    transformStore: function() {
	var me = this;
        if (me.debug) console.log('dndScatterChartController: transformStore: Starting');
	me.store.each(function(rec) {	    
	    for (var dim in me.config) {
		var configFns = me.config[dim];
		if (!configFns) alert("dndScatterChartController.transformStore: Did not find dynField config for '"+dim+"'");
		var fn = configFns.get("convert");
		var v = fn.apply(me, [rec]);

                // Special treatment for radius and color
		switch (dim) {
		case "radius":
		    if (!v || v < 3.0) v = 3.0;
		    v = 3.0 * v;
		    break;
		case "color":
		    if (v === parseFloat(v)) {
			// We've found an integer that we need to convert into a color
			var b = [0, 255, 0];
			var a = [0, 0, 255];

			var mix = [];
			mix[0] = Math.round((a[0]*v + b[0]*(10-v)) / 10.0); // red
			mix[1] = Math.round((a[1]*v + b[1]*(10-v)) / 10.0); // red
			mix[2] = Math.round((a[2]*v + b[2]*(10-v)) / 10.0); // red

			v = "#" + me.componentToHex(mix[0]) + me.componentToHex(mix[1]) + me.componentToHex(mix[2]);
		    }
		    break;
		}

		rec.set(""+dim, v);
	    }
	});
        if (me.debug) console.log('dndScatterChartController: transformStore: Finished');
    },

    componentToHex: function(c) {
	var hex = c.toString(16);
	return hex.length == 1 ? "0" + hex : hex;
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

        // Transform x/y to relative value changed based on axis config
        var relValueX = relX * (xAxis.to - xAxis.from) / xAxis.length;
        var relValueY = relY * (yAxis.to - yAxis.from) / yAxis.length;

        // Write updated values into server store
        var rec = me.store.getById(""+me.dndSpriteShadow.attr.oid);
	var relVal = {x_axis: relValueX, y_axis: relValueY};
	for (dim in relVal) {

	    var configFns = me.config[dim];
	    if (!configFns) alert("dndScatterChartController.transformStore: Did not find dynField config for '"+dim+"'");
	    var convertFn = configFns.get("convert");
	    var v = convertFn.apply(me, [rec]);
	    v = v + relVal[dim];
	    rec.set(""+dim, v);

	    // Now write back into record
	    var updateFn = configFns.get("update");
	    if (!!updateFn) updateFn.apply(me, [rec,v]);
	};

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

    setConfig(dim, dynFieldModel) { 
	var me = this; 
	me.config[dim] = dynFieldModel;
    }

});


Ext.define('comboController', {
    extend: 'Ext.app.Controller',
    debug: true,
    chart: null,
    dndController: null,
    dynFieldStore: null,

    refs: [
        { ref: 'xCombo', selector: '#combo_x_axis' },
        { ref: 'yCombo', selector: '#combo_y_axis' },
        { ref: 'radiusCombo', selector: '#combo_radius' },
        { ref: 'colorCombo', selector: '#combo_color' }
    ],

    init: function() {
        var me = this;
        if (me.debug) console.log('comboController.init:');
	
	this.getXCombo().on("select", me.comboSelect, me);
	this.getYCombo().on("select", me.comboSelect, me);
	this.getRadiusCombo().on("select", me.comboSelect, me);
	this.getColorCombo().on("select", me.comboSelect, me);

        if (me.debug) console.log('comboController.init:');
    },

    /**
     * One of our combos has changed
     */
    comboSelect: function(combo, comboValues, eOpts) {
	var me = this;
        if (me.debug) console.log('comboController.comboSelect:');

	// Get the DynField configuration
	var dim = combo.id.substring(6);                // cut off the first 6 chars from ID
	var value = comboValues[0].data.value;
	var dynFieldModel = me.dynFieldStore.findRecord("value", value);
	if (!dynFieldModel) return;

        // Update the axis of the chart
        var yAxis = me.chart.axes.get('left');
	switch (dim) {
	case "x_axis": 
            var xAxis = me.chart.axes.get('bottom');
	    var display = dynFieldModel.get("display");
	    xAxis.setTitle(display);
	    break;
	case "y_axis": 
            var xAxis = me.chart.axes.get('left');
	    var display = dynFieldModel.get("display");
	    yAxis.setTitle(display);
	    break;
	}

	// Update the controller and update the x/y store values
	me.dndController.setConfig(dim, dynFieldModel);
	me.dndController.transformStore();
    }
});




Ext.onReady(function() {
    // ProjectStore needs parameters before load
    var projectMainStore = Ext.create('PO.store.project.ProjectMainStore');
   
    var chart = new Ext.chart.Chart({
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


    var dynFieldStore = Ext.create('Ext.data.Store', {
	fields: ['display', 'value', 'convert', 'update'],
	data : [{
	    value: "score_strategic", 
	    display: "@strategic_l10n@", 
	    convert: function(model) { 
		var str = model.get("score_strategic");
		var v = parseFloat(str); 
		if (!v || v < 0) v = 0; if (v > 10.0) v = 10.0;
		return Math.round(v * 10.0) / 10.0;
	    },
	    update: function(model, v) { 
		if (!v || v < 0) v = 0; if (v > 10.0) v = 10.0;
		v = Math.round(v * 10.0) / 10.0;
		model.set("score_strategic", ""+v);
	    }
	}, {
	    value: "score_finance_npv",
	    display: "@npv_l10n@", 
	    convert: function(model) { 
		var str = model.get("score_finance_npv");
		var v = parseFloat(str); 
		if (!v || v < 0) v = 0; if (v > 10.0) v = 10.0;
		return Math.round(v * 10.0) / 10.0;
	    },
	    update: function(model, v) { 
		if (!v || v < 0) v = 0; if (v > 10.0) v = 10.0;
		v = Math.round(v * 10.0) / 10.0;
		model.set("score_finance_npv", ""+v);
	    }
	}, {
	    value: "score_customers",
	    display: "@customer_l10n@", 
	    convert: function(model) { 
		var str = model.get("score_customers");
		var v = parseFloat(str);
		if (!v || v < 0) v = 0; if (v > 10.0) v = 10.0;
		return Math.round(v * 10.0) / 10.0;
	    },
	    update: function(model, v) { 
		if (!v || v < 0) v = 0; if (v > 10.0) v = 10.0;
		v = Math.round(v * 10.0) / 10.0;
		model.set("score_customers", ""+v);
	    }
	}, {
	    value: "score_finance_cost",
	    display: "@cost_l10n@", 
	    convert: function(model) { 
		var str = model.get("score_finance_cost");
		var v = parseFloat(str);
		if (!v || v < 0) v = 0; if (v > 10.0) v = 10.0;
		return Math.round(v * 10.0) / 10.0;
	    },
	    update: function(model, v) { 
		if (!v || v < 0) v = 0; if (v > 10.0) v = 10.0;
		v = Math.round(v * 10.0) / 10.0;
		model.set("score_finance_cost", ""+v);
	    }
	}]
    });

    // Main panel with selection
    Ext.create('widget.panel', {
	width: @diagram_width@,
	height: @diagram_height@,
	title: '@diagram_caption@',
        renderTo: '@diagram_id@',
	layout: 'fit',
	header: false,
	tbar: [{
	    xtype: 'combo',
	    id: "combo_x_axis",
	    fieldLabel: "X-Axis",
	    labelWidth: 35,
	    width: 80 + 35,
	    editable: false,
	    queryMode: 'local',
	    mode: 'local',
	    store: dynFieldStore,
	    autoSelect: false,
	    displayField: 'display',
	    valueField: 'value',
	    value: "score_finance_npv"
	}, { 
	    xtype: 'tbspacer', width: 5
	}, {
	    xtype: 'combo',
	    id: "combo_y_axis",
	    fieldLabel: "Y-Axis",
	    labelWidth: 35,
	    width: 80 + 35,
	    editable: false,
	    queryMode: 'local',
	    mode: 'local',
	    store: dynFieldStore,
	    autoSelect: false,
	    displayField: 'display',
	    valueField: 'value',
	    value: "score_strategic"
	}, { 
	    xtype: 'tbspacer', width: 5
	}, {
	    xtype: 'combo',
	    id: "combo_radius",
	    fieldLabel: "Radius",
	    labelWidth: 50,
	    width: 80 + 50,
	    editable: false,
	    queryMode: 'local',
	    mode: 'local',
	    store: dynFieldStore,
	    autoSelect: false,
	    displayField: 'display',
	    valueField: 'value',
	    value: "score_finance_cost"
	}, { 
	    xtype: 'tbspacer', width: 5
	}, {
	    xtype: 'combo',
	    id: "combo_color",
	    fieldLabel: "Color",
	    labelWidth: 30,
	    width: 80 + 30,
	    editable: false,
	    queryMode: 'local',
	    mode: 'local',
	    store: dynFieldStore,
	    autoSelect: false,
	    displayField: 'display',
	    valueField: 'value',
	    value: "score_customers"
	}],
	items: chart
    });
    
    // Handles drag-and-drop of chart sprites.
    // "config" handles the mapping of BizObject values into x_axis/
    // y_axis and writing values back into the BizObject model.
    var dndController = Ext.create('dndScatterChartController', {
	debug: false,
	store: projectMainStore,
	chart: chart,
	config: {
	    x_axis: dynFieldStore.findRecord("value", "score_finance_npv"),
	    y_axis: dynFieldStore.findRecord("value", "score_strategic"),
	    radius: dynFieldStore.findRecord("value", "score_finance_cost"),
	    color:  dynFieldStore.findRecord("value", "score_customers")
	}
    });
    dndController.init();

    // Handles select events from the axis combo boxes
    var comboController = Ext.create('comboController', {
	debug: false,
	chart: chart,
	dynFieldStore: dynFieldStore,
	dndController: dndController
    }).init();


    // Now issue the store load.
    // Once loaded, the store will become transformed into x_axis/y_axis
    // values, the chart will be displayed, and the sprites will get DnD
    // mouse events.
    projectMainStore.getProxy().extraParams = { 
        format: "json",
        query: "parent_id = @project_id@ and project_status_id in (76)"
    };
    projectMainStore.load();

});
</script>
</div>
