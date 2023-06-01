trigger Product2Trigger on Product2 (before insert) {
    if(trigger.isBefore) {
        Product2Handler.productParent(trigger.new);
    }
}