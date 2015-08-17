({
	addSource: function(component, event, helper) {
		var group = component.get('v.group');
        
        var segNew = {Source_Type__c:"Campaign"};
        var csegNew = {Segment:segNew};
        group.listChildCSegments.push(csegNew);
        
        /*
        group.items.push({
            id: window.getNextId(),
            parent: group.id,
            type: 'filter'
        });
        */
        component.set('v.group', group);
	},
    
    delete: function(component, event, helper) {
    	alert('not yet implemented!');
	},
})