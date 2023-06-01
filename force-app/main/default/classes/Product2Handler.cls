public class Product2Handler {
    public static void productParent(List<Product2> triggerNew) {
        for(Product2 produto : triggerNew) {
            if(produto.Grade__c == false && produto.CodigoGrade__c == null) {
                produto.Type = 'Base';
            }
        }
    }
}