import { LightningElement, api, track } from 'lwc';
import getProductCategoriesMedia from '@salesforce/apex/B2BCaroselController.getProductCategoriesMedia';


export default class B2bProductCategoriesCarosel extends LightningElement {
    @api categoryId;
    @api webStoreId;
    @api accountId;
    
    carouselItems=[];
    @track activeIndex = 0;
    previousDisable = false;
    nextDisable = false;


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
            console.log('objStr :>> ', JSON.stringify(objStr));
            this.carouselItems = objStr.map((obj, index)=>{
                return {
                    Id: index,
                    imageUrl: obj.url,
                    title: obj.title
                }
            }); 

            // this.carouselInterval = setInterval(() => {
            //     this.showNext();
            //   }, 5000);

        })
        .catch(error => console.log(error))
    }

    get carouselStyle() {
        return `transform: translateX(-${this.activeIndex * 33.33}%);`;
    }

    showPrevious() {
        if (this.activeIndex > 0) {
          this.activeIndex -= 3;
        }

        setArrows();
    }

    setArrows(){
        this.previousDisable = (this.activeIndex === 0) ? true : false;
        this.nextDisable = (this.activeIndex >= this.carouselItems.length - 3) ? true : false;
    }
    
    showNext() {
        if (this.activeIndex < this.carouselItems.length - 3) {
          this.activeIndex += 3;
        }
        setArrows();  
    }
}