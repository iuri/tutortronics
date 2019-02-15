<div id=diagram_12345></div>
<script type='text/javascript'>

Ext.require(['Ext.chart.*', 'Ext.Window', 'Ext.fx.target.Sprite', 'Ext.layout.container.Fit']);
Ext.onReady(function () {
    
	projectEvaStore = Ext.create('Ext.data.Store', {
		fields: ['date', 'planned_value', 'percent_completed', 'cost_type_3702', 'cost_type_3703', 'cost_type_3718'],
		data: [
	{'date': new Date('2014-06-16'), 'planned_value': 1000.0, 'percent_completed': 0.0, 'cost_type_3702': 0.0, 'cost_type_3703': 0.0, 'cost_type_3718': 0.0},
	{'date': new Date('2014-06-18'), 'planned_value': 5000.0, 'percent_completed': 10000.0, 'cost_type_3702': 1000.0, 'cost_type_3703': 0.0, 'cost_type_3718': 510.0},
	{'date': new Date('2014-06-19'), 'planned_value': 16000.0, 'percent_completed': 15000.0, 'cost_type_3702': 5000.0, 'cost_type_3703': 0.0, 'cost_type_3718': 270.0},
	{'date': new Date('2014-07-23'), 'planned_value': 16000.0, 'percent_completed': 25000.0, 'cost_type_3702': 1000.0, 'cost_type_3703': 0.0, 'cost_type_3718': 0.0}
		       ]
	    });

	projectEvaChart = new Ext.chart.Chart({
		store: projectEvaStore,
		legend: { position: 'right' },
		theme: 'Base:gradients',
		axes: [{
			type: 'Numeric',
			minimum: 0,
			position: 'left',
			fields: [
				 'planned_value', 
				 'percent_completed'
				 ]
		    }, {
			type: 'Time',
			position: 'bottom',
			fields: 'date',
			dateFormat: 'M d'
		    }],
		series: [{
			type: 'area',
			axis: 'left',
			xField: 'date',
			yField: ['planned_value', 'percent_completed']
		    }]
	    });


	var projectEvaPanel = Ext.create('widget.panel', {
		width: 1000,
		height: 500,
		title: 'Test',
		renderTo: 'diagram_12345',
		layout: 'fit',
		header: false,
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
		items: projectEvaChart
	    });
    });
</script>
