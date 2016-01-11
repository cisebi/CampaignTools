({
    handleSourceChange: function(component, event, helper) {
        var sourceSegment = event.getParam("value");
        if ('REPORT_SOURCE_SEGMENT' !== sourceSegment.segmentType) return;
        var columnNameComponent = component.find("columnName");
        var action = component.get("c.getReportIdColumns");
        action.setParams({"reportId": sourceSegment.sourceId});
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var columns = response.getReturnValue();
                var options = [{
                    label: 'Select Id Column',
                    value: ''
                }];
                values = Object.keys(columns);
                for (i = 0; i < values.length; i++) {
                    var columnLabel = columns[values[i]];
                    var columnId = values[i];
                    var isSelected = (sourceSegment.columnName === values[i]);
                    options.push({
                        label: columnLabel,
                        value: columnId,
                        selected: isSelected
                    });
                }
                component.find("columnName").set("v.options", options);
            }
            else if (state === "ERROR") {
                // @todo what do we do if we can't find any id columns or the
                // report doesn't exist, etc?
                component.find("columnName").set(
                    "v.options",
                    [{
                        label: '--',
                        value: ''
                    }]
                );
            }
        });
        $A.enqueueAction(action);
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