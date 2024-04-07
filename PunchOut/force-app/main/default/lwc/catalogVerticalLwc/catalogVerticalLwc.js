import { LightningElement,track,api } from 'lwc';
import saveSO from '@salesforce/apex/PunchOutRequestController.saveCart';
import addBulkProduct from '@salesforce/apex/PunchOutRequestController.addBulkProduct';
import NoImageContent from "@salesforce/resourceUrl/NoImageContent";
import CUST_MODEL_LABEL from '@salesforce/label/c.Cust_Model';
import Price_100 from '@salesforce/label/c.Price_100';
import Price_1000 from '@salesforce/label/c.Price_1000';
import UOM_Price from '@salesforce/label/c.UOM_Price';
import Order_Quantity_for_Product from  '@salesforce/label/c.Order_Quantity_for_Product';
import is_less_then_Minimum_Order_Quantity_MOQ from '@salesforce/label/c.is_less_then_Minimum_Order_Quantity_MOQ'
import Box_Quantity from '@salesforce/label/c.Box_Quantity';
import is_not_the_multiples_of_Box_quantity from '@salesforce/label/c.is_not_the_multiples_of_Box_quantity';
import and_add_it_in_the_CART from '@salesforce/label/c.and_add_it_in_the_CART';
import The_nearest_multiples_of_box_quantity from  '@salesforce/label/c.The_nearest_multiples_of_box_quantity';
import Click_OK_to_confirm_Order_Quantity from '@salesforce/label/c.Click_OK_to_confirm_Order_Quantity';
import Select from '@salesforce/label/c.Select';
import SelectLabel from '@salesforce/label/c.Select_Label';
import Qty from '@salesforce/label/c.Qty';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';



export default class CatalogVerticalLwc extends LightningElement {
    @track catalogVertical=true;@track flagFamily =true;@track parentcmp=false; @track quickViewLabel='Quick View'; @api parentData =[]; @api selectedTabs;  @track tempValue;
    @track fethparentdata;   @track proPricedata;@track proPriceBy1000data2nd =false;@track currencyType; @track uomPrice;@track notlabelsampandtickets;@track HangerBusiness;
    @track MCare;@track displayPagination;@track sizerhanger = false;@api sizerIndex;@track sizerIndex;  clickedIndices = [];@api selectedCustomeId;@track indexvalues;@track indexarry; 
    @api selectedCurrencys; @api searchedCurrencys;@track quantity;@api callchildForbulkdatas;@api retailerCodes;@track getParentDtaforAddtocart; @track outputText;
    @track LabelQuickview=false;@api quickviewedProduct;@track quickview=false;@track quickviewSizer=false;  @track fullboxQtys; @track showPrices;
    @track vardataproduct; @track Novardataproduct;@track Labelsamp;@track OrderQuantityForProduct=Order_Quantity_for_Product;@track clickok =Click_OK_to_confirm_Order_Quantity;
    @track noImageContentResource=('background:url('+NoImageContent+')');@track minimumOrderQuantity=is_less_then_Minimum_Order_Quantity_MOQ;@track nearest=The_nearest_multiples_of_box_quantity;
    @track additinthecart =and_add_it_in_the_CART;@track isnotmultipleBox =is_not_the_multiples_of_Box_quantity;
    @track getquantityfield; @track vardatproductNo; @track vardatproductYes;@track productvardata=true;@track careLabelOrder =false;
    @track newQtyArr =[]; @api selectedCompany;@track selectedCompany;@track parentData =[];@track addedToCartcls; @track addedToCartcls2;
    @track addedAsLabel;@track addedToCartcls3;@track addedAsLabel4 ='Added';@track addedAsLabel2 ='Pending';
    @track addcartbuttoncss ='slds-button slds-button_destructive slds-button_red';@track addcartbuttoncss2 ='slds-button slds-button_destructive slds-button_red';
    @track proImgURLsimage;@track selectedkeycolor=false;
    @track productlistfromparent =[];@api loadedcareLabelSelectedDataList=[];

     renderedCallback(){
        console.log();
     }
     connectedCallback(){
        console.log('in catalogvertical9999000>'+JSON.stringify(this.parentData));
        this.setupConditions(); 
        console.log('after setup');
        console.log('selectedTabs ?>>'+this.selectedTabs);
        if(this.selectedTabs =='Labels & Tickets'){
            this.quickview=false;
            this.Labelsamp=true;
        }

       
        //this.parentData = JSON.parse(JSON.stringify(this.parentData));
       // this.setuphtml();
    }

   
    @api
    setuphtml(){
        //alert('inside setuphtml;');
        //this.connectedCallback();
        var getparentwrapper =JSON.parse(JSON.stringify(this.parentData));
  console.log('setuphtml --::>>'+JSON.stringify(getparentwrapper));
  getparentwrapper.forEach(element => {
        element.tempMap.forEach(childElement =>{
            if(childElement.value.vardataproduct=='Yes'){
                childElement.noVarProd = true;
            }else{
                childElement.noVarProd = false;
            }
            console.log('selectedColor ;;;;->'+JSON.stringify(element.selectedColor));
                console.log('key  ;;;;->'+JSON.stringify(childElement.key));
            if(childElement.key == element.selectedColor){
                childElement.selectedColorKey =true;
            }
            else{
                childElement.selectedColorKey =false;
            }
            
        }); 
    });
  
    

this.parentData =getparentwrapper;
// this.parentData = JSON.parse(JSON.stringify(this.parentData));
console.log('last parentdata -->'+JSON.stringify(this.parentData));
// this.notlabelsampandtickets =true;
this.connectedCallback();
    }

    handleset(event){
        // alert('country-->'+event.detail.country+'  value--> '+event.detail.catalogVertical);
        this.sizerhanger = false;
        this.LabelQuickview = true;
        this.catalogVertical = event.detail.catalogVertical;
         this.selectedCompany = event.detail.country; 
         var selectComp = event.detail.country;

         const selectedEvent = new CustomEvent("handleset", { detail: {country:selectComp} });
         this.dispatchEvent(selectedEvent);
    }

        setupConditions(){
           // alert('inside child');
            var datas= '';
            var showPicklistPricedatas='';
            var proPriceBy1000data='';
            var currency ='';
            var uomPrice ='';
            var vardataproduct ='';
            var fullboxQty='';
            var showPrice='';
            var vardatproductNo ='';
            var vardatproductYes ='';
            var addprodct='';
            var labelforadded ='';
            var proImgURLs ='';
            var getimageurl ;
            var equalproducts ;

                const fethparentdata =this.parentData;
                this.getParentDtaforAddtocart=this.parentData;
            
            if(this.parentData){
            var getparentwrapper =JSON.parse(JSON.stringify(this.parentData));
            console.log('vrapdataa --::>>'+JSON.stringify(getparentwrapper));
            getparentwrapper.forEach(element => {
                    element.tempMap.forEach(childElement =>{
                        if(childElement.value.vardataproduct=='Yes'){
                            childElement.noVarProd = true;
                        }else{
                            childElement.noVarProd = false;
                        }
                        console.log('selectedColor ;;;;->'+JSON.stringify(element.selectedColor));
                            console.log('key  ;;;;->'+JSON.stringify(childElement.key));
                        if(childElement.key == element.selectedColor){
                            childElement.selectedColorKey =true;
                        }
                        else{
                            childElement.selectedColorKey =false;
                        }
                        
                    }); 
                });
            

            this.parentData =getparentwrapper;
            this.productlistfromparent =this.parentData;
            
                console.log('vrapdataaafter4444444444 ---'+JSON.stringify(this.parentData));
                console.log('vrapdataaafter5555555 ---'+JSON.stringify(this.productlistfromparent));
                for(var i=0; i<fethparentdata.length; i++){
                    for(var j=0; j<fethparentdata[i].tempMap.length; j++){
                    
                        datas=fethparentdata[i].tempMap[j].value.proPrice;
                        showPicklistPricedatas=fethparentdata[i].tempMap[j].value.showPicklistPrice;
                        proPriceBy1000data=fethparentdata[i].tempMap[j].value.proPriceBy1000;
                        currency=fethparentdata[i].tempMap[j].value.currencyType;
                        uomPrice=fethparentdata[i].tempMap[j].value.uomPrice;
                        fullboxQty=fethparentdata[i].tempMap[j].value.fullboxQty;
                        showPrice=fethparentdata[i].tempMap[j].value.showPrice;
                        addprodct=fethparentdata[i].tempMap[j].value.addedToCart;
                        labelforadded=fethparentdata[i].tempMap[j].value.addedAsLabel;
                    // proPrices =fethparentdata[i].tempMap[j].value.proPrice;
                        proImgURLs=fethparentdata[i].tempMap[j].value.proImgURL;
                        this.proImgURLsimage =('background:url('+proImgURLs+')');
                        console.log('proImgURLs >>::>'+fethparentdata[i].Id);

                        // this.proImgURLsimage ='background:url('+proImgURLs+')';
                        //  console.log('proimage >>'+this.proImgURLsimage);
                        // if(fethparentdata[i].tempMap[j].key ==  fethparentdata[i].selectedColor){
                        //     alert('inside condition')
                        //     console.log('selectedColor ;;;;->'+JSON.stringify(fethparentdata[i].selectedColor));
                        //     console.log('key  ;;;;->'+JSON.stringify(fethparentdata[i].tempMap[j].key));
                        //    this.selectedkeycolor =true;
                        //    alert(this.selectedkeycolor);
                        // }
            
        }
    }
    
    
    if(addprodct ==true){
        this.addedToCartcls ='item-inner Selected_BG';
        this.addedToCartcls2='slds-show';
        this.addedToCartcls3='icon-sale-label inCart_font-size sale-right Added';
       // this.addcartbuttoncss='slds-button slds-button_destructive slds-button_red slds-button_red-disabled';
       // this.addcartbuttoncss2='slds-button slds-button_destructive slds-button_red slds-button_red-disabled';
       // this.addedAsLabel4=;
    }
    else if(addprodct ==false){
        this.addedToCartcls='item-inner';
       // this.addedToCartcls2='slds-hide';
      this.addcartbuttoncss='slds-button slds-button_destructive slds-button_red';
    }
 if(labelforadded ==true){
    this.addedAsLabel ='icon-sale-label inCart_font-size sale-left Pending';
    //this.addedAsLabel2='Pending';
 }
  
 
if(datas !=null && showPicklistPricedatas =='100'){
this.proPricedata=true;
}
else{
    this.proPricedata=false;  
}
if(proPriceBy1000data !=null && showPicklistPricedatas =='1000'){
this.proPriceBy1000data2nd=true;
}
else{
    this.proPriceBy1000data2nd=false; 
}
 if(currency !=null){
    this.currencyType =true;
}
else{
    this.currencyType =false;
}
if(fullboxQty ==true){

    this.fullboxQtys=true;
}
else{
    this.fullboxQtys=false;
}
if(showPrice ==true){
this.showPrices=true;
}
else{
    this.showPrices=false; 
}
if(vardataproduct =='Yes'){
this.vardataproduct=true;

}
else{
    this.vardataproduct=false; 
}
if(vardataproduct =='No'){
    this.Novardataproduct=true;
}
else{
    this.Novardataproduct=false;
}
 if(uomPrice !=null && showPicklistPricedatas=='UOM'){
    this.uomPrice=true;
}
else{
    
     this.uomPrice=false;

}
if(vardatproductYes ==false){
    this.vardatproductYes =true;
}
else{
    this.vardatproductYes =false; 
}
if(vardatproductNo ==false){
    this.vardatproductNo=true;
}
else{
    this.vardatproductNo=false;
}
const selectedTabs =this.selectedTabs;
if(selectedTabs !='Labels & Tickets'){
    console.log('selected tab made true');
    this.notlabelsampandtickets=true;
}
if(selectedTabs =='MCare'){
    this.MCare=true;
}
if(selectedTabs == 'Labels & Tickets'){
    this.Labelsamp=true;
}
 else if(selectedTabs =='Hanger Business'){
    this.HangerBusiness=true;
}

else{
    this.MCare=false;
    this.Labelsamp=false;

    this.HangerBusiness=false;
    this.notlabelsampandtickets=false;
}
}



    }
get labelQty() {
    return Qty;
}

    get custModelLabel() {
        return CUST_MODEL_LABEL;
    }
    get Price100(){
        return Price_100;
    }
    get Price1000(){
        return Price_1000;
    }
    get UOMPrice(){
        return UOM_Price;
    }
    get BoxQuantity(){
        return Box_Quantity;
    }
    get labelSelect(){
        return Select;
    }
    get labelValue(){
        return SelectLabel;
    }
 
    quickviewcmp(event) {
        alert('this.selectedTabs'+this.selectedTabs);
        alert("currtName --> "+event.target.name);
        alert(this.parentData[event.target.name].productfamily);
        if (this.selectedTabs == 'Labels & Tickets') {
            alert('insdie');
            alert('catalogVertical 1'+(this.catalogVertical));
            
            this.quickviewedProduct = this.parentData[event.target.name];
        } else {
            this.quickviewedProduct = this.parentData[event.target.name];
            
            console.log('quickviewedProduct--> '+JSON.stringify(this.quickviewedProduct));
        }
        alert('catalogVertical 2'+(this.catalogVertical));
        if (this.parentData[event.target.name].productfamily.includes('SIZER')) {
            //  alert('inside if Sizer --> '+this.parentData[event.target.name].productfamily.includes('SIZER'));
            this.sizerIndex = event.target.name;
            this.quickviewSizer = true;
            
        } else if (this.selectedTabs === 'MCare' && this.parentData[event.target.name].tempMap[0].value.vardataproduct === 'Yes') {
            this.sizerIndex = event.target.name;
            this.quickviewSizer = true;

        } else {
            alert('quickview');
            this.quickview = true;
        }
    }
    handleSizerProduct(event) {
        // alert('onselect');
        this.sizerIndex = event.target.name;
        // alert('this.sizerIndex -->'+this.sizerIndex);
        this.sizerhanger = true;
        this.catalogVertical = false;
        this.displayPagination = false;
    }
    colorChange(event) {
        const ind = parseInt(event.target.name);
    const color = event.target.id;
    const completeWrap = JSON.parse(JSON.stringify(this.parentData));
    completeWrap[ind].selectedColor = color;
    this.parentData = completeWrap;

    }

    handleQtyChange(event) {
        // let disableBulkAddButton = new CustomEvent("disablebulkaddbutton", {
        //     detail: { buttonDisabled: false }
        // });
        // this.dispatchEvent(disableBulkAddButton);
    
    var updatedQuantity = event.target.value; 
    alert('qty --> '+ event.target.value);
    this.outputText=updatedQuantity;
    this.getquantity=updatedQuantity;
    var getId = event.target.dataset.id;
    console.log('getId -->'+getId);
    let existingEntryIndex = this.newQtyArr.findIndex(entry => entry.id === getId);

    if (existingEntryIndex !== -1) {
        if (this.orderQnty === "") {
            this.newQtyArr.splice(existingEntryIndex, 1);
        } else {
            this.newQtyArr[existingEntryIndex].Qty = this.orderQnty;
        }
    } else {
        this.newQtyArr.push({
            'id': getId,
            'Qty': updatedQuantity
        });
    }
    console.log('newQtyArr>>' + JSON.stringify(this.newQtyArr));
      
    }   
   
    handleAddToCart(event) {   
    this.addcartbuttoncss2='slds-button slds-button_destructive slds-button_red slds-button_red-disabled';     
    // const index = event.currentTarget;  
    const ind = event.target.name;
    const key = event.target.getAttribute('data-record');
    const indexval = ind + ' ' + key;
    this.indexvalues=indexval;
    this.saveToCart();

    }
    
saveToCart(event){   
    const custid =this.selectedCustomeId;
    this.indexarry=this.indexvalues;
    const values=this.indexarry;
    var indexarr = values.split(" ");
let completeData = [...this.parentData]; 
let qty= this.outputText;
let productData = this.parentData[indexarr[0]];
const qua =this.quantity;
console.log(('productData :'+JSON.stringify(productData)));
let retailercode = productData.tempMap[indexarr[1]].value.retailercodeId;
let getvalues=(productData.tempMap[indexarr[1]]);
let boxquantity = productData.tempMap[indexarr[1]].value.boxquantity;
let fullboxQty = productData.tempMap[indexarr[1]].value.fullboxQty;
let MOQ = productData.tempMap[indexarr[1]].value.MOQ;

let currency;
if (productData.tempMap[indexarr[1]].value.priceByCurr) {
    currency = productData.tempMap[indexarr[1]].value.priceByCurr;
}
let custRefModel = this.parentData[indexarr[0]].tempMap[indexarr[1]].value.custRefModel;
let result = Math.ceil(qty / boxquantity) * boxquantity;

if (!qty || qty <= 0) {
    const toastEvent = new ShowToastEvent({
        title: 'warning',
        message: 'Entered Product Quantity is not valid',
        variant: 'warning'
    });
    this.dispatchEvent(toastEvent);

    return;
} else if (qty < MOQ && boxquantity && (qty < boxquantity || qty % boxquantity !== 0) && fullboxQty) {
    result = Math.ceil(MOQ/boxquantity)*boxquantity;
    if (!confirm('Order Quantity for ' + this.parentData[indexarr[0]].Name + ' is less than Minimum Order Quantity (MOQ) of ' + MOQ + '. The nearest multiples of box quantity is ' + result + '. Click OK to confirm Order Quantity of ' + result + ' and add it to the CART.')) {
        return;
    }
    qty = result; 
    completeData[indexarr[0]] = productData;
    this.parentData = completeData;
}else if (qty < MOQ && boxquantity && (MOQ < boxquantity || MOQ % boxquantity !== 0) && fullboxQty) {
    result = Math.ceil(MOQ/boxquantity)*boxquantity;
    
    if (!confirm('Order Quantity for ' + this.parentData[indexarr[0]].Name + ' is less than Minimum Order Quantity (MOQ) of ' + MOQ + '. The nearest multiples of box quantity is ' + result + '. Click OK to confirm Order Quantity of ' + result + ' and add it to the CART.')) {
        return;
    }
    qty  = result; 
    completeData[indexarr[0]] = productData;
    this.parentData = completeData;
}

else if (qty < MOQ) {
    if (!confirm('Order Quantity for ' + this.parentData[indexarr[0]].Name + ' is less than Minimum Order Quantity (MOQ) of ' + MOQ + '. Click OK to confirm Order Quantity of ' + MOQ + ' and add it to the CART.')) {
        return;
    }
    qty  = MOQ;
    completeData[indexarr[0]] = productData;
    this.parentData = completeData;
} else if (fullboxQty && boxquantity && (qty < boxquantity || qty % boxquantity !== 0)) {
    if (result) {
        if (!confirm('Order Quantity for ' + this.parentData[indexarr[0]].Name + ' is not a multiple of Box Quantity. The nearest multiples of box quantity is ' + result + '. Click OK to confirm Order Quantity of ' + result + ' and add it to the CART.')) {
            return;
        }

     
    qty = result; 
        completeData[indexarr[0]] = productData;
        this.parentData = completeData;
    } else {
        return;
    }
}

const PricebookData = productData.tempMap[indexarr[1]].value.priceBookId;


saveSO({
    customerData:custid,
    retailercode : retailercode,
    quantity : qty,
    priceBookProId : PricebookData,
    priceByCurr : currency,
    custRefModel : custRefModel,
    selectedCurrency:this.selectedCurrencys,
    searchedCurrency:this.searchedCurrencys
})
.then(result => {
    console.log('state:::SUCCESS'+JSON.stringify(result));
    const toastEvent = new ShowToastEvent({
        title: 'Success',
        message: 'Product added to cart successfully',
        variant: 'success'
    });
    this.dispatchEvent(toastEvent);
     this.parentData=' ';
     refreshApex(this.saveSO);
     window.location.reload();

   // eval("$A.get('e.force:refreshView').fire();");
})
.catch(error => {
    console.error('Error message: ' + error.message);

    const toastEvent = new ShowToastEvent({
        title: 'Error',
        message: 'Add to cart Failed',
        variant: 'error'
    });
    this.dispatchEvent(toastEvent);

    if (Array.isArray(error) && error.length > 0) {
        console.error('Error message: ' + error[0].message);
    } else {
        console.error('Unknown error');
    }
});


    }

    saveBulkToCart(retailerCodeId,bulkCartDataToSave){

        const custid =this.selectedCustomeId;

        addBulkProduct({
            custid:custid,
            retailerCodeId:retailerCodeId,
            bulkCartDataToSave:JSON.stringify(bulkCartDataToSave),
            selectedCurrency:this.selectedCurrencys,
            searchedCurrency:this.searchedCurrencys
        })
        .then(result =>{
            const evt = new ShowToastEvent({
                title: 'Toast Success',
                message: 'Product added to Cart Successfull',
                variant: 'success',
                mode: 'dismissable'
            });
            this.dispatchEvent(evt)
            window.location.reload();
        })
        .catch(error => {
            const toastEvent = new ShowToastEvent({
                title: 'Error',
                message: 'Add to cart failed',
                variant: 'error'
            });
            this.dispatchEvent(toastEvent);
            console.error('Error message: ' + error.message);

        });
    }
    @api  
    getBulkData(event) {
        var addBulkcart = JSON.parse(JSON.stringify(this.parentData));
        var bulkCartDataToSave=[];
        var retailerCodeId='';
        var result;
        console.log('before displayCarcompletewrapParentDatatDetail' + JSON.stringify(addBulkcart));
        for (let i = 0; i < this.newQtyArr.length; i++) {
            for(var j=0;j<addBulkcart.length;j++)
            {  
                
                 for(var k=0;k<addBulkcart[j].tempMap.length;k++) {
                    console.log('Id' + JSON.stringify(addBulkcart[j].Id));
                if (addBulkcart[j].Id == this.newQtyArr[i].id) {
                    addBulkcart[j].tempMap[k].quantity = this.newQtyArr[i].Qty;
                    console.log('updated displayCartDetail' + JSON.stringify(addBulkcart));
                 } 
             }
            
            }
        }
        this.parentData = addBulkcart;
        var completeWrap = JSON.parse(JSON.stringify(this.parentData));
      
        for(var i=0;i<completeWrap.length;i++)
        {
            
            console.log('inside forloop'+JSON.stringify((completeWrap[i])));
            for(var j=0;j<completeWrap[i].tempMap.length;j++)
            {
                if(completeWrap[i].tempMap[j].quantity && !completeWrap[i].tempMap[j].value.addedToCart)
                {
                    //alert('MOQ>>'+completeWrap[i].tempMap[j].value.MOQ);
                    result = Math.ceil(completeWrap[i].tempMap[j].value.quantity/completeWrap[i].tempMap[j].value.boxquantity)*completeWrap[i].tempMap[j].value.boxquantity;
                  
                    
                    // alert('result :::'+completeWrap[i].tempMap[j].quantity )
                    if(!completeWrap[i].tempMap[j].quantity || completeWrap[i].tempMap[j].quantity<=0)
                    {    
                        const toastEvent = new ShowToastEvent({
                            title: 'warning',
                            message: 'Entered Product Quantity is not valid'+' '+"for"+' '+completeWrap[i].tempMap[j].value.MainettiModelCode,
                            variant: 'warning'
                        });
                        this.dispatchEvent(toastEvent);
                        return;
                    }else{
                                            
                    if(completeWrap[i].tempMap[j].quantity < completeWrap[i].tempMap[j].value.MOQ && completeWrap[i].tempMap[j].value.boxquantity && completeWrap[i].tempMap[j].value.fullboxQty &&(completeWrap[i].tempMap[j].quantity<completeWrap[i].tempMap[j].value.boxquantity || completeWrap[i].tempMap[j].quantity % completeWrap[i].tempMap[j].value.boxquantity!=0))
                    {
                        result = Math.ceil(completeWrap[i].tempMap[j].value.MOQ / completeWrap[i].tempMap[j].value.boxquantity)*completeWrap[i].tempMap[j].value.boxquantity;
                        if (!confirm("Order Quantity for Product"+completeWrap[i].tempMap[j].value.MainettiModelCode+"is less then Minimum Order Quantity MOQ" + ( completeWrap[i].tempMap[j].value.MOQ ) + "The nearest multiples of box quantity" + ( result ) + "Click OK to confirm Order Quantity" + ( result ) +  "and add it in the CART")) 
                        {
                            return; 
                        }
                        retailerCodeId=completeWrap[i].tempMap[j].value.retailercodeId;
                        var singlecartDataToSave={"color":completeWrap[i].tempMap[j].key,"pricebookId":completeWrap[i].tempMap[j].value.priceBookId,"quantity":result,"cur":completeWrap[i].tempMap[j].value.priceByCurr,"custRefModel":completeWrap[i].tempMap[j].value.custRefModel};
                        bulkCartDataToSave.push(singlecartDataToSave);
                    } 
                    else if(completeWrap[i].tempMap[j].quantity < completeWrap[i].tempMap[j].value.MOQ && completeWrap[i].tempMap[j].value.boxquantity && completeWrap[i].tempMap[j].value.fullboxQty &&(completeWrap[i].tempMap[j].value.MOQ <completeWrap[i].tempMap[j].value.boxquantity || completeWrap[i].tempMap[j].value.MOQ % completeWrap[i].tempMap[j].value.boxquantity!=0))
                    {
                        result = Math.ceil(completeWrap[i].tempMap[j].value.MOQ / completeWrap[i].tempMap[j].value.boxquantity)*completeWrap[i].tempMap[j].value.boxquantity;
                        if (!confirm("Order Quantity for Product"+completeWrap[i].tempMap[j].value.MainettiModelCode+"is less then Minimum Order Quantity MOQ" + ( completeWrap[i].tempMap[j].value.MOQ ) + "The nearest multiples of box quantity" + ( result ) + "Click OK to confirm Order Quantity" + ( result ) + "and add it in the CART")) 
                        {
                            return; 
                        }
                        retailerCodeId=completeWrap[i].tempMap[j].value.retailercodeId;
                        var singlecartDataToSave={"color":completeWrap[i].tempMap[j].key,"pricebookId":completeWrap[i].tempMap[j].value.priceBookId,"quantity":result,"cur":completeWrap[i].tempMap[j].value.priceByCurr,"custRefModel":completeWrap[i].tempMap[j].value.custRefModel};
                        bulkCartDataToSave.push(singlecartDataToSave);
                    }
                     else if(completeWrap[i].tempMap[j].quantity < completeWrap[i].tempMap[j].value.MOQ )
                    {
                        if (!confirm("Order Quantity for Product"+completeWrap[i].tempMap[j].value.MainettiModelCode+"is less then Minimum Order Quantity MOQ"+( completeWrap[i].tempMap[j].value.MOQ ) + "Click OK to confirm Order Quantity"  + ( completeWrap[i].tempMap[j].value.MOQ ) + "and add it in the CART")) 
                        {
                            return;
                        }
                        retailerCodeId=completeWrap[i].tempMap[j].value.retailercodeId;
                        var singlecartDataToSave={"color":completeWrap[i].tempMap[j].key,"pricebookId":completeWrap[i].tempMap[j].value.priceBookId,"quantity":completeWrap[i].tempMap[j].value.MOQ,"cur":completeWrap[i].tempMap[j].value.priceByCurr,"custRefModel":completeWrap[i].tempMap[j].value.custRefModel};
                        bulkCartDataToSave.push(singlecartDataToSave);
                    }
                    else if(completeWrap[i].tempMap[j].value.fullboxQty && completeWrap[i].tempMap[j].value.boxquantity && (completeWrap[i].tempMap[j].quantity<completeWrap[i].tempMap[j].value.boxquantity || completeWrap[i].tempMap[j].quantity % completeWrap[i].tempMap[j].value.boxquantity!=0))
                    {
                        result = Math.ceil(completeWrap[i].tempMap[j].quantity/completeWrap[i].tempMap[j].value.boxquantity)*completeWrap[i].tempMap[j].value.boxquantity;
                        if (!confirm("Order Quantity for Product"+completeWrap[i].tempMap[j].value.MainettiModelCode+"is not the multiples of Box quantity" +"The nearest multiples of box quantity" + ( result ) + "Click OK to confirm Order Quantity"  + ( result ) +"and add it in the CART"))
                        {
                            return; 
                        }
                        retailerCodeId=completeWrap[i].tempMap[j].value.retailercodeId;
                        var singlecartDataToSave={"color":completeWrap[i].tempMap[j].key,"pricebookId":completeWrap[i].tempMap[j].value.priceBookId,"quantity":result,"cur":completeWrap[i].tempMap[j].value.priceByCurr,"custRefModel":completeWrap[i].tempMap[j].value.custRefModel};
                        bulkCartDataToSave.push(singlecartDataToSave);
                    }
                    else
                    {
                        retailerCodeId=completeWrap[i].tempMap[j].value.retailercodeId;
                        var singlecartDataToSave={"color":completeWrap[i].tempMap[j].key,"pricebookId":completeWrap[i].tempMap[j].value.priceBookId,"quantity":completeWrap[i].tempMap[j].quantity,"cur":completeWrap[i].tempMap[j].value.priceByCurr,"custRefModel":completeWrap[i].tempMap[j].value.custRefModel};
                        bulkCartDataToSave.push(singlecartDataToSave); 
                    }
                    }
                }
            }
        }
      alert('bulkCartDataToSave.length --> '+bulkCartDataToSave.length);
      console.log('retailerCodeId --> '+retailerCodeId);
      console.log('bulkCartDataToSave --> '+JSON.stringify(bulkCartDataToSave));
      
        if(bulkCartDataToSave.length>0){
            this.saveBulkToCart(retailerCodeId ,bulkCartDataToSave);
        }
    }

    selectLabel(event){
        alert("currtName --> "+event.target.name);
        this.quickviewedProduct = this.parentData[event.target.name];
        alert('selectLabel --> '+JSON.stringify(this.quickviewedProduct));
        this.quickview=true;
        this.careLabelOrder =true;
        this.LabelQuickview = true;
    }

    closeQuickView(event){
        this.quickview = false;
    }

    cancleQuickView(event){
        this.quickviewSizer =false;
        this.sizerhanger = false;
   }

   handlecarelabelselecteddatalist(event){
    var getcareselectedlist = event.detail.careLabelSelectedDataList;
    this.loadedcareLabelSelectedDataList=getcareselectedlist;
    alert('inside handlecarelabelselecteddatalist');
    console.log('getcareselectedlist1234 >>'+JSON.stringify(getcareselectedlist));
   }
}