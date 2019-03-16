@error_html;noquote@
<if @show_diagram_p@ gt 0>
<div id="@diagram_id@" style="height: @diagram_height@px; width: @diagram_width@px"></div>
<script type='text/javascript'>
Ext.require(['Ext.chart.*', 'Ext.Window', 'Ext.fx.target.Sprite', 'Ext.layout.container.Fit']);
Ext.onReady(function () {
    
    projectEvaStore = Ext.create('Ext.data.Store', {
	fields: [@fields_json;noquote@],
	data: @data_json;noquote@
    });
    
    projectEvaChart = new Ext.chart.Chart({
	store: projectEvaStore,
	legend: { position: 'float', x:40 },
	theme: 'Base:gradients',
	axes: [{
	    type: 'Numeric',
	    position: 'left',
	    minimum: 0,
	    fields: ['planned_hours', 'logged_hours', 'completed_hours']
	}, {
	    type: 'Time',
	    position: 'bottom',
	    fields: ['date'],
	    dateFormat: 'j M y',
	    label: {rotate: { degrees: 315}},
	    step: [@step_uom@, @step_units@]
	}],
	series: [
	    { title: '@work_planned_l10n;noquote@', type: 'line', axis: 'left', xField: 'date', yField: 'planned_hours'},
	    { title: '@work_done_l10n;noquote@', type: 'line', axis: 'left', xField: 'date', yField: 'completed_hours'},
	    { title: '@work_logged_l10n;noquote@', type: 'line', axis: 'left', xField: 'date', yField: 'logged_hours'}
	]
    });
    
    var projectEvaPanel = Ext.create('widget.panel', {
	width: @diagram_width@,
	height: @diagram_height@,
	title: 'Test',
	renderTo: '@diagram_id@',
	layout: 'fit',
	header: false,
/*
	tbar: [{
	    xtype: 'combo',
	    editable: false,
	    store: false,
	    mode: 'local',
	    displayField: 'display',
	    valueField: 'value',
	    triggerAction: 'all',
	    width: 150,
	    forceSelection: true,
	    value: 'all_time',
	    listeners:{select:{fn:function(combo, comboValues) {
		var value = comboValues[0].data.value;
		var extraParams = projectEvaStore.getProxy().extraParams;
		extraParams.diagram_interval = value;
		projectEvaStore.load();
	    }
			      }
		      }
	}],
*/
	items: projectEvaChart
    });
});
</script>
</if>
