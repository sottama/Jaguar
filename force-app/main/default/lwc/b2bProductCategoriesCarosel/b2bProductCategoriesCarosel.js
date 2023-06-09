import { LightningElement, api, track, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

import getProductCategoriesMedia from '@salesforce/apex/B2BCaroselController.getProductCategoriesMedia';
import getCategories from '@salesforce/apex/B2BCaroselController.getCategories';


export default class B2bProductCategoriesCarosel extends NavigationMixin(LightningElement) {
    @api webstoreName;
    @api categoryName;
    

    @track items = []; 
    @track itemsToShow = []; 
    @track currentPage = 1; 
    @track pageSize = 4;
    categorias = [];
    paths = [];

    connectedCallback() {
        getProductCategoriesMedia({
            webstoreName: this.webstoreName,
            effectiveAccountId: '',
            categoryName: this.categoryName,
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

            this.items.sort((a, b) => a.title.localeCompare(b.title));
            this.showItems();
            this.buscarCategorias();
        })
        .catch(error => console.log(error))
    }
    handleCategory(event){
        const categoryTitle = event.currentTarget.dataset.itemTitle;
        let category = this.categorias.find(obj => obj.Name.toLowerCase() == categoryTitle.toLowerCase());

        const url = `/category/${category.Id}`;
        console.log('url :>> ', url);

        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: url
            }
        });
    }

    buscarCategorias(){
        getCategories({
            categoryName: this.categoryName
        }).then((res) => {
            this.categorias = res;
        }).catch((err) => {
            console.log('err :>> ', err);
        });
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
        } else {
            this.currentPage = 1; // Volta para a primeira página
        }
        this.showItems();
    }
}