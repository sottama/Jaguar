// This must implement the sfdc_checkout.CartTaxCalculations interface
// in order to be processed by the checkout flow and used for your Taxes integration.
global with sharing class B2BTax implements sfdc_checkout.CartTaxCalculations {
    global sfdc_checkout.IntegrationStatus startCartProcessAsync(sfdc_checkout.IntegrationInfo jobInfo, Id cartId) {
        sfdc_checkout.IntegrationStatus integStatus = new sfdc_checkout.IntegrationStatus();
        try {
            // In the Spring '20 release, there should be one delivery group per cart.
            // In the future, when multiple delivery groups can be created,
            // this sample should be updated to loop through all delivery groups.

            // We need to get the ID of the delivery group in order to get the DeliverTo info.
            Map<String, Decimal> mapCFXIPI = new Map<String, Decimal>();
            Map<String, TributoICMSST__c> mapCFXICMSST = new Map<String, TributoICMSST__c>();
            Map<String, TributoICMSST__c> mapCFXICMSSTImportacao = new Map<String, TributoICMSST__c>();
            Id cartDeliveryGroupId = [SELECT CartDeliveryGroupId FROM CartItem WHERE CartId = :cartId WITH SECURITY_ENFORCED][0].CartDeliveryGroupId;
            CartDeliveryGroup deliveryGroup = [SELECT DeliverToState, DeliverToCountry FROM CartDeliveryGroup WHERE Id = :cartDeliveryGroupId WITH SECURITY_ENFORCED][0];
            WebCart cart = [SELECT Id, NaturezaOperacao__c,
                            TYPEOF Account
                                WHEN Account THEN IsentoIPI__c, IsentoICMSST__c, Cidade__r.UF__c
                                , RegimeTributario__c, InscricaoEstadual__c
                            END
                            FROM WebCart WHERE Id = :cartId WITH SECURITY_ENFORCED][0];
            Account acc = cart.Account;
            List<CartItem> listCartItem = [SELECT Sku, TotalPrice, Product2.ClassificaFiscal__c, Type FROM CartItem WHERE CartId = :cartId WITH SECURITY_ENFORCED];

            List<String> listClassificacaoFiscal = new List<String>();
            for (CartItem cartItem : listCartItem) {
                listClassificacaoFiscal.add(cartItem.Product2.ClassificaFiscal__c);
            }
            if(!acc.IsentoIPI__c) {
                for (TributoIPI__c tributo : [SELECT ClassificacaoFiscal__c, PercentualAliquota__c FROM TributoIPI__c
                                            WHERE ClassificacaoFiscal__c IN :listClassificacaoFiscal AND NaturezaOperacao__c = :cart.NaturezaOperacao__c WITH SECURITY_ENFORCED]) {
                    mapCFXIPI.put(tributo.ClassificacaoFiscal__c, tributo.PercentualAliquota__c);
                }
            }
            //Buscar os tributos aplicaveis aos itens se conta não for isenta
            if(!acc.IsentoICMSST__c && String.IsNotBlank(acc.InscricaoEstadual__c)) {
                Boolean regimeTributario = acc.RegimeTributario__c == 'S';
                for (TributoICMSST__c tributo : [SELECT MVA__c, PercentualICMSUFDestino__c, PercentualICMSUFOrigem__c
                                                FROM TributoICMSST__c
                                                WHERE ClassificacaoFiscal__c IN :listClassificacaoFiscal
                                                AND CalculoItemImportado__c = false
                                                AND RegimeTributario__c = :regimeTributario
                                                AND UnidadeFederativa__c = :acc.Cidade__r.UF__c
                                                WITH SECURITY_ENFORCED]) {
                    mapCFXICMSST.put(tributo.ClassificacaoFiscal__c, tributo);
                }
                for (TributoICMSST__c tributo : [SELECT MVA__c, PercentualICMSUFDestino__c, PercentualICMSUFOrigem__c
                                                FROM TributoICMSST__c
                                                WHERE ClassificacaoFiscal__c IN :listClassificacaoFiscal
                                                AND CalculoItemImportado__c = true
                                                AND RegimeTributario__c = :regimeTributario
                                                AND UnidadeFederativa__c = :acc.Cidade__r.UF__c
                                                WITH SECURITY_ENFORCED]) {
                    mapCFXICMSSTImportacao.put(tributo.ClassificacaoFiscal__c, tributo);
                }
            }
            // Get all SKUs, the cart item IDs, and the total prices from the cart items.

            for (CartItem cartItem : listCartItem) {
                //Calculo do IPI
                if (mapCFXIPI.containsKey(cartItem.Product2.ClassificaFiscal__c)) {
                    cartItem.IPI__c = cartItem.TotalPrice * mapCFXIPI.get(cartItem.Product2.ClassificaFiscal__c);
                } else {
                    cartItem.IPI__c = 0;
                }
                //Calculo do ICMS ST
                if (cartItem.Product2.ProdutoImportado__c && mapCFXICMSSTImportacao.containsKey(cartItem.Product2.ClassificaFiscal__c)) {
                    cartItem.ICMSST__c = calcularICMSST(cartItem, mapCFXICMSSTImportacao.get(cartItem.Product2.ClassificaFiscal__c));
                } else if (!cartItem.Product2.ProdutoImportado__c && mapCFXICMSST.containsKey(cartItem.Product2.ClassificaFiscal__c)) {
                    cartItem.ICMSST__c = calcularICMSST(cartItem, mapCFXICMSST.get(cartItem.Product2.ClassificaFiscal__c));
                } else {
                    cartItem.ICMSST__c = 0;
                }
            }

            update listCartItem;
            integStatus.status = sfdc_checkout.IntegrationStatus.Status.SUCCESS;
        } catch(Exception e) {
            // For testing purposes, this example treats exceptions as user errors, which means they are displayed to the buyer user.
            // In production you probably want this to be an admin-type error. In that case, throw the exception here
            // and make sure that a notification system is in place to let the admin know that the error occurred.
            // See the readme section about error handling for details about how to create that notification.
            return integrationStatusFailedWithCartValidationOutputError(
                integStatus,
                'An exception of type ' + e.getTypeName() + ' has occurred: ' + e.getMessage(),
                jobInfo,
                cartId
            );
        }
        return integStatus;
    }

    private Decimal calcularICMSST(CartItem item, TributoICMSST__c tributo) {
        Decimal valorComIPI         = item.TotalPrice + item.IPI__c;
        Decimal valorICMS           = item.TotalPrice * tributo.PercentualICMSUFOrigem__c;
        Decimal baseCalculoICMSST   = valorComIPI * ( 1 + tributo.MVA__c );
        Decimal aliquotaICMSinterna = baseCalculoICMSST * tributo.PercentualICMSUFDestino__c;
        return (aliquotaICMSinterna - valorICMS);
    }

    private sfdc_checkout.IntegrationStatus integrationStatusFailedWithCartValidationOutputError(
        sfdc_checkout.IntegrationStatus integrationStatus, String errorMessage, sfdc_checkout.IntegrationInfo jobInfo, Id cartId) {
            integrationStatus.status = sfdc_checkout.IntegrationStatus.Status.FAILED;
            // For the error to be propagated to the user, we need to add a new CartValidationOutput record.
            // The following fields must be populated:
            // BackgroundOperationId: Foreign Key to the BackgroundOperation
            // CartId: Foreign key to the WebCart that this validation line is for
            // Level (required): One of the following - Info, Error, or Warning
            // Message (optional): Message displayed to the user (maximum 255 characters)
            // Name (required): The name of this CartValidationOutput record. For example CartId:BackgroundOperationId
            // RelatedEntityId (required): Foreign key to WebCart, CartItem, CartDeliveryGroup
            // Type (required): One of the following - SystemError, Inventory, Taxes, Pricing, Shipping, Entitlement, Other
            CartValidationOutput cartValidationError = new CartValidationOutput(
                BackgroundOperationId = jobInfo.jobId,
                CartId = cartId,
                Level = 'Error',
                Message = errorMessage.left(255),
                Name = (String)cartId + ':' + jobInfo.jobId,
                RelatedEntityId = cartId,
                Type = 'Taxes'
            );
            insert(cartValidationError);
            return integrationStatus;
    }
}