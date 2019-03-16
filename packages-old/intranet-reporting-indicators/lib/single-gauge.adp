    var component_gauge_menu_@id;literal@ = Ext.create('Ext.menu.Menu', {
        floating: true,
        items: [ @context_menu_items;literal@ ]
    });

    var div = Ext.get('component_gauge_more_@id;literal@');
    div.on('mouseenter', function(e) {
         component_gauge_menu_@id;literal@.showAt(e.getXY());
    });

    var gauge_store_@id;literal@ = Ext.create('Ext.data.JsonStore', {
            fields: ['data1'],
            data: [
                  { 'data1': @value;literal@ }
            ]
    });

    Ext.create('Ext.chart.Chart', {
        renderTo: div_gauge_@id;literal@,
        store: gauge_store_@id;literal@,
        width: 160,
        height: 110,
        animate: true,
        insetPadding: 30,
        flex: 1,
        axes: [{
            type: 'kpigauge',
            position: 'center',
            minimum: @min;literal@,
            maximum: @max;literal@,
            steps: 5,
            margin: 7,
            label: {
                fill: '#333',
                font: '12px Heveltica, sans-serif'
            }
        }],
        series: [{
            type: 'kpigauge',
            field: 'data1',
            showValue: false,
                needle: {
                    width: 2,
                    pivotFill: '#000',
                    pivotRadius: 6
                },
            ranges: [ @ranges;literal@ ],
            donut: 45
            // colorSet: ['@chart_color_value;literal@', '#ddd']

        }]
     });

