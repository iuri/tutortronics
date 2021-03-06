/**
 * sencha-core/www/class/PreferenceStateProvider.js
 *
 * Copyright (C) 2016, ]project-open[
 * @author Frank Bergmann (frank.bergmann@project-open.com)
 * @creation-date 2013-11-29
 * @cvs-id $Id: PreferenceStateProvider.js,v 1.3 2016/11/11 11:50:03 cvs Exp $
 */


/*
 * Create a specific store for categories.
 * The subclass contains a special lookup function.
 */
Ext.define('PO.class.PreferenceStateProvider', {
    extend: 'Ext.state.Provider',
    requires: [
        'PO.Utilities',
        'PO.model.user.SenchaPreference',
        'PO.store.user.SenchaPreferenceStore'
    ],

    /**
     * Create a new PreferenceStateProvider
     * @param {Object} [config] Config object.
     */
    constructor : function(config){
        var me = this;
        me.userId = PO.Utilities.userId();
        me.currentUrl = config.url;
	if (typeof me.currentUrl == "undefined" || me.currentUrl === null) {
	    me.currenturl = window.location.pathname;
	}
        me.callParent(arguments);
        me.state = me.readPreferences();
    },

    set : function(name, value){
        var me = this;
        if (typeof value == "undefined" || value === null) {
            me.clear(name);
            return;
        }
        me.setPreference(name, value);
        me.callParent(arguments);
    },

    clear : function(name){
        this.clearPreference(name);
        this.callParent(arguments);
    },

    /**
     * Retreive all available preferences for this user and this URL from the server
     */
    readPreferences : function(){
        var me = this;
        // We need to create and load the store during initialization of the application.
        // It should contain all keys for the current userId and url.
        var senchaPreferenceStore = Ext.StoreManager.get('senchaPreferenceStore');
        var preferences = {};

        // Loop through the store and add elements to object
        senchaPreferenceStore.each(function(pref) {
            preferences[pref.get('preference_key')] = me.decodeValue(pref.get('preference_value'));
        });
        return preferences;
    },

    /**
     * Store a specific name-value pair into the preference store
     */
    setPreference : function(name, value){
        var me = this;
        var senchaPreferenceStore = Ext.StoreManager.get('senchaPreferenceStore');
        var pref, 
	    prefIndex = senchaPreferenceStore.findExact('preference_key',name);

        if (prefIndex < 0) {
            // We need to create a new preference
            pref = Ext.create('PO.model.user.SenchaPreference', {
                preference_url: me.currentUrl,
                preference_key: name,
                preference_value: me.encodeValue(value)
            });
            senchaPreferenceStore.add(pref);
            pref.save();	    // Asynchroneously save the value, but don't wait for the confirmation - not necessary.
        } else {
            // The preference is already there - update the value
	    pref = senchaPreferenceStore.getAt(prefIndex);
            pref.set('preference_value',  me.encodeValue(value));
            pref.save();	    // Asynchroneously save the value, but don't wait for the confirmation - not necessary.	    
        }
    },

    clearPreference : function(name){
        var me = this;
        var senchaPreferenceStore = Ext.StoreManager.get('senchaPreferenceStore');
        var pref = senchaPreferenceStore.findExact('preference_key',name);

        if (typeof pref == "undefined" || pref === null) {
            // No preference found - so there is no need to clear the value
        } else {
            // Found the preference - delete it
            // This will send a DELETE HTTP request to the server.
            pref.destroy();
        }
    }
});
