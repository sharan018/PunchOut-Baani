import { LightningElement,track,api } from 'lwc';
import getcostomerinfo from '@salesforce/apex/CatalogOrderController.getcostomerinfo';
import checkRetailerInSO from '@salesforce/apex/PunchOutRequestController.checkRetailerInSO';
import retailerCodeDisplay from '@salesforce/apex/CatalogOrderController.retailerCodeDisplay';
 import getDependentPicklistValues from '@salesforce/apex/CatalogOrderController.getDependentPicklistValues';
import getcostomerRetailerData from '@salesforce/apex/CatalogOrderController.getcostomerRetailerData';
import Doc_image from '@salesforce/label/c.Doc_image';
import HANGERS_AND_ACCESSORIES from '@salesforce/label/c.HANGERS_AND_ACCESSORIES';
import LABELS_AND_TICKETS from '@salesforce/label/c.LABELS_AND_TICKETS';
import FLEXIBLE_PACKAGING from '@salesforce/label/c.FLEXIBLE_PACKAGING';
import MCARE from '@salesforce/label/c.MCARE';
import STRUCTURAL_PACKAGING from '@salesforce/label/c.STRUCTURAL_PACKAGING';
import EAS_AND_RFID from '@salesforce/label/c.EAS_AND_RFID';
import Start_Order from '@salesforce/label/c.Start_Order';
import Cancel from '@salesforce/label/c.Cancel';
import Please_select_a_Bussiness_Vertical from '@salesforce/label/c.Please_select_a_Bussiness_Vertical';
import Preferred_Currency from '@salesforce/label/c.Preferred_Currency';
import Order_To_Company from '@salesforce/label/c.Order_To_Company';
import Error from '@salesforce/label/c.Error';
import Please_Select_a_Preferred_Currency from '@salesforce/label/c.Please_Select_a_Preferred_Currency';
import Selected_Retailer from '@salesforce/label/c.Selected_Retailer';
import Order_Bussiness_Vertical from '@salesforce/label/c.Order_Bussiness_Vertical';
import Order_Selection from '@salesforce/label/c.Order_Selection';
import Retailer from '@salesforce/label/c.Retailer';
import Retailer_Code_Please_select_a_Retailer from '@salesforce/label/c.Retailer_Code_Please_select_a_Retailer';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';




export default class DisplayRetailerLwc extends LightningElement {
    @track retailercmp=true; @track onselectRetailercode; @api Retailerselect; @api cartVertical='Hanger Business';
    @api selectcustomeidstoCatalogOrder ; @api cartCompany ; @api cartCurrency; @track isCartCreated =false ;@track RoList=[];
    @track SelectRetailer; @track showConfirmDialog =false;@track listOfCompanies =[];@track listOfCurrency=[];
   @track SelectedPiklistCompany =''; @track SelectedPiklistCurrency =''; @track SelectedPiklistVertical ='Hanger Business';
   @track pleaseselsectBusinessvertical=Please_select_a_Bussiness_Vertical;@track Error=Error; @track pleaseselectPreferdCurrency =Please_Select_a_Preferred_Currency;
    @track Catalogcmp =false; @api selectRetailercode; @track labels='Labels & Tickets'; @api DisplayRetailers =false;
    @track currentUrl;
    connectedCallback(){
        this.DisplayRetailers=true;
        this.Getcontactid();
        
    }

    Getcontactid(){

        getcostomerinfo()
        .then(result => {
            // this.showSpinner = false;
            if(result) 
            {
                console.log('result--> '+JSON.stringify(result));
                this.selectcustomeidstoCatalogOrder = result.Customer_Information__c;
                // alert(this.selectcustomeidstoCatalogOrder);
                var custInfoId =result.Customer_Information__c;
                this.toCheckSORetailer(custInfoId);
            }
        })
        .catch(error => {
            // this.showSpinner = false;
            if (Array.isArray(error.body)) {
                if (error.body[0] && error.body[0].message) {
                    alert("Error message: " + error.body[0].message);
                }
            } else {
                alert("Unknown error");
            }
        });
    }
    //customlabels
    get DocImage(){
        return Doc_image;
    }
    get labelRetailer(){
        return Retailer;
    }
    get RetailerCode(){
        return Retailer_Code_Please_select_a_Retailer;
    }
    get OrderSelection(){
        return Order_Selection;
    }
    get SelectedRetailer(){
        return Selected_Retailer;
    }
    get OrderBusinessVertical(){
        return Order_Bussiness_Vertical;
    }
    get OrderToCompanyss(){
        return Order_To_Company;
    }
    get preferdCurency(){
        return Preferred_Currency;
    }
    get Cancel(){
        return Cancel;
    }
    get StartOrder(){
        return Start_Order;
    }
    get HangerBusiness(){
        return HANGERS_AND_ACCESSORIES;
    }
    get LabelsTickets(){
        return LABELS_AND_TICKETS;
    }
    get FlexiblePackaging(){
        return FLEXIBLE_PACKAGING;
    }
    get MCare(){
return MCARE;
    }
    get TLA(){
        return STRUCTURAL_PACKAGING;
    }
    get INTELLIGENTSOLUTIONS(){
        return EAS_AND_RFID;
    }



        toCheckSORetailer(custInfoId) {
    
        // this.currentUrl = window.location.href;
        // alert('currentUrl '+this.currentUrl);
        // var sParameterName = currentUrl.split('=');
      //  alert('sParameterName '+sParameterName[1]);

      let custId = custInfoId
      console.log('check custInfoId -->'+custId);
            checkRetailerInSO({
                 customerid: custId
                //  punchoutRqtId : 'a2vF4000003guiaIAA'
                 })
                .then(result => {
                    console.log('ressss--> '+JSON.stringify(result));
                    if (result && result.Retailer_Code1__c) {
                        this.onselectRetailercode = result.Retailer_Code1__c;
                        this.Retailerselect = result.Retailer_Code1__r.Name;
                        console.log('Retailerselect check'+this.Retailerselect);
                        this.cartVertical = result.Vertical__c;
                        this.cartCompany = result.Company__c;
                        this.cartCurrency = result.CurrencyIsoCode;
                        this.isCartCreated = true;
                        this.loadCatalogOrder();
                    } else {
                        this.toGetRetailerData();
                    }
                })
                .catch(error => {
                    console.error("Error message: " + error.body.message);
                });
        }

        toGetRetailerData(event){
            retailerCodeDisplay()
            .then(result => {
                if(result){
                this.RoList = result;
                console.log('RoList-->'+JSON.stringify(this.RoList));
                let RList =this.RoList;
                for(var i=0;i<RList.length;i++){
            if(RList[i].Name){
                this.Retailerselect = RList[i].Name;
                this.selectRetailercode = RList[i].Id;
                // alert('selectedretrailercodein  displayy>>>>'+this.selectRetailercode );
                // this.selectRetailercode =this.onselectRetailercode;
            }
        }
        let controllingValue =this.Retailerselect;
        let controllingFields ='Retailer_Code_Hidden__c';
        let dependentField ='Order_Country__c';
        this.pickListVal(controllingValue,controllingFields,dependentField);
        this.SelectRetailer=this.Retailerselect;
        this.GetcustomInfoid();
        this.showConfirmDialog =true;
        // alert('show popup');
                }
            })
            .catch(error => {
                console.error("Error message: " + error.body.message);
            });
        } 

        loadCatalogOrder(){
            this.retailercmp = false;
            this.catalogcmp = true;
        }

        // catalogcmp(event){
        //  this.Retailerselect = event.currentTarget.dataset.name;
        // //  alert(this.Retailerselect);
         
        // }

pickListVal(controllingValue,controllingFields,dependentField){
   
    getDependentPicklistValues({
        controllingValue : controllingValue,
        controllingFields :controllingFields,
        dependentField : dependentField
    })
    .then(result => {
        
          if(result){
            if(dependentField=='Order_Country__c')
            {
              
               this.listOfCompanies = result;
            }
            else if(dependentField =='Preferred_Currency__c'){
            this.listOfCurrency =result;
          }
        }
        
    })
    .catch(error => {
        console.error("Error message: " + error.body.message);
    });
}

GetcustomInfoid(){
    getcostomerRetailerData({
        retailerCode : this.SelectRetailer
    })
    .then(result => {
       this.selectedCompany =result.Order_to_Company__c;
       this.SelectedPiklistCompany=result.Order_to_Company__c;
       let controllingValue= this.selectedCompany;
       let controllingFields='Order_Country__c';
       let dependentField ='Preferred_Currency__c';
       this.pickListValues(controllingValue,controllingFields,dependentField);
       this.selectedCurrency=result.Preferred_Currency__c;
       this.SelectedPiklistCurrency=result.Preferred_Currency__c;
    })
    .catch(error => {
        console.error("Error message: " + error.body.message);
    });
}

pickListValues(controllingValue,controllingFields,dependentField){
    
    getDependentPicklistValues({
        controllingValue : controllingValue,
        controllingFields :controllingFields,
        dependentField : dependentField
    })
    .then(result => {
        
            if(dependentField=='Order_Country__c')
            {
              
               this.listOfCompanies = result;
            }
            else if(dependentField =='Preferred_Currency__c'){
            this.listOfCurrency =result;
          }
        
    })
    .catch(error => {
        console.error("Error message: " + error.body.message);
    });
}
     OrderToCompany(event){
    let controllingValue = event.target.value;
    let controllingFields='Order_Country__c';
    let dependentField='Preferred_Currency__c';

    this.pickListVal(controllingValue,controllingFields,dependentField);
    this.SelectedPiklistCompany =controllingValue;
    this.selectedCurrency ='NULL';
    this.SelectedPiklistCurrency ='NULL';

}
onVerticleChange(event){
    let gettabs =event.target.value;
    this.SelectedPiklistVertical =gettabs;

}
preferredCurrency (event){
    let getCurency =event.target.value;
    this.SelectedPiklistCurrency =getCurency;
}
cancelPopUp(){
    this.showConfirmDialog =false;
    this.selectedCompany=null;
    this.selectedCurrency=null;
    this.DisplayRetailers=true;
}
handleStartOrder(){
    let vertical = this.SelectedPiklistVertical ;
    let company =  this.SelectedPiklistCompany ;
    let currency = this.SelectedPiklistCurrency ;
    if(vertical == ''){
        const evt = new ShowToastEvent({
            title: this.Error,
            message: this.pleaseselsectBusinessvertical,
            variant: 'Error',
            mode: 'dismissable'
        });
        this.dispatchEvent(evt)
       return;
   }
   else{
    this.cartVertical =vertical;
}
if(company == '' || company == 'NULL')
{
    const evt = new ShowToastEvent({
        title: this.Error,
        message: this.pleaseselectPreferdCurrency,
        variant: 'Error',
        mode: 'dismissable'
    });
    this.dispatchEvent(evt)
   return;
}
else{
    this.cartCompany=company;
   // this.cartCurrency=currency;
}
if(currency == '' || currency == 'NULL' )
{
    const evt = new ShowToastEvent({
        title: this.Error,
        message: 'Please Select Order company',
        variant: 'Error',
        mode: 'dismissable'
    });
    this.dispatchEvent(evt)
    return;
}
else{
    this.cartCurrency=currency;
}
if(this.cartVertical != '' &&  this.cartCompany != '' && this.cartCurrency != ''){
    this.loadCatalogOrder();
    this.showConfirmDialog =false;

}
else{
    alert('Error');
}
}
loadCatalogOrder(){
this.Catalogcmp=true;
this.Retailercmp =false;
   
}


}