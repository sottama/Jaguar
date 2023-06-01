public without sharing class B2BProductSelectController {
/*
    @AuraEnabled
    public static String getProductClass(String productId) {
        System.debug('Id do Produto: ' + productId);
        Product2 produ = [SELECT Id, Name, StockKeepingUnit, ProductClass, ProductCode FROM Product2 WHERE Id = :productId LIMIT 1];
        System.debug('Produto Encontrado: ' + produ);
        if(produ.ProductClass == 'Simple') {
            ProductWrapper produWrapper = new ProductWrapper();
           
            produWrapper.id = produ.Id;
            produWrapper.name = produ.Name;
            produWrapper.sku = produ.StockKeepingUnit;
            produWrapper.code = produ.ProductCode;
            
            produWrapper.simple = true;
            produWrapper.parent = false;
            System.debug('Produto Simple Wrapper: ' + produWrapper);
            return JSON.serialize(produWrapper); 
        }
        if(produ.ProductClass == 'VariationParent') {
            ProductWrapper produWrapper = new ProductWrapper();
            produWrapper.simple = false;
            produWrapper.parent = true;
            System.debug('Produto Parent Wrapper: ' + produWrapper);
            return JSON.serialize(produWrapper);
        }
        return null;
    }
*/
    @AuraEnabled
    public static String getProductVariationInfo(String productId01) {
        try {
            String productId = '01tDT000009u5PTYAY';
            String urlBase = URL.getOrgDomainUrl().toExternalForm();
            System.debug('URL base ==> ' + urlBase);
            WebStore store = getStore();
        
            String userId = UserInfo.getUserId();
            System.debug('Id do Usuário: ' + userId);
            // Query the User object to get the record for the logged-in user, including its associated Contact and Account records
            User userRecord = [SELECT Id, ContactId, AccountId, ProfileId FROM User WHERE Id = :userId];
            System.debug('Registro do Usuário ==> ' + userRecord);
            System.debug('Account Id ==> ' + userRecord.AccountId);
            System.debug('Id do Perfil do Usuário ==> ' + userRecord.ProfileId + '\n\n');
            List<String> fields = new List<String>();
            List<String> mediaGroups = new List<String>();
/*
            Boolean excludeFields = false;
            Boolean excludeMedia = false;
            Boolean excludeEntitlementDetails = true;
            Boolean excludePrimaryProductCategory = true;
            Boolean excludeVariationInfo = false;
            Boolean excludeAttributeSetInfo = false;
*/          

            Product2 product = [SELECT Id, ProductClass FROM Product2 WHERE Id = :productId LIMIT 1];
            System.debug('Produto "base" encontrado: ' + product);
            
            List<ProductAttribute> lstVariation;
            Set<Id> setProduVariationId;
            Map<Id, String> mapProduVariationUrl;
            List<ProductWrapper> lstProduVariation = new List<ProductWrapper>();
            
            if(product.ProductClass == 'VariationParent') {
               System.debug('Caiu no IF == VariationParent');
                //lstVariation = [SELECT ProductId FROM ProductAttribute WHERE VariantParentId = :product.Id];
                setProduVariationId  = new Set<Id>();
                mapProduVariationUrl = new Map<Id, String>();

                for(ProductAttribute produ : [SELECT ProductId FROM ProductAttribute WHERE VariantParentId = :product.Id]) {
                    ConnectApi.ProductDetail produDetail = ConnectApi.CommerceCatalog.getProduct(store.Id, produ.ProductId, userRecord.AccountId, fields, false, mediaGroups, false, false, false, false, false);
                    mapProduVariationUrl.put(produ.ProductId, urlBase+produDetail.defaultImage?.url);
                    setProduVariationId.add(produ.ProductId);
                }
    
                for(Product2 produVariation : [SELECT Id, Name, StockKeepingUnit, ProductCode FROM Product2 WHERE Id IN :setProduVariationId]) {
                    ProductWrapper produWrapper = new ProductWrapper();
                    produWrapper.id     = produVariation.Id;
                    produWrapper.name   = produVariation.Name;
                    produWrapper.sku    = produVariation.StockKeepingUnit;
                    produWrapper.code   = produVariation.ProductCode;
                    produWrapper.imgUrl = mapProduVariationUrl.get(produVariation.Id);
                    produWrapper.simple = false;
                    produWrapper.parent = true;
                    lstProduVariation.add(produWrapper);
                }
                for(ProductWrapper teste : lstProduVariation)
                    System.debug('Lista de produtos na lista de Wrapper ==> ' + teste + '\n');
            } else if(product.ProductClass == 'Simple') {
                System.debug('Caiu no IF == Simple');
                ConnectApi.ProductDetail produDetail = ConnectApi.CommerceCatalog.getProduct(store.Id, product.Id, userRecord.AccountId, fields, false, mediaGroups, false, false, false, false, false);
                //mapProduVariationUrl.put(produDetail.ProductId, urlBase+produDetail.defaultImage?.url);

                Product2 productSimple = [SELECT Id, Name, StockKeepingUnit, ProductCode FROM Product2 WHERE Id = :product.Id];
                ProductWrapper produWrapper = new ProductWrapper();
                produWrapper.id     = productSimple.Id;
                produWrapper.name   = productSimple.Name;
                produWrapper.sku    = productSimple.StockKeepingUnit;
                produWrapper.code   = productSimple.ProductCode;
                produWrapper.imgUrl = urlBase+produDetail.defaultImage?.url;
                produWrapper.parent = false;
                produWrapper.simple = true;
                lstProduVariation.add(produWrapper);
                System.debug('Lista de produtos na lista de Wrapper ==> ' + lstProduVariation);
            } else {
                System.debug('Caiu no IF == NULL');
                return null;
            }

            return JSON.serialize(lstProduVariation);

        } catch(Exception ex) {
            System.debug('Causa ==> ' + ex.getCause() +
                         '\nLinha ==> ' + ex.getLineNumber() +
                         '\n Mensagem ==>' + ex.getMessage());
            return JSON.serialize(new List<ProductWrapper>());
        }
    }

    @AuraEnabled
    public static string addItemToCart(String productId, Integer quantity){
        System.debug(productId);
        try {
            System.debug('Acessou 01');
            WebStore store = getStore();
            ConnectApi.CartItemInput cartItemInput = new ConnectApi.CartItemInput();
            cartItemInput.productId = productId;
            cartItemInput.quantity = String.valueOf(quantity);
            cartItemInput.type = ConnectApi.CartItemType.Product;
            System.debug('Acessou 02');
            if (!Test.isRunningTest()) {
                System.debug('Caiu no IF !Test');
                Connectapi.CommerceCart.addItemToCart(store.Id, null, 'current', cartItemInput);
            } 

            System.debug('Acessou 02');
            WebCart cart = [SELECT Id FROM WebCart WHERE OwnerId =: UserInfo.getUserId() AND Status = 'Active' AND Type = 'Cart' LIMIT 1];
            System.debug('WebCart Id: ' + cart.Id);
            return cart.Id;
        } catch (Exception e) {
            String er = '\nLinha: '+ e.getLineNumber() + '\n Mensagem: ' + e.getMessage() + '\nCausa: ' + e.getCause() + '\nTipo: ' + e.getTypeName() + '\nStack: ' + e.getStackTraceString();
            System.debug(er);
            throw new AuraHandledException(er);
    
        }
    }

    private static WebStore getStore() {
        try {  
            WebStore store;
            if (!Test.isRunningTest()){
                System.debug('Entrou no método getStore()');
                //System.debug('Network Id ==> ' + Network.getNetworkId());
                Network storeNetWork = [SELECT Name FROM Network WHERE Id = :Network.getNetworkId()];
                store = [SELECT Id, Name FROM WebStore WHERE Name = :storeNetWork.Name]; //:storeNetWork.Name     'Jaguar Embalagens'
                System.debug('Nome da Loja ==> ' + store.Name);
                System.debug('Id da Loja ==> ' + store.Id);
            } else {
                store = [SELECT Id FROM WebStore LIMIT 1];
            }
            return store;
        } catch(Exception ex) {
            System.debug('Causa ==> ' + ex.getCause() +
                         '\nLinha ==> ' + ex.getLineNumber() +
                         '\n Tipo ==> ' + ex.getTypeName() +
                         '\n Número de Dmls ==> '+ ex.getNumDml() +
                         '\n  Stack ==> ' + ex.getStackTraceString() +
                         '\n Mensagem ==>' + ex.getMessage());
            return new WebStore();
        }
    }
    
    public class ProductWrapper {
        @AuraEnabled public String id;
        @AuraEnabled public String name;
        @AuraEnabled public String sku;
        @AuraEnabled public String imgUrl;
        @AuraEnabled public String valor;
        @AuraEnabled public String code;
        @AuraEnabled public Boolean parent;
        @AuraEnabled public Boolean simple;
    }

    /*
    for(ProductAttribute produ : lstVariation) {
                ConnectApi.ProductDetail produDetail = ConnectApi.CommerceCatalog.getProduct(store.Id, produ.ProductId, userRecord.AccountId, fields, false, mediaGroups, false, false, false, false, false);
    
                System.debug('Detalhes do Produto ==> ' + produDetail);
                System.debug('Nome do Produto ==> ' + produDetail.fields.get('Name'));
                System.debug('Titulo da Imagem ==> ' + produDetail.defaultImage?.title);
                System.debug('URL da Imagem ==> ' + produDetail.defaultImage?.url);
                System.debug('URL Completa ==> ' + urlBase+produDetail.defaultImage?.url + '\n\n');
                mapProduVariationUrl.put(produ.ProductId, produDetail.defaultImage?.url);
                setProduVariationId.add(produ.ProductId);
            }

            for(Product2 produVariation : [SELECT Id, Name, StockKeepingUnit FROM Product2 WHERE Id IN :setProduVariationId]) {
                ProductWrapper produWrapper = new ProductWrapper();
                produWrapper.id     = produVariation.Id;
                produWrapper.name   = produVariation.Name;
                produWrapper.sku    = produVariation.StockKeepingUnit;
                produWrapper.imgUrl = mapProduVariationUrl.get(produVariation.Id);
                lstProduVariation.add(produWrapper);
            }
    */
}