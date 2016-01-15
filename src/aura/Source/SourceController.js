({
    handleSourceChange: function(component, event, helper) {
        var sourceSegment = event.getParam("value");
        helper.updateReportColumns(component, helper, sourceSegment);
    },

    handleSourceType: function(component, event, helper) {
        var selectCmp = component.find("sourceType");
        var source = component.get('v.source');
        source.segmentType = selectCmp.get("v.value");
        component.set("v.source", source);
    },

    handleColumnName: function(component, event, helper) {
        var selectCmp = component.find("columnName");
        var source = component.get('v.source');
        var columnName = selectCmp.get("v.value");
        if ('' === columnName) {
            delete source.columnName;
        } else {
            source.columnName = columnName;
        }
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

    handleAutocomplete: function(component, event, helper) {
        var selOpt = event.getParam('selectedOption');
        var sourceSegment = component.get("v.source");
        sourceSegment.sourceName = selOpt.label;
        sourceSegment.sourceId = selOpt.value;
        component.set("v.source", sourceSegment);
    }
})
