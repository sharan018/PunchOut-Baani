import { LightningElement,api,track,wire } from 'lwc';
import NoImageContent from "@salesforce/resourceUrl/NoImageContent";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import saveSO from '@salesforce/apex/PunchOutRequestController.saveCart';

export default class QuickViewProductLwc extends LightningElement {

    @api selectedTab;
    @api completeWrap;
    @api selectcustomeid;
    @api quickviewSizer;
    @api quickviewprod;
    @api labelQuickview;
    @api quickviewedProduct;
    @track quickviewedProduct;
    @api catalogVertical;
    @track catalogVertical = true;

    @track completeWrap;
    @track isSelectAll = false;
    @track isShipcmp = false;
    @track selectedRetailer;
    @track selectedRetailercode;
    @track quickviewedIndex;
    @track proImgURL;
    @track proAdditionImgURL=[];
    @track selectedColorKey;
    @track productImgURL;
    @track NoImageContent;
    @track mCareTab;
    @track isCurrencyType;
    @track isFullboxQty;
    @track labelTickectTab;
    @track hangerBusinessTab;
    @track addcartbuttoncss ='slds-button slds-button_destructive slds-button_red';
    @track addcartbuttoncss2;
    @track closeicon ='slds-button slds-button_icon slds-button_icon-inverse';
    @track qty;
    @track disableAddToCartBtn;
    @track productIncart;

    connectedCallback(){
        
        var getQuickViewProduct = JSON.parse(JSON.stringify(this.quickviewedProduct));

           getQuickViewProduct.tempMap.forEach(childElement => {
             console.log('selectedColor ;;;;->' + JSON.stringify(this.quickviewedProduct.selectedColor));

             console.log('key  ;;;;->' + JSON.stringify(childElement.key));
             console.log('if cond --> '+ (childElement.key == this.quickviewedProduct.selectedColor));
            if (childElement.key == this.quickviewedProduct.selectedColor) {
                childElement.keyAndColor = true;
            console.log('addedToCart inside ;;;;->' + JSON.stringify(childElement.value.addedToCart));
            if(childElement.value.addedToCart == true){
                this.productIncart = true;
            }else{
                this.productIncart = false;
                this.addcartbuttoncss2 = 'slds-button slds-button_destructive slds-button_red';
            }
                // console.log('childElement.keyAndColor '+childElement.keyAndColor);
            } else {
                childElement.keyAndColor = false;
                // console.log('childElement.keyAndColor else '+childElement.keyAndColor);
            }

            //  console.log('proAdditionalImgURL ;;;;->' + JSON.stringify(this.quickviewedProduct.tempMap[0].value.proImgURL));
             this.productImgURL = this.quickviewedProduct.tempMap[0].value.proImgURL;
             console.log('productImgURL '+this.productImgURL);
            //  console.log('proImgURL ;;;;->' + JSON.stringify(childElement.value.proImgURL));
            if(childElement.value.proImgURL){
                childElement.isProImgURL =true;
                // console.log('childElement.isProImgURL '+childElement.isProImgURL);
            }
            else{
                childElement.isProImgURL =false;
                // console.log('childElement.isProImgURL '+childElement.isProImgURL);
            }

            console.log('currencyType ;;;;->' + JSON.stringify(childElement.value.currencyType));
            
            if(childElement.value.currencyType != 'NA'){
                childElement.isCurrencyType =true;
                // console.log('childElement.isCurrencyType '+childElement.isCurrencyType);
            }
            else if(childElement.value.currencyType == 'NA'){
                childElement.isCurrencyType =false;
                // console.log('childElement.isCurrencyType '+childElement.isCurrencyType);
            }

            console.log('fullboxQty ;;;;->' + JSON.stringify(childElement.value.fullboxQty));

            if(childElement.value.fullboxQty){
                childElement.isFullboxQty =true;
                // console.log('childElement.isFullboxQty '+childElement.isFullboxQty);
            }
            else if(childElement.value.fullboxQty == ''){
                childElement.isFullboxQty =false;
                // console.log('childElement.isFullboxQty '+childElement.isFullboxQty);
            }
        });

        this.quickviewedProduct = getQuickViewProduct;

        if(this.selectedTab){
        if(this.selectedTab == 'MCare'){
            this.mCareTab = true;
        }
        else{
        this.mCareTab = false;
        }

        if(this.selectedTab == 'Labels & Tickets'){
            this.labelTickectTab = true;
        }else{
            this.labelTickectTab = false;
        }

        if(this.selectedTab = 'Hanger Business'){
            this.hangerBusinessTab = true;
        }else{
            this.hangerBusinessTab = false;
        }

    }
    // if(this.qty != null){
    //     this.disableAddToCartBtn = true;
    // }else{
    //     this.disableAddToCartBtn = false;
    // }

    }


    handleQuantity(event){
        var quanty = event.target.value;
        this.qty = quanty;
         console.log('quantity --> '+this.qty);
    }


    close(event){
    this.quickviewprod = false;
    this.quickviewSizer = false ;
    this.displayPagination = true;
    this.catalogVertical = true;
   var compEvent = new CustomEvent("closevent", {detail: {param1: 'true'}});
   this.dispatchEvent(compEvent); 
    }


    colorChange(event) {
     var ind = event.target.name;
    //  alert('ind--> '+ind);
    var color = event.target.title;
    alert('color --> '+color);
    var completeWrap = JSON.parse(JSON.stringify(this.quickviewedProduct));
    completeWrap.selectedColor = color;
    alert('quickviewedProduct color change --> '+JSON.stringify(completeWrap.selectedColor ));
    this.quickviewedProduct = completeWrap;
    console.log('quick viewed Product  --> '+JSON.stringify(this.quickviewedProduct));
    console.log('quickviewedProduct color change --> '+JSON.stringify(this.quickviewedProduct.selectedColor));
    this.connectedCallback();
    }

    changeImage(event){
        var imageAdditional = event.target.src;
        // Get the target image element
        var image = this.template.querySelector('.geeks');
        // Set the source of the target image
        image.src = imageAdditional;
    }

    saveproddata(event){
        var ind = event.target.name;
        var key = event.target.getAttribute('data-record');
        var indexval = ind + ' ' + key;

        this.saveToCart(indexval);
    }


    saveToCart(indexval){
        var custid = this.selectcustomeid;
        // console.log('quickviewedProduct'+JSON.stringify(this.quickviewedProduct));
        var productData = this.quickviewedProduct;
        // console.log('hiii>>'+JSON.stringify(this.quickviewedProduct));
        var selectedColor = productData.selectedColor;
        var priceBook;
        var quantity;
        var boxquantity;
        var fullboxQty;
        var MOQ;
        var result;

        for(var i=0;i<productData.tempMap.length;i++)
        {
            if(productData.tempMap[i].key==selectedColor)
            {
                fullboxQty=productData.tempMap[i].value.fullboxQty;
                priceBook = productData.tempMap[i].value;
                //alert(JSON.stringify(priceBook.priceByCurr));
                //quantity = productData.tempMap[i].quantity;
                quantity = this.qty;
                boxquantity=productData.tempMap[i].value.boxquantity;
                MOQ=productData.tempMap[i].value.MOQ;
            }
        }

        if(!quantity || quantity<=0)
        {
            const toastEvent = new ShowToastEvent({
                title: 'warning',
                message: 'Entered Product Quantity is not valid',
                variant: 'warning'
            });
            this.dispatchEvent(toastEvent);
            return;
        }
        else if(quantity)
        {       
            for(var i=0;i<productData.tempMap.length;i++)
            {
                if(quantity < MOQ && boxquantity && (quantity<boxquantity || (quantity % boxquantity)!=0) && fullboxQty)
                {
                    result = Math.ceil(MOQ/boxquantity)*boxquantity;
                    if(productData.tempMap[i].key==selectedColor)
                    {
                        if (!confirm(("Order Quantity for Product")+productData.Name+("is less then Minimum Order Quantity MOQ") + (MOQ) + ".\n" + ("The nearest multiples of box quantity") + ( result ) + ".\n" + ("Click OK to confirm Order Quantity") + ( result ) + ("and add it in the CART"))) 
                    	{
                            return; 
                        } 
                    }
                    productData.tempMap[i].quantity=result;
                }
                else if(quantity < MOQ && boxquantity && (MOQ<boxquantity || (MOQ % boxquantity)!=0) && fullboxQty)
                {
                    result = Math.ceil(MOQ/boxquantity)*boxquantity;
                    if(productData.tempMap[i].key==selectedColor)
                    {
                        if (!confirm(("Order Quantity for Product")+productData.Name+("is less then Minimum Order Quantity MOQ") + (MOQ) + ".\n" + ("The nearest multiples of box quantity") + ( result ) + ".\n" + ("Click OK to confirm Order Quantity") + ( result ) + ("and add it in the CART")))                     	{
                            return; 
                        } 
                    }
                    productData.tempMap[i].quantity=result;
                }
                else if(quantity < MOQ )
                {
                    if(productData.tempMap[i].key==selectedColor)
                    {
                        if (!confirm(("Order Quantity for Product")+productData.Name+("is less then Minimum Order Quantity MOQ") + ( MOQ ) + ".\n" + ("Click OK to confirm Order Quantity") + ( MOQ ) + ("and add it in the CART"))) 
                    	{
                            return; 
                        } 
                    }
                    productData.tempMap[i].quantity=MOQ;
                }
                else if(fullboxQty && boxquantity &&(quantity<boxquantity || (quantity % boxquantity)!=0))
                {
                    result = Math.ceil(quantity/boxquantity)*boxquantity;
                    if(productData.tempMap[i].key==selectedColor)
                    {
                        if (!confirm(("Order Quantity for Product")+productData.Name+("is not the multiples of Box quantity") + ".\n" + ("The nearest multiples of box quantity") +  ( result ) + ".\n" + ("Click OK to confirm Order Quantity") + ( result ) + ("and add it in the CART")))
                        {
                            return; 
                        } 
                    }
                    productData.tempMap[i].quantity=result;
                }
                else
                {
                    productData.tempMap[i].quantity=quantity;
                } 
            }
            this.quickviewedProduct = productData;
            console.log('productData --> '+this.quickviewedProduct);
        }
        // console.log('customerData --> '+custid);
        // console.log('priceBook --> '+JSON.stringify(priceBook));
        // console.log('retailercode --> '+priceBook.retailercodeId);
        // console.log('quantity --> '+productData.tempMap[0].quantity);
        // console.log('priceBookProId --> '+priceBook.priceBookId);            
        // console.log('priceByCurr --> '+priceBook.priceByCurr);


        saveSO({
            customerData : custid,
            retailercode : priceBook.retailercodeId,
            quantity :productData.tempMap[0].quantity,
            priceBookProId : priceBook.priceBookId,
            priceByCurr : priceBook.priceByCurr
        })
        .then(result=>{
            if(result){
                console.log('saveSO result --> '+JSON.stringify(result));
                const toastEvent = new ShowToastEvent({
                    title: 'success',
                    message: 'Product added to cart successfully',
                    variant: 'success'
                });
                this.dispatchEvent(toastEvent);
                setTimeout(() => {
                    location. reload();
                    // eval("$A.get('e.force:refreshView').fire();");
                }, 2000);
                return;
            }
        })
        .catch(error=>{
            if(error){
            console.log("Error --> "+error);
            const toastEvent = new ShowToastEvent({
                title: 'Error',
                message: 'Add to cart Failed',
                variant: 'Error'
            });
            this.dispatchEvent(toastEvent);
            return;
        }else{
            console.log("Unknown error");
        }
        })
    }


    get NoImageContent(){
        return NoImageContent;
    }

}