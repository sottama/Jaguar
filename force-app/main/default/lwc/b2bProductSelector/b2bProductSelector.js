import { LightningElement, api } from 'lwc';

export default class B2bProductSelector extends LightningElement {
    
    @api recordId;

    connectedCallback(){
        console.log('recordId:'+this.recordId);
    }
}