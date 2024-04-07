import { LightningElement,api,track,wire } from 'lwc';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import productSizerDetails from '@salesforce/apex/CatalogOrderController.productSizerDetails';
import CheckCartDetailsForUpdate from '@salesforce/apex/CatalogOrderController.CheckCartDetailsForUpdate';
import addSizerProduct from '@salesforce/apex/PunchOutCatalogOrderController.addSizerProduct';
import deleteRow from '@salesforce/apex/PunchOutCatalogOrderController.deleteRow';
import getSizerList from '@salesforce/apex/PunchOutCatalogOrderController.getSizerList';
import deletedSOLI from '@salesforce/apex/CatalogOrderController.deletedSOLI';
import addSizerToCart from '@salesforce/apex/PunchOutCatalogOrderController.addSizerToCart';

import {CurrentPageReference} from 'lightning/navigation';
import {fireEvent} from 'c/pubsub';

const columns = [
    { label: 'Mainetti Model', fieldName: 'prodname' },
    { label: 'Customer Ref Model', fieldName: 'custRefModel' },
    { label: 'Color', fieldName: 'color' },
    { label: 'Size', fieldName: 'size' },
    { label: 'Quantity', fieldName: 'quantity' },
    {type: "button", initialWidth: 100, typeAttributes: {
        
        disabled: false,
        value: 'view',
        iconPosition: 'left',
        iconName:'utility:delete',
            variant:'destructive'
    }
}
];

export default class HangerSizerCmpLwc extends LightningElement {
@api sizerIndex;
@api selectedTab;
@api completeWrap;
@api selectedCompany;
@api selectedCurrency;
@api searchedCurrency;
@api retailerID;
@api selectcustomeid;
@api flagFamily;
@api displayPagination;
@api hangersizer;
@api hangerListDetail;
@api catalogVertical;
@api quickviewSizer;

columns = columns;

@track hangerListDetail;
@api cartDataList=[];
@api isActive=false;
@api isSizerQuickview;
// @track isSizerQuickview;
@track colorChartPriority;
@track customerInfoMagnetPrice;
@track disaplaySizerTxt = false;
@track disaplayGloveTxt= false;
@track selectedColor;
@track selectedSize;
@track colorlist=[];
@track sizelist=[];
@track colorSizeDependentList;


@track selectedSizer=[];
@track selectedSizer1=[];
@track selectedProduct;
@track deletedRowList=[];
@track sizerList=[];

@track deletedSOLIList=[];

@track flagFamily=true;
// @track selectcustomeid;
@track sizelist11;
@track colorSel;
@track selSize;
@track selcolor1;
@track selQty;


@track sizerListSize;
@track sizerListColor;
@track selectedSizerListSize =false;
@track selectedSizerListColor =false;
@track showQuickview;


@track loopSize=[];

@wire(CurrentPageReference) pageRef;

connectedCallback(){

    console.log('this.isSizerQuickview '+this.isSizerQuickview);
    console.log('this.completeWrap '+JSON.stringify(this.completeWrap));
    console.log('this.sizerIndex '+this.sizerIndex);
    console.log('this.selectedCompany '+JSON.stringify(this.selectedCompany));
    console.log('this.selectedCurrency '+JSON.stringify(this.selectedCurrency));
    console.log('this.flagFamily '+JSON.stringify(this.flagFamily));
    console.log('this.selectedTab '+JSON.stringify(this.selectedTab));
    

    if(this.isSizerQuickview == 'true'){
        this.showQuickview = true;
    console.log('this.showQuickview '+this.showQuickview);

    }else{
        this.showQuickview = false;
    console.log('this.showQuickview '+this.showQuickview);
    }


if(this.sizerIndex != undefined){

    var parentData = this.completeWrap[this.sizerIndex];
    var prodName = parentData.Name;
    var orderToCompany = this.selectedCompany;
    var preCurrency = this.selectedCurrency;

    this.callproductSizerDetails();
}else{
    console.log(JSON.stringify(response.getError()));
}
// this.checkCartData();
}

callproductSizerDetails(){
var parentData = this.completeWrap[this.sizerIndex];
var prodName = parentData.Name;

    productSizerDetails({
    "prodname":parentData.Name,
    "retailerCode":this.retailerID,
    "orderToCompany":this.selectedCompany,
    "preCurrency":this.selectedCurrency,
    "selectedTab" :this.selectedTab})

.then(result=>{
    //   alert('inside result');
        var colorlist=[];
        var sizelist=[];

        var res = result;
        // console.log('res>>'+JSON.stringify(result));
            this.customerInfoMagnetPrice = res.customerInfoMagnetPrice;
        // console.log('res.customerInfoMagnetPrice-->'+res.customerInfoMagnetPrice);
        // console.log('res.colorPriorityCheck-->'+res.colorPriorityCheck);
        if(res.colorPriorityCheck){
            this.colorSizeDependentList = res.colorSizeDependentList;
            for(var key in res.colorSizeDependentList){
                colorlist.push(key);
            }
            colorlist.sort();
            this.colorlist = colorlist

            var defaultColor = parentData.selectedColor?parentData.selectedColor:colorlist[0];
            this.selectedColor = defaultColor;
            // console.log('defaultColor-->'+defaultColor);
        }else{
            this.colorSizeDependentList = res.sizeColorDependentList;
            //   console.log('res.sizeColorDependentList -->>'+JSON.stringify(res.sizeColorDependentList));
                for(var key in res.sizeColorDependentList){
                    sizelist.push(key);
                }
                sizelist.sort();
                this.sizelist = sizelist;

                var defaultSize=parentData.selectedSize?parentData.selectedSize:sizelist[0];
                this.selectedColor = defaultSize;

                // component.find('sizelist').set('value',defaultSize);
                this.selSize = defaultSize;
            //  console.log('this.selSize -->'+this.selSize);
                this.colorSel = res.sizeColorDependentList[defaultSize][0];

                this.selectedColor = res.sizeColorDependentList[defaultSize][0];
                this.colorlist = res.sizeColorDependentList[defaultSize];

            //  parentData.selectedSize = defaultSize;

            console.log('sort::::::'+JSON.stringify(this.colorlist));
            console.log('sort::::::'+JSON.stringify(this.sizelist));   
            }

            this.colorChartPriority = res.colorPriorityCheck;
            // console.log('colorChartPriority>>>>>>'+JSON.stringify(this.colorChartPriority));


            this.selectedProduct = parentData;
            // console.log('selectedProduct>>>>>>'+JSON.stringify(this.selectedProduct));

            this.sizerList = res.sizerList;
            // console.log('this.sizerList -->'+JSON.stringify(this.sizerList));

            if(this.sizerList){
                var a = this.sizerList;
            for(var i=0; i<a.length ; i++){
                // console.log('this.sizerList -->'+JSON.stringify(this.sizerList));

                if(a[i].Sizer_Print__c == this.selSize){
                    if((a[i].Color__c == this.selectedColor)){
                    this.loopSize.Id = a[i].Id;
                    this.loopSize.Product_image_url__c = a[i].Product_image_url__c;
                    this.loopSize.Name = a[i].Name
                    this.loopSize.Description__c = a[i].Description__c;
                    this.loopSize.Customer_Ref_Model__c = a[i].Customer_Ref_Model__c;
                    this.loopSize.BOX_QTY__c = a[i].BOX_QTY__c;
                    this.loopSize.Full_Box_Order__c = a[i].Retailer_Code__r.Full_Box_Order__c;
                    console.log('loopsize-->'+this.loopSize);
                    this.selectedSizerListSize = true;
                }
            }
            }
            }
            this.getSizerListData(prodName);

    
})

.catch(error=>{
    alert('ERROR '+error);
})
}




getSizerListData(prodName){
var retailercode = this.retailerID;
var customerid = this.selectcustomeid;
// console.log('this.retailerID --> '+this.retailerID);
// console.log('this.selectcustomeid --> '+this.selectcustomeid);
// console.log('this.prodName --> '+prodName);

getSizerList({"retailercode":retailercode,
        "customerid":customerid,
        "prodName":prodName})

.then(result=>{
var resp = result;
var array=[];

if(result){
for(var i=0;i<resp.length;i++){
    console.log('resp.length[i]  :::'+JSON.stringify(resp[i]));
    var obj=new Object();
    obj.recordId=resp[i].Id;
    obj.prodname=resp[i].Mainetti_Model_Code__c;
    obj.color=resp[i].Colour__c;
    obj.size=resp[i].Print__c;
    obj.quantity=resp[i].Quantity__c;   
    obj.businessVertical=resp[i].Business_Vertical__c; 

    if(resp[i].Business_Vertical__c == 'Hanger Business'){
        this.disaplaySizerTxt = true;
    }else if(resp[i].Business_Vertical__c == 'MCare'){
        this.disaplayGloveTxt = true;
    }

        obj.retailerCodeId = this.retailerID;
        obj.orderToCompany = this.selectedCompany;
        obj.preCurrency = this.selectedCurrency;
        obj.customeid = this.selectcustomeid;
        obj.custRefModel = resp[i].Customer_Ref_Model__c;

    array.push(obj);
    // console.log('array-->'+JSON.stringify(array));
}
if(array.length >0){
    this.selectedSizer = array;
    this.hangerListDetail = true;
}

}else{
    const toastEvent = new ShowToastEvent({
            title: 'Error',
            message: 'Add to cart failed',
            variant: 'Error'
        });
        this.dispatchEvent(toastEvent);
        return;
}
})

.catch(error=>{
var errors = error;
console.log('error due to '+error);
})
}





changeProd()
{
this.displayPagination = true;
this.catalogVertical = true;
this.hangersizer = false;
this.hangerListDetail = false;

let obj={"flag": "fromSizer",
    "company":this.selectedCompany};
fireEvent(this.pageRef,"CatalogEvent",obj);

const selectedEvent = new CustomEvent("seture", { detail: {country:this.selectedCompany,
catalogVertical : true}});
this.dispatchEvent(selectedEvent);

}



handleQuantity(event){
var selectedQty = event.detail.value;
this.selQty = selectedQty;
console.log('quantity--> '+this.selQty);
}


addToList(){
console.log('addToList selectedProduct--> '+JSON.stringify(this.selectedProduct));
var completeWrap = JSON.parse(JSON.stringify(this.selectedProduct));
// console.log('completeWrap ::::'+completeWrap);
var selectedColor;
var selectedSize;
if(this.colorChartPriority == true){
    selectedColor = this.selcolor1;
    selectedSize = this.sizelist11; 
    } else{
    selectedColor = this.colorSel;
    selectedSize = this.selSize; 
    }


    var sizerList = this.sizerList;
    // console.log(JSON.stringify(this.selectedProduct.tempMap));
    // console.log('sizerList>>'+JSON.stringify(sizerList));
    // console.log('selected sizer>>'+JSON.stringify(this.selectedSizer));

    var prodName;
    var finalQuantity;
    var boxquantity;
    var fullboxQty;
    var MainettiModelCode;
    var priceBookId;
    var priceByCurr;
    var custRefModel;
    var MOQ;

    for(var i=0;i<sizerList.length;i++)
    {
        console.log('sizerList[i] ::::'+sizerList[i]);
        if(sizerList[i].Name == completeWrap.Name && sizerList[i].Color__c == selectedColor && sizerList[i].Sizer_Print__c == selectedSize)
        {
            prodName=sizerList[i].Name;
            boxquantity=sizerList[i].BOX_QTY__c;
            MOQ = sizerList[i].MOQ__c;
            fullboxQty=sizerList[i].Retailer_Code__r.Full_Box_Order__c;
            MainettiModelCode=sizerList[i].Name;
            priceBookId=sizerList[i].Id;
            // console.log(sizerList[i].MOQ__c);
            //priceByCurr=sizerList[i].Price_Product_by_Currency__r[0].Id;
        
            var customerInfoMagnetPrice = this.customerInfoMagnetPrice;
            for(var j=0;j<sizerList[i].Price_Product_by_Currency__r.length;j++)
            {
            if(this.searchedCurrency.split('-')[0].trim() == sizerList[i].Price_Product_by_Currency__r[j].CurrencyIsoCode && sizerList[i].Price_Product_by_Currency__r[j].MagNET_Price_Code__c == customerInfoMagnetPrice)
                {
                        priceByCurr=sizerList[i].Price_Product_by_Currency__r[j].Id;
                            break;	
                }   
                else if(this.searchedCurrency.split('-')[0].trim() == sizerList[i].Price_Product_by_Currency__r[j].CurrencyIsoCode && sizerList[i].Price_Product_by_Currency__r[j].MagNET_Price_Code__c == null)
                {
                    priceByCurr=sizerList[i].Price_Product_by_Currency__r[j].Id;
                }
            }
            custRefModel=sizerList[i].Customer_Ref_Model__c;
        //  console.log('custRefModel-->'+custRefModel);
        }
    }

    if(!selectedColor){ 
        const toastEvent = new ShowToastEvent({
            title: 'warning',
            message: 'Select the Color',
            variant: 'warning'
        });
        this.dispatchEvent(toastEvent);
        return;
    }

    if(!selectedSize){ 
        const toastEvent = new ShowToastEvent({
            title: 'warning',
            message: 'Select the Size',
            variant: 'warning'
        });
        this.dispatchEvent(toastEvent);
        return;
    }

    var obj = new Object();
    var array = this.selectedSizer;
    var duplicatePrsentAndApproved = false;
    // console.log("array"+JSON.stringify(array));
    if(array.length>0)
    {
        for(var i=0;i<array.length;i++)
        {
            
            if(array[i].prodname == this.selectedProduct.Name && array[i].color == selectedColor && array[i].size == selectedSize)
            {

                if (confirm("Entered value" +array[i].color + "And" +array[i].size + "already present Do you want to update the quantity"))
                {
                    duplicatePrsentAndApproved=true;
                }  
                else
                {
                    return;
                }
            }
            
        }
    }

var quantityy = parseInt(this.selQty);
console.log('parse Quantity --> '+ quantityy)
console.log(JSON.stringify(completeWrap.ProductDataMap[selectedColor]));
var result = Math.ceil(quantityy/boxquantity)*boxquantity;
console.log('result-->'+JSON.stringify(result));


if(!quantityy || quantityy<=0)
{ 
    const toastEvent = new ShowToastEvent({
        title: 'warning',
        message: 'Entered Product Quantity is not valid',
        variant: 'warning'
    });
    this.dispatchEvent(toastEvent);
    return;
} 
else if(duplicatePrsentAndApproved == false && quantityy < MOQ && boxquantity && (quantityy<boxquantity || quantityy % boxquantity!=0) && fullboxQty == true)
{
    result = Math.ceil(MOQ/boxquantity)*boxquantity;
    
    if (!confirm("Order Quantity for Product" + MainettiModelCode + "is less then Minimum Order Quantity MOQ" + ( MOQ )+ ".\n" + "The nearest multiples of box quantity" + ( result ) + ".\n" + "Click OK to confirm Order Quantity" + ( result ) + "and add it in the CART")) 
    {
        return;
    }
    completeWrap.ProductDataMap[selectedColor].quantity= result;
    finalQuantity = result;
    this.completeWrap = completeWrap.ProductDataMap[selectedColor].quantity;
}
else if(duplicatePrsentAndApproved == false && quantityy < MOQ && boxquantity && (MOQ<boxquantity || MOQ % boxquantity!=0) && fullboxQty == true)
{
    result = Math.ceil(MOQ/boxquantity)*boxquantity;
    
    if (!confirm("Order Quantity for Product" + MainettiModelCode + "is less then Minimum Order Quantity MOQ" + ( MOQ ) +".\n" + "The nearest multiples of box quantity" + ( result ) +".\n" + "Click OK to confirm Order Quantity" + ( result ) + "and add it in the CART")) 
    {
        return;
    }
    completeWrap.ProductDataMap[selectedColor].quantity = result;
    finalQuantity = result;
    this.completeWrap = completeWrap.ProductDataMap[selectedColor].quantity;
}
else if(quantityy < MOQ && duplicatePrsentAndApproved == false)
{
    if (!confirm("Order Quantity for Product" + MainettiModelCode + "is less then Minimum Order Quantity MOQ" + ( MOQ ) + ".\n" + "Click OK to confirm Order Quantity" + ( result ) + "and add it in the CART")) 
    {
        return;
    }
    completeWrap.ProductDataMap[selectedColor].quantity = MOQ;
    finalQuantity = MOQ;
    this.completeWrap = completeWrap.ProductDataMap[selectedColor].quantity;
}
else if(fullboxQty && boxquantity && (quantityy<boxquantity || quantityy % boxquantity!=0))
{
    if(result)
    {
        if (!confirm("Order Quantity for Product" + MainettiModelCode + "is not the multiples of Box quantity" + ".\n" + "The nearest multiples of box quantity" + ( result ) + ".\n" + "Click OK to confirm Order Quantity" + ( result ) + "and add it in the CART")) 
        {
            return; 
        }
        completeWrap.ProductDataMap[selectedColor].quantity = result;
        finalQuantity=result;
        this.completeWrap = completeWrap.ProductDataMap[selectedColor].quantity; 
    }else
{
    return;
}            
}
    else
    {
        completeWrap.ProductDataMap[selectedColor].quantity = quantityy;
        finalQuantity = quantityy;
        this.completeWrap = completeWrap.ProductDataMap[selectedColor].quantity; 
    }
    obj.prodname=prodName;
    obj.color = selectedColor;
    obj.size = selectedSize;
    obj.quantity = finalQuantity;
    obj.retailerCodeId = this.retailerID;
    obj.orderToCompany = this.selectedCompany;
    obj.preCurrency = this.selectedCurrency;
    obj.customeid = this.selectcustomeid;
    obj.priceBookId = priceBookId;
    obj.pricebycur = priceByCurr;
    obj.custRefModel = custRefModel;

    this.displayPagination = false;

    this.saveSizerToCart(obj);

}


saveSizerToCart(obj,addTo){
addSizerProduct({"obj":JSON.stringify(obj),
                    "addTo": addTo,
                    "selectedCurrency":this.selectedCurrency,
                    "searchedCurrency":this.searchedCurrency })

.then(result=>{

    alert(result);
    this.getSizerListData();
    if(this.selectedCurrency){
        this.selectedCurrency = this.selectedCurrency;
    }
    this.hangerListDetail = true;

    const obj={"flag": "BlockRetailer"};
    fireEvent(this.pageRef,"CatalogEvent",obj);

    const toastEvent = new ShowToastEvent({
        title: 'success',
        message: 'Product added to List successfully',
        variant: 'success'
    });
    this.dispatchEvent(toastEvent);
    return;
}) 
.catch(error=>{
    const toastEvent = new ShowToastEvent({
        title: 'Error',
        message: 'Add to cart Failed',
        variant: 'Error'
    });
    this.dispatchEvent(toastEvent);
    return;
})   
this.selQty = '';             
}


addTocart(){
var retailercode = this.retailerID;
var customerid = this.selectcustomeid;
addSizerToCart({"retailercode":retailercode,
    "customerid":customerid})

.then(result=>{
    const toastEvent = new ShowToastEvent({
            title: 'Success',
            message: 'Product added to cart successfully',
            variant: 'Success'
        });
        this.dispatchEvent(toastEvent);
        location.reload();
        //eval("$A.get('e.force:refreshView').fire();");
    return;
})
.catch(error=>{
    const toastEvent = new ShowToastEvent({
        title: 'Error',
        message: 'Add to cart Failed',
        variant: 'Error'
    });
    this.dispatchEvent(toastEvent);
    return;
})
}

deleteSOLIData(soliIdToDelete){
deletedSOLI({"soliIdToDelete": soliIdToDelete})
.then(result=>{

})
.catch(error=>{
    alert('ERROR OCCURED.'+JSON.stringify(error));
})
}


checkCartDatail(){
var selectedColor = this.colorSel;
// console.log("selectedColor: " + selectedColor);

var selectedSize = this.selSize;
this.selectedSize = selectedSize;
// console.log("selectedSize: " + selectedSize);

var CartData = this.cartDataList;
// console.log("CartData: " + CartData);
for(var i=0;i<CartData.length;i++){
    if(CartData[i].PSBP == this.selectedProduct.Name && CartData[i].Color == selectedColor && CartData[i].Size == selectedSize){
        this.isActive = true;
        return;
    }
    else{
        this.isActive = false;
    }
}
}


onSelectColor(event){
var colorSizeDependentList = this.colorSizeDependentList;
var selectedColor = event.detail.value;
this.selcolor1 = selectedColor;
this.sizelist = colorSizeDependentList[selectedColor];
var completeWrap = this.selectedProduct;
this.sizelist11 = colorSizeDependentList[selectedColor][0];
this.selectedSize = colorSizeDependentList[selectedColor][0];
this.selectedProduct = completeWrap; 

// if(selectedColor == this.sizerListColor){
//     this.selectedSizerListColor = true;
// }
this.checkCartDatail();
}

//onselect Sizer picklist
onSelectSize(event){
    var selSize = event.detail.value;
    this.sizelist11 = selSize;
    // if(selSize == this.sizerListSize){
    //     this.selectedSizerListSize = true;
    // }
    this.checkCartDatail();
}

//onselect Color picklist
onSelectColorForSizeDepend(event){
    var selColor = event.detail.value;
    this.colorSel = selColor;
    this.checkCartDatail();
}

//onselect Sizer picklist
onSelectSizeForSizeDepend(event){
var sizeColorList = this.colorSizeDependentList;
var sizeee = event.detail.value;
this.selSize = sizeee;
this.colorlist = sizeColorList[selectedSize];
var completeWrap = this.selectedProduct;
console.log('completeWrap --> '+completeWrap);

completeWrap.selectedSize = sizeee;
this.selectedSize = sizeee;

this.colorSel = sizeColorList[selectedSize][0];
this.selectedColor = sizeColorList[selectedSize][0];
this.selectedProduct = completeWrap;

this.checkCartDatail();
}

callRowAction(event) {
    const recId = event.detail.row.recordId;
    alert('datatabel><>'+JSON.stringify(recId));
    this.selectedSizer = this.selectedSizer.filter( item => item.recordId !==recId);
    console.log(' this.selectedSizerfiltered><>'+JSON.stringify( this.selectedSizer));
    deleteRow({"idTODalete":recId})

    .then(result=>{
        const toastEvent = new ShowToastEvent({
            title: 'success',
            message: 'Product removed from Cart',
            variant: 'success'
        });
        this.dispatchEvent(toastEvent);
        return;
    })
    .catch(error=>{
        const toastEvent = new ShowToastEvent({
            title: 'Error',
            message: 'Add to cart Failed',
            variant: 'Error'
        });
        this.dispatchEvent(toastEvent);
        return;
    })
}

//remove rows from the list
removeRow(event){
    var selectedSizer = this.selectedSizer;
    var selectedItem = event.target.getAttribute('data-index');
    var idTODalete = selectedSizer[selectedItem].recordId;
    alert('selectedSizer><>'+selectedSizer);
    alert('selectedItem><>'+selectedItem);
    selectedSizer.splice(selectedItem, 1);
    this.selectedSizer = selectedSizer;
    
    this.RemoveRow(idTODalete);

    if(selectedSizer.length==0)
    {
    this.hangerListDetail = false;
    const obj={"flag": "allSizerRemoved"};
    fireEvent(this.pageRef,"CatalogEvent",obj);
    }
}


RemoveRow(idTODalete){
     alert('idTODalete --> '+idTODalete);
    deleteRow({"idTODalete":idTODalete})

    .then(result=>{
        const toastEvent = new ShowToastEvent({
            title: 'success',
            message: 'Product removed from Cart',
            variant: 'success'
        });
        this.dispatchEvent(toastEvent);
        return;
    })
    .catch(error=>{
        const toastEvent = new ShowToastEvent({
            title: 'Error',
            message: 'Add to cart Failed',
            variant: 'Error'
        });
        this.dispatchEvent(toastEvent);
        return;
    })
}


checkCartData(){
var retailercode = this.retailerID;
var customerid = this.selectcustomeid;

CheckCartDetailsForUpdate({"retailercode":retailercode,
                            "customerid":customerid })
.then(result=>{
    var resp = result;
    // console.log('response.getReturnValue '+JSON.stringify(resp));
    this.cartDataList = resp;
    var selectedColor = this.colorSel;
    // console.log('selectedColor '+JSON.stringify(selectedColor));
    var selectedSize = this.selSize;
    // console.log('selectedSize '+JSON.stringify(selectedSize));
    var CartData = this.cartDataList;
    // console.log('CartData '+JSON.stringify(CartData));
    for(var i=0;i<CartData.length;i++){
        if(CartData[i].PSBP == this.selectedProduct.Name && CartData[i].Color == selectedColor && CartData[i].Size == selectedSize){
            
            this.isActive = true;
            return;
            }
            else{
                this.isActive = false;
            }
    }
})
.catch(error=>{
    console.log('ERROR due to '+error);
    const toastEvent = new ShowToastEvent({
        title: 'Error',
        message: 'Add to cart Failed',
        variant: 'Error'
    });
    this.dispatchEvent(toastEvent);
    return;
})                          
}

close(){
this.displayPagination = true;
this.catalogVertical = true;
this.hangerListDetail = false;
this.quickviewSizer = false;
}

cancel(event){
var compEvent = new CustomEvent("cancelevent", {detail: {param1: 'true'}});
this.dispatchEvent(compEvent); 
}


}


//  this.selSize  ---> component.find('sizelist').set('v.value')
//  this.colorSel ---->  component.find('colorlist').set('v.value')

//  this.selcolor1 ---->  component.find('colorlist1').set('v.value')
//  this.this.sizelist11 ----> component.find('sizelist1').get('v.value'); 
//   this.selQty -----> (component.find("quantity").get("v.value");