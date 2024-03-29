({
    // called at init to load information from the campaign, including
    // it's segment tree (if one exists)
    loadCampaignInfo: function(component) {
        // parse out url parameter of campaignId
        //var cmpId = this.getParam('CampaignId');
        var cmpId = component.get('v.campaignId');

        // query for the campaign object (name and Campaign_List__c)
        var action = component.get("c.getCampaign");
        action.setParams({ campaignId : cmpId });
        var self = this;
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (component.isValid() && state === "SUCCESS") {
                var campaign = response.getReturnValue();
                component.set("v.campaign", campaign);
                if (campaign.Campaign_List__c != null)
                    self.loadCSegmentTree(component);
                else
                    self.newCSegmentTree(component);
            }
            else if (component.isValid() && state === "ERROR") {
                self.reportError(response);
            }
        });
        $A.enqueueAction(action);
    },

    // create a new CSegmentTree for a campaign
    newCSegmentTree: function(component) {
        var csegRootOriginal = {
            segmentType: 'AND_SEGMENT',
            isExclusion: false,
            children: [
                {
                    isExclusion: false,
                    children: []
                },
                {
                    segmentType: 'AND_SEGMENT',
                    isExclusion: true,
                    children: []
                }
            ]
        };

        this.setParentAndRootValues(csegRootOriginal, null, csegRootOriginal);

        // save our csegments with the component
        component.set("v.csegRootOriginal", csegRootOriginal);
        component.set("v.csegRoot", csegRootOriginal.children[0]);
        component.set("v.csegExcludes", csegRootOriginal.children[1]);
    },

    // load a CSegmentTree from the server
    loadCSegmentTree: function(component) {
        // make sure we have the campaign first
        var cmp = component.get('v.campaign');
        if (cmp == null)
            return;

        // query for the segment tree
        var action = component.get("c.getSerializedSegmentTree");
        action.setParams({ rootSegmentId : cmp.Campaign_List__c });
        var self = this;
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (component.isValid() && state === "SUCCESS") {
                var csegRoot = JSON.parse(response.getReturnValue());
                var csegRootOriginal = csegRoot;

                // our parent and root references will not get serialized from Apex to Javascript,
                // so let's fix them up ourselves.
                self.setParentAndRootValues(csegRoot, null, csegRoot);

                var csegExcludes = null;
                // find the final excludes node
                if (csegRoot.segmentType == 'AND_SEGMENT' &&
                    csegRoot.children != null &&
                    csegRoot.children.length == 2) {
                    var cseg1 = csegRoot.children[0];
                    var cseg2 = csegRoot.children[1];
                    if (cseg1.isExclusion) {
                        csegExcludes = cseg1;
                        csegRoot = cseg2;
                    } else if (cseg2.isExclusion) {
                        csegExcludes = cseg2;
                        csegRoot = cseg1;
                    }
                }

                component.set("v.csegRoot", csegRoot);
                component.set("v.csegRootOriginal", csegRootOriginal);
                component.set("v.csegExcludes", csegExcludes);
            }
            else if (component.isValid() && state === "ERROR") {
                self.reportError(response);
            }
        });
        $A.enqueueAction(action);
    },

    // return a parameter value from the current URL
    getParam: function(sname) {
        var params = location.search.substr(location.search.indexOf("?")+1);
        var sval = "";
        params = params.split("&");
        // split param and value into individual pieces
        for (var i=0; i<params.length; i++) {
            temp = params[i].split("=");
            if ( [temp[0]] == sname ) { sval = temp[1]; }
        }
        return sval;
    },

    // set the Parent and Root CSegment values for each node in the tree
    setParentAndRootValues: function(csegRoot, csegParent, csegChild) {
        csegChild.root = csegRoot;
        csegChild.parent = csegParent;
        for (var i = 0; i < csegChild.children.length; i++) {
            var cseg = csegChild.children[i];
            this.setParentAndRootValues(csegRoot, csegChild, cseg);
        }
    },

    // clear the Parent and Root CSegment values for each node in the tree
    clearParentAndRootValues: function(cseg) {
        cseg.root = null;
        cseg.parent = null;
        for (var i = 0; i < cseg.children.length; i++) {
            var csegChild = cseg.children[i];
            this.clearParentAndRootValues(csegChild);
        }
    },

    // save the csegment tree to the campaign
    saveCSegmentTree: function(component, closeOnSuccess) {
        // make sure we have the campaign first
        var cmp = component.get('v.campaign');
        if (cmp == null)
            return;
        var csegRoot = component.get('v.csegRootOriginal');
        if (csegRoot == null)
            return;

        // aura will complain about circular references if we
        // try to pass the CSegment tree as is.  we need to remove
        // parent and root references to avoid circular references that
        // JSON cannot handle.
        // unfortunately, we couldn't get aura to marshall our csegRoot,
        // so now we are converting it to JSON and passing that instead.
        this.clearParentAndRootValues(csegRoot);
        strJson = JSON.stringify(csegRoot);

        // save the segment tree
        var action = component.get("c.saveCSegmentTree");
        action.setParams({ campaignId: cmp.Id, csegRoot: strJson});
        var self = this;
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (component.isValid() && state === "SUCCESS") {
                if (closeOnSuccess && response.getReturnValue()==true)
                    self.close(component);
            }
            else if (component.isValid() && state === "ERROR") {
                self.reportError(response);
            }
            self.setParentAndRootValues(csegRoot, null, csegRoot);
        });
        $A.enqueueAction(action);
    },

    // close the builder and return to the campaign
    close: function(component) {
        if (typeof sforce === "undefined") {
            window.top.location.replace('/' + component.get('v.campaign.Id'));
        } else {
            sforce.one.navigateToSObject(component.get('v.campaign.Id'));
        }
    },

    // helper to display an errors that occur from a server method call
    reportError: function(response) {
        var errors = response.getError();
        if (errors) {
            $A.logf("Errors", errors);
            if (errors[0] && errors[0].message) {
                $A.error("Error message: " + errors[0].message);
            } else if (errors[0] && errors[0].pageErrors && errors[0].pageErrors[0].message) {
                $A.error("Error message: " + errors[0].pageErrors[0].message);
            } else {
                $A.error("Unknown error");
            }
        } else {
            $A.error("Unknown error");
        }
    },

    insertParentInTree : function(cseg, csegNewParent) {
        // replace cseg from its parent's children with csegNewParent
        var csegOldParent = cseg.parent;
        var i = csegOldParent.children.indexOf(cseg);
        csegOldParent.children[i] = csegNewParent;

        // make sure the new parent has its correct parent
        csegNewParent.parent = csegOldParent;

        // add cseg to new parent's children
        csegNewParent.children.push(cseg);

        // set new Parent for cseg
        cseg.parent = csegNewParent;
    },

    insertChildInTree : function (cseg, csegNewChild) {
        csegNewChild.parent = cseg;
        cseg.children.push(csegNewChild);
    },

    addGroup: function(component, event) {
        var cseg = event.getParam("cseg");
        var csegRoot = component.get('v.csegRoot');
        var csegExcludes = component.get('v.csegExcludes');
        if (cseg == null || csegRoot == null || csegExcludes == null)
            return;

        // if current segment is a source, we want
        // to create an AND group for it, before we create the other new group
        if (cseg.segmentType != 'AND_SOURCE' && cseg.segmentType != 'OR_SEGMENT') {
            var csegNew = {
                segmentType: 'AND_SEGMENT',
                children: [],
                root: cseg.root,
                parent: cseg.parent
            };
            this.insertParentInTree(cseg, csegNew);
            // if the group was the root, update the app's root
            if (csegRoot == cseg)
                csegRoot = csegNew;
            // if the group was the excludes node, update it
            if (csegExcludes == cseg)
                csegExcludes = csegNew;
            // now continue using the new And group
            cseg = csegNew;
        }

        // if the current segment isn't an OR, then we have to add a level
        if (cseg.segmentType != 'OR_SEGMENT') {
            var csegNew = {
                segmentType: 'OR_SEGMENT',
                children: [],
                root: cseg.root,
                parent: cseg.parent
            };
            this.insertParentInTree(cseg, csegNew);

            // if the group was the root, update the app's root
            if (csegRoot == cseg)
                csegRoot = csegNew;
            // if the group was the excludes node, update it
            if (csegExcludes == cseg)
                csegExcludes = csegNew;

            // now make the new OR the parent we add to
            cseg = csegNew;
        }

        // now create the new child
        var csegNewGroup = {
            segmentType: 'AND_SEGMENT',
            children: [],
            root: cseg.root,
            parent: cseg
        };
        this.insertChildInTree(cseg, csegNewGroup);
        // now create the new child's src
        var csegNew = {
            children: [],
            root: csegNewGroup.root,
            parent: csegNewGroup
        };
        this.insertChildInTree(csegNewGroup, csegNew);

        // forces refresh
        component.set("v.csegRoot", csegRoot);
        component.set("v.csegExcludes", csegExcludes);
    },


})