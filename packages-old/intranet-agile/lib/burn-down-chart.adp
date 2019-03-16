<if @chart_p@ gt 0>
<div id=@diagram_id@></div>

<script type='text/javascript'>
Ext.require(['Ext.chart.*', 'Ext.Window', 'Ext.fx.target.Sprite', 'Ext.layout.container.Fit']);
Ext.onReady(function () {
    
    var burnDownStore = Ext.create('Ext.data.Store', {
	fields: ['day', 'planned', 'done'],
	data : [
<multiple name="burn_down">
<if "" ne @burn_down.done@>
{day: @burn_down.day@, planned: @burn_down.planned@, done: @burn_down.done@},
</if>
<else>
{day: @burn_down.day@, planned: @burn_down.planned@},
</else>
</multiple>
	]
    });

    var burnDownChart = new Ext.chart.Chart({
	animate: false,
	store: burnDownStore,
	legend: { position: 'right' },
	theme: 'Base:gradients',
	axes: [{
            type: 'Numeric',
            minimum: 0,
            position: 'left',
            fields: ['planned', 'done'],
            title: 'Work',
        }, {
            type: 'Numeric',
            position: 'bottom',
            fields: ['day'],
            title: 'Days'
        }],

	series: [
	    {
		type: 'line',
		axis: 'left',
		xField: 'day',
		yField: 'planned',
		title: 'Planned'
	    }, {
		type: 'line',
		axis: 'left',
		xField: 'day',
		yField: 'done',
		title: 'Done'
	    }
	]
    });

    var burnDownPanel = Ext.create('widget.panel', {
        width: @diagram_width@,
        height: @diagram_height@,
        title: '@diagram_title@',
	renderTo: '@diagram_id@',
        layout: 'fit',
	header: false,
        items: burnDownChart
    });

//    var sprite = burnDownChart.surface.add({
//        x: 100, 
//	y: 100, 
//	width: 100,
//	height: 100,
//	radius: 10,
//        type: 'rect',
//        stroke: 'red',
//        'stroke-width': 1
//    }).show(true);
    



});
</script>
</if>
