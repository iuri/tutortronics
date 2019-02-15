
<div id="@diagram_id@" style="height: @diagram_height@px; width: @diagram_width@px; overflow: hidden; -webkit-user-select: none; -moz-user-select: none; -khtml-user-select: none; -ms-user-select: none; "></div>
<script type='text/javascript'>

// Ext.Loader.setConfig({enabled: true});
Ext.Loader.setPath('Ext.ux', '/sencha-v411/examples/ux');
Ext.Loader.setPath('PO.model', '/sencha-core/model');
Ext.Loader.setPath('PO.store', '/sencha-core/store');
Ext.Loader.setPath('PO.class', '/sencha-core/class');
Ext.Loader.setPath('PO.view.gantt', '/sencha-core/view/gantt');
Ext.Loader.setPath('PO.controller', '/sencha-core/controller');

Ext.require([
    'Ext.data.*',
    'Ext.grid.*',
    'Ext.tree.*',
    'PO.store.CategoryStore',
    'PO.store.user.UserStore',
    'PO.store.project.ProjectMainStore'
]);

function launchScoringMatrix(){

    // Define which fields to use for which display dimension
    var dimensions = {
	x_axis: "score_finance_npv",
	y_axis: "score_strategic",
	radius: "score_finance_cost",
	color: "ticket_prio_id"
    };

    var prioColors = ['red','red','red','red','yellow','yellow','yellow','green','green','green'];

    var ticketStore = Ext.StoreManager.get('ticketStore');
    ticketStore.on("load", function() {
	ticketStore.each(function(rec) {
	    var v = parseFloat(rec.get('score_strategic'));
	    if (!v || v < 0) v = 0; if (v > 10.0) v = 10.0;
	    rec.set('y_axis', v);
	    
	    var v = parseFloat(rec.get('score_finance_npv'));
	    if (!v || v < 0) v = 0; if (v > 10.0) v = 10.0;
	    rec.set('x_axis', v);
	    
	    var v = 3.0 * parseFloat(rec.get('score_finance_cost'));
	    if (!v || v < 3) v = 3; if (v > 10.0) v = 10.0;
	    rec.set('radius', v);

	    // Ticket Priority ID
	    var v = parseFloat(rec.get('ticket_prio_id'));
	    if (!v) v = 30205;                           // Prio 5
	    v = v - 30200;                               // v=1..9
	    if (v > 9) v = 9;
	    if (v < 1) v = 1;
	    var color = prioColors[v];
	    rec.set('color', color);

	})}
    );

    var dynFieldStore = Ext.create('Ext.data.Store', {
	fields: ['display', 'value'],
	data : [
            {"display":"@priority_l10n@", "value":"ticket_prio_id"},
            {"display":"@strategic_l10n@", "value":"score_strategic"},
            {"display":"@npv_l10n@", "value":"score_finance_npv"},
            {"display":"@customer_l10n@", "value":"score_customers"}
	]
    });

    var chart = new Ext.chart.Chart({
        animate: false,
        store: ticketStore,
        axes: [{
            type: 'Numeric',
            title: 'Strategic',
            position: 'left', 
            fields: ['x_axis'], 
            grid: true,
            minimum: 0.0,
            maximum: 10.0
        }, {
            type: 'Numeric', 
            title: 'NPV',
            position: 'bottom', 
            fields: ['y_axis'],
            minimum: 0,
            maximum: 10.0,
            label: {
                renderer: function(v){
                    if (v > 1000000) { return Math.round(v / 1000000.0)+"M"; }
                    if (v > 1000) { return Math.round(v / 1000.0)+"K"; }
                    return v
                }
            }
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

            renderer: function(sprite, record, attr, index, store) {
                var newAttr = Ext.apply(attr, {
                    radius: record.get('radius'),
                    fill: record.get('color'), // 'green',
                    oid: record.get('id')
                });
                return newAttr;
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
        tbar: [ {
            xtype: 'combo',
            editable: false,
            queryMode: 'local',
            mode: 'local',
            store: ticketStore,
            autoSelect: false,
            displayField: 'user_name',
            valueField: 'user_id',
            width: 150,
            value: "",
            listeners:{select:{fn:function(combo, comboValues) {
                var value = comboValues[0].data.user_id;
                var extraParams = projectMainStore.getProxy().extraParams;
                delete extraParams.project_lead_id;
                
                if ("" != value) {
                    chartStore.clearFilter();
                    chartStore.filter('project_lead_id', ""+value);
                } else {
                    chartStore.clearFilter();
                }
                chart.redraw(false);
            }}}
        }],
        items: chart
    });


    
    // Drag - and - Drop variables: The DnD start position and the shape to move
    var dndSpriteShadow = null;

    // Start the DnD gesture by creating a "shadow"
    var onSpriteMouseDown = function(sprite, event, eOpts) {
        // Create a copy of the sprite configuration "attr"
        var attrs = Ext.clone(sprite.attr);
        delete attrs.fill;
        attrs.type = sprite.type;
        attrs.stroke = 'blue';
        attrs['stroke-opacity'] = 1.0;

        // Create the shadow and add DnD tracking values
        dndSpriteShadow = sprite.surface.add(attrs).show(true);
        dndSpriteShadow.dndOrgSprite = sprite;
        dndSpriteShadow.dndStartXY = event.getXY();
    };

    // The shadow is being draged around
    var onSurfaceMouseMove = function(event, eOpts) {
        if (dndSpriteShadow == null) { return; }
        var xy = event.getXY();
        var startXY = dndSpriteShadow.dndStartXY;
        dndSpriteShadow.setAttributes({
            x: xy[0] - startXY[0],
            y: xy[1] - startXY[1]
        }, true);
    };

    // End the DnD and update store & chart
    var onSurfaceMouseUp = function(event, eOpts) {
        if (dndSpriteShadow == null) { return; }
        var surface = chart.surface;
        var xy = event.getXY();

        // Get the axis of the chart
        var xAxis = chart.axes.get('bottom');
        var yAxis = chart.axes.get('left');

        // Relative movement of sprite from original position
        var relX = xy[0] - dndSpriteShadow.dndStartXY[0];
        var relY = xy[1] - dndSpriteShadow.dndStartXY[1];
        relY = -relY;

        // Relative value changed for sprite values
        var relValueX = relX * (xAxis.to - xAxis.from) / xAxis.length;
        var relValueY = relY * (yAxis.to - yAxis.from) / yAxis.length;
        // console.log("onSurfaceMouseUp: pid="+oid+", relXY=("+relX+","+relY+"), val=("+relValueX+","+relValueY+")");

        // Write updated values into server store
        var oid = dndSpriteShadow.attr.oid;
        var rec = ticketStore.getById(""+oid);

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
        rec.save();	// Write changes to server
        this.remove(dndSpriteShadow, true);
        dndSpriteShadow = null;
        dndStart = null;
    };


    // The shadow is being draged outside the surface
    var onSurfaceMouseLeave = function(event, eOpts) {
        if (dndSpriteShadow == null) { return; }

        // Close the DnD operation
        this.remove(dndSpriteShadow, true);
        dndSpriteShadow = null;
        dndStart = null;

    };


    // Add drag-and-drop listeners to the sprites
    var surface = chart.surface;
    var items = surface.items.items;
    for (var i = 0, ln = items.length; i < ln; i++) {
        var sprite = items[i];
        if (sprite.type != "circle") { continue; } // only add listeners to circles
        sprite.on("mousedown", onSpriteMouseDown, sprite);
    }
    surface.on("mousemove", onSurfaceMouseMove, surface);
    surface.on("mouseup", onSurfaceMouseUp, surface);
    surface.on("mouseleave", onSurfaceMouseLeave, surface);

};

Ext.onReady(function() {
    Ext.QuickTips.init();

    var ticketStore = Ext.create('PO.store.helpdesk.TicketStore');
    ticketStore.getProxy().extraParams = { 
        format: "json",
	// Load tickets "below" the parent project in status "open"
        query: "parent_id = @project_id@ and project_status_id in (76)"
    };
    ticketStore.load();

    // Proceed to launch chart, without waiting for the store
    launchScoringMatrix();
});
</script>
</div>
