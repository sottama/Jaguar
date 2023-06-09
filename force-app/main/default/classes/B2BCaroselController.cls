public without sharing class B2BCaroselController {
    @AuraEnabled (cacheable=true)
    public static String getImageUrl(String listContentKeys, String channelName){
        System.debug('Apex Iniciado');
        List<String> keys = listContentKeys.split(',', 59);
        DateTime dateNow = DateTime.now();
        String startDate = '2000-01-01T00:00:00.000Z';
        String endDate = dateNow.format('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'');
        ConnectApi.ManagedContentVersionCollection obj;
        if(!Test.isRunningTest()) {
            String channelId = [SELECT Id FROM ManagedContentChannel WHERE Name = :channelName LIMIT 1].id;
            obj = ConnectApi.ManagedContent.getContentByContentKeys(channelId, keys, 0, 25, null, 'cms_image',
                                                                    false, startDate, endDate, true);  
        } else {
            obj = new ConnectApi.ManagedContentVersionCollection();
            obj.items = new List<ConnectApi.ManagedContentVersion>();
            ConnectApi.ManagedContentVersion item = new ConnectApi.ManagedContentVersion();
            item.title = 'isTest';
            item.contentNodes = new Map<String, ConnectApi.ManagedContentNodeValue>();
            obj.items.add(item);
        }
        
        List<ReturnWrapper> wrapperList = new List<ReturnWrapper>();
       
        for(ConnectApi.ManagedContentVersion versionObj : obj.items){
            ReturnWrapper wrapper = new ReturnWrapper();
            wrapper.title = versionObj.title;
            Map<String, ConnectApi.ManagedContentNodeValue> contentNodesMap = versionObj.contentNodes;
            for(String str : contentNodesMap.keySet()){                
                if(str == 'source'){
                    wrapper.url= ((ConnectApi.ManagedContentMediaSourceNodeValue)contentNodesMap.get(str)).url;
                }		
            }
            wrapperList.add(wrapper);	
        }
        return JSON.serialize(wrapperList);
    }

    @AuraEnabled (cacheable=true)
    public static String getProductCategoriesMedia(String webstoreName, String effectiveAccountId, 
        String categoryName, List<String> fields, Boolean excludeFields, List<String> mediaGroups, Boolean excludeMedia)
    {
        try {
            String webstoreId = [SELECT Id FROM Webstore WHERE Name = :webstoreName].Id;
            String parentProductCategoryId = [SELECT Id FROM ProductCategory WHERE Name = :categoryName LIMIT 1].Id;
            
            // if(String.isblank(effectiveAccountId)){
            //     effectiveAccountId = [SELECT Id FROM Account LIMIT 1].Id;
            // }

            ConnectApi.ProductCategoryDetailCollection categories = ConnectApi.CommerceCatalog.getProductCategoryChildren(webstoreId, null, parentProductCategoryId,
                                                                    fields, excludeFields, mediaGroups, excludeMedia);

            List<ReturnWrapper> wrapperList = new List<ReturnWrapper>();
            List<String> lstKeys = new List<String>();

            for(ConnectApi.ProductCategoryDetail categoryDetail : categories.productCategories){
                if(categoryDetail.mediaGroups.size() > 0){
                    String setUrl = categoryDetail.mediaGroups[0].mediaItems[0].url.substringBetween('media/', '?');
                    lstKeys.add(setUrl);
                }
            }

            return B2BCaroselController.getImageUrl(String.join(lstKeys, ','), webstoreName);

        } catch (Exception e) {
            System.debug('error: ' + e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static List<ProductCategory> getCategories(String categoryName){
        try {
            String parentCategory = [SELECT Id, Name FROM ProductCategory WHERE Name = :categoryName LIMIT 1].Id;
            List<ProductCategory> lstCategories = [SELECT Id, Name FROM ProductCategory WHERE ParentCategoryId = :parentCategory];
            return lstCategories;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    public class ReturnWrapper{
        String title {get;set;}
        String url {get;set;}
    }
}