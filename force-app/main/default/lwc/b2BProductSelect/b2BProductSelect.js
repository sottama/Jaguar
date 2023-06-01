import { LightningElement, api, track, wire } from 'lwc';
import { NavigationMixin }                    from 'lightning/navigation';
import { getRecord, getFieldValue }           from 'lightning/uiRecordApi';
import getProductVariationInfo                from '@salesforce/apex/B2BProductSelectController.getProductVariationInfo';
import addItemToCart                          from '@salesforce/apex/B2BProductSelectController.addItemToCart';
//import getProductClass                        from '@salesforce/apex/B2BProductSelectController.getProductClass';
import NOME_FIELD                             from '@salesforce/schema/Product2.Name';
import SKU_FIELD                              from '@salesforce/schema/Product2.StockKeepingUnit';
import CLASS_FIELD                            from '@salesforce/schema/Product2.ProductClass';


export default class B2BProductSelect extends NavigationMixin(LightningElement) {
    @api recordId;
    //@track productId = '';
    @track simple;
    @track variant;
    @track product;
    @track productSimple;
    @track productVariant;
    showAddedToCart = false;
    disableAddToCart = true;
    
/*
    @wire(getRecord, { recordId: '$productIdOrRecord', fields: [CLASS_FIELD, NOME_FIELD, SKU_FIELD] })
    product;
    
    get productClass() {
        if(getFieldValue(this.product.data, CLASS_FIELD) === 'Simple') { 
            return true;
        }
    }

    get name() {
        return getFieldValue(this.product.data, NOME_FIELD);
    }

    get sku() {
        return getFieldValue(this.product.data, SKU_FIELD);
    }

    get productIdOrRecord() {
        return this.productId != '' ? this.productId : this.recordId;
    }
*/
    connectedCallback() {
        getProductVariationInfo({ productId: this.recordId })
            .then(result => {
                let productObj = JSON.parse(result);
                this.product   = productObj;
                console.log(this.product);
                this.simple    = this.product[0].simple;
                this.variant   = this.product[0].parent;
                //this.simple = this.product.simple;
                //this.parent = this.product.parent; 
            })
            .catch(error => {
                console.log('Ocorreu o seguinte erro ao buscar a lista de variante dos produtos: ' + error.message);
            });
        /*
        getProductClass({productId: this.recordId})
            .then(result => {
                this.product = JSON.parse(result);
                this.simple = this.product.simple;
                this.parent = this.product.parent;

                console.log('Simples: ' + this.simple);
                console.log('Pai: ' + this.parent);
                if(this.simple && !!this.parent)
                    this.getVariation(this.recordId);
                if(this.simple && !!this.parent)
                    this.getVariation(this.recordId);
            })
            .catch(error => {
                console.log('Ocorreu o seguinte erro ao buscar o produto: ' + error.message);
            });
        */
    }

    getVariation(recordId) {
        getProductVariationInfo({ productId: recordId })
            .then(result => {
                this.productVariant = result;  
            })
            .catch(error => {
                console.log('Ocorreu o seguinte erro ao buscar a lista de variante dos produtos: ' + error.message);
            });
    }

    addToCart(event) {
        console.log('Log 00');
        this.isLoading = true;
        console.log('Log 01');
        let quantity = this.template.querySelectorAll('[data-id="Quantidade"]')[0].value;
        let recId = event.target.value;
        console.log('Id do produto que será adicionado a loja ==> ' + recId);
        console.log('Log 002');
        addItemToCart ({ productId: recId , quantity : quantity})
        .then(result => {
        console.log('Log SUCCESS');

            this.isLoading = false;
            this.cartId = result;
            this.dispatchEvent(new CustomEvent("cartchanged", {
                bubbles: true,
                composed: true
            }));
            this.showAddedToCart = true;
            //this.messagePopUp('', 'Produto adicionado ao carrinho', 'success');
        })
        .catch(error => {
        console.log('Log ERROR');
            console.log(error);
            console.log(error.message);
            this.isLoading = false;
            this.disableAddToCart = false;
            console.log('Ocorreu ao tentar adicionar o item no Carrinho: ' + error.message);
        });
    }

    closeAddedToCartModal() {
        console.log('Log 02');

        this.showAddedToCart = false;  
    }

    navigateToCart() {
        console.log('Log 03');

        this[NavigationMixin.Navigate]({
        
            type: 'standard__recordPage',
        
            attributes: {
        
            recordId: this.cartId,
        
            objectApiName: 'WebCart',
        
            actionName: 'view'
        
            },
        }); 
    }
}