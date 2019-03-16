Ext.require('Ext.chart.*');
Ext.require('Ext.Window');
Ext.require('Ext.fx.target.Sprite');
Ext.require('Ext.layout.container.Fit');

Ext.onReady(function () {

   Ext.define('IndicatorResults', {
            extend: 'Ext.data.Model',
            idProperty: 'id',
            fields: [
                      {name: 'id',                   type: 'int'},
                      {name: 'object_name',          type: 'string'},
                      {name: 'result_id',            type: 'int'},
                      {name: 'result_indicator_id',  type: 'int'},
                      {name: 'result_date',          type: 'date'},
                      {name: 'result_date_pretty',   type: 'string'},
                      {name: 'result',               type: 'int'},
                      {name: 'result_count',         type: 'int'},
                      {name: 'result_system_key',    type: 'string'},
                      {name: 'result_sector_id',     type: 'int'},
                      {name: 'result_company_size',  type: 'int'},
                      {name: 'result_geo_region_id', type: 'int'},
                      {name: 'result_object_id',     type: 'int'}
            ],
        proxy: {
           type: 'rest',
                   autoLoad: true,
                   getParams: Ext.emptyFn,
           url: '@url;literal@',
           reader: {
               type: 'json',
               root: 'data'
           }
        }
        });

   var store1 = Ext.create('Ext.data.Store', {
           fields: ['result_date_pretty','result'],
           model: 'IndicatorResults',
   });


   var mychart = Ext.create('Ext.chart.Chart', {
           xtype: 'chart',
           renderTo: '@render_to;literal@',
           theme: 'Green',
           hidden: false,
           width: @diagram_width;literal@,
           height: @diagram_height;literal@,
           store: store1,
           maximizable: true,
           title: '@title;literal@',
           layout: 'fit',
           axes: [{
               title: '@label_y;literal@',
               type: 'Numeric',
               position: 'left',
               fields: ['result'],
               grid: { odd: { opacity: 0.5, fill: '#ddd'}}
           }, {
	       title: '@label_x;literal@',
	       type: 'Time',
	       position: 'bottom',
	       fields: ['result_date_pretty'],
	       dateFormat: 'M Y',
	       step: [Ext.Date.MONTH, 1],
	       label: {rotate: { degrees: 315}}
           }],
           series: [{
               type: 'line',
               xField: 'result_date_pretty',
               yField: 'result',
               highlight: {size: 2, radius: 2}
           }]
        });
        store1.load();
        mychart.redraw();
});
