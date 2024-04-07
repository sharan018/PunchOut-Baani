import { LightningElement,api,track,wire} from 'lwc';
import getRetailerMsg from '@salesforce/apex/CatalogOrderController.getRetailerMsg';
import getDependentPicklistValues from '@salesforce/apex/CatalogOrderController.getDependentPicklistValues';
import searchProducts from '@salesforce/apex/PunchOutRequestController.searchProducts';
import getcostomerinfo from '@salesforce/apex/CatalogOrderController.getcostomerinfo';
import getCartDataCount from '@salesforce/apex/PunchOutRequestController.getCartDataCount';
import checkRetailerInSO from  '@salesforce/apex/PunchOutRequestController.checkRetailerInSO';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import Not_Allowed_to_change_tabs_when_cart_is_not_empty from '@salesforce/label/c.Not_Allowed_to_change_tabs_when_cart_is_not_empty';
import {CurrentPageReference} from 'lightning/navigation';
import { registerListener } from 'c/pubsub';


export default class CatalogOrderLwc extends LightningElement {
    @track sizehanger=false; @track flag;@track displayPagination =false;@api passBoolean=false;
    @api showSpinner = false; @track parentCmp =true; viewbulk =true;   @api disableBulkAdd = false;  @api selectedTab ; @track NotAllowed=Not_Allowed_to_change_tabs_when_cart_is_not_empty;
     @track labelValue1 = 'ADDTOCART';
       @track labelValue ='VIEWCART'
   @track isShipcmp = false;
   @track searchKeywordLabel='Keywords'
   @track dependentField ='Preferred_Currency__c';
   @track flagFamily=true;
     @track productInCartLabel='There are products added in the CART, please review if necessary.'
     @api logo =false;
    @track logo = false;
    @track closologo =true;
   // @track parentcmp = true;
    @track cartCount ;
      
    @track selectedTab;
   @track  hangersAndAccessoriesLabel = 'HANGERS AND ACCESSORIES';
   @track LABELSANDTICKETS='LABELS AND TICKETS';
   @track FLEXIBLEPACKAGING ='FLEXIBLE PACKAGING'
@track EASANDRFID="EAS AND RFID";
@track STRUCTURALPACKAGING='STRUCTURAL PACKAGING';
@track MCARE="MCARE";
    @track count = false;
  @track CatalogUIMessage;
  @track listOfCompanies;
  @track listOfCurrency; 
  //@track cartFlag ;
  //@api cartFlag =false;
  @api selectedCompany ;

  @track labelOrderToCompany ='Order To Company'
@api selectedCurrency;
  //@track selectedCurrency ='USD - United States Dollar';
  @track labelOrderToCurency='Preferd Currency'
  //@track listOfCompanies;
  @track searchedCurrency;
  @track completeWrap;
  @api total;
  @api page=1;
  @api pages;
  @track fieldList;
  @track selectedFamily;
  @track searchKeyword ;
  @track compoptions;
  //@track selectedTab ='Hanger Business'
  //@track SelectedRetailercode ='a00O000000mDAkPIAW'
  @track retailerCode ='a00O000000mDAkPIAW';
  @api SelectedRetailercode = 'a00O000000mDAkPIAW';
  //@track SelectedRetailer;
  @api selectedRetailer;
  @track RecordStart =0;
  @track OffsetValue = 0;
  @track isSearch = false;
  @track  searchLabel = 'Search';
   //@track selectcustomeid;
   @api selectcustomeid;
   @track flagFamily =true;
   @api sendcompleteWrap;
   @track searchedKeyword;
   @track searchedselectedCurrency;
   @track onsearch;
   @track onsearchLabel;
   @track callchildforbulkdata ;
   @track CatalogUIMessageforLabels;
   @track LabelsTickets ='Labels & Tickets';
   @track Flexiblepackaging ='Flexible Packaging';
   @track EasAndRfid ='INTELLIGENT SOLUTIONS';
   @track StructuralPackaging ='TLA';
   @track MCare ='MCare';
   @track Countss =false;
   @track selectedcompanyfromorder;
   @track compoptions=[];
   @track orderCompanyOptions=[];
   @track selectedCurrencyOptions=[];
   @track selectedFamilyOptions=[];
   @track companyselect;
    @track getTabName;
   @track isLoading=false;
    @api SelectedImage;
    @api Selectedsize;
    @api SelectedFabricArray;
    @api SelectedCountry;
    @api SelectedInstImage;
    @api ExCareIns;
    @api FreeText;
    @api DevCountry;
    @api DevSize;
    @api DevFabric;
    @api DevCare;
    @api DevExcare;
    @api Devlogo;
    @api DevFree;
   get NotAllowed() {
    return NotAllowed;
}

get compoptions(){
 this.compoptions=this.companyselect;
}



// selectcustomeid ;
// @wire(getcostomerinfo, {retailerCode:'a00O000000mDAkPIAW'})
//     wiredgetcostmerinfo({data, error}){
//         if(data){
//             const custoid = data.Customer_Information__c;
//             this.selectcustomeid=custoid;
//             this.callgetCartDataCount();
//         }
//         else if (error) {
//             if (error.body && error.body.message) {
//                 alert('Error message: ' + error.body.message);
//                 } else {
//                alert('Unknown error');
//             }
//         }
        
//     }

@wire(CurrentPageReference) pageRef;
   
connectedCallback(){
    const selectedTabs =this.selectedTab;
   // this.setcurrecncy=this.selectedCurrency;
    this.companyselect =this.selectedCompany;
   // alert('selectedTab >>'+this.selectedTab);
    this.slectCompany=this.selectedCompany;
    this.cartFlag=false;
    this.parentcmp=true;
    //this.SelectedRetailercode=this.retailerCode;
//getRetailerMsg
this.GetcustomInfoid();
this.piclistval();
this.getretailMsg();
this.getCartCount();
this.piclistVlues();



  
if(selectedTabs !='Labels &amp; Tickets'){
    this.notlabelsampandtickets=true;
}
if(selectedTabs =='MCare'){
    this.MCare=true;
}
 else if(selectedTabs =='Hanger Business'){
    this.HangerBusiness=true;
}


else{
    this.MCare=false;
    this.HangerBusiness=false;
    this.notlabelsampandtickets=false;
}
//this.Search();

registerListener('loadMyEvent', this.handleGetValueFromApplicationEvent, this);
registerListener('CloseLogoEvent', this.hideLogoGeneration, this);
registerListener('CatalogEvent', this.handleCatalogEvent, this);


}

GetcustomInfoid(){
    getcostomerinfo({
        retailerCode : this.retailerCode
    })
    .then(result => {
        const custoid = result.Customer_Information__c;
        this.selectcustomeid=custoid;
      // this.getCartCount();
      })
.catch(error => {
   console.error('Error: ', error);
});
   }
   getCartCount(){
    getCartDataCount({ 
    customerid: this.selectcustomeid})
   
    .then(result => {
    if (result > 0) {
    this.Count = true;
    this.Countss=true;
    this.cartCount = result;
    }
 
  })
.catch(error => {
console.error('Error: ', error);
});
}

   piclistval(){
    let controllingValue=this.selectedRetailer;
    let controllingFields ='Retailer_Code_Hidden__c';
    let dependentField ='Order_Country__c';
    getDependentPicklistValues({
        controllingValue:controllingValue,
        controllingFields: controllingFields,
        dependentField:dependentField})
        .then(result =>{
     if (dependentField == 'Order_Country__c') {
        this.listOfCompanies = result;
        this.orderCompanyOptions = [{ label: "None", value: 'None' },...this.listOfCompanies.map(option => ({ label: option, value: option }))];
       // alert('orderCompanyOptions -->'+this.orderCompanyOptions);
    } else if (dependentField === 'Preferred_Currency__c') {
        this.listOfCurrency = result;
        this.selectedCurrencyOptions = [{ label: "None", value: 'None' },...this.listOfCurrency.map(option => ({ label: option, value: option }))];
        
    }
    
        })
        .catch(error => {
            console.error('Error fetching record data:', error);
        });
    
        this.selectedCompany = this.selectedCompany;
   }
   getretailMsg(){
    getRetailerMsg({ retailerId: this.retailerCode})
.then(result => {
this.CatalogUIMessage =result.Catalog_Msg_Hangers_Accessories__c;
this.CatalogUIMessageforLabels=result.Catalog_Msg_UI_Labels_Tickets__c;

})
.catch(error => {
console.error('Error fetching record data:', error);
});
   }
   piclistVlues(){
   // alert('inside piclistVlues');
   // alert('dependentField >>2333'+this.dependentField);
   getDependentPicklistValues({
    controllingValue:this.selectedCompany,
    controllingFields:'Order_Country__c',
    dependentField:'Preferred_Currency__c'})
    .then(result =>{
       // alert('inside result >>'+JSON.stringify(this.result));
 if (this.dependentField === 'Order_Country__c') {
    this.listOfCompanies = result;
    this.orderCompanyOptions = [{ label: "None", value: 'None' },...this.listOfCompanies.map(option => ({ label: option, value: option }))];
} else if (this.dependentField == 'Preferred_Currency__c') {
    this.listOfCurrency = result;
    this.selectedCurrencyOptions = [{ label: "None", value: 'None' },...this.listOfCurrency.map(option => ({ label: option, value: option }))];

}

    })
    .catch(error => {
        console.error('Error fetching record data:', error);
    });
this.selectedCurrency=this.selectedCurrency;
}
 

//bulk add


     
    @track hangersAndAccessoriestrue=false;
    @track LabelsTicketstrue=false;
    @track Flexiblepackagingtrue=false;
    @track INTELLIGENTSOLUTIONStrue=false;
    @track tabIdtrue=false;
    @track MCaretrue=false;
    selectTab(event) {
        //('inside tab selecedcompanyfromoredr >>>'+this.selectedcompanyfromorder);
      //  const getCompanyFromOrder =this.selectedcompanyfromorder;
        this.showSpinner = false;
        const tabId =event.target.value
        if(tabId=='Hanger Business'){
            this.hangersAndAccessoriestrue=true;
            this.LabelsTicketstrue=false;
           
        }else if(tabId=='Labels & Tickets'){
            this.LabelsTicketstrue=true;
            this.hangersAndAccessoriestrue=false;
            
        }else if(tabId=='Flexible Packaging'){
            this.Flexiblepackagingtrue=false;
        }
        else if(tabId=='INTELLIGENT SOLUTIONS'){
            this.INTELLIGENTSOLUTIONStrue=false;
        }
        else if(tabId=='TLA'){
            this.TLAtrue=false;
        }else if(tabId=='MCare'){
            this.MCaretrue=false;
        }
        alert('tabId >>'+tabId);
        this.getTabName =tabId;
        this.selectedTab=tabId;
        this.toCheckSORetailer(tabId);
        this.viewbulk = true;
        this.selectedFamily = null;
        this.displayPagination = true;
        this.catalogVertical = true;
        this.catalogOrder = false;
        this.sizerhanger = false;
        this.careLabelOrder = false;
        this.logo = false;
       // this.selectedCompany = this.selectedCompany;
        this.Count=true;
       


 
        }
        toCheckSORetailer(tabId){
          //  alert('toCheckSORetailer'+this.selectcustomeid);
            console.log('toCheckSORetailer'+this.selectcustomeid);
            checkRetailerInSO({
                customerid : this.selectcustomeid
            })
            .then(result =>{
               //  alert('result >>>'+JSON.stringify(result));
                if(result){
                    let verticalVal = result.Vertical__c;
                  //  alert('verticalVal >>'+verticalVal);
                    console.log('verticalVal >>'+JSON.stringify(verticalVal));
                    if (!verticalVal || verticalVal == null){
                    verticalVal = 'Hanger Business';
                    }
                if (tabId == verticalVal) {
                    this.toGetTabData(tabId);
                }
                else {
                   // alert('warning');
                   
                    const toastEvent = new ShowToastEvent({
                        title: 'warning',
                        message:this.NotAllowed,
                        variant: 'warning'
                    });
                    this.dispatchEvent(toastEvent);
                    this.selectedTab =verticalVal;
                }
                }
                else {
                    this.toGetTabData(tabId);
                }

            })
            .catch(error => {
                console.error('Error fetching record data:', error);
            });

        }
            
            toGetTabData(tabId){
            //  if(getCompanyFromOrder ==null){
                console.log("tabId >>"+tabId);
                console.log('retailerCode >>'+this.retailerCode);
                console.log('OffsetValue >>'+this.OffsetValue);
                console.log('selectedCompany >>'+this.selectedCompany);
                console.log('selectedCurrency >>'+this.selectedCurrency);
                console.log('page >>'+this.page);
                searchProducts({
                    selectedTab : tabId,
                    retailerCode : this.retailerCode,
                offsetValue: this.OffsetValue ,  
                orderToCompany :this.selectedCompany,
                preCurrency:this.selectedCurrency,
                pageNumber :this.page
            })
            .then(response =>{
                var res =response;
                console.log('resresponse >>::>'+JSON.stringify(res));
                for (var i = 0; i < res.productList.length; i++) {
                    var tempList = [];
                    for (var key in res.productList[i].ProductDataMap) {
                        tempList.push({ value: res.productList[i].ProductDataMap[key], key: key, quantity: res.productList[i].ProductDataMap[key].quantity });
                    }
                    res.productList[i].tempMap = tempList;
                    console.log('insideloop99999999999>'+JSON.stringify(res.productList[i].tempMap));
                    
                }
                
                this.total = res.productList.length;
                this.page = res.pageNumber;
                this.pages = Math.ceil(res.totalRecords / res.pageSize);
                this.listOfCurrency = res.PcurrList;
                this.completeWrap = res;
                
                console.log('completeWrap3333333333>'+JSON.stringify(this.completeWrap.productList));
                
                this.sendcompleteWrap=res.productList;
                console.log('completeWrap444444>'+JSON.stringify(this.sendcompleteWrap));
                //this.onsearch =true;
                this.selectedCompany = res.Ocomp;
                this.TotalRecords=res.productList.length;
                
                if (res.productFamilyList.length != 0) {
                    this.fieldList = res.productFamilyList;
                    this.selectedFamilyOptions = [{ label: "None", value: 'NULL' },...this.fieldList.map(option => ({ label: option, value: option }))];

                 } else {
                     this.selectedFamily = null;
                    this.fieldList = [];
                }
                
                var listofcomp =  this.listOfCompanies ;
                var selectedcom = this.selectedCompany;
                for (var i = 0; i < listofcomp.length; i++) {
                    if (selectedcom.localeCompare(listofcomp[i]) == 0)		// if doesent contains 
                    {
                        this.selectedCurrency = res.Pcurr;
                       this.searchedCurrency =res.Pcurr;
                    }
                }
             
                console.log('last>'+tabId);
                if(tabId =='Labels & Tickets'){
                this.onsearchLabel =true;
                this.onsearch=false;
                // alert('onsearchLabel');
                }
                else{
                    // alert('elseeee');
                    this.onsearch=true;
                    this.onsearchLabel =false;
                }
                

            })
            .catch(error => {
                console.error('Error fetching record data:', error);
            });
       // }
      /*  else{
         
            searchProducts({
                selectedTab : tabId,
                retailerCode : this.retailerCode,
                offsetValue: this.OffsetValue ,  
                orderToCompany :getCompanyFromOrder,
                preCurrency:this.selectedCurrency,
                pageNumber :this.page
            })
            .then(response =>{
                const res =response;
                for (var i = 0; i < res.productList.length; i++) {
                    var tempList = [];
                    for (var key in res.productList[i].ProductDataMap) {
                        tempList.push({ value: res.productList[i].ProductDataMap[key], key: key, quantity: res.productList[i].ProductDataMap[key].quantity });
                    }
                    res.productList[i].tempMap = tempList;
                }
                this.total = res.productList.length;
                this.page = res.pageNumber;
                this.pages = Math.ceil(res.totalRecords / res.pageSize);
                this.listOfCurrency = res.PcurrList;
                this.completeWrap = res;
                this.sendcompleteWrap=res.productList;
                this.selectedCompany = res.Ocomp;
                this.TotalRecords=res.productList.length;
                
                if (res.productFamilyList.length != 0) {
                    this.fieldList = res.productFamilyList;
                 } else {
                     this.selectedFamily = 'NULL';
                    this.fieldList = [];
                }
                
                var listofcomp =  this.listOfCompanies ;
                var selectedcom = this.selectedCompany;
                for (var i = 0; i < listofcomp.length; i++) {
                    if (selectedcom.localeCompare(listofcomp[i]) == 0)		// if doesent contains 
                    {
                        this.selectedCurrency = res.Pcurr;
                       this.searchedCurrency =res.Pcurr;
                    }
                }
                this.onsearch =true;


            })
            .catch(error => {
                console.error('Error fetching record data:', error);
            });
        }*/
        
    
        }
        
        OrderToCompany(event) {
            //this.selectedCompany = event.target.value;
          // this.searchedCurrency = this.selectedCurrency;
           // this.dependentField='Preferred_Currency__c';
            var controllingValue = event.target.value;
            this.selectedCompany =event.target.value;
          var  controllingFields ='Order_Country__c';
          var dependentField ='Preferred_Currency__c';
          this.pickListVal(controllingValue,controllingFields,dependentField);
         this.productSearch();
         console.log('parent Data');
         
        //  let myPromise = new Promise(function(myResolve) {
        //     alert('inside >>');
        //     this.productSearch();
        //     myResolve();
        //     console.log('loaded data >>'+JSON.stringify(this.completeWrap.productList));
        //     });
           
        //     myPromise.then(
        //         function(value) {
        //             alert('inside mmyPromise');
        //         console.log('executed 3rd Promise');
        //         this.template.querySelector('c-catalog-vertical-lwc').parentData = this.completeWrap.productList;
        //         this.template.querySelector('c-catalog-vertical-lwc').setuphtml();
        //         },
        //         function(error) {
        //         console.log('executed F');
        //         }
        //       );
         

            }

            preferredCurrency(event){
                this.selectedFamily ='NULL';
              // this.selectedFamily='null';
               const templist =[];
               this.fieldList =templist;
               let currencyselected =event.target.value;
               this.selectedCurrency =event.target.value;
              // this.selectPrifferdCurrency(currencyselected);
              this.productSearch();


                            }

//FAMILY
            Family(event) {
                this.page=1;
               this.selectedFamily=event.target.value;
                searchProducts({
                     SearchKeyword:null,
                     selectedFamily: this.selectedFamily,
                    selectedTab: this.selectedTab,
                    retailerCode: this.retailerCode,
                    offsetValue: this.RecordStart,
                    orderToCompany: this.selectedCompany,
                    preCurrency: this.selectedCurrency,
                    pageNumber: this.page
                }) 
                .then(result => {
                    
                   // this.template.querySelector('.spinner').classList.remove('slds-show');
                    const res = result;
                    for (var i = 0; i < res.productList.length; i++) {
                        var tempList = [];
                        for (var key in res.productList[i].ProductDataMap) {
                            tempList.push({ value: res.productList[i].ProductDataMap[key], key: key, quantity: res.productList[i].ProductDataMap[key].quantity });
                        }
                        res.productList[i].tempMap = tempList;
    
                    }
                    this.completeWrap = res;
                    this.template.querySelector('c-catalog-vertical-lwc').parentData = this.completeWrap.productList;
                    this.template.querySelector('c-catalog-vertical-lwc').setuphtml();
                   this.sendcompleteWrap=res.productList;
                    this.total = res.productList.length;
                    this.page = res.pageNumber;
                    this.pages = Math.ceil(res.totalRecords / res.pageSize);
                    this.listOfCurrency = res.PcurrList;
                    if (res.productFamilyList.length !== 0) {
                        this.fieldList = res.productFamilyList;
                        this.selectedFamilyOptions = [{ label: "None", value: 'NULL'},...this.fieldList.map(option => ({ label: option, value: option }))];

                    } else {
                        this.selectedFamily = null;
                        this.fieldList = [];
                    }
                    this.selectedCompany = res.Ocomp;
                    this.selectedCurrency = res.Pcurr;
                    this.searchedCurrency = res.Pcurr;
                    this.catalogVertical = true;
                    this.sizerhanger = false;
                    this.displayPagination = true;
                    this.careLabelOrder = false;
                   // this.isSearch = true;
                    // this.Search();
                    if(this.selectedTab =='Labels & Tickets'){
                        this.onsearchLabel =true;
                        this.onsearch=false;
                        // alert('onsearchLabel');
                        }
                        else{
                            // alert('elseeee');
                            this.onsearch=true;
                            this.onsearchLabel =false;
                        }
                     
                })
                .catch(error => {
                    console.error('Error: ', JSON.stringify(error));
                    const toastEvent = new ShowToastEvent({
                        title: 'Error',
                        message: 'An error occurred while searching for products.',
                        variant: 'error',
                    });
                    this.dispatchEvent(toastEvent);
                });

            }


            keywordchange(event){
                this.searchKeyword = event.target.value;
                this.searchedKeyword=event.target.value ;
                this.Search();
            } 
            //search
            Search(event) {
                this.page = 1;
                console.log('searchedKeyword -->'+JSON.stringify(this.searchedKeyword));
                console.log('getTabName -->'+JSON.stringify(this.getTabName));
                console.log('RecordStart -->'+JSON.stringify(this.RecordStart));
                console.log('retailerCode -->'+JSON.stringify(this.retailerCode));
                console.log('selectedFamily -->'+JSON.stringify(this.selectedFamily));
                console.log('selectedCompany -->'+JSON.stringify(this.selectedCompany));
                console.log('selectedCurrency -->'+JSON.stringify(this.selectedCurrency));
                console.log('page -->'+JSON.stringify(this.page));
              
                 searchProducts({
                    SearchKeyword: this.searchedKeyword,
                    selectedTab: this.getTabName,
                    offsetValue: this.RecordStart,
                    retailerCode: this.retailerCode,
                    selectedFamily: this.selectedFamily,
                    orderToCompany: this.selectedCompany,
                    preCurrency: this.selectedCurrency,
                    pageNumber: this.page
                })     
                .then(result => {
                    const res = result;
                   
                    console.log('resresres ====>'+JSON.stringify(res));
                    for (var i = 0; i < res.productList.length; i++) {
                        var tempList = [];
                        for (var key in res.productList[i].ProductDataMap) {
                            tempList.push({ value: res.productList[i].ProductDataMap[key], key: key, quantity: res.productList[i].ProductDataMap[key].quantity });
                        }
                        res.productList[i].tempMap = tempList;

    
                    }
                     this.completeWrap = res;
                     this.template.querySelector('c-catalog-vertical-lwc').parentData = this.completeWrap.productList;
                     this.template.querySelector('c-catalog-vertical-lwc').setuphtml();
                     this.sendcompleteWrap=res.productList;
                    this.total = res.productList.length;
                     this.page = res.pageNumber;
                     this.pages = Math.ceil(res.totalRecords / res.pageSize);
                     this.listOfCurrency = res.PcurrList;
                     if (res.productFamilyList.length !== 0) {
                        this.fieldList = res.productFamilyList;
                        this.selectedFamilyOptions = [{ label: "None", value: 'None' },...this.fieldList.map(option => ({ label: option, value: option }))];
                     } else {
                         this.selectedFamily = 'NULL';
                        this.fieldList = [];
                    }
                    this.selectedCompany = res.Ocomp;
                    this.selectedCurrency = res.Pcurr;
                     this.searchedCurrency = res.Pcurr;
                    this.catalogVertical = true;
                   this.sizerhanger = false;
                     this.displayPagination = true;
                     this.careLabelOrder = false;
                   // this.isSearch = true;
                    //this.onsearch =true;
                    if(this.selectedTab =='Labels & Tickets'){
                        this.onsearchLabel =true;
                        this.onsearch=false;
                        // alert('onsearchLabel');
                        }
                        else{
                            // alert('elseeee');
                            this.onsearch=true;
                            this.onsearchLabel =false;
                        }
                 })
                .catch(error => {
                     console.error('Error: ', JSON.stringify(error));
                     const toastEvent = new ShowToastEvent({
                         title: 'Error',
                         message: 'An error occurred while searching for products.',
                         variant: 'error',
                     });
                   this.dispatchEvent(toastEvent);
                });
            }

         
                   pickListVal(controllingValue,controllingFields,dependentField){
                    // alert('inside piclist');
                    getDependentPicklistValues({
                        controllingValue: controllingValue ,
                        controllingFields:controllingFields ,
                        dependentField:  dependentField
                    })
                        .then(result =>{
                     //var getreurnvalues=result;
                     if (dependentField == 'Order_Country__c') {
                        this.listOfCompanies = result;
                        
                        this.orderCompanyOptions = [{ label: "None", value: 'None' },...this.listOfCompanies.map(option => ({ label: option, value: option }))];
                    } else if (dependentField == 'Preferred_Currency__c') {
                        this.listOfCurrency = result;
                        this.selectedCurrencyOptions = [{ label: "None", value: 'None' },...this.listOfCurrency.map(option => ({ label: option, value: option }))];


                    }
                    
                        })
                        .catch(error => {
                            console.error('Error fetching record data:', error);
                        });
                   }

                   //
                  

                   //ProductSearch
                   productSearch(){
                    console.log('inside productSearch');
                    console.log('selected company >>'+this.selectedCompany);
                    console.log('selected currency >>'+ this.selectedCurrency );
                    console.log('selected selectedTab >>'+ this.selectedTab );
                    console.log('selected retailerCode >>'+ this.retailerCode );
                    console.log('selected offsetValue >>'+ this.RecordStart );
                    console.log('selected page >>'+ this.page );
                    if (this.selectedCurrency == 'NULL' || this.selectedCurrency == '') {
                        const toastEvent = new ShowToastEvent({
                            title: 'warning',
                            message: 'Select Preferd Currency',
                            variant: 'warning'
                        });
                        this.dispatchEvent(toastEvent);
                    }
                    this.searchedCurrency=this.selectedCurrency;
                    
                     searchProducts({
                    SearchKeyword: this.searchKeyword,
                    selectedFamily:this.selectedFamily,
                     selectedTab: this.selectedTab,
                     retailerCode: this.retailerCode,
                     offsetValue: this.RecordStart,
                     orderToCompany: this.selectedCompany,
                     preCurrency: this.selectedCurrency,
                     pageNumber: this.page
                 })
                 .then(result => {
                    const res = result;
                    console.log("resofOrderCompany"+JSON.stringify(res));
                    for (var i = 0; i < res.productList.length; i++) {
                        var tempList = [];
                        for (var key in res.productList[i].ProductDataMap) {
                            tempList.push({ value: res.productList[i].ProductDataMap[key], key: key, quantity: res.productList[i].ProductDataMap[key].quantity });
                        }
                        res.productList[i].tempMap = tempList;
    
                    }
                     this.completeWrap = res;
                     console.log('Fetched data in parent');
                     console.log('Fetched data in parent666 >>'+JSON.stringify(this.completeWrap.productList));
                     this.template.querySelector('c-catalog-vertical-lwc').parentData = this.completeWrap.productList;
                     this.template.querySelector('c-catalog-vertical-lwc').setuphtml();
                     this.sendcompleteWrap=res.productList;

                    this.total = res.productList.length;
                     this.page = res.pageNumber;
                     this.pages = Math.ceil(res.totalRecords / res.pageSize);
                     this.listOfCurrency = res.PcurrList;
                     if (res.productFamilyList.length != 0) {
                        this.fieldList = res.productFamilyList;
                        this.selectedFamilyOptions = [{ label: "None", value: 'None' },...this.fieldList.map(option => ({ label: option, value: option }))];
                     } else {
                         this.selectedFamily = null;
                        this.fieldList = [];
                    }
                    this.selectedCompany = res.Ocomp;
                  //  this.selectedcompanyfromorder = res.Ocomp;
                    this.selectedCurrency = res.Pcurr;
                     this.searchedCurrency = res.Pcurr;
                    this.catalogVertical = true;
                   this.sizerhanger = false;
                     this.displayPagination = true;
                     this.careLabelOrder = false;
                     
                     if(this.selectedTab =='Labels & Tickets'){
                        this.onsearchLabel =true;
                        this.onsearch=false;
                        // alert('onsearchLabel');
                        }
                        else{
                            // alert('elseeee');
                            this.onsearch=true;
                            this.onsearchLabel =false;
                        }
                  //  this.isSearch = true;
                  
                   // this.Search();
                 })
                .catch(error => {
                     console.error('Error: ', JSON.stringify(error));
                     const toastEvent = new ShowToastEvent({
                         title: 'Error',
                         message: 'An error occurred while searching for products.',
                         variant: 'error',
                     });
                   this.dispatchEvent(toastEvent);
                });

                   }


                   //preferd currency
                   selectPrifferdCurrency(currencyselected){
                    this.selectedCurrency =currencyselected;
                    if(currencyselected == 'NULL' || currencyselected =='') {
                        const toastEvent = new ShowToastEvent({
                           title: 'Warning',
                            message: 'Select the Preferred Currency',
                            variant: 'warning',
                        });
                        this.dispatchEvent(toastEvent);
                        return;
                    }
           
                    this.searchedCurrency = this.selectedCurrency;

                   searchProducts({
                       SearchKeyword: this.searchKeyword,
                       selectedTab: this.getTabName,
                       offsetValue: this.RecordStart,
                       retailerCode: this.retailerCode,
                       selectedFamily: this.selectedFamily,
                       orderToCompany: this.selectedCompany,
                       preCurrency:  this.selectedCurrency,
                       pageNumber: this.page
                   })
                   .then(result => {
                      // this.template.querySelector('.spinner').classList.remove('slds-show');
                       const res = result;
                       for (var i = 0; i < res.productList.length; i++) {
                           var tempList = [];
                           for (var key in res.productList[i].ProductDataMap) {
                               tempList.push({ value: res.productList[i].ProductDataMap[key], key: key, quantity: res.productList[i].ProductDataMap[key].quantity });
                           }
                           res.productList[i].tempMap = tempList;
       
                       }
                       this.completeWrap = res;
                       this.sendcompleteWrap=res.productList;
                       this.total = res.productList.length;
                       this.page = res.pageNumber;
                       this.pages = Math.ceil(res.totalRecords / res.pageSize);
                       this.listOfCurrency = res.PcurrList;
                       if (res.productFamilyList.length != 0) {
                           this.fieldList = res.productFamilyList;
                           this.selectedFamilyOptions = [{ label: "None", value: 'None' },...this.fieldList.map(option => ({ label: option, value: option }))];
                       } else {
                           this.selectedFamily = 'NULL';
                           this.fieldList = [];
                       }
                       this.selectedCompany = res.Ocomp;
                       this.selectedCurrency = res.Pcurr;
                       this.searchedCurrency = res.Pcurr;
                       this.catalogVertical = true;
                       this.sizerhanger = false;
                       this.displayPagination = true;
                       this.careLabelOrder = false;
                       this.isSearch = true;
                       this.onsearch =true;
                       
                   })
                   .catch(error => {
                       console.error('Error: ', JSON.stringify(error));
                       const toastEvent = new ShowToastEvent({
                           title: 'Error',
                           message: 'An error occurred while searching for products.',
                           variant: 'error',
                       });
                       this.dispatchEvent(toastEvent);
                   });
   

                   }
                   //bulkadd
           getBulkData(event) {
            let child = this.template.querySelector('c-catalog-vertical-lwc');
            alert(child);
            child.getBulkData();
           // this.callchildforbulkdata=true;
                   }

                   //view button
                   handleButtonViewClick(){
                 this.isShipcmp =true;
                 this.parentcmp =false;
                 this.hangersAndAccessoriestrue=false;
                   }
        shipcmp() {
        this.parentcmp = false;
        this.isShipcmp = true;
        this.logo = false;
    }

    handlePageChange(event){
        const direction = event.detail.direction;
        const searchText = event.detail.searchText;
    }
@track closelogo = true;
    handleGetValueFromApplicationEvent(obj) {
        console.log('obj--> '+JSON.stringify(obj));
        console.log('obj.sizekey--> '+obj.sizeKey);
        console.log('obj.FabricArray--> '+JSON.stringify(obj.FabricArray));
        console.log('obj.SelectedInstImage -->'+JSON.stringify(obj.SelectedInstImage));
      
        
        if (this.closelogo) {
            
          if(obj.radiokey != null || obj.radiokey != undefined){
            this.SelectedImage = obj.radiokey;
            console.log('Selected Image --> '+this.SelectedImage);
            this.Devlogo = true;
          }

          if(obj.FabricArray != null || obj.FabricArray != undefined){
          console.log('Fabric value check');
            if ((obj.FabricArray).length>0) { 
                console.log('inside FabricArray');
                this.SelectedFabricArray = [...obj.FabricArray];
                if(this.SelectedFabricArray[0]){
                this.DevFabric = true;
                console.log('Selected Fabric Array -->> '+this.SelectedFabricArray);
                }else{
                this.DevFabric = false; 
                }
            }
          }
         

            if(obj.sizeKey != null || obj.sizeKey != undefined){
            this.Selectedsize = obj.sizeKey;
            this.DevSize = true;
            }

            if(obj.country != null || obj.country != undefined){
                this.SelectedCountry = obj.country;
                if(this.SelectedCountry == '-NONE-'){
                    this.DevCountry = false;
                }else{
                    this.DevCountry = true;
                }
                console.log('SelectedCountry ::'+ SelectedCountry);
            }

            if(obj.SelectedInstImage != null || obj.SelectedInstImage != undefined){
            console.log('SelectedInstImage'+ obj.SelectedInstImage);
            var selimag =obj.SelectedInstImage;
            if (selimag) { 
                console.log('inside SelectedInstImage');
                this.SelectedInstImage =selimag;
                if(this.SelectedInstImage){
                    this.DevCare = true;
                console.log('Selected Inst Image -->> '+this.SelectedInstImage);
                }else{
                this.DevCare = false; 
                }
            }
            }

            if(obj.ExCareIns != null || obj.ExCareIns != undefined){
            if ((obj.ExCareIns).length>0) { 
                console.log('inside ExCareIns');
                this.ExCareIns = [...obj.ExCareIns];
                if(this.ExCareIns[0]){
                    this.DevExcare = true;
                console.log('Selected ExCareIns -->> '+this.ExCareIns);
                }else{
                this.DevExcare = false; 
                }
            }
            console.log(obj.ExCareIns);
            }

            if(obj.FreeTextkey != null || obj.FreeTextkey != undefined){
            this.FreeText = obj.FreeTextkey;
            this.DevFree = true;
            console.log('FreeText ::'+ JSON.stringify(this.FreeText));
            }

            if(obj.LogoGeneratorURL != null || obj.LogoGeneratorURL != undefined){
                this.LogoGeneratorURL = obj.LogoGeneratorURL;
                console.log(this.LogoGeneratorURL);
            }

            this.logo = true;
            console.log('logoooo >>>', this.logo);
        }
    }
   
    hideLogoGeneration(event){
        var closelogo =event.closelogo;
        this.closologo =closelogo;
    }

    handleCatalogEvent(event){
      //  alert('handleCatalogEvent catalogOrder');
        var flag = event.flag;
      //  alert('flag value -->'+flag);
        if (flag == 'BlockRetailer') {
            this.cartFlag = true;
           // alert('cartFlag'+this.cartFlag);
        }
        else if (flag == 'fromSizer' || flag == 'fromLabel') {
            this.productSearch();
        }
        else if (flag == 'allSizerRemoved' && !this.cartCount) {
            this.cartFlag = false;
        }
    }
}