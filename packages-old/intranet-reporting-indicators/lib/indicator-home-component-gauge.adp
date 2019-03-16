<if @indicator_cnt@ gt 0 >
    <div class="gauge_content">
    @html_div_output;literal@
    <br><br><br>
    </div>

    <script type="text/javascript">
        Ext.Loader.setConfig({
            enabled: true
        });
        Ext.Loader.setPath('Ext.ux', '/sencha-core/ux');
        Ext.Loader.setConfig('disableCaching', false);
        Ext.require([
                'Ext.chart.*',
                'Ext.ux.chart.series.KPIGauge',
                'Ext.ux.chart.axis.KPIGauge',
                'Ext.chart.axis.Gauge',
                'Ext.chart.series.*'
        ]);

        Ext.onReady(function () {
            @html_js_output;literal@
        });
    </script>
</if>
