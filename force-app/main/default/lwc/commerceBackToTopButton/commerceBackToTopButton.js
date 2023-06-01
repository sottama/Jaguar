import { LightningElement, api, track } from 'lwc';

export default class CommerceBackToTopButton extends LightningElement {

    @api desiredOffset;
    @track showButton = false;

    get showButton() {
        return this.showButton;
    }
    connectedCallback() {
        window.addEventListener(
            "scroll",
            () => {
                if(window.scrollY > this.desiredOffset){
                    this.showButton = true 
                }
                else{
                    this.showButton = false 
                }
            },
            false
        );
    }

    // When the user clicks on the button, scroll to the top of the document
    topFunction(e) {
        document.body.scrollTop = 0; // For Safari
        document.documentElement.scrollTop = 0; // For Chrome, Firefox, IE and Opera
    }


}