import { LightningElement, api, track, wire } from 'lwc';
import getImageUrl from '@salesforce/apex/B2BCaroselController.getImageUrl';

export default class B2BCarosel extends LightningElement {
    @api contentKeys;
    @api channelName;
    @track results=[];
    channel;
    keys;

    connectedCallback() {
        console.log('Componente Carrossel inciado');
        this.channel = this.channelName;
        this.keys = this.contentKeys;
        console.log('Canal ==> ' + this.channelName);
        console.log('Chaves ==> ' + this.contentKeys);
    }

    @wire(getImageUrl,{listContentKeys: '$keys', channelName: '$channel'})
    wiredData({error, data}) {
        if (data) {
            let objStr = JSON.parse(data);
            objStr.map(element=>{
                this.results = [...this.results,{title:element.title, url:element.url}]
            });  
            this.error = undefined;            
        } else if (error) {
            this.error = error;
            this.results = undefined;
        }
    }
}