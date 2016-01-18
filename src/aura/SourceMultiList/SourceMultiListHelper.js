({
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
    }
})