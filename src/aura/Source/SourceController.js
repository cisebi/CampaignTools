({
    handleSourceType: function(component, event, helper) {
        var selectCmp = component.find("sourceType");
        var source = component.get('v.source');
        source.segmentType = selectCmp.get("v.value");
        component.set("v.source", source);
    },

    delete: function(component, event, helper) {
        var source = component.get('v.source');
        if (source == null)
            return;

        var event = $A.get("e.c:deleteCSegmentEvent");
        event.setParams({ "cseg" : source });
        event.fire();

    },

    handleAutocomplete: function(component, event) {
        var source = component.get('v.source');
        var selOpt = event.getParam('selectedOption');
        source.sourceName = selOpt.label;
        source.sourceId = selOpt.value;
        component.set("v.source", source);
    },
})
