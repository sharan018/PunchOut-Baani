import { LightningElement,api,track,wire } from 'lwc';
import Cancel from '@salesforce/label/c.Cancel';
import Confirm_Purchase_Order from '@salesforce/label/c.Confirm_Purchase_Order';
import Confirm_Sales_Order from '@salesforce/label/c.Confirm_Sales_Order';
import Details from '@salesforce/label/c.Details';
import Order_To_Company from '@salesforce/label/c.Order_To_Company';
import Preferred_Currency from '@salesforce/label/c.Preferred_Currency';
import Expected_Ex_Factory_Date from '@salesforce/label/c.Expected_Ex_Factory_Date';
import Retailer_PO from '@salesforce/label/c.Retailer_PO';
import Delivery_Instruction from '@salesforce/label/c.Delivery_Instruction';
import Factory_Internal_PO from '@salesforce/label/c.Factory_Internal_PO';
import Retailer_Information from '@salesforce/label/c.Retailer_Information';
import Retailer_Code from '@salesforce/label/c.Retailer_Code';
import Supplier_Vendor_Code from '@salesforce/label/c.Supplier_Vendor_Code';
import Manufacturer_Factory_POF_Code from '@salesforce/label/c.Manufacturer_Factory_POF_Code';
import Customer_comment_and_Remarks from '@salesforce/label/c.Customer_comment_and_Remarks';
import Bill_To from '@salesforce/label/c.Bill_To';
import Ship_To from '@salesforce/label/c.Ship_To';
import { RefreshEvent } from 'lightning/refresh';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import FetchCustAddForCatalogOrder from '@salesforce/apex/PunchOutRequestController.FetchCustAddForCatalogOrder';
import convertPOstoSo from '@salesforce/apex/SOController.convertPOstoSo';
import saveCatalogSOPDF from '@salesforce/apex/SOController.saveCatalogSOPDF';
import updateSalesOrderForPDF from '@salesforce/apex/SOController.updateSalesOrderForPDF';
import SaveBaseOrder from '@salesforce/apex/PunchOutRequestController.SaveBaseOrder';
// import SaveOrder from '@salesforce/apex/SOController.SaveOrder';
import customerEmailAfterPOtoSOconversion from '@salesforce/apex/SOController.customerEmailAfterPOtoSOconversion';
import uncheckPoCheckbox from '@salesforce/apex/SOController.uncheckPoCheckbox';
import sendSOEmailToCustomer from '@salesforce/apex/SOController.sendSOEmailToCustomer';
import toCancelOrder from '@salesforce/apex/PunchOutRequestController.toCancelOrder';
import cancelPOChanges from '@salesforce/apex/SOController.cancelPOChanges';
import DependentPicklist from '@salesforce/apex/SOController.DependentPicklist';
import deleteInactiveModel from '@salesforce/apex/PunchOutRequestController.deleteInactiveModel';
import getPunchoutRequestId from '@salesforce/apex/PunchOutRequestController.getPunchoutRequestId';
import getLeadTime from '@salesforce/apex/PunchOutRequestController.getLeadTime';
import getAllActiveCartDetails from '@salesforce/apex/PunchOutRequestController.getAllActiveCartDetails';
import getAllOldShipTO from '@salesforce/apex/PunchOutRequestController.getAllOldShipTO';
import ToastContainer from 'lightning/toastContainer';
import {CurrentPageReference} from 'lightning/navigation';
import { registerListener } from 'c/pubsub';


export default class SalesOrderAddressForCatalogOrderLwc extends LightningElement {
    @api retailerName;
    @api retailerCodeId;
    @api customerInfoId;
    @api shipTermList;
    @api companyList;
    @api currencyList;
    // @api orderDetailFlag ;
    @track orderDetailFlag= true;
    @api addressPopupFlag;
    // <!-- Address -->
    @api billAddressList;
    @api shipAddressList;
    @api buyerAddressList;
    @api invoiceAddressList;
    @track addressPopupFlag;
    @api billAddressIndex;
    @api shipAddressIndex;
    @api buyerAddressIndex;
    @api invoiceAddressIndex;
    @api orderSource;
    @api suzhouFlag;
    @api popdfFlag;
    @api salesOrderObj = {
        sobjectType: 'Sales_Order__c',
        // Other fields specific to your Sales_Order__c object
        // For example: Name: 'Your default value for Name field'
        // Add other fields here as needed
    };

    // <!-- PO to SO -->
    @api comfirmPOList;
    // <!-- Catalog -->
    @api companyName;
    @api currencyName;
    @api seasonList;
    @api seasonYearList;
    @api divisionList;
    @api expectedDeliveryDate;
    @api brandLabelList;
    // <!--SO Conversion Choice of Single SO /Multiple So -->
    @api sOChoiceFlag;
    // <!-- Mask/UnMask of Supplier and Manufacturer Code -->
    @api supplierUnMask = false;
    @api manufacturerUnMask = false;
    @api mandatoryCheck = {sobjectType: 'Retailer_Code__c',};
        // Add other fields and default values specific to Retailer_Code__c object
    
    @api toUncheck = [];
    @api divisionCheck = false;
    @api seasonCheck = false;
    @api seasonYearCheck = false;
    @api retailerCheck = false;
    @api brandLabelCheck = false;
    @api remarksCheck = false;
    @track deliveryInstructionOptions=[];

    @track spinnerClass = 'slds-hide';
    @track sourceOrder;
    @api tablesizeExpand; // Assuming this is a boolean property indicating whether to expand the table size
    @track tableClass = 'slds-table slds-table1';
    @api displayCartDetail;
    @track LeadTime;
    @track ShipAddressListOld =[];
    @track OldShipTo = false;
    @api StringList;
    
    position = 'top-center';
    toastContainerObj = ToastContainer.instance();


    @wire(CurrentPageReference) pageRef;
    connectedCallback(){
        alert('salesOrderAddressForCatalogOrder');
        this.getLeadDate();
        this.AllActiveCartDetails();
        this.getAllOldShipTOAddress();

            this.toGetCustomerAddess();
            console.log('this.orderSource -->> '+this.orderSource);
            if (this.orderSource === 'PO') {
                const confirmPO = this.comfirmPOList;
                const po = confirmPO[0].POwrap;
                // alert('po ' + JSON.stringify(confirmPO[0].POwrap));
                this.salesOrderObj.Retailer_Code1__c = po.Retailer_Code1__c;
                this.toGetDependentValues(po.Retailer_Code1__r.Name, 'Retailer_Code_Hidden__c', 'Order_Country__c');
                this.retailerName = po.Retailer_Code1__r.Name;
    
                let retailerPOnumber = '';
                for (let i = 0; i < confirmPO.length; i++) {
                    if (i !== 0) {
                        retailerPOnumber += ',';
                    }
                    retailerPOnumber += confirmPO[i].POwrap.Order_Number__c;
                }
                this.salesOrderObj.Order_Number__c = retailerPOnumber;
            }
            var today = new Date();
            // today.setDate(today.getDate() + this.LeadTime);
            var formattedDate = today.toISOString().slice(0, 10);
            this.salesOrderObj.Expected_Delivery_Date__c = formattedDate;
            console.log('formatted date-->'+formattedDate);

            let getSourceOrder = this.orderSource;
            if(getSourceOrder == "PO"){
                this.sourceOrder = true;
            }else{
                this.sourceOrder = false;
            }

            this.updateTableClass();
            registerListener('onaddressSelect', this.changeAddress, this); 
            this.toGetrequestIdId();
        }

        
        updateTableClass() {
            // Check the value of tablesizeExpand and update the tableClass accordingly
            this.tableClass = this.tablesizeExpand ? 'slds-table slds-table1' : 'slds-table slds-table2';
        } 

getLeadDate(){
    alert('inside getLeadDate()');
        getLeadTime({punchoutID : '123'})
        .then(result=>{
            console.log('getLeadTime result --> '+result);
            var returnValue = result;
            this.LeadTime = returnValue;
            console.log("LeadTime --> "+this.LeadTime);
            var today = new Date();
            today.setDate(today.getDate() + this.LeadTime);
            var formattedDate = today.toISOString().slice(0, 10);
            this.salesOrderObj.Expected_Delivery_Date__c = formattedDate;
            console.log("formattedDate --> "+formattedDate);
        })
        .catch(error=>{
            console.log('Error occured in getLeadTime '+ error);
        })
    }
       

    AllActiveCartDetails(){

        getAllActiveCartDetails()
        .then(result=>{
            var activeCartProducts = result;
            this.displayCartDetail = activeCartProducts;
            // this.displayCartDetail = this.displayCartDetail.map(cartDetail => ({
            //     ...cartDetail,
            //     formattedValue: cartDetail.CurrencyIsoCode + ' ' + cartDetail.BlankString + ' ' + cartDetail.TotalPriceByCurrency
            // }));
            console.log('activeCartProducts --> '+JSON.stringify(activeCartProducts));
        })
        .catch(error=>{
            console.log('Error occured in getAllActiveCartDetails '+ error);
        })
    }

    getAllOldShipTOAddress(){
        getAllOldShipTO()
        .then(result=>{
            var res = result;
            console.log('getAllOldShipTO result -->'+JSON.stringify(result));
            this.ShipAddressListOld = res.billAddListRqt;
            console.log('Bill Old TO<><>>'+JSON.stringify(res.billAddListRqt));
            this.OldShipTo = res.billAddListRqt;
            console.log('Old Ship TO<><>>'+JSON.stringify(this.OldShipTo));

            var oldShipto = res;
            if(this.OldShipTo){
                const toastEvent = new ShowToastEvent({
                    title: 'Alert',
                    message: "ShipTo Address is Changed",
                    variant: 'Alert'
                });
                this.dispatchEvent(toastEvent);
                return;
            }
        })
        .catch(error=>{
            console.log('Error occured in getAllOldShipTO '+ error);
        })
    }

    changeDate(event){
        // var givenDate = this.salesOrderObj.Expected_Delivery_Date__c;
         var givenDate = event.detail.value;
        console.log("givenDate:"+givenDate);
        this.salesOrderObj.Expected_Delivery_Date__c = givenDate;
        const today = new Date();
        today.setDate(today.getDate() + this.LeadTime);
        const presentDate = today.toISOString().slice(0, 10);
        console.log("presentDate:"+presentDate);
        if(givenDate<presentDate){
            const toastEvent = new ShowToastEvent({
                title: 'warning',
                message: 'Expected Ex Factory Date must be later than today',
                variant: 'warning'
            });
            this.dispatchEvent(toastEvent);
            event.preventDefault();
            return;
        }
        // if(givenDate!=undefined){
            
        //     return;
        // }
    }
    get Cancel(){return Cancel;}
    get Confirm_Purchase_Order(){return Confirm_Purchase_Order;}
    get Confirm_Sales_Order(){return Confirm_Sales_Order;}
    get Details(){return Details;}
    get Order_To_Company(){return Order_To_Company;}
    get Preferred_Currency(){return Preferred_Currency;}
    get Expected_Ex_Factory_Date(){return Expected_Ex_Factory_Date ;}
    get Retailer_PO(){return Retailer_PO;}
    get Delivery_Instruction(){return Delivery_Instruction;}
    get Factory_Internal_PO(){return Factory_Internal_PO;}
    get Retailer_Information(){return Retailer_Information;}
    get Retailer_Code(){return Retailer_Code;}
    get Supplier_Vendor_Code(){return Supplier_Vendor_Code;}
    get Manufacturer_Factory_POF_Code(){return Manufacturer_Factory_POF_Code;}
    get Customer_comment_and_Remarks(){return Customer_comment_and_Remarks;}
    get Bill_To(){return Bill_To;}
    get Ship_To(){return Ship_To;}


    @track companyOptions =[];

    handleOrderToCompany(event) {
        var compName = event.detail.value;
        this.salesOrderObj.Company__c = compName;
        this.toGetDependentValues(compName,'Order_Country__c','Preferred_Currency__c');
        var SO = this.salesOrderObj;
        SO.CurrencyIsoCode='NULL';
        this.salesOrderObj=SO;
        var compName = event.detail.value;
        this.toGetDependentValues(compName,'Order_Country__c','Delivery_Instruction__c');
        if(compName.includes("SuzhouX"))
        {
            this.suzhouFlag=true;
            if(this.buyerAddressList.length==0)
            {
                const toastEvent = new ShowToastEvent({
                    title: 'warning',
                    message: 'Please update default company as Suzhou and add at least 1 Buyer address',
                    variant: 'warning'
                });
                this.dispatchEvent(toastEvent);
                return; 
            }
            if(this.invoiceAddList.length == 0){
                const toastEvent = new ShowToastEvent({
                    title: 'warning',
                    message: 'Please update default company as Suzhou and add at least 1 Invoice To address',
                    variant: 'warning'
                });
                this.dispatchEvent(toastEvent);
                return;
            }
        }else{
            this.suzhouFlag=false;
        }
    }

    handlePreferredCurrency(event){
        var selectedCurrency = event.detail.value;

        var SO =this.salesOrderObj;
        SO.CurrencyIsoCode=selectedCurrency;
    }
    
    @track selectedOption='None';
    @track selectedBrandLabel='None';
    @track selectedDivision='None';
    @track selectedSeason='None';
    @track selectedSeasonYear='None';
    @track remarkText;

@track requestId;
    toGetrequestIdId(){
        getPunchoutRequestId()
            .then(result=>{
                console.log(' getPunchoutRequestId '+JSON.stringify(result));
              this.requestId=result;
            })
            .catch(error=>{
              console.log('Error in fetching result'+error);
            }) 

    }
    toGetCustomerAddess(){
        var custInfoid = this.customerInfoId;
        var retailerName = this.retailerName;
        console.log("retailer name>>>>" + retailerName);
        console.log("custInfoid >>>>" + custInfoid);
        this.retailerCodeId = 'a00O000000mDAkPIAW';
        console.log("retailerCodeId >>>>" + this.retailerCodeId);

        FetchCustAddForCatalogOrder({custInfoid:custInfoid,
            retailer:retailerName,
            retailercodeId:this.retailerCodeId,
            orderSource:this.orderSource})
        .then(result =>{
            console.log('FetchCustAddForCatalogOrder result --> '+JSON.stringify(result));
            this.billAddressList = result.shipAddList;
            this.shipAddressList = result.billAddListRqt;
            console.log('shipAddressList result --> '+JSON.stringify(result.billAddListRqt));

            this.buyerAddressList = result.buyerAddList;
            this.invoiceAddressList = result.invoiceAddList;
            this.shipTermList = result.shipTermList;
            this.deliveryInstructionOptions = [{ label: "None", value: 'None' },...this.shipTermList.map(option => ({ label: option, value: option }))];
           
            this.suzhouFlag = result.SuzhouFlag;
            this.seasonList = result.seasonsList;
            this.seasonListOptions = [{ label: "None", value: 'None' },...this.seasonList.map(option => ({label: option,value: option}))];

            this.seasonYearList = result.seasonsYearList;
            this.seasonYearListOptions = [{ label: "None", value: 'None' },...this.seasonYearList.map(option => ({label: option,value: option}))];

            this.divisionList = result.divisionList;
            this.divisionListOptions =[{ label: "None", value: 'None' },... this.divisionList.map(option => ({label: option,value: option}))];

            this.brandLabelList = result.brandLabelList;
            this.brandLabelListOptions =[{ label: "None", value: 'None' },...this.brandLabelList.map(option => ({label: option,value: option}))];
            
           
            this.supplierUnMask = result.SOUnMask;
            this.manufacturerUnMask = result.MOUnMask;
            this.mandatoryCheck = result.MandatoryCheckFields;
            console.log('order source --> '+result.protoSO.OrderSource__c);
            if(result.protoSO.OrderSource__c == 'Cloned'){
                var today = new Date();
                const options = { year: 'numeric', month: '2-digit', day: '2-digit' };
                var formattedDate = today.toLocaleDateString('en-US', options);
                result.protoSO.Expected_Delivery_Date__c = formattedDate;
                this.salesOrderObj = result.protoSO;
            }else{
                this.salesOrderObj.Supplier_Code__c = result.protoSO.Supplier_Code__c;
                this.salesOrderObj.Manufacturer_Code__c = result.protoSO.Manufacturer_Code__c;
                this.salesOrderObj.Id = result.protoSO.Id;
            }
            console.log("salesOrderObj -->>>>" + JSON.stringify(this.salesOrderObj));
            var checkFlag = this.mandatoryCheck;
            for (var j = 0; j < checkFlag.length; j++) {
                this.divisionCheck=checkFlag[j].Division_Mandatory__c;
                this.seasonCheck=checkFlag[j].Season_Mandatory__c;
                this.seasonYearCheck=checkFlag[j].Season_Year_Mandatory__c;
                this.retailerCheck=checkFlag[j].Retailer_PO_Mandatory__c;
                this.brandLabelCheck=checkFlag[j].Brand_Label_Mandatory__c;
                // alert('brandLabelCheck --> '+JSON.stringify(this.brandLabelCheck));
                this.remarksCheck=checkFlag[j].MG_Remarks_Mandatory__c;
                // alert('remarksCheck --> '+JSON.stringify(this.remarksCheck));
        }
            if(this.orderSource == "PO"){
                var currencyListVar = this.toGetDependentValues(result.defaultCompany, 'Order_Country__c', 'Preferred_Currency__c');
                this.currencyList = currencyListVar;
                this.salesOrderObj.Company__c = result.defaultCompany;
                this.salesOrderObj.CurrencyIsoCode = result.defaultCurrency;

                if(result.defaultCompany.includes("Suzhou2")){
                    this.toastContainerObj.toastPosition = 'Top Center';
                    if(result.buyerAddList.length == 0){
                        const toastEvent = new ShowToastEvent({
                            title: 'warning',
                            message: 'Please update default company as Suzhou and add at least 1 Buyer address',
                            variant: 'warning'
                        });
                        this.dispatchEvent(toastEvent);
                        return;
                    }
                    if(result.invoiceAddList.length == 0){
                        this.toastContainerObj.toastPosition = 'Top Center';
                        const toastEvent = new ShowToastEvent({
                            title: 'warning',
                            message: 'Please update default company as Suzhou and add at least 1 Invoice To address',
                            variant: 'warning'
                        });
                        this.dispatchEvent(toastEvent);
                        return;
                    }
                }
            }else{
                this.companyName=result.defaultCompany;
                this.currencyName=result.defaultCurrency;
                if(result.defaultCompany.includes("Suzhou2")){
                    this.suzhouFlag =true;
                    if(result.buyerAddList.length == 0){
                        // alert('warning -->> '+'Please update default company as Suzhou and add at least 1 Buyer address');
                        this.toastContainerObj.toastPosition = 'Top Center';
                        const toastEvent = new ShowToastEvent({
                            title: 'warning',
                            message: 'Please update default company as Suzhou and add at least 1 Buyer address',
                            variant: 'warning'
                        });
                        this.dispatchEvent(toastEvent);
                        return;
                    }
                    if(result.invoiceAddList.length == 0){
                        this.toastContainerObj.toastPosition = 'Top Center';
                        const toastEvent = new ShowToastEvent({
                            title: 'warning',
                            message: 'Please update default company as Suzhou and add at least 1 Invoice To address',
                            variant: 'warning'
                        });
                        this.dispatchEvent(toastEvent);
                        // alert('warning -->> '+'Please update default company as Suzhou and add at least 1 Invoice address');
                        this.salesOrderObj.Company__c = 'NULL';
                        return;
                    }
                }
            }
            console.log('result.protoSO.OrderSource --> '+result.protoSO.OrderSource__c);
            if(result.protoSO.OrderSource__c == 'Cloned'){
                this.getSelectedAddress();
            }else{
                this.getDefaultAddress();
            }
        })
    }


    handleRetailerPo(event){
        var givenRetailerNumber = event.detail.value;
        var SO = this.salesOrderObj;
        SO.Order_Number__c = givenRetailerNumber;
    }

    handleBrandLabelList(event) {
        this.selectedBrandLabel = event.detail.value;
        var SO = this.salesOrderObj;
        SO.Brand_Label__c =this.selectedBrandLabel; 
      }
      handleDivisionList(event){
        this.selectedDivision = event.detail.value;
        var SO = this.salesOrderObj;
        SO.Division__c =this.selectedDivision;
      }  
      handleSeasonOption(event){
        this.selectedSeason = event.detail.value;
        var SO = this.salesOrderObj;
        SO.Season__c =this.selectedSeason;
      } 
      handleSeasonYearOption(event){
        this.selectedSeasonYear = event.detail.value;
        var SO = this.salesOrderObj;
        SO.Season_Year__c =this.selectedSeasonYear;
      }
      handleDeliveryInst(event){
        this.selectedOption = event.detail.value;
        var SO = this.salesOrderObj;
        SO.Delivery_Instructions__c =this.selectedOption;
      }
      handleRemark(event){
        var text = event.detail.value;
        this.remarkText = text;
        var SO = this.salesOrderObj;
        SO.Remarks__c =this.remarkText;
      }
      handleShippingMark(event){
        var shippingmark = event.detail.value;
        var SO=this.salesOrderObj;
        SO.Shipping_Mark__c = shippingmark;
      }
      handleForwarderTransportationDetails(event){
        var forwdTransDetails = event.detail.value;
        var SO=this.salesOrderObj;
        SO.Transportation_Details__c = forwdTransDetails;
      }

    toGetDependentValues(controllingValue, controllingFields, dependentField){
        DependentPicklist({controllingValue: controllingValue,controllingFields: controllingFields,dependentField: dependentField})
        .then(result =>{
            if (dependentField == 'Order_Country__c'){
                this.companyList = result;
            }else if (dependentField == 'Preferred_Currency__c'){
                this.currencyList = result;
            }else if (dependentField == 'Delivery_Instruction__c'){
                this.shipTermList = result;
            }
        })
        .catch(error=>{
            this.error = error.message;
            console.log('error==>'+this.error);
        })
    }

    getSelectedAddress(){
        var so = this.salesOrderObj;
        var BillAddressList = this.billAddressList;
        var BillAddressIndex = this.billAddressIndex;
        for (var i = 0; i < BillAddressList.length; i++) {
            if (BillAddressList[i].Id == so.Bill_to_Address__c) {
                BillAddressList[i].Is_Default__c = true;
                BillAddressIndex = i;
            }
            else
                BillAddressList[i].Is_Default__c = false;
        }
        this.billAddressList = BillAddressList;
        this.billAddressIndex = BillAddressIndex;

        var ShipAddressList = this.shipAddressList;
        var ShipAddressIndex = this.shipAddressIndex;
        for (var i = 0; i < ShipAddressList.length; i++) {
            if (ShipAddressList[i].Id == so.Ship_to_Address__c) {
                ShipAddressList[i].Is_Default__c = true;
                ShipAddressIndex = i;
            }
            else
                ShipAddressList[i].Is_Default__c = false;
        }
        this.shipAddressList = ShipAddressList;
        this.shipAddressIndex = ShipAddressIndex;

        var BuyerAddressList = this.buyerAddressList;
        var BuyerAddressIndex = this.buyerAddressIndex;
        for (var j = 0; j < BuyerAddressList.length; j++) {
            if (BuyerAddressList[j].Is_Default__c) {
                BuyerAddressList[j].Is_Default__c = true;
                BuyerAddressIndex = i;
            }
            else
                BuyerAddressList[j].Is_Default__c = false;
        }
        this.buyerAddressList = BuyerAddressList;
        this.buyerAddressIndex = BuyerAddressIndex;

        var InvoiceAddressList = this.invoiceAddressList;
        var InvoiceAddressIndex = this.invoiceAddressIndex;
        for (var k = 0; k < InvoiceAddressList.length; k++) {
            if (InvoiceAddressList[k].Is_Default__c) {
                InvoiceAddressList[k].Is_Default__c = true;
                InvoiceAddressIndex = i;
            }
            else
                InvoiceAddressList[k].Is_Default__c = false;
        }
        this.invoiceAddressList = InvoiceAddressList;
        this.invoiceAddressIndex = InvoiceAddressIndex;
    }

    getDefaultAddress(){
        var BillAddressList = this.billAddressList;
        var BillAddressIndex = this.billAddressIndex;
        for (var i = 0; i < BillAddressList.length; i++) {
            if (BillAddressList[i].Is_Default__c)
                BillAddressIndex = i;
        }
        this.billAddressIndex = BillAddressIndex;

        var ShipAddressList = this.shipAddressList;
        var ShipAddressIndex = this.shipAddressIndex;
        for (var i = 0; i < ShipAddressList.length; i++) {
            if (ShipAddressList[i].Is_Default__c)
                ShipAddressIndex = i;
        }
        this.shipAddressIndex = ShipAddressIndex;

        var BuyerAddressList = this.buyerAddressList;
        var BuyerAddressIndex = this.buyerAddressIndex;
        for (var j = 0; j < BuyerAddressList.length; j++) {
            if (BuyerAddressList[j].Is_Default__c)
                BuyerAddressIndex = j;
        }
        this.buyerAddressIndex =BuyerAddressIndex;

        var InvoiceAddressList = this.invoiceAddressList;
        var InvoiceAddressIndex = this.invoiceAddressIndex;
        for (var k = 0; k < InvoiceAddressList.length; k++) {
            if (InvoiceAddressList[k].Is_Default__c)
                InvoiceAddressIndex = k;
        }
        this.invoiceAddressIndex = InvoiceAddressIndex;
    }


    closeModal(){
        this.orderDetailFlag = false;
        var compEvent = new CustomEvent("closepopup", {
            detail: {
                addressPopupFlag: false
            }
        });
        this.dispatchEvent(compEvent);
        // this.addressPopupFlag = false;

      /*  if(this.orderSource=="PO")
        {
            this.cancelPOnPOLIChanges();
        }
        else
        {
            this.cancelOrderChanges();
        }
        */
    }

    // confirmOrder(){
    //     window.open('https://mainetti--magnets1--c.sandbox.vf.force.com/apex/PunchOutPage?requestId='+this.requestId);
    // }
    
    confirmOrder(){
        alert('comfirm order btn clicked');

        var billAddressList = this.billAddressList;
        var checkDefaultBillAddress = false;
        console.log('billAddressList --> '+this.billAddressList);
        for(var i = 0 ; i<billAddressList.length ; i++)
        {
            if(billAddressList[i].Is_Default__c)
            {
                checkDefaultBillAddress = true;
            }
        }
        /*if(!checkDefaultBillAddress){
            // alert('error -->> '+'Select atleast one default billing Address');
            this.toastContainerObj.toastPosition = 'Top Center';
            const event = new ShowToastEvent({
                title: 'error',
                message: "Select atleast one default billing Address",
                variant: 'error',
            });
            this.dispatchEvent(event);
            return  
        }*/
        var ShipAddressList = this.shipAddressList;
        console.log('shipAddressList --> '+this.shipAddressList);
        var checkDefaultShippAddress = false;
        for(var i = 0 ; i<ShipAddressList.length ; i++)
        {
            if(ShipAddressList[i].Is_Default__c)
            {
                checkDefaultShippAddress = true;
            }
        }
     /*   if(!checkDefaultShippAddress)
        {
            this.toastContainerObj.toastPosition = 'Top Center';
            const event = new ShowToastEvent({
                title: 'error',
                message: "Please select atleast one default shipping Address",
                variant: 'error',
            });
            this.dispatchEvent(event);
            // alert('error -->> '+'Select atleast one default shipping Address');
            return
        }*/

        var SO =this.salesOrderObj;
        if(this.orderSource == "PO"){
            if(SO.Company__c==null||SO.Company__c==''){
                this.toastContainerObj.toastPosition = 'Top Center';
                const event = new ShowToastEvent({
                    title: 'Warning',
                    message: "Please select Order To Company",
                    variant: 'Warning',
                });
                this.dispatchEvent(event);
                return
            }
            if(SO.CurrencyIsoCode == null || SO.CurrencyIsoCode ==''){
                this.toastContainerObj.toastPosition = 'Top Center';
                const event = new ShowToastEvent({
                    title: 'Warning',
                    message: "Please select Preferred Currency",
                    variant: 'Warning',
                });
                this.dispatchEvent(event);
            // alert('Warning -->> '+'Please select Preferred Currency');
                return 
            }
            if(SO.Delivery_Instructions__c == 'None' || SO.Delivery_Instructions__c ==undefined){
                this.toastContainerObj.toastPosition = 'Top Center';
                const event = new ShowToastEvent({
                    title: 'Warning',
                    message: "Please select Delivery Instruction",
                    variant: 'Warning',
                });
                this.dispatchEvent(event);
                // alert('Warning -->> '+'Please select Delivery Instruction');
                return 
            }
            // validations for Supplier Code and Manufacturer Code
            if(SO.Supplier_Code__c == null || SO.Supplier_Code__c ==''){
                this.toastContainerObj.toastPosition = 'Top Center';
                const event = new ShowToastEvent({
                    title: 'Warning',
                    message: "Please give Supplier Code",
                    variant: 'Warning',
                });
                this.dispatchEvent(event);
                // alert('Warning -->> '+'Please select Supplier Code');
                return 
            }
            if(SO.Supplier_Code__c != null && SO.Supplier_Code__c.length> 255){
                this.toastContainerObj.toastPosition = 'Top Center';
                const event = new ShowToastEvent({
                    title: 'Warning',
                    message: "Supplier Vendor Code should be less than or equal to 255 characters",
                    variant: 'Warning',
                });
                this.dispatchEvent(event);           
                // alert('Warning -->> '+'Supplier Vendor Code should be less than or equal to 255 characters');
                return
            }
            if(SO.Manufacturer_Code__c == 'NULL' || SO.Manufacturer_Code__c ==''){
                this.toastContainerObj.toastPosition = 'Top Center';
                const event = new ShowToastEvent({
                    title: 'Warning',
                    message: "Please select Manufacturer Code",
                    variant: 'Warning',
                });
                this.dispatchEvent(event);
                // alert('Warning -->> '+'Please select Delivery Instruction');
                return 
            }
            if(SO.Manufacturer_Code__c != null && SO.Manufacturer_Code__c.length >255){
                this.toastContainerObj.toastPosition = 'Top Center';
             const event = new ShowToastEvent({
                    title: 'Warning',
                    message: "Manufacturer Factory POF Code should be less than or equal to 255 characters",
                    variant: 'Warning',
                });
                this.dispatchEvent(event);
                // alert('Warning -->> '+'Manufacturer Factory POF Code should be less than or equal to 255 characters');
                return
            }
            //new date validation to be later thAn today
            var today = new Date();
            today.setDate(today.getDate() + this.LeadTime);
            var presentDate = today.toISOString().slice(0, 10);
            console.log('presentDate -->> '+presentDate);
            alert('presentDate -->> '+presentDate);
            // this.salesOrderObj.Expected_Delivery_Date__c = presentDate;
            if(SO.Expected_Delivery_Date__c<presentDate)
            {
                this.toastContainerObj.toastPosition = 'Top Center';
                const event = new ShowToastEvent({
                    title: 'Warning',
                    message: "Expected Ex Factory Date must be later than today",
                    variant: 'Warning',
                });
                this.dispatchEvent(event);
                event.preventDefault();
                // alert('Warning -->> '+'Expected Ex Factory Date must be later than today');
                return 
            }
            this.unCheckAllPO();
            this.convertPOToSalesOrder();
        }else{
            // alert('inside elseeeeeee');

            var check=this.mandatoryCheck;
        console.log('mandatoryCheck --> '+this.mandatoryCheck);
            for(var j=0;j<check.length;j++){
                console.log("inside>>"+JSON.stringify(check[j].Season_Mandatory__c)+SO.Season__c);
                if(check[j].Season_Mandatory__c==true && SO.Season__c==undefined || SO.Season__c=='None'){
                    this.toastContainerObj.toastPosition = 'Top Center';
                    const event = new ShowToastEvent({
                        title: 'Warning',
                        message: "Please select a Season",
                        variant: 'Warning',
                    });
                    this.dispatchEvent(event);
                    // alert('Warning -->> '+'Please select a Season');
                    return
                }
                if(check[j].Brand_Label_Mandatory__c==true && SO.Brand_Label__c==undefined || SO.Brand_Label__c=='None'){
                    this.toastContainerObj.toastPosition = 'Top Center';
                        const event = new ShowToastEvent({
                            title: 'Warning',
                            message: "Please select a Label",
                            variant: 'Warning',
                        });
                        this.dispatchEvent(event);
                        // alert('Warning -->> '+'Please select a Label');
                        return
                }
                var remarks = SO.Remarks__c;
                var remarksisBlank = this.lineIsBlank(remarks);
               if(check[j].MG_Remarks_Mandatory__c==true && remarksisBlank ){
                this.toastContainerObj.toastPosition = 'Top Center';
               const event = new ShowToastEvent({
                title: 'Warning',
                message: "Please Add Remarks",
                variant: 'Warning',
                });
                this.dispatchEvent(event);
                // alert('Warning -->> '+'Please Add Remarks');
                return
                }
                if(check[j].Season_Year_Mandatory__c==true && SO.Season_Year__c==undefined || SO.Season_Year__c=='None'){
                    this.toastContainerObj.toastPosition = 'Top Center';
                    const event = new ShowToastEvent({
                        title: 'Warning',
                        message: "Please select a Season Year",
                        variant: 'Warning',
                        });
                        this.dispatchEvent(event);
                        // alert('Warning -->> '+'Please select a Season Year');
                        return
                }
            var orderNo = SO.Order_Number__c;
            var orderNoisBlank = this.lineIsBlank(orderNo);
            if(check[j].Retailer_PO_Mandatory__c==true && orderNoisBlank){
                this.toastContainerObj.toastPosition = 'Top Center';
                const event = new ShowToastEvent({
                    title: 'Warning',
                    message: "Please Enter Retailer PO",
                    variant: 'Warning',
                    });
                    this.dispatchEvent(event);
                    // alert('Warning -->> '+'Please Enter Retailer PO');
                    return
            }
            if(check[j].Division_Mandatory__c==true && SO.Division__c==undefined || SO.Division__c=='None'){
                this.toastContainerObj.toastPosition = 'Top Center';
                const event = new ShowToastEvent({
                    title: 'Warning',
                    message: "Please select a Division",
                    variant: 'Warning',
                    });
                    this.dispatchEvent(event);
                    // alert('Warning -->> '+'Please select a Division');
                    return
            }
        }
        if(!SO.Expected_Delivery_Date__c || SO.Expected_Delivery_Date__c == null){
            this.toastContainerObj.toastPosition = 'Top Center';
            const event = new ShowToastEvent({
                title: 'Warning',
                message: "Expected Delivery Date is mandatory",
                variant: 'Warning',
                });
                this.dispatchEvent(event);
                // alert('Warning -->> '+'Expected delivery date is mandatory');
                return
        }
        if(SO.Delivery_Instructions__c==undefined||SO.Delivery_Instructions__c=='None'){
            this.toastContainerObj.toastPosition = 'Top Center';
            const event = new ShowToastEvent({
                title: 'Warning',
                message: "Please select Delivery Instruction",
                variant: 'Warning',
                });
                this.dispatchEvent(event);
                // alert('Warning -->> '+'Please select Delivery Instruction');
                return
        } 
        // validations for Supplier Code and Manufacturer Code
        if(SO.Supplier_Code__c==null ||SO.Supplier_Code__c=='')
         {
            this.toastContainerObj.toastPosition = 'Top Center';
        const event = new ShowToastEvent({
            title: 'Warning',
            message: "Please give a supplier code",
            variant: 'Warning',
            });
            this.dispatchEvent(event);
            // alert('Warning -->> '+'Please give a Supplier code');
            return
        }
        if(SO.Supplier_Code__c != null && SO.Supplier_Code__c.length> 255){
            this.toastContainerObj.toastPosition = 'Top Center';
            const event = new ShowToastEvent({
                title: 'Warning',
                message: "Supplier Vendor Code should be less than or equal to 255 characters",
                variant: 'Warning',
            });
            this.dispatchEvent(event);
            // alert('Warning -->> '+'Supplier Vendor Code should be less than or equal to 255 characters');
            return
        }
        if(SO.Manufacturer_Code__c == 'NULL' || SO.Manufacturer_Code__c ==''){
            this.toastContainerObj.toastPosition = 'Top Center';
            const event = new ShowToastEvent({
                title: 'Warning',
                message: "Please select Manufacturer Code",
                variant: 'Warning',
            });
            this.dispatchEvent(event);
            // alert('Warning -->> '+'Please select Manufacturer Code');
            return 
        }
        if(SO.Manufacturer_Code__c != null && SO.Manufacturer_Code__c.length >255){
            this.toastContainerObj.toastPosition = 'Top Center';
         const event = new ShowToastEvent({
                title: 'Warning',
                message: "Manufacturer Factory POF Code should be less than or equal to 255 characters",
                variant: 'Warning',
            });
            this.dispatchEvent(event);
            // alert('Warning -->> '+'Manufacturer Factory POF Code should be less than or equal to 255 characters');
            return
        }
          //new date validation to be later thAn today
          var today = new Date();
        //   today.setDate(today.getDate() + 1);
        today.setDate(today.getDate() + this.LeadTime);
          var presentDate = today.toISOString().slice(0, 10);
          console.log('presentDate -->> '+presentDate);
          // this.salesOrderObj.Expected_Delivery_Date__c = presentDate;
          if(SO.Expected_Delivery_Date__c<presentDate)
          {
            this.toastContainerObj.toastPosition = 'Top Center';
              const event = new ShowToastEvent({
                  title: 'Warning',
                  message: "Expected Ex Factory Date must be later than today",
                  variant: 'Warning',
              });
              this.dispatchEvent(event);
              event.preventDefault();
            //   alert('Warning -->> '+'Expected Ex Factory Date must be later than today');
              return 
          }
          deleteInactiveModel()
          .then(result=>{
            console.log('INACTIVE Products are deleted'+result);
          })
          .catch(error=>{
            alert('ERROR OCCURED'+JSON.stringify(error.body.message));
          })
        // this.confirmSalesOrder();
        alert('confirmBaseOrder method called');

        this.confirmBaseOrder();

        }
        
    }
    

    confirmBaseOrder()
    {
        var ShipAdd = this.shipAddressList;

        console.log('ShipAdd><>>'+JSON.stringify(ShipAdd));
        alert('inside confirmBaseOrder');

        SaveBaseOrder({"punchoutShipTO": ShipAdd})
        .then(result=>{
            if(result){
                this.toastContainerObj.toastPosition = 'Top Center';
                const toastEvent = new ShowToastEvent({
                    title: 'Success',
                    message: 'Punched Out',
                    variant: 'Success'
                });
                this.dispatchEvent(toastEvent);
                // alert('SaveBaseOrder Punched Out');
                window.open('https://mainetti--magnets1--c.sandbox.vf.force.com/apex/PunchOutPage?requestId='+this.requestId);

                var myParamValue = result;
                console.log('checkingAddAndCloneData>>'+myParamValue);
              var  vfPageUrl = '/apex/PunchOutPage';
            //   var param1='a2jHz0000006jahIAA';
            //   let urlWithParams = `${vfPageUrl}?param1=${param1}`;
            //   window.location.href = urlWithParams;
            //   console.log('url With Params'+urlWithParams);
            
            }
        })
        .catch(error=>{
            alert('ERROR OCCURED.'+JSON.stringify(error.body.message));
        })
    }

   /* openPDF()
    {
        var billAddressList = this.billAddressList;
        var checkDefaultBillAddress = false;
        for(var i = 0 ; i<billAddressList.length ; i++)
        {
            if(billAddressList[i].Is_Default__c)
            {
                checkDefaultBillAddress = true;
            }
        }
        if(!checkDefaultBillAddress){
            // const event = new ShowToastEvent({
            //     title: 'error',
            //     message: "Select atleast one default billing Address",
            //     variant: 'error',
            // });
            this.dispatchEvent(event);
            // return
        }
        var ShipAddressList = this.shipAddressList;
         var checkDefaultShippAddress = false;
        for(var i = 0 ; i<ShipAddressList.length ; i++)
        {
            if(ShipAddressList[i].Is_Default__c)
            {
                checkDefaultShippAddress = true;
            }
        }
        if(!checkDefaultShippAddress)
        {
            const event = new ShowToastEvent({
                title: 'error',
                message: "Please select atleast one default shipping Address",
                variant: 'error',
            });
            this.dispatchEvent(event);
            return
        }
        var SO =this.salesOrderObj;
        var OrderToCompany = SO.Company__c;
        var PreferredCurrency = SO.CurrencyIsoCode;
        var ShipmentTerms = SO.Delivery_Instructions__c;
        var DefaultBillToID;
        var DefaultShippToID;
        var DefaultBuyerToID;
        var DefaultInvoiceToID;
        if(SO.Supplier_Code__c=='NULL' ||SO.Supplier_Code__c=='')
        {
            const event = new ShowToastEvent({
                title: 'warning',
                message: "Please give Supplier Code",
                variant: 'warning',
            });
            this.dispatchEvent(event);
            return
        }
        if(SO.Supplier_Code__c != null && SO.Supplier_Code__c.length> 255){
            const event = new ShowToastEvent({
                title: 'warning',
                message: "Supplier Vendor Code should be less than or equal to 255 characters",
                variant: 'warning',
            });
            this.dispatchEvent(event);
            return
        }
        if(SO.Manufacturer_Code__c=='NULL' ||SO.Manufacturer_Code__c=='')
        {
            const event = new ShowToastEvent({
                title: 'warning',
                message: "Please give Manufacturer Factory POF Code",
                variant: 'warning',
            });
            this.dispatchEvent(event);
            return  
        }if(SO.Manufacturer_Code__c != null && SO.Manufacturer_Code__c.length> 255){
            const event = new ShowToastEvent({
                title: 'warning',
                message: "Manufacturer Factory POF Code should be less than or equal to 255 characters",
                variant: 'warning',
            });
            this.dispatchEvent(event);
            return  
        }
        if(this.orderSource=="PO")
        {  
            var currentURL = currentURL + '/apex/LightningPDFGenerator';
            var selecPO = this.confirmPOList;
            var list = [];
            var POLIQtyArr  = [];
            for(var i = 0 ; i< selecPO.length;i++)
            {
                list[i] = selecPO[i].POwrap.Id;
            }
            if(list.length>1)
            {
                this.orderDetailFlag = false;
                this.popdfFlag = true;
            }else{
                
                this.PDFForStagePO(list);
            }

        }else{
            
            this.PDFForCatalog();
        }
    }
    */

    printPOPDF(event){
        var poId =event.detail.value;
        this.PDFForStagePO(poId);
    }


    closeBoxRqdModal(){
        this.orderDetailFlag = false;
        this.popdfFlag = true;
    }

    cancelPOnPOLIChanges(){
        var selecPO = this.confirmPOList;
        cancelPOChanges({POString:JSON.stringify(selecPO)})
        .then(result=>{
            console.log('cancelPOnPOLIChanges success');
            var compEvent = new CustomEvent("closepopup", {
                detail: {
                    addressPopupFlag: false
                }
            });
            this.dispatchEvent(compEvent);
        }).catch(error=>{
        alert('Error in cancelPOnPOLIChanges(): ' + JSON.stringify(error.body.message));
         })
    }

    cancelOrderChanges(){
        var SO = this.salesOrderObj;
        toCancelOrder({dOrder:SO})
        .then(result=>{
            console.log("Successfully saved");
            var compEvent = new CustomEvent("closepopup", {
                detail: {
                    addressPopupFlag: false
                }
            });
            this.dispatchEvent(compEvent);
        }).catch(error=>{
            alert('error due to '+error.body.message);
        })
    }

    sendOrderEmailWithAttachment(SOID){
            sendSOEmailToCustomer({SOID: SOID})
            .then(result=>{
                console.log("Successfully sent");
            }).catch(error=>{
                alert('error '+error.body.message);
            })
    }

    unCheckAllPO(){
        uncheckPoCheckbox({SelectedId:this.toUncheck})
        .then(result=>{
            var accs = result;
        }).catch(error=>{
            console.log('Error due to '+error.body.message);
        })
    }

    sendOrderEmailWithAttachmentforPOtoSO(SOID){
        let getSorecId = SOID;
        // alert('getSorecId '+getSorecId);
        customerEmailAfterPOtoSOconversion({soIdForEmail: SOID})
        .then(result=>{
            console.log("Successfully sent");
        }).catch(error=>{
            console.log('Error : ' + JSON.stringify(error.body.message));
        })
    }
    
    // confirmSalesOrder(){
    //     var billAddIndex = this.billAddressIndex;
    //     var billAdd = this.billAddressList[billAddIndex];
    //     var custInfoid = this.customerInfoId;
    //     var shipAddIndex = this.shipAddressIndex;
    //     var shipAdd = this.shipAddressList[shipAddIndex];
    //     var buyerAddressIndex = this.buyerAddressIndex;
    //     var buyerAdd = this.buyerAddressList[buyerAddressIndex];
    //     var invoiceAddressIndex = this.invoiceAddressIndex;
    //     var invoiceAdd = this.invoiceAddressList[invoiceAddressIndex];

    //     SaveOrder({
    //         SO: this.salesOrderObj,
    //         custInfoid: custInfoid,
    //         BillAddress: billAdd,
    //         shipAddress: shipAdd,
    //         buyerAddress: buyerAdd,
    //         invoiceAddress: invoiceAdd
    //     })
    //     .then(result => {
    //         const toastEvent = new ShowToastEvent({
    //             title: 'Success',
    //             message: 'The Order has been placed successfully',
    //             variant: 'success'
    //         });
    //         this.dispatchEvent(toastEvent);
    //         location. reload();
            //  //eval("$A.get('e.force:refreshView').fire();");
    //          //to send email
    //          this.sendOrderEmailWithAttachment(result);
    //     })
    //     .catch(error => {
    //         console.error('Error in SaveOrder(): ' + JSON.stringify(error.body.message));
    //     })
    //     var spinnerElement = this.template.querySelector('.spinner-class');
    //         if (spinnerElement) {
    //             spinnerElement.classList.toggle('slds-hide');
    //         }

    // }

    PDFForCatalog(){
        var billAddIndex = this.billAddressIndex;
        var billAdd = this.billAddressList[billAddIndex];
        var custInfoid = this.customerInfoId;
        var shipAddIndex = this.shipAddressIndex;
        var shipAdd = this.shipAddressList[shipAddIndex];
        var buyerAddressIndex = this.buyerAddressIndex;
        var buyerAdd = this.buyerAddressList[buyerAddressIndex];
        var invoiceAddressIndex = this.invoiceAddressIndex;
        var invoiceAdd = this.invoiceAddressList[invoiceAddressIndex];

        var SO = this.salesOrderObj;
        var mydate = new Date(SO.Expected_Delivery_Date__c);

        if (SO.Remarks__c == 'None'){
            SO.Remarks__c = '';
        }
        if (SO.Brand_Label__c == 'None'){
            SO.Brand_Label__c = '';
        }
        if (SO.Division__c == 'None'){
            SO.Division__c = '';
        }
        if (SO.Season__c == 'None'){
            SO.Season__c = '';
        }
        if (SO.Season_Year__c == 'None'){
            SO.Season_Year__c = '';
        }

        if (SO.Delivery_Instructions__c == 'None'){
            SO.Delivery_Instructions__c = '';
        }

        updateSalesOrderForPDF({
            SO: this.salesOrderObj,
            custInfoid: custInfoid,
            BillAddress: billAdd,
            shipAddress: shipAdd,
            buyerAddress: buyerAdd,
            invoiceAddress: invoiceAdd,
            suzhouFlag:this.suzhouFlag})
            .then(result=>{
                console.log('check return value-->'+result);
                saveCatalogSOPDF({SOid:result})
                .then(res=>{
                    console.log('check return -->'+res);
                    // var urlString = window.location.href;
                    var urlString = '/apex/SOConfirmationPDF';
                    console.log('URL String--> '+urlString);
                    // var communityBaseURL = urlString.substring(0, urlString.indexOf("/n/"));communityBaseURL + "/apex/SOConfirmationPDF" +
                    urlString = urlString+ "?DefaultBillToID=" + billAdd.Id + "&DefaultShippToID=" + shipAdd.Id + "&SupplierCode=" + SO.Supplier_Code__c + "&ManufacturerCode=" + SO.Manufacturer_Code__c;
                    console.log('urlString for catalog>>>>' + urlString);
                    var win = window.open(urlString, '_blank');
                })
                .catch(err=>{
                    console.log("ERROR in updateSalesOrderForPDF()"+err.body.message);
                })
            })
            .catch(error=>{
                console.log("ERROR "+error.body.message);
            })
            // var spinnerElement = this.template.querySelector('.spinner-class');
            // if (spinnerElement) {
            //     spinnerElement.classList.toggle('slds-hide');
            // }
    }


    PDFForStagePO(POIdList){
        var SO =this.salesOrderObj;
        console.log("salesOrderObj>>>" + JSON.stringify(this.salesOrderObj));
        var PreferredCurrency = SO.CurrencyIsoCode;

        if (SO.Delivery_Instructions__c == 'NULL')
            SO.Delivery_Instructions__c = '';
        var ShipmentTerms = SO.Delivery_Instructions__c;

        var billAddIndex = this.billAddressIndex;
        var billAdd = this.billAddressList[billAddIndex];
        var DefaultBillToID = billAdd.Id;

        var shipAddIndex = this.shipAddressIndex;
        var shipAdd = this.shipAddressList[shipAddIndex];
        var DefaultShippToID =shipAdd.Id;

        var suzhouFlag = this.suzhouFlag;
        var DefaultBuyerToID;
        var DefaultInvoiceToID;
        if (suzhouFlag) {
            var buyerAddressIndex = this.buyerAddressIndex;
            var buyerAdd = this.buyerAddressList[buyerAddressIndex];
            DefaultBuyerToID = buyerAdd.Id;

            var invoiceAddressIndex = this.invoiceAddressIndex;
            var invoiceAdd = this.invoiceAddressList[invoiceAddressIndex];
            DefaultInvoiceToID = invoiceAdd.Id;
        }else {
            DefaultBuyerToID = 'DefaultBuyerToID';
            DefaultInvoiceToID = 'DefaultInvoiceToID';
        }

        if(!SO.Expected_Delivery_Date__c) {
            SO.Expected_Delivery_Date__c = null;
        }

        console.log('data sent to pdf view' + SO);

        var urlString = window.location.href;
        var CommunityBaseURL = urlString.substring(0, urlString.indexOf("/s/"));
        // console.log('CommunityBaseURL>>>>'+CommunityBaseURL);
        urlString = CommunityBaseURL + '/apex/POConfirmationPDF' + '?Id=' + POIdList;
        urlString += '&SupplierCode=' + SO.Supplier_Code__c + '&ManufacturerCode=' + SO.Manufacturer_Code__c;
        urlString += '&OrderToCompany='  + OrderToCompany + '&PreferredCurrency=' + PreferredCurrency + '&ShipmentTerms=' + ShipmentTerms;
        urlString += '&suzhouFlag=' + suzhouFlag;
        urlString += '&DefaultBillToID=' + DefaultBillToID + '&DefaultShippToID=' + DefaultShippToID;
        if (suzhouFlag)
            urlString += '&DefaultInvID=' + DefaultInvoiceToID + '&DefaultBuyerID=' + DefaultBuyerToID;
        urlString += '&expectedDeliveryDate=' + SO.Expected_Delivery_Date__c;
        if (SO.Division__c == 'None')
            SO.Division__c = '';
        if (SO.Season__c == 'None')
            SO.Season__c = '';
        if (SO.Season_Year__c == 'None')
            SO.Season_Year__c = '';
        if (!SO.Factory_Internal_PO__c)
            SO.Factory_Internal_PO__c = '';

        urlString += '&div=' + SO.Division__c + '&seaS=' + SO.Season__c + '&seaY=' + SO.Season_Year__c;
        urlString += '&finternalPO=' + SO.Factory_Internal_PO__c;
        if (SO.Transportation_Details__c && SO.Transportation_Details__c.includes('\n'))
        SO.Transportation_Details__c = SO.Transportation_Details__c.replace(new RegExp('\n', 'g'), '_space');
    if (SO.Transportation_Details__c)
        urlString += '&forw=' + SO.Transportation_Details__c;
    else
        urlString += '&forw=' + '';
    if (SO.Shipping_Mark__c && SO.Shipping_Mark__c.includes('\n'))
        SO.Shipping_Mark__c = SO.Shipping_Mark__c.replace(new RegExp('\n', 'g'), '_space');
    if (SO.Shipping_Mark__c)
        urlString += '&ship=' + SO.Shipping_Mark__c;
    else
        urlString += '&ship=' + '';
        var win = window.open(urlString, '_blank');
    }

    convertPOToSalesOrder(){
        var billAddIndex = this.billAddressIndex;
        var billAdd = this.billAddressList[billAddIndex];
        var custInfoid = this.customerInfoId;
        var shipAddIndex = this.shipAddressIndex;
        var shipAdd = this.shipAddressList[shipAddIndex];
        var buyerAddressIndex = this.buyerAddressIndex;
        var buyerAdd = this.buyerAddressList[buyerAddressIndex];
        var invoiceAddressIndex = this.invoiceAddressIndex;
        var invoiceAdd = this.invoiceAddressList[invoiceAddressIndex];
        var SO = this.salesOrderObj;
        var selecPO = this.confirmPOList;

        if (this.sOChoiceFlag == 'Multiple SO Conversion') {
            convertPOstoSo({
            SO: SO,
            slctRec: JSON.stringify(selecPO),
            BillAddress: billAdd,
            shipAddress: shipAdd,
            buyerAddress: buyerAdd,
            invoiceAddress: invoiceAdd,
            suzhouFlag: this.suzhouFlag,
            })
            .then(result=>{
                var res = result;
                var sorecId = res.substring(res.indexOf('Id=') + 3);
                var splitArr = res.split("Id=");
                res = splitArr[0];
                if (res.includes("Quantity is updated to nearest Box Quantity value")) {
                    this.toastContainerObj.toastPosition = 'Top Center';
                    const toastEvent = new ShowToastEvent({
                        title: 'success',
                        message: 'The Order has been placed successfully and ' + res ,
                        variant: 'success',
                        duration: 20000,
                    });
                    this.dispatchEvent(toastEvent);
                    this.addressPopupFlag=false;
                    location. reload();
                    //eval("$A.get('e.force:refreshView').fire();");
                    this.sendOrderEmailWithAttachmentforPOtoSO(sorecId);
                    return;
                }
                if (!res.includes("Success")) {
                    var spinnerElement = this.template.querySelector('.spinner-class');
                    if (spinnerElement) {
                        spinnerElement.classList.toggle('slds-hide');
                    }
                    this.toastContainerObj.toastPosition = 'Top Center';
                    const toastEvent = new ShowToastEvent({
                        title: 'warning',
                        message: res,
                        variant: 'warning'
                    });
                    this.dispatchEvent(toastEvent);
                    return;
                }
                this.toastContainerObj.toastPosition = 'Top Center';
                const toastEvent = new ShowToastEvent({
                    title: 'success',
                    message: "The Order has been placed successfully",
                    variant: 'success',
                });
                this.dispatchEvent(toastEvent);
                location. reload();
                // eval("$A.get('e.force:refreshView').fire();");
                this.sendOrderEmailWithAttachmentforPOtoSO(sorecId);

            }).catch(error=>{
                var errorRes = JSON.stringify(error);
                console.log('Error : ' + errorRes);
                var errorString = "An error occured, please contact your Administrator";
                if(errorRes.includes("INVALID_OR_NULL_FOR_RESTRICTED_PICKLIST")){
                    errorString = "Selected currency is not supported by the system, Please choose any other currency";
                    this.toastContainerObj.toastPosition = 'Top Center';
                    const toastEvent = new ShowToastEvent({
                        title: 'warning',
                        message: errorString,
                        variant: 'warning'
                    });
                    this.dispatchEvent(toastEvent);
                return;
            }
            else {
                alert('Inside Error Callback');
            }
            })
            var spinnerElement = this.template.querySelector('.spinner-class');
            if (spinnerElement) {
                spinnerElement.classList.toggle('slds-hide');
            }
        }
    }

    lineIsBlank(str) {
        return !str || /^\s*$/.test(str);
    }


    changeAddress(event){
        this.checkShippAddress = event.checkShippAddress;
        console.log('checkShippAddress -->'+this.checkShippAddress);
        var objectAPIName = event.objectAPIName;
        console.log('objectAPIName --> '+objectAPIName);
        var index = parseInt(objectAPIName);

         var context = event.context;
         console.log('context --> '+context);

         if(context === "Bill")
         {
            var BillAddressList = this.billAddressList;
            this.billAddressIndex =index;
            for(var i=0; i<BillAddressList.length; i++)
            {
                if(index!=i){
                    BillAddressList[i].Is_Default__c = false;
                }else if(index==i){
                    BillAddressList[i].Is_Default__c =true;
                }
            }
            this.billAddressList=BillAddressList;
         }
         else if(context === "Ship"){
            var ShipAddressList = this.shipAddressList;
            this.shipAddressIndex=index;
            for(var i=0; i<ShipAddressList.length; i++)
            {
                if(index!=i){
                    ShipAddressList[i].Is_Default__c = false;
                }else if(index==i){
                    ShipAddressList[i].Is_Default__c = true;
                }
            }
            this.shipAddressList=ShipAddressList;
         }
         if(context === "Buyer"){
            var BuyerAddressList =this.buyerAddressList;
            for(var i=0; i<BuyerAddressList.length; i++)
            {
                if(index!=i){
                    BuyerAddressList[i].Is_Default__c = false;
                }else if(index==i){
                    BuyerAddressList[i].Is_Default__c = true;
                }
            }
            this.buyerAddressList=BuyerAddressList;
            this.buyerAddressIndex=index;
         }
         else if(context === "Invoice"){
            var InvoiceAddressList = this.invoiceAddressList;
            for(var i=0; i<InvoiceAddressList.length; i++)
            {
                if(index!=i){
                    InvoiceAddressList[i].Is_Default__c = false;
                }else if(index==i){
                    InvoiceAddressList[i].Is_Default__c = true;
                }
            }
            this.invoiceAddressList=InvoiceAddressList;
            this.invoiceAddressIndex=index;
         }
    }


    @track orderQnty;
    @track newQtyArr = [];

    calculateBoxQty(event) {
        this.orderQnty = event.detail.value;
        let getId = event.target.dataset.id;
        console.log('quantity-->' + this.orderQnty);

        let existingEntryIndex = this.newQtyArr.findIndex(entry => entry.id === getId);
        if (existingEntryIndex !== -1) {
            // An entry with the same ID already exists, update it or delete it
            if (this.orderQnty === "") {
                // If orderQnty is empty, delete the existing entry
                this.newQtyArr.splice(existingEntryIndex, 1);
            } else {
                // Update the existing entry
                this.newQtyArr[existingEntryIndex].Qty = this.orderQnty;
            }
        } else {
            // If no existing entry found, push a new entry
            this.newQtyArr.push({
                'id': getId,
                'Qty': this.orderQnty
            });
        }
        console.log('newQtyArr>>' + JSON.stringify(this.newQtyArr));
    }

}