import { LightningElement, api, track } from 'lwc';
import getProductCategoriesMedia from '@salesforce/apex/B2BCaroselController.getProductCategoriesMedia';


export default class B2bProductCategoriesCarosel extends LightningElement {
    @api categoryId;
    @api webStoreId;
    @api accountId;
    

    @track items = []; 
    @track itemsToShow = []; 
    @track currentPage = 1; 
    @track pageSize = 4; 

    connectedCallback() {
        getProductCategoriesMedia({
            webstoreId: this.webStoreId,
            effectiveAccountId: this.accountId,
            parentProductCategoryId: this.categoryId,
            fields: null,
            excludeFields: true,
            mediaGroups: null,
            excludeMedia: false
        })
        .then(data =>{
            let objStr = JSON.parse(data);
            
            this.items = objStr.map((obj, index)=>{
                return {
                    Id: index,
                    imageUrl: obj.url,
                    title: obj.title
                }
            });
            this.showItems();
        })
        .catch(error => console.log(error))
    }

    showItems() {
        const startIndex = (this.currentPage - 1) * this.pageSize;
        this.itemsToShow = this.items.slice(startIndex, startIndex + this.pageSize);
        this.previousDisable = this.currentPage === 1;
        this.nextDisable = this.currentPage >= Math.ceil(this.items.length / this.pageSize);
    }
    
    showPrevious() {
        if (this.currentPage > 1) {
          this.currentPage--;
          this.showItems();
        }
    }
    
    showNext() {
        if (this.currentPage < Math.ceil(this.items.length / this.pageSize)) {
          this.currentPage++;
          this.showItems();
        }
    }
}