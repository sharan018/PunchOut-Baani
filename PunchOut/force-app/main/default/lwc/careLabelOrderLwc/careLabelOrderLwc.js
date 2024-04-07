import { LightningElement,track,api,wire } from 'lwc';
import getWrapperData from '@salesforce/apex/PunchOutCareLabelController.getWrapperData';
import saveCareLabelData from '@salesforce/apex/PunchOutCareLabelController.saveCareLabelData';
import deleteCareLabelData from '@salesforce/apex/PunchOutCareLabelController.deleteCareLabelData';
import deletedCLLI from '@salesforce/apex/PunchOutCareLabelController.deletedCLLI';
import fetchCareLabelData from '@salesforce/apex/PunchOutCareLabelController.fetchCareLabelData';
import Carelabel_Order from '@salesforce/label/c.Carelabel_Order';
 import Language from '@salesforce/label/c.Language';
 import Selected_Language from '@salesforce/label/c.Selected_Language';
 import Quantity from '@salesforce/label/c.Quantity';
 import Box_Quantity from '@salesforce/label/c.Box_Quantity';
 import UOM from '@salesforce/label/c.UOM';
 import Clear from '@salesforce/label/c.Clear';
 import Add_Label from '@salesforce/label/c.Add_Label';
 import { ShowToastEvent } from 'lightning/platformShowToastEvent';
 import {CurrentPageReference} from 'lightning/navigation';
import {fireEvent} from 'c/pubsub';
import { registerListener } from 'c/pubsub';


export default class CareLabelOrderLwc extends LightningElement {
@api careLabelSelectedData ={ exCareSelectedData: '{}', brandIcondata: '{}',sizeChartData: '{}',ChartData: '{}', countryOriginData: {}, CareSelectedData: [],FabricSelectedData: [],freetextData: {} };
@track careLabelSelectedData ={ exCareSelectedData: '{}', brandIcondata: '{}',sizeChartData: '{}',ChartData: '{}', countryOriginData: {}, CareSelectedData: [],FabricSelectedData: [],freetextData: {} };
@track Careinstruction=[];@track selectedLang;@track Quantity;@track BrandIconContent=true;@track FabricComponentContent;
@track SizeChartComponetContent;@track CountryOfOriginContent;@track CareLabelInstructionDetailContent=false;@track ExcareInstructionContent=false;
@track FreeTextContent=false; @track fullboxQty=false;@track boxquantity='';@track uomOrder='';@track MOQ='';@track picvalue;
@api sizelist=[];@api lstcmpname='[]';@api lstfabname='[]'; @track lstcountryname='[]';
@track selectedcountry;@track Excareinstruction='[]';@track Excarecmpname='[]';@track careLabelOrderDetail=false;@track careLabelOrder=true;
@track careLabelSelectedDataList=[];@track itemMaster='Item_Master__c';@api deletedCLLIIdList=[];@track Careinstructionlength =false;
@track careLabelSelectedDataListlength =false;@track viewedIndex;@track finalviewedCarelabelData ={};
@track logo =false;@track catalogVertical =false;@track Fabriccmp=false;@track BranIcon=false; @track country=false; @track instruction =false;@track freetext =false;
@track picvalue;@api itemMasterForView='Item_Master__c';@api BrandlistForView=[];@api selectedBrand;
@api viewedCarelabelData ={};@api lstcmpnameForView=[];@track BrandIconTabId;@track FabricomTabId;@track SizeChartTabId;
@track selectedTab='BRAND ICON';@track sizelist;@track sizecmp=false;@api lstcountryname='[]';@track selectedCarTabId;
@track countryTabId;@track FreeTextTabId;@track selectedproduct =[];@track careinsructiontabid;@api viewedCarelabelDataCareInstruction ={};
//api
@api pagination;@api viewQuick;@api selectedTab;@api selectedproduct =[];@api selectedcustomerid;@api selectedcurrency;@api searchedcurrency;
@api isBrandOpenModal=false;@api CareInstructions ='CareInstruction';@api Brandlist;@api selectedcountry;@api isCountryModalOpen=false;
@api selectedCarTabId;@api isCareInstructionModal =false;@api Careinstruction =[];@api isFreetextmodal =false;
@api tempBrandIconId;@api itemMaster ='Item_Master__c';@track viewCarelabelFlag =false;@track propfabric='slds-hide';
@track propBranIcon='slds-tabs_scoped__content';@track propsizechart ='slds-hide';@track propCountry ='slds-hide';@track propInstruction='slds-hide';@track propfreetext ='slds-hide';

//<!--Attributes for view And edit-->
@track itemMasterForView ='Item_Master__c';@track picvalueForView;@track BrandlistForView =[];@track sizelistForView =[];@api sizelistForView =[];
@track lstcmpnameForView =[];@track lstfabnameForView=[];@track lstcountrynameForView=[];@track selectedcountryForView;
@track CareinstructionForView =[];@track ExcareinstructionForView=[];@track ExcarecmpnameForView=[];@api DevCountry =false;@api DevSize=false;
@api DevViewEdit=false;@track selectedLanguages;@api CareinstructionForView =[];@track getselectedviewlanguage;@track getselectedviewQuantity;
@api DevFree =false;@track activetab ='slds-is-active';@track viewselecteddata =true;@track Brandlist;@track colouronselectBrandIcon='slds-is-active';@track colouronselectFabric;
@track succesborderforBrandIcon;@track succesborderforFabric;@track succesborderforSize;@api loadedcaredata=[];
@track succesborderforCareInstruction;
@track succesborderforCountry;
@track succesborderforFreetext;
@api devCare=false;
@track picvalueoption =[];

@wire(CurrentPageReference) pageRef;
    connectedCallback(){
         this.careLabelSelectedData = { exCareSelectedData: '{}', brandIcondata: '{}',sizeChartData: '{}',ChartData: '{}', countryOriginData: {}, CareSelectedData: [],FabricSelectedData: [],freetextData:  {} };
         this.Careinstruction=[];
         this.selectedLang='';
         this.Quantity=0;
         this.BrandIconContent=true;
         this.FabricComponentContent=false;
         this.SizeChartComponetContent=false;
         this.CountryOfOriginContent=false;
         this.CareLabelInstructionDetailContent =false;
         this.ExcareInstructionContent=false;
         this.FreeTextContent=false;
         const selectedProduct=this.selectedproduct;

         const fullboxQty=selectedProduct.ProductDataMap[selectedProduct.selectedColor].fullboxQty;
         this.fullboxQty=selectedProduct.ProductDataMap[selectedProduct.selectedColor].fullboxQty;
         const boxquantity=selectedProduct.ProductDataMap[selectedProduct.selectedColor].boxquantity;
        this.boxquantity=selectedProduct.ProductDataMap[selectedProduct.selectedColor].boxquantity;
        const prodid=selectedProduct.ProductDataMap[selectedProduct.selectedColor].prodid;
        this.uomOrder=selectedProduct.ProductDataMap[selectedProduct.selectedColor].UomOrder;
        this.MOQ=selectedProduct.ProductDataMap[selectedProduct.selectedColor].MOQ;
        this.getselectedproductname=this.selectedproduct.Name;
      var getcareLabelSelectedDataList =this.loadedcaredata;
      console.log('getcareLabelSelectedDataList 2323232>>'+JSON.stringify(getcareLabelSelectedDataList));
         if(getcareLabelSelectedDataList.length >0){
             this.careLabelSelectedDataListlength=true;
        }
         else{
             this.careLabelSelectedDataListlength=false;
        }
        this.getWrapper(prodid,fullboxQty,boxquantity);

            const tabLink = this.template.querySelector('a[data-id="BrandIconTab"]');
            if (tabLink) {
                const tabId = tabLink.getAttribute('data-id');
            }
            registerListener('changeTabColor', this.changeTabColorBrandIcon, this);
            registerListener('changeTabColorFabric', this.changeTabColorFabricComponent, this);
            registerListener('changeTabColorSize', this.changeTabColorSizeChart, this);
            registerListener('changeTabColorCountry', this.changeTabColorCountryOfOrigin, this);
            registerListener('changeTabColorCareInstruction', this.changeTabColorCareInstructionDetails, this);
            registerListener('changeTabColorFreeText', this.changeTabColorFreeText, this);
            this.getExistingLabelData();
        }


        getWrapper(prodid,fullboxQty,boxquantity){
          
            getWrapperData({
                retailerCode:'a00O000000mDAkPIAW',
                productname:this.selectedproduct.Id,
                customerid:this.selectedcustomerid,
                fullboxQty:fullboxQty,
                boxquantity:boxquantity
            })
            .then(result => {
                console.log('mainwrapper in lwc ::: ' + JSON.stringify(result));
                    if (!result.itemMaster.Brand_Icon__c) {
                        if (!result.itemMaster.Fabric_Component__c) {
                            if (!result.itemMaster.Size_Chart__c) {
                                if (!result.itemMaster.Country_Of_Origin__c) {
                                    if (!result.itemMaster.Care_Instruction__c) {
                                        if (!result.itemMaster.Excare_Instruction__c) {
                                            if (!result.itemMaster.Free_Text__c) {

                                            } else {
                                                this.FreeTextContent = true;
                                                this.BrandIconContent = false;
                                            }
                                        } else {
                                            this.BrandIconContent = false;
                                            this.ExcareInstructionContent = true;
                                        }
                                    } else {
                                        this.CareLabelInstructionDetailContent = true;
                                        this.BrandIconContent = false;
                                    }
                                } else {
                                    this.CountryOfOriginContent = true;
                                    this.BrandIconContent = false;
                                }
                            } else {
                                this.SizeChartComponetContent = true;
                                this.BrandIconContent = false;
                            }
                        } else {
                            this.FabricComponentContent = true;
                            this.BrandIconContent = false;
                        }
                    } else {
                        this.BrandIconContent = true;
                    }

                   
                    this.picvalue = result.LangCombList;
                    this.picvalueoption = [{ label: "Selected Language", value: 'NULL' },...this.picvalue.map(option => ({ label: option, value: option }))];
                    this.Brandlist = result.BrandIcon;
                    this.sizelist = result.sizechart;
                    this.lstcmpname = result.FabricComponent;
                    this.lstfabname = result.MaterialComponent;
                    this.lstcountryname = result.CountryofOrigin;
                    this.selectedcountry = result.LangCountryList;
                    this.StyleNumber = result.StyleNumber;
                    this.Careinstruction = result.Careinstruction;
                    if( this.Careinstruction.length >0){
                        this.Careinstructionlength=true;
                    }
                    if (result.itemMaster.Excare_Instruction__c) {
                        this.Excareinstruction = result.Excareinstruction;
                        this.Excarecmpname = result.ExcarePosition;
                    }
                    if (result.careLabelSelectedDataList.length > 0) {
                        this.careLabelOrderDetail = true;
                        this.careLabelSelectedDataList = result.careLabelSelectedDataList;
                    }
                    this.itemMaster = result.itemMaster;
                
            })
            .catch(error => {
                console.error('ERROR OCCURRED: ' + JSON.stringify(error));
            });
            
    }
    get labelCarelabelOrder(){
         return Carelabel_Order;
     }
     get Language(){
        return Language;
     }
     get SelectedLanguage(){
         return Selected_Language;
     }
     get Quantity(){
         return Quantity;
     }
     get BoxQuantity(){
        return Box_Quantity +this.boxquantity;
     }
     get labelUOM(){
        return UOM;
     }
     get Clear(){
        return Clear;
     }
     get AddLabel(){
        return Add_Label;
     }
     getWrapperLang(event){
        const getselectedlanguage =event.target.value;
        this.selectedLang=getselectedlanguage;
        
     }
     handleQtyChange(event){
        const getselecteQuantity =event.target.value;
        this.Quantity=getselecteQuantity;
     }
     handleBrandIconData(event){
       // alert('inside 1st dispach');
        this.careLabelSelectedData.brandIcondata=event.detail.BrandIcondata;
        

    }
    handleviewedCarelabelData(event){
      //  alert('inside handleviewedCarelabelData');
        this.finalviewedCarelabelData.brandIcondata=event.detail.viewedCarelabelData;
        console.log('handleviewedCarelabelData2222>'+JSON.stringify(this.finalviewedCarelabelData));
    }
        handelviewedselectedarray(event){
            this.finalviewedCarelabelData.FabricSelectedData=event.detail.viewedSelectedArray;
        }
        handleviewsizechartdata(event){
            this.finalviewedCarelabelData.sizeChartData=event.detail.viewSizeChartData;
        }
    // handleChildEvent(){
    //     let carefab =this.template.querySelector('c-care-label-order-fabric-component-lwc');
    //     carefab.bindFabricData();
    // }
   


     //New add and clone
     @api
     newAddAndClone(){
      
         this.template.querySelector('c-care-label-order-fabric-component-lwc').bindFabricData();
       
    
        let CareIns = this.template.querySelector('c-care-label-order-brand-icon-lwc').getSelectedData();
        
     this.template.querySelector('c-care-label-order-size-chart-lwc').selectedSize();
        
        
            this.template.querySelector('c-care-label-country-component-lwc').FetchCountry();
        
   this.template.querySelector('c-care-label-care-instruction-component-lwc').bindSelectedData();
        
         this.template.querySelector('c-care-label-order-free-text-lwc').FreetextData();
        
       
        var itemMaster=this.itemMaster;
        var careLabelSelectedData=this.careLabelSelectedData;
        console.log('mainwrapper ==>'+JSON.stringify(careLabelSelectedData));
          if(this.selectedLang ==''){
        const toastEvent = new ShowToastEvent({
            title: 'warning',
            message: 'Language is missing',
            variant: 'warning'
        });
        this.dispatchEvent(toastEvent);
        return;
    }
    if(this.Quantity <=0){
        const toastEvent = new ShowToastEvent({
            title: 'warning',
            message: 'Label Quantity  is missing',
            variant: 'warning'
        });
        this.dispatchEvent(toastEvent); 
        return;  
    }
    var result;
if(this.Quantity<this.MOQ && this.boxquantity && this.fullboxQty && (this.Quantity <this.boxquantity ||this.Quantity % this.boxquantity !=0))
{
    result = Math.ceil(this.MOQ / this.boxquantity) * this.boxquantity;
  if(confirm('Order Quantity for Product' +this.getselectedproductname +'is less then Minimum Order Quantity MOQ'+this.MOQ +"\n" +'The nearest multiples of box quantity'+ result + "\n" +'Click OK to confirm Order Quantity' +result +'and add it in the CART')){
     this.Quantity=result;
  }
  else{
    return;
}

}
else if(this.Quantity<this.MOQ && this.boxquantity && this.fullboxQty && (this.MOQ <this.boxquantity ||this.MOQ % this.boxquantity !=0)){
    result = Math.ceil(this.MOQ / this.boxquantity) * this.boxquantity;
    if(confirm('Order Quantity for Product' +this.getselectedproductname +'is less then Minimum Order Quantity MOQ'+this.MOQ +"\n" +'The nearest multiples of box quantity'+ result + "\n" +'Click OK to confirm Order Quantity' +result +'and add it in the CART')){
        this.Quantity=result;
     }
     else{
       return;
   }
}
else if(this.Quantity <this.MOQ){

    if(confirm('Order Quantity for Product'+this.getselectedproductname +'is less then Minimum Order Quantity MOQ'+this.MOQ)){
        this.Quantity=this.MOQ;
    }
    else{
        return;
    }
}
else{
     var result = Math.ceil(this.Quantity  / this.boxquantity);
  if(this.fullboxQty && this.boxquantity && (this.Quantity <this.boxquantity ||this.Quantity % this.boxquantity !=0)){

    if(confirm('Order Quantity for Product'+this.getselectedproductname +'is less then Minimum Order Quantity MOQ'+this.MOQ)){
        this.Quantity=this.MOQ;
    }
    else{
        return;
    }
  }

}
if(itemMaster.Brand_Icon__c && careLabelSelectedData.brandIcondata==='{}'){
    const toastEvent = new ShowToastEvent({
        title: 'warning',
        message: 'Brand_Icon_is_missing',
        variant: 'warning'
    });
    this.dispatchEvent(toastEvent); 
    return;  
}
if(itemMaster.Fabric_Component__c && careLabelSelectedData.FabricSelectedData.length<1){
    const toastEvent = new ShowToastEvent({
        title: 'warning',
        message: 'Fabric Data is missing',
        variant: 'warning'
    });
    this.dispatchEvent(toastEvent); 
    return;  
}
var compCount={};
var fabCount={};
var total=0;
for(var i=0;i<careLabelSelectedData.FabricSelectedData.length;i++)
{
    if(careLabelSelectedData.FabricSelectedData[i].Component)
    {
        if(!compCount[careLabelSelectedData.FabricSelectedData[i].Component]){
        compCount[careLabelSelectedData.FabricSelectedData[i].Component]=0;
    compCount[careLabelSelectedData.FabricSelectedData[i].Component]+=careLabelSelectedData.FabricSelectedData[i].value;
    }
}
if(!careLabelSelectedData.FabricSelectedData[i].Component)
{
    total+=careLabelSelectedData.FabricSelectedData[i].value;
}

     }
     for(var key in compCount){
        if(compCount[key]<100)
        {
            const toastEvent = new ShowToastEvent({
                title: 'warning',
                message: 'Component has value lesser than 100 in Fabric',
                variant: 'warning'
            });
            this.dispatchEvent(toastEvent); 
            return;  
        }
     }
     if(total!=0 && (total<100 || total>100))
     {
        const toastEvent = new ShowToastEvent({
            title: 'warning',
            message: 'Fabric combination value lesser greater than 100',
            variant: 'warning'
        });
        this.dispatchEvent(toastEvent); 
        return;  
     }
     if(itemMaster.Size_Chart__c && careLabelSelectedData.sizeChartData==='{}'){
        const toastEvent = new ShowToastEvent({
            title: 'warning',
            message: 'Size chart is missing',
            variant: 'warning'
        });
        this.dispatchEvent(toastEvent); 
        return;  
     }
     if(itemMaster.Country_Of_Origin__c && (!careLabelSelectedData.countryOriginData.selectedcountry || careLabelSelectedData.countryOriginData.selectedcountry==='-NONE-'))
     {
        const toastEvent = new ShowToastEvent({
            title: 'warning',
            message: 'Country of Origin is missing',
            variant: 'warning'
        });
        this.dispatchEvent(toastEvent); 
        return;  
     }
     if(this.Careinstruction.length>0 && careLabelSelectedData.CareSelectedData.length<1){
        const toastEvent = new ShowToastEvent({
            title: 'warning',
            message: 'Care instructions is missing',
            variant: 'warning'
        });
        this.dispatchEvent(toastEvent); 
        return;  
     }
     if(this.Careinstruction.length>0 && careLabelSelectedData.CareSelectedData.length>0)
     {
        var Careinstruction=this.Careinstruction;
        if(Careinstruction.length!=careLabelSelectedData.CareSelectedData.length)
        {
            const toastEvent = new ShowToastEvent({
                title: 'warning',
                message: 'All the Care instructions have not been selected',
                variant: 'warning'
            });
            this.dispatchEvent(toastEvent); 
            return;   
        }
     }
     if(itemMaster.Excare_Instruction__c && (!careLabelSelectedData.exCareSelectedDataList  || careLabelSelectedData.exCareSelectedDataList.length==0)) {  
        const toastEvent = new ShowToastEvent({
            title: 'warning',
            message: 'Excare instructions is missing',
            variant: 'warning'
        });
        this.dispatchEvent(toastEvent); 
        return; 
     }
     if(this.Careinstruction.length>0 && JSON.stringify(careLabelSelectedData.freetextData)=='{}' ){
         
        const toastEvent = new ShowToastEvent({
            title: 'warning',
            message: 'Free Text is missing',
            variant: 'warning'
        });
        this.dispatchEvent(toastEvent); 
        return; 
    }
    else if(itemMaster.Free_Text__c){
        if((itemMaster.Style_Number__c && !careLabelSelectedData.freetextData.StyleNumber))
            {
               
        const toastEvent = new ShowToastEvent({
            title: 'warning',
            message: 'Style Number is missing',
            variant: 'warning'
        });
        this.dispatchEvent(toastEvent); 
        return;    
            }
            else if((itemMaster.RN_Number__c && !careLabelSelectedData.freetextData.RNNumber))
            {
                const toastEvent = new ShowToastEvent({
                    title: 'warning',
                    message: 'RN Number is missing',
                    variant: 'warning'
                });
                this.dispatchEvent(toastEvent); 
                return;    
            }
            else if((itemMaster.Lot_Number__c && !careLabelSelectedData.freetextData.LotNumber))
            {
                const toastEvent = new ShowToastEvent({
                    title: 'warning',
                    message: 'LotNumber is missing',
                    variant: 'warning'
                });
                this.dispatchEvent(toastEvent); 
                return;   
            }
            else if((itemMaster.Supplier_Number__c && !careLabelSelectedData.freetextData.SupplierNumber))
            {
                const toastEvent = new ShowToastEvent({
                    title: 'warning',
                    message: 'Supplier Number is missing',
                    variant: 'warning'
                });
                this.dispatchEvent(toastEvent); 
                return;
            }
            else if((itemMaster.Labelling_Code__c && !careLabelSelectedData.freetextData.LabellingCode))
            {
                const toastEvent = new ShowToastEvent({
                    title: 'warning',
                    message: 'Labelling Code is missing',
                    variant: 'warning'
                });
                this.dispatchEvent(toastEvent); 
                return;
            }
            else if((itemMaster.Packaging_Code__c && !careLabelSelectedData.freetextData.PackagingCode))
            {
                const toastEvent = new ShowToastEvent({
                    title: 'warning',
                    message: 'Packaging Code is missing',
                    variant: 'warning'
                });
                this.dispatchEvent(toastEvent); 
                return;
            }
            else if((itemMaster.Season_Month__c && !careLabelSelectedData.freetextData.SeasonMonth))
            {
                const toastEvent = new ShowToastEvent({
                    title: 'warning',
                    message: 'Season Month is missing',
                    variant: 'warning'
                });
                this.dispatchEvent(toastEvent); 
                return;
            }
            else if((itemMaster.Season_Year__c && !careLabelSelectedData.freetextData.SeasonYear))
            {
                const toastEvent = new ShowToastEvent({
                    title: 'warning',
                    message: 'Season Year is missing',
                    variant: 'warning'
                });
                this.dispatchEvent(toastEvent); 
                return;
            }
            else if((itemMaster.Item_Number__c && !careLabelSelectedData.freetextData.ItemNumber))
                {
                    const toastEvent = new ShowToastEvent({
                        title: 'warning',
                        message: 'Item_Number_is_missing',
                        variant: 'warning'
                    });
                    this.dispatchEvent(toastEvent); 
                    return;

               }
               else if((itemMaster.Care_Instruction__c && !careLabelSelectedData.freetextData.careinstruct))
              {
                const toastEvent = new ShowToastEvent({
                    title: 'warning',
                    message: 'care instruction is missing',
                    variant: 'warning'
                });
                this.dispatchEvent(toastEvent); 
                return;
              }
    }
    var temp=new Object();
    temp.selectedLang=this.selectedLang;
    temp.quantity=this.Quantity;
    if(careLabelSelectedData.brandIcondata!='{}')
    {
        temp.brandIcondata=careLabelSelectedData.brandIcondata;   
    }
    temp.FabricSelectedData=careLabelSelectedData.FabricSelectedData;
    if(careLabelSelectedData.sizeChartData!='{}')
        {
            temp.sizeChartData=careLabelSelectedData.sizeChartData;
        }
        if(careLabelSelectedData.countryOriginData!='{}')
        {
            temp.countryOriginData=careLabelSelectedData.countryOriginData;
        }
        temp.CareSelectedData=careLabelSelectedData.CareSelectedData;
        if(careLabelSelectedData.exCareSelectedDataList && careLabelSelectedData.exCareSelectedDataList.length>0)
        {
            temp.exCareSelectedDataList=careLabelSelectedData.exCareSelectedDataList;	
        }
        if(careLabelSelectedData.freetextData!='{}')
        {
            temp.freetextData=careLabelSelectedData.freetextData;
        }
        var careLabelSelectedDataList=this.careLabelSelectedDataList;
        for(var i=0;i<careLabelSelectedDataList.length;i++)
        { 
            var tempFab=careLabelSelectedDataList[i].FabricSelectedData;
            var fabMached=true;
            if(itemMaster.Fabric_Component__c){
                if(tempFab.length==temp.FabricSelectedData.length)
                {
                    for(var j=0;j<tempFab.length;j++)
                    {
                        var fabId=tempFab[j]['fabId'];
                        delete tempFab[j]['fabId'];
                        var matched=false;
                        for(var k=0;k<temp.FabricSelectedData.length;k++)
                        {
                            if(JSON.stringify(temp.FabricSelectedData[k])===JSON.stringify(tempFab[j]))
                            {
                                matched=true;
                            }
                        }
                        tempFab[j]['fabId']=fabId;
                        if(!matched)
                        {
                            fabMached=false;
                            break;
                        }
                    }
                }
                else{
                fabMached=false;
           }
           var careInstMatch=true;
           if(this.Careinstruction.length>0)
           {
            if(temp.CareSelectedData.length==careLabelSelectedDataList[i].CareSelectedData.length)
            {
                var tempCareInstr=careLabelSelectedDataList[i].CareSelectedData;
                for(var j=0;j<tempCareInstr.length;j++)
                {
                    var careIdList=tempCareInstr[j]['careIdList'];
                    delete tempCareInstr[j]['careIdList'];
                    var matched1=false;
                    for(var k=0;k<temp.CareSelectedData.length;k++)
                    {
                        delete temp.CareSelectedData[k]['careIdList'];
                        if(JSON.stringify(temp.CareSelectedData[k])===JSON.stringify(tempCareInstr[j]))
                        {
                            matched1=true;
                        }
                    }
                    tempCareInstr[j]['careIdList']=careIdList;
                    if(!matched1)
                    {
                        careInstMatch=false;
                            break;
                    }
                }
            }
            else{
            careInstMatch=false;
           }
           var tempEx=careLabelSelectedDataList[i].exCareSelectedDataList;
           var exMatched=true;
           if(itemMaster.Excare_Instruction__c){
            for(var j=0;j<tempEx.length;j++)
            {
                var excareId=tempEx[j]['excareId'];
                delete tempEx[j]['excareId'];
                var matched=false;
                for(var k=0;k<temp.exCareSelectedDataList.length;k++)
                {
                    if(JSON.stringify(temp.exCareSelectedDataList[k])===JSON.stringify(tempEx[j]))
                    {
                        matched=true;
                    }
                }
                tempEx[j]['excareId']=excareId;
                        if(!matched)
                        {
                            exMatched=false;
                            break;
                        }
            }
           }
           else{
           exMatched=false;
          }
          var freeTextMatch=true;
          if(itemMaster.Free_Text__c){
            if(careLabelSelectedDataList[i].freetextData && ((itemMaster.Style_Number__c && careLabelSelectedDataList[i].freetextData.StyleNumber!=temp.freetextData.StyleNumber)
                   ||(itemMaster.RN_Number__c && careLabelSelectedDataList[i].freetextData.RNNumber!=temp.freetextData.RNNumber)
                   ||(itemMaster.Lot_Number__c && careLabelSelectedDataList[i].freetextData.LotNumber!=temp.freetextData.LotNumber)
                   ||(itemMaster.Care_Instruction__c && careLabelSelectedDataList[i].freetextData.careinstruct!=temp.freetextData.careinstruct)
                   ||(itemMaster.Supplier_Number__c && careLabelSelectedDataList[i].freetextData.SupplierNumber!=temp.freetextData.SupplierNumber)
                   ||(itemMaster.Labelling_Code__c && careLabelSelectedDataList[i].freetextData.LabellingCode!=temp.freetextData.LabellingCode)
                   ||(itemMaster.Packaging_Code__c && careLabelSelectedDataList[i].freetextData.PackagingCode!=temp.freetextData.PackagingCode)
                   ||(itemMaster.Season_Month__c && careLabelSelectedDataList[i].freetextData.SeasonMonth!=temp.freetextData.SeasonMonth)
                   ||(itemMaster.Season_Year__c && careLabelSelectedDataList[i].freetextData.SeasonYear!=temp.freetextData.SeasonYear)
                   ||(itemMaster.Item_Number__c && careLabelSelectedDataList[i].freetextData.ItemNumber!=temp.freetextData.ItemNumber)))
                {
                    freeTextMatch=false;
                }
          }
          var brandIconPresent=true;
            if(itemMaster.Brand_Icon__c)
            {
                if(careLabelSelectedDataList[i].brandIcondata.Id==temp.brandIcondata.Id)
                {
                    brandIconPresent=true;
                }
                else
                {
                    brandIconPresent=false;
                }
            }
            var sizeChartPresent=true;
            if(itemMaster.Size_Chart__c)
            {
                if(careLabelSelectedDataList[i].sizeChartData.Id==temp.sizeChartData.Id)
                {
                    sizeChartPresent=true;
                }
                else
                {
                    sizeChartPresent=false;
                }
            }
            var countryOfOriginPresent=true;
            if(itemMaster.Country_Of_Origin__c)
            {
                if(temp.countryOriginData.selectedcountry==careLabelSelectedDataList[i].countryOriginData.selectedcountry)
                {
                    countryOfOriginPresent=true;
                }
                else
                {
                    countryOfOriginPresent=false;
                }
            }
            
            if(careLabelSelectedDataList[i].selectedLang==temp.selectedLang && 
                careLabelSelectedDataList[i].quantity==temp.quantity ||
                brandIconPresent ||
                sizeChartPresent ||
                fabMached ||
                careInstMatch ||
                exMatched ||
                freeTextMatch ||
                countryOfOriginPresent
               )
             {
                const toastEvent = new ShowToastEvent({
                    title: 'warning',
                    message: 'Data Already Present',
                    variant: 'warning'
                });
                this.dispatchEvent(toastEvent); 
                return;
             }
           }
          
            }
        }
        careLabelSelectedDataList.push(temp);
        this.careLabelSelectedDataList =careLabelSelectedDataList ;
        console.log('setting CarelabelDatalist --->'+JSON.stringify(this.careLabelSelectedDataList));
        this.careLabelOrderDetail=true;
        const label ='label';
        this.saveCareData(label);
    }
   
    saveCareData(label){
        console.log('this.careLabelSelectedDataList -->'+JSON.stringify(this.careLabelSelectedDataList));
        console.log('this.selectedproduct.Id -->'+JSON.stringify(this.selectedproduct.Id));
        console.log('this.selectedproduct -->'+JSON.stringify(this.selectedproduct));
        console.log('this.selectedcustomerid -->'+JSON.stringify(this.selectedcustomerid));
        console.log('this.label -->'+JSON.stringify(label));
        console.log('this.selectedcurrency -->'+JSON.stringify(this.selectedcurrency));
        console.log('this.careLabelSelectedDataList -->'+JSON.stringify(this.searchedcurrency));
        console.log('deletedCLLIIdList >>'+this.deletedCLLIIdList.length);
        saveCareLabelData({
            careLabelSelectedDataList:JSON.stringify(this.careLabelSelectedDataList),
            productId:this.selectedproduct.Id,
            retailerId:'a00O000000mDAkPIAW',
            completeWrap:JSON.stringify(this.selectedproduct),
            customeid:this.selectedcustomerid,
            addTo:label,
            selectedCurrency:this.selectedcurrency,
            searchedCurrency:this.searchedcurrency
        })
        .then(result =>{
           var resp=result;
           console.log('saveCareData --:>>'+JSON.stringify(resp));
           if(label=='label')
           {  
            if(this.deletedCLLIIdList.length>0){
               this.deleteCarelabelData();
            }
            else{
                const toastEvent = new ShowToastEvent({
                    title: 'success',
                    message: 'Successfully added to the List',
                    variant: 'success'
                });
                this.dispatchEvent(toastEvent); 
                this.getExistingLabelData();
               
                if(this.selectedCurrency){
                    this.selectedCurrency=this.searchedcurrency;
                }
                // const flag = 'BlockRetailer';
                // const selectedEvent = new CustomEvent('CatalogEvent', {
                //     detail: { flag : flag },
                // });
                
                // this.dispatchEvent(selectedEvent );
                const obj={"flag": "BlockRetailer"};
                fireEvent(this.pageRef,"CatalogEvent",obj);
                
            }
           }
            if(label=='Cart')
           {
            const toastEvent = new ShowToastEvent({
                title: 'success',
                message: 'Successfully added to the Cart',
                variant: 'success'
            });
            this.dispatchEvent(toastEvent);  
            eval("$A.get('e.force:refreshView').fire();");
           }
           
        })
        .catch(error => {
            console.error('Error message: ' + error.message);
        });
        
    }
    deleteCarelabelData(){
        deletedCLLI({
            deletedCLLIList:this.deletedCLLIIdList
        })
        .then(result =>{
            if(result){
                this.getExistingLabelData();
            }

        })
        .catch(error => {
            console.error('Error message: ' + error.message);
        });
        
    }
    getExistingLabelData(){
        alert('customeid >>'+this.selectedcustomerid);
        console.log('customeid >>'+this.selectedcustomerid);
        fetchCareLabelData({
            retailerId:'a00O000000mDAkPIAW',
            customeid:this.selectedcustomerid
        })
        .then(result =>{
           console.log('result in getExistingLabelData --'+JSON.stringify(result));
            this.viewselecteddata =true;
                this.careLabelSelectedDataList=result;
                console.log('careLabelSelectedDataList >>'+JSON.stringify(this.careLabelSelectedDataList));
                if(this.careLabelSelectedDataList.length >0){
                    this.careLabelSelectedDataListlength =true;
                }else{
                    this.careLabelSelectedDataListlength =false;
                }
                const careLabelSelectedDataList = new CustomEvent('carelabelselecteddatalist', {
                    detail: {'careLabelSelectedDataList':this.careLabelSelectedDataList}
                });
                this.dispatchEvent(careLabelSelectedDataList);

            

        })
        .catch(error => {
            console.error('Error message: ' + error.message);
        });
    }


    //BrandIconTab
    BrandIconTab(event){
        const tabId = event.currentTarget.getAttribute('data-id');
        this.BrandIconTabId =tabId;
        this.careinsructiontabid ='';
        this.SizeChartTabId ='';
        this.FabricomTabId ='';
        this.countryTabId ='';
        this.SizeChartTabId ='';
        this.FreeTextTabId ='';
        this.BranIcon=true;
        this.Fabriccmp =false;
        this.country =false;
        this.BrandIconContent=true;
        if(this.BrandIconContent ==true){
            this.propBranIcon ='slds-tabs_scoped__content';
        }
        this.sizecmp=false;
         this.instruction =false;
         this.freetext =false;
        this.FabricComponentContent=false;
        if(this.FabricComponentContent ==false){
            this.propfabric ='slds-hide';
            
        }
        this.SizeChartComponetContent=false;
        if(this.SizeChartComponetContent ==false){
            this.propsizechart='slds-hide';
           
        }
        this.CountryOfOriginContent=false;
        if(this.CountryOfOriginContent ==false){
            this.propCountry='slds-hide';
            
        }
        this.CareLabelInstructionDetailContent=false;
        if(this.CareLabelInstructionDetailContent ==false){
            this.propInstruction='slds-hide';
           
        }
        this.ExcareInstructionContent=false;
        this.FreeTextContent=false;
        if(this.FreeTextContent ==false){
            this.propfreetext='slds-hide';
            
        }
        const BrandIconTab = event.target.getAttribute('id');
       //if(BrandIconTab){
        this.colouronselectBrandIcon='slds-is-active';
       this.colouronselectFabric='slds-is-inactive';
       this.colouronselectSize='slds-is-inactive';
       this.colouronselectCareInstruction ='slds-is-inactive';
       this.colouronselectCountry ='slds-is-inactive';
       this.colouronselectFreeText='slds-is-inactive';
      // }
       
    }
    FabricComponentTab(event){
        const tabId = event.currentTarget.getAttribute('data-id');
        this.FabricomTabId =tabId;
        this.careinsructiontabid ='';
        this.SizeChartTabId ='';
        this.BrandIconTabId ='';
        this.countryTabId ='';
        this.FreeTextTabId ='';
        this.BranIcon=false;
        this.Fabriccmp =true;
        this.country =false;
        this.sizecmp=false;
        this.instruction =false;
        this.freetext =false;
        this.BrandIconContent=false;
        if(this.BrandIconContent == false){
            this.propBranIcon ='slds-hide';
            this.colouronselect='buttonconstant';
        }
        this.FabricComponentContent=true;
        if(this.FabricComponentContent ==true){
            this.propfabric ='slds-tabs_scoped__content';
            this.colouronselect='buttonneutral';
        }
       
        this.SizeChartComponetContent=false;
        if(this.SizeChartComponetContent ==false){
            this.propsizechart='slds-hide';
            this.colouronselect='buttonconstant';
        }
        this.CountryOfOriginContent=false;
        if(this.CountryOfOriginContent ==false){
            this.propCountry='slds-hide';
            this.colouronselect='buttonconstant';
        }
        this.CareLabelInstructionDetailContent=false;
        if(this.CareLabelInstructionDetailContent ==false){
            this.propInstruction='slds-hide';
            this.colouronselect='buttonneutral';
        }
        this.ExcareInstructionContent=false;
        this.FreeTextContent=false;
        if(this.FreeTextContent ==false){
            this.propfreetext='slds-hide';
            this.colouronselect='buttonneutral';
        }
        this.colouronselectFabric='slds-is-active';
        this.colouronselectSize='slds-is-inactive';
     this.colouronselectBrandIcon='slds-is-inactive';
     this.colouronselectCountry ='slds-is-inactive';
     this.colouronselectCareInstruction ='slds-is-inactive';
     this.colouronselectFreeText='slds-is-inactive';
    }
    SizeChartTab(event){
        const tabId = event.currentTarget.getAttribute('data-id');
        this.SizeChartTabId =tabId;
        this.careinsructiontabid ='';
        this.FabricomTabId ='';
        this.BrandIconTabId ='';
        this.countryTabId ='';
        this.FreeTextTabId ='';
        this.country =false;
        this.instruction =false;
        this.freetext =false;
       
        this.sizecmp=true;
        this.BranIcon=false;
        this.Fabriccmp =false;
        this.BrandIconContent=false;
        
        this.FabricComponentContent=false;
        this.SizeChartComponetContent=true;
        if(this.SizeChartComponetContent == true){
            this.propsizechart ='slds-tabs_scoped__content';
            this.colouronselect='buttonneutral';
        }
        this.CountryOfOriginContent=false;
        this.CareLabelInstructionDetailContent=false;
        this.ExcareInstructionContent=false;
        this.FreeTextContent=false;
        if(this.BrandIconContent ==false &&  this.FabricComponentContent ==false && this.CountryOfOriginContent==false &&   this.CareLabelInstructionDetailContent ==false &&  this.FreeTextContent ==false){
            this.propBranIcon ='slds-hide';
            this.propfreetext ='slds-hide';
            this.propInstruction='slds-hide';
            this.propCountry ='slds-hide';
            this.propfabric ='slds-hide';
            this.colouronselect='slds-button_constant';
        }
        const SizeChartTab = event.target.getAttribute('id');
       this.colouronselectSize='slds-is-active'
       this.colouronselectFabric='slds-is-inactive';
       this.colouronselectBrandIcon='slds-is-inactive';
       this.colouronselectCountry ='slds-is-inactive';
       this.colouronselectFreeText='slds-is-inactive';
    }
    CountryOfOriginTab(event){
        const tabId = event.currentTarget.getAttribute('data-id');
        this.countryTabId =tabId;
        this.SizeChartTabId ='';
        this.BrandIconTabId ='';
        this.FreeTextTabId ='';
        this.FabricomTabId='';
        this.careinsructiontabid ='';
        this.BranIcon=false;
        this.Fabriccmp =false;
        this.country =true;
        this.sizecmp=false;
        this.instruction =false;
        this.freetext =false;
        this.BrandIconContent=false;
        this.FabricComponentContent=false;
        this.SizeChartComponetContent=false;
        this.CountryOfOriginContent=true;
        if(this.CountryOfOriginContent == true){
            this.propCountry ='slds-tabs_scoped__content';
            this.colouronselect='buttonneutral';
        }
        this.CareLabelInstructionDetailContent=false;
        this.ExcareInstructionContent=false;
        this.FreeTextContent=false;
        if(this.BrandIconContent == false &&  this.FabricComponentContent == false  && this.SizeChartComponetContent == false &&   this.CareLabelInstructionDetailContent ==false &&  this.FreeTextContent ==false){
            this.propBranIcon ='slds-hide';
            this.propfreetext ='slds-hide';
            this.propInstruction='slds-hide';
            this.propsizechart ='slds-hide';
            this.propfabric ='slds-hide';
            this.colouronselect='buttonconstant';
        }
        const CountryOfOriginTab = event.target.getAttribute('id');
        this.colouronselectSize='slds-is-inactive';
        this.colouronselectFabric='slds-is-inactive';
        this.colouronselectCountry ='slds-is-active';
    this.colouronselectBrandIcon='slds-is-inactive';
    this.colouronselectCareInstruction ='slds-is-inactive';
    this.colouronselectFreeText='slds-is-inactive';
       
    }
    CareInstructionDetailsTab(event){
        const tabId = event.currentTarget.getAttribute('data-id');
        this.careinsructiontabid =tabId;
        this.BrandIconContent=false;
        this.FreeTextTabId ='';
        this.SizeChartTabId ='';
        this.BrandIconTabId ='';
        this.countryTabId ='';
        this.FabricomTabId='';
        this.instruction =true;
        this.BranIcon=false;
        this.Fabriccmp =false;
        this.country =false;
        this.sizecmp=false;
        this.freetext =false;
        this.FabricComponentContent=false;
        this.SizeChartComponetContent=false;
        this.CountryOfOriginContent=false;
        this.CareLabelInstructionDetailContent=true;
        if(this.CareLabelInstructionDetailContent == true){
            this.propInstruction='slds-tabs_scoped__content';
            this.colouronselect='buttonneutral';
        }
        this.ExcareInstructionContent=false;
        this.FreeTextContent=false;
        if(this.BrandIconContent ==false &&  this.FabricComponentContent ==false && this.SizeChartComponetContent ==false &&   this.CountryOfOriginContent ==false &&  this.FreeTextContent ==false){
            this.propBranIcon ='slds-hide';
            this.propfreetext ='slds-hide';
            this.propCountry='slds-hide';
            this.propsizechart ='slds-hide';
            this.propfabric ='slds-hide';
            this.colouronselect='buttonconstant';
        }
       // const CareInstructionDetailsTab = event.target.getAttribute('id');
        for(var i=0;i<8;i++)
        {
            this.selectedCarTabId ='care-'+i;
        }
        this.selectedCarTabId ='care-0';

        this.colouronselectFabric='slds-is-inactive';
        this.colouronselectSize='slds-is-inactive';
     this.colouronselectBrandIcon='slds-is-inactive';
     this.colouronselectCountry ='slds-is-inactive';
     this.colouronselectCareInstruction ='slds-is-active';
     this.colouronselectFreeText='slds-is-inactive';
    }
    ExcareInstructionsTab(event){
        this.BrandIconContent=false;
        this.FabricComponentContent=false;
        this.SizeChartComponetContent=false;
        this.CountryOfOriginContent=false;
        this.CareLabelInstructionDetailContent=false;
        this.ExcareInstructionContent=true;
        this.FreeTextContent=false;
        const ExcareInstructionsTab = event.target.getAttribute('id');
       
    }
    FreeTextTab(event){
        const tabId = event.currentTarget.getAttribute('data-id');
        this.FreeTextTabId =tabId;
        this.careinsructiontabid ='';
        this.SizeChartTabId ='';
        this.FabricomTabId ='';
        this.countryTabId ='';
        this.SizeChartTabId ='';
        this.BrandIconTabId ='';
        this.freetext =true;
        this.instruction =false;
        this.BranIcon=false;
        this.Fabriccmp =false;
        this.country =false;
        this.sizecmp=false;
        this.country =false;
        this.BrandIconContent=false;
        this.FabricComponentContent=false;
        this.SizeChartComponetContent=false;
        this.CountryOfOriginContent=false;
        this.CareLabelInstructionDetailContent=false;
        this.ExcareInstructionContent=false;
        this.FreeTextContent=true;
        if(this.FreeTextContent == true){
            this.propfreetext='slds-tabs_scoped__content';
            this.colouronselect='buttonneutral';
        }
        if(this.BrandIconContent ==false &&  this.FabricComponentContent ==false && this.SizeChartComponetContent ==false &&   this.CountryOfOriginContent ==false &&  this.CareLabelInstructionDetailContent ==false){
            this.propBranIcon ='slds-hide';
            this.propInstruction ='slds-hide';
            this.propCountry='slds-hide';
            this.propsizechart ='slds-hide';
            this.propfabric ='slds-hide';
            this.colouronselect='buttonconstant';
        }
        const FreeTextTab = event.target.getAttribute('id');
        this.colouronselectFreeText='slds-is-active';
        this.colouronselectFabric='slds-is-inactive';
        this.colouronselectSize='slds-is-inactive';
     this.colouronselectBrandIcon='slds-is-inactive';
     this.colouronselectCountry ='slds-is-inactive';
     this.colouronselectCareInstruction ='slds-is-inactive';
    }
    addLabel(){
       this.careLabelOrder=false;
        this.logo=false;
        this.catalogVertical=true;
        console.log('incarecountry >>>000'+this.selectedcountry);
        const obj={"flag": "fromLabel",
                "company":this.selectedcountrys};
        fireEvent(this.pageRef,"CatalogEvent",obj);
       // eval("$A.get('e.force:refreshView').fire();");
       

const selectedEvent = new CustomEvent("seture", { detail: {country:this.selectedcountry,
  catalogVertical : true}});
this.dispatchEvent(selectedEvent);
    }
 
    viewCareLabelss(event){
      alert('viewCareLabel >>123');
      const viewInd =event.target.name;
      alert('viewInd >>'+viewInd);
      this.viewedIndex=viewInd;
 this.finalviewedCarelabelData ={};
 this.getWrapperDataForView(viewInd);

 const CloseLogo = new CustomEvent('CloseLogoEvent', {
    detail: {'closelogo':false}
});
this.dispatchEvent(CloseLogo);
    }

    ClearData(){
        // let child = this.template.querySelector('c-catalog-vertical-lwc');
                // child.getBulkData();
        let CareIns = this.template.querySelector('c-catalog-vertical-lwc');
        let itemMaster=this.itemMaster;
        let careLabelSelectedData=this.careLabelSelectedData;
        let temp=new Object();
        temp.selectedLang=this.selectedLang;
        temp.quantity=this.Quantity;
        if(careLabelSelectedData.brandIcondata!='{}')
        {
            temp.brandIcondata=careLabelSelectedData.brandIcondata;
        }
        temp.FabricSelectedData=careLabelSelectedData.FabricSelectedData;
        if(careLabelSelectedData.sizeChartData!='{}')
        {
            temp.sizeChartData=careLabelSelectedData.sizeChartData;
        }
        if(careLabelSelectedData.countryOriginData!='{}')
        {
            temp.countryOriginData=careLabelSelectedData.countryOriginData;
        }
        temp.CareSelectedData=careLabelSelectedData.CareSelectedData;
        if(careLabelSelectedData.exCareSelectedData!='{}')
        {
            temp.exCareSelectedData=careLabelSelectedData.exCareSelectedData;
        }	
        if(careLabelSelectedData.freetextData!='{}')
        {
            temp.freetextData=careLabelSelectedData.freetextData;
        }	
        careLabelSelectedData.exCareSelectedData='{}';
        careLabelSelectedData.brandIcondata=' ';
        var brandIcondata=this.Brandlist;
        for (var i = 0; i <brandIcondata.length; i++) {
            brandIcondata[i].BrandIconCheckbox = false;
        }
        this.Brandlist=brandIcondata;
        careLabelSelectedData.sizeChartData=' ';
        let sizeChartData=this.sizelist;
        for (var i = 0; i <sizeChartData.length; i++) {
            sizeChartData[i].selectedsizechart = false;
        } 
        this.sizelist=sizeChartData;
        careLabelSelectedData.CareSelectedData=[];
        careLabelSelectedData.FabricSelectedData=[];
        careLabelSelectedData.freetextData=' ';
        careLabelSelectedData.countryOriginData=' ';
        this.selectedLang='';
        this.Quantity=0;
        // this.template.querySelector('c-care-label-order-fabric-component-lwc').clearSelectedData('Clear');
        // this.template.querySelector('c-care-label-order-brand-icon-lwc').clearSelectedData('Clear');
        // this.template.querySelector('c-care-label-order-size-chart-lwc').clearSelectedData('Clear');
        // this.template.querySelector('c-care-label-country-component-lwc').clearSelectedData('Clear');
        // this.template.querySelector('c-care-label-care-instruction-component-lwc').clearSelectedData('Clear');
        // this.template.querySelector('c-care-label-order-free-text-lwc').clearSelectedData('Clear');

    }
    handlFabricSelectedData(event){
        this.careLabelSelectedData.FabricSelectedData=event.detail.FabricSelectedData;

    }
    handleselectedsize(event){
         this.careLabelSelectedData.sizeChartData =event.detail.sizeChartData;
    }
    handleGetTempBrandIconData(event){
        this.tempbrandicondata =event.detail.TempBrandIcondata;
    }
    HandleSelectedcountry(event){
    let getselectedcountry =event.detail.selectedcountry;
        if (Array.isArray(this.careLabelSelectedData)) {
            this.careLabelSelectedData = this.careLabelSelectedData.countryOriginData.selectedcountry.map(selectedcountry => ({
                ...selectedcountry,
                selectedcountry: getselectedcountry,
            
            }));
        }
        else{

            var temp =this.careLabelSelectedData;
            temp.countryOriginData.selectedcountry=getselectedcountry;
          
             this.careLabelSelectedData =[];
            this.careLabelSelectedData =temp;
            // this.careLabelSelectedData =[...temp];

        }
       
}
handleviewselectedcountry(event){
    
    this.finalviewedCarelabelData.countryOriginData=event.detail.viewselectedcountry;
}
handlefreetextdata(event){
    this.careLabelSelectedData.freetextData=event.detail.freetextData;
}
handlecareinstructon(event){
    this.careLabelSelectedData.CareSelectedData=event.detail.selectedCareInstList;
}
handlevaiwcareselecteddata(event){
    this.finalviewedCarelabelData.CareSelectedData=event.detail.vaiwCareSelectedData;
}
handleviewFreetextData(event){
   // alert('handleviewFreetextData >>');
    this.finalviewedCarelabelData.freetextData=event.detail.viewFreetextData;
}

getWrapperDataForView(viewInd){
alert('inside getwrapper')
    console.log('in getWrapperDataForView --> '+JSON.stringify(this.careLabelSelectedDataList));
    console.log('viewInd -->'+viewInd);
    console.log('selectedcustomerid -->'+this.selectedcustomerid);
    console.log('productName -->'+this.careLabelSelectedDataList[viewInd].productName);
    getWrapperData({
        retailerCode :'a00O000000mDAkPIAW',
        productname:this.careLabelSelectedDataList[viewInd].productName,
        customerid :this.selectedcustomerid

    })
    .then(result => {
        var mainwrapper =result;
       
console.log('view wrapper -->'+JSON.stringify(mainwrapper));
      this.itemMasterForView=mainwrapper.itemMaster;
      console.log('itemMasterForView --->'+JSON.stringify(this.itemMasterForView));
      this.picvalueForView = mainwrapper.LangCombList;
      this.BrandlistForView=mainwrapper.BrandIcon;
      this.sizelistForView =mainwrapper.sizechart;
      this.lstcmpnameForView=mainwrapper.FabricComponent;
      this.lstfabnameForView =mainwrapper.MaterialComponent;
      this.lstcountrynameForView=mainwrapper.CountryofOrigin;
      this.selectedcountryForView=mainwrapper.LangCountryList;
      this.CareinstructionForView=mainwrapper.Careinstruction;
      this.ExcareinstructionForView=mainwrapper.Excareinstruction;
      this.ExcarecmpnameForView =mainwrapper.ExcarePosition;
      this.viewedCarelabelData=this.careLabelSelectedDataList[viewInd];
      console.log('viewedCarelabelData -->'+JSON.stringify(this.viewedCarelabelData));
    //  this.selectedLanguages =this.careLabelSelectedDataList[viewInd].selectedLang;
      this.viewCarelabelFlag =true;
       
      alert('viewCarelabelFlag>>'+this.viewCarelabelFlag);
    })
    .catch(error => {
       console.log('errorrr'+error);
    });
}
closeViewCareLabel(){
    this.viewCarelabelFlag =false; 
}
removeCarelabelLine(event){
    var careLabelSelectedDataList =this.careLabelSelectedDataList;
    var removeInd  =event.target.name;
    var soliIdToDelete=careLabelSelectedDataList[removeInd].soliId;
    var soId=careLabelSelectedDataList[removeInd].soId;
    var deleterow=careLabelSelectedDataList.splice(removeInd, 1);
    this.careLabelSelectedDataList =careLabelSelectedDataList;
    this.deleteSOLICarelabelData(soId,soliIdToDelete);
}
deleteSOLICarelabelData(soId,soliIdToDelete){
    this.viewselecteddata =false;
    deleteCareLabelData({
      'soid':soId,
      'soliIdToDelete':soliIdToDelete
    })
    .then(result=>{
        const toastEvent = new ShowToastEvent({
            title: 'warning',
            message: 'Selected Label Is removed',
            variant: 'warning'
        });
        this.dispatchEvent(toastEvent);
       
        this.careLabelSelectedDataListlength=false;

    })
    .catch(error=>{

    })
}
addDataToCart(){
    var label ='Cart'
    this.saveCareData(label);
}
viewselectedLanguages(evet){
    this.getselectedviewlanguage=evet.target.value;
}
viewselectedQuantity(event){
  //  this.getselectedviewQuantity =event.target.value;
    this.Quantity=event.target.value;
}
LatestSubmitViewedCareLabl(){
    this.propBranIcon ='slds-hide';
    var itemMaster =this.itemMasterForView;
    console.log('Brandicon ==>'+itemMaster.Brand_Icon__c);
    console.log('itemMaster >>>))00>'+JSON.stringify(itemMaster));
    var tempViewedCarelabelData={};

    // this.template.querySelector('c-care-label-order-brand-icon-lwc').viewSelectedBrand();
    // this.template.querySelector('c-care-label-order-fabric-component-lwc').viewbindFabricData();
    // this.template.querySelector('c-care-label-order-size-chart-lwc').viewselectedSize();
    //  this.template.querySelector('c-care-label-country-component-lwc').viewFetchCountry();
    //  this.template.querySelector('c-care-label-care-instruction-component-lwc').viewbindSelectedData();
     //this.template.querySelector('c-care-label-order-free-text-lwc').viewFreetextDatas();
    var viewedCarelabelData =this.finalviewedCarelabelData;
    console.log('viewedCarelabelData>>'+JSON.stringify(viewedCarelabelData));
    console.log('Box>>'+JSON.stringify(viewedCarelabelData.boxquantity));
    var viewedIndex =this.viewedIndex;
    console.log('viewedIndex >>'+JSON.stringify(viewedIndex));

    var careLabelSelectedDataList =this.careLabelSelectedDataList;
    console.log('LatestSubmitViewedCareLabl ::'+JSON.stringify(careLabelSelectedDataList));
    console.log('LatestSubmitViewedCareLabl  001::'+JSON.stringify(careLabelSelectedDataList[viewedIndex]));
    console.log('Quantity --->'+this.Quantity);
  if(this.getselectedviewlanguage ==''){
    const toastEvent = new ShowToastEvent({
        title: 'warning',
        message: 'Language is missing',
        variant: 'warning'
    });
    this.dispatchEvent(toastEvent);
    return;
  }
  else{
    viewedCarelabelData.selectedLang = this.getselectedviewlanguage;
  }
  if(this.Quantity <=0){
    const toastEvent = new ShowToastEvent({
        title: 'warning',
        message: 'Label Quantity is missing',
        variant: 'warning'
    });
    this.dispatchEvent(toastEvent);
    return;
  }
  else{   
   
   
    var result;
     if(this.Quantity< this.MOQ && this.fullboxQty && this.viewedCarelabelData.boxquantity && (this.Quantity <this.viewedCarelabelData.boxquantity ||this.Quantity %this.viewedCarelabelData.boxquantity)  !=0)
     {
        result = Math.ceil(this.Quantity / this.viewedCarelabelData.boxquantity)*this.viewedCarelabelData.boxquantity;
        if(confirm('Order Quantity for Product' +this.selectedproduct.Name +'is less then Minimum Order Quantity MOQ'+this.MOQ +"\n" +'The nearest multiples of box quantity'+ result + "\n" +'Click OK to confirm Order Quantity' +result +'and add it in the CART'))
        {
            alert('1st if');
        console.log('itemMaster.Brand_Icon__c'+itemMaster.Brand_Icon__c);
            viewedCarelabelData.quantity=result;
            console.log('inside quantity -->'+result);
            this.Quantity =viewedCarelabelData.quantity;
            //this.Quantity =result;
         }
                 return;  
    }
   
            else if(this.Quantity<this.MOQ && this.fullboxQty && this.viewedCarelabelData.boxquantity && (this.MOQ <this.viewedCarelabelData.boxquantity ||this.MOQ %this.viewedCarelabelData.boxquantity)!=0)
    {
        alert('2nd if');
        result = Math.ceil(this.MOQ/this.viewedCarelabelData.boxquantity)*this.viewedCarelabelData.boxquantity;
        if(confirm('Order Quantity for Product' +this.selectedproduct.Name +'is less then Minimum Order Quantity MOQ'+this.MOQ +"\n" +'The nearest multiples of box quantity'+ result + "\n" +'Click OK to confirm Order Quantity' +result +'and add it in the CART'))
        {
            viewedCarelabelData.quantity=result;
            this.Quantity =viewedCarelabelData.quantity;
            this.Quantity =result;
        }
        return;
    }
    else if(this.Quantity<this.MOQ ){
        alert('3rd if');
        if(confirm('Order Quantity for Product' +this.selectedproduct.Name +'is less then Minimum Order Quantity MOQ'+this.MOQ +"\n" +'The nearest multiples of box quantity'+ result + "\n" +'Click OK to confirm Order Quantity' +result +'and add it in the CART')){
            viewedCarelabelData.quantity=this.MOQ;
            this.Quantity =viewedCarelabelData.quantity;
            this.Quantity =this.MOQ;
        }
        return;
    }
    result=Math.ceil(this.Quantity/this.viewedCarelabelData.boxquantity)*this.viewedCarelabelData.boxquantity;
    if(this.fullboxQty && this.viewedCarelabelData.boxquantity && (this.Quantity<this.viewedCarelabelData.boxquantity || this.Quantity % this.viewedCarelabelData.boxquantity)!=0)
    {
        alert('after 4th if');
        result=Math.ceil(this.Quantity/this.viewedCarelabelData.boxquantity)*this.viewedCarelabelData.boxquantity;
        if(confirm('Order Quantity for Product' +this.selectedproduct.Name +'is not the multiples of Box quantity'+this.MOQ +"\n" +'The nearest multiples of box quantity'+ result + "\n" +'Click OK to confirm Order Quantity' +result +'and add it in the CART'))
        {
            viewedCarelabelData.quantity=result;
            this.Quantity =viewedCarelabelData.quantity;
            this.Quantity =result;
        }
        return; 
    }
    viewedCarelabelData.quantity= this.Quantity;
}
console.log('after else >>'+this.itemMasterForView.Brand_Icon__c);
if(viewedCarelabelData.brandIcondata){
    alert('viewedCarelabelData.brandIcondata');
    if(viewedCarelabelData.brandIcondata==='{}')
            {
                const toastEvent = new ShowToastEvent({
                    title: 'warning',
                    message: 'Brand_Icon_is_missing',
                    variant: 'warning'
                });
                this.dispatchEvent(toastEvent); 
                return; 
            } 
}
else if(this.itemMasterForView.Brand_Icon__c ==true)
{
    alert('inside itemMaster.Brand_Icon__c');
    viewedCarelabelData.brandIcondata=careLabelSelectedDataList[viewedIndex].brandIcondata;
}
if(viewedCarelabelData.FabricSelectedData){
    alert('inside iewedCarelabelData.FabricSelectedData');
    if(viewedCarelabelData.FabricSelectedData.length<1){
        const toastEvent = new ShowToastEvent({
            title: 'warning',
            message: 'Fabric combination value lesser  than 100',
            variant: 'warning'
        });
        this.dispatchEvent(toastEvent); 
        return;  
    }
    var compCount={};
    var fabCount={};
    var total=0;
    for(var i=0;i<viewedCarelabelData.FabricSelectedData.length;i++)
            {
                alert('viewedCarelabelData.FabricSelectedData.length');
                if(viewedCarelabelData.FabricSelectedData[i].Component)
                {
                    if(!compCount[viewedCarelabelData.FabricSelectedData[i].Component])
                    compCount[viewedCarelabelData.FabricSelectedData[i].Component]=0;
                compCount[viewedCarelabelData.FabricSelectedData[i].Component]+=viewedCarelabelData.FabricSelectedData[i].value;
                }
                if(!viewedCarelabelData.FabricSelectedData[i].Component)
                {
                    total+=viewedCarelabelData.FabricSelectedData[i].value;
                }
            }
            for(var key in compCount){
                if(compCount[key]<100)
                {
                    const toastEvent = new ShowToastEvent({
                        title: 'warning',
                        message: 'Fabric combination value lesser greater than 100',
                        variant: 'warning'
                    });
                    this.dispatchEvent(toastEvent); 
                    return;  
                }
            }
            if(total!=0 && (total<100 || total>100))
            {
                const toastEvent = new ShowToastEvent({
                    title: 'warning',
                    message: 'Fabric combination value lesser greater than 100',
                    variant: 'warning'
                });
                this.dispatchEvent(toastEvent); 
                return;  
            }
}
else if(itemMaster.Fabric_Component__c)
{
    alert('inside itemMaster.Fabric_Component__c');
    viewedCarelabelData.FabricSelectedData=careLabelSelectedDataList[viewedIndex].FabricSelectedData;
}
if(viewedCarelabelData.sizeChartData){
    alert('inside viewedCarelabelData.sizeChartData');
    if(viewedCarelabelData.sizeChartData==='{}'){
    const toastEvent = new ShowToastEvent({
        title: 'warning',
        message: 'Size chart is missing',
        variant: 'warning'
    });
    this.dispatchEvent(toastEvent); 
    return;  
}
else{
    viewedCarelabelData.sizeChartData=careLabelSelectedDataList[viewedIndex].sizeChartData;
}
}
else if(itemMaster.Size_Chart__c)
{
    alert('inside itemMaster.Size_Chart__c');
    viewedCarelabelData.sizeChartData=careLabelSelectedDataList[viewedIndex].sizeChartData;
}
if(viewedCarelabelData.countryOriginData){
    alert('inside viewedCarelabelData.countryOriginData');
    if(viewedCarelabelData.countryOriginData.selectedcountry=='-NONE-'){
        const toastEvent = new ShowToastEvent({
            title: 'warning',
            message: 'Country of Origin is missing',
            variant: 'warning'
        });
        this.dispatchEvent(toastEvent); 
        return;  
    }

}
else if(itemMaster.Country_Of_Origin__c)
{
    alert('inside itemMaster.Country_Of_Origin__c');
    viewedCarelabelData.countryOriginData=careLabelSelectedDataList[viewedIndex].countryOriginData;
}
if(viewedCarelabelData.CareSelectedData){
    alert('inside viewedCarelabelData.CareSelectedData')
    if(viewedCarelabelData.CareSelectedData.length <1){
        alert('iewedCarelabelData.CareSelectedData.length')
        const toastEvent = new ShowToastEvent({
            title: 'warning',
            message: 'Care instructions is missing',
            variant: 'warning'
        });
        this.dispatchEvent(toastEvent); 
        return;  
    }


var Careinstruction=this.CareinstructionForView;
console.log('CareinstructionForView --:::>'+JSON.stringify(this.CareinstructionForView));
if(Careinstruction.length != viewedCarelabelData.CareSelectedData.length)
{
    const toastEvent = new ShowToastEvent({
        title: 'warning',
        message: 'All the Care instructions have not been selected',
        variant: 'warning'
    });
    this.dispatchEvent(toastEvent); 
    return;   
}
}
else if(this.CareinstructionForView.length>0)
        {
            alert('this.CareinstructionForView.length >>');
            console.log('this.CareinstructionForView.length --:::>'+JSON.stringify(this.CareinstructionForView.length));
            viewedCarelabelData.CareSelectedData=careLabelSelectedDataList[viewedIndex].CareSelectedData;
        }   
        if(itemMaster.Excare_Instruction__c)
        {
            alert('inside itemMaster.Excare_Instruction__c')
            if(viewedCarelabelData.exCareSelectedDataList)
            {
                alert('viewedCarelabelData.exCareSelectedDataList');
                 if(viewedCarelabelData.exCareSelectedDataList.length==0)
                 {
                    
                    const toastEvent = new ShowToastEvent({
                         title: 'warning',
                         message: 'Excare instructions is missing',
                         variant: 'warning'
                     });
                     this.dispatchEvent(toastEvent); 
                     return;  
                 }
                 else
                 {
                   
                 }
            }
            else
            {
                viewedCarelabelData.exCareSelectedDataList=careLabelSelectedDataList[viewedIndex].exCareSelectedDataList;
            }
        }
            if(viewedCarelabelData.freetextData)
        {
            if(JSON.stringify(viewedCarelabelData.freetextData)=='{}' ){
            const toastEvent = new ShowToastEvent({
                title: 'warning',
                message: 'Free Text is missing',
                variant: 'warning'
            });
            this.dispatchEvent(toastEvent); 
            return;        
        }
         if((itemMaster.Style_Number__c && !viewedCarelabelData.freetextData.StyleNumber))
            {
               
        const toastEvent = new ShowToastEvent({
            title: 'warning',
            message: 'Style Number is missing',
            variant: 'warning'
        });
        this.dispatchEvent(toastEvent); 
        return;    
            }
             if((itemMaster.RN_Number__c && !viewedCarelabelData.freetextData.RNNumber))
            {
                const toastEvent = new ShowToastEvent({
                    title: 'warning',
                    message: 'RN Number is missing',
                    variant: 'warning'
                });
                this.dispatchEvent(toastEvent); 
                return;    
            }
             if((itemMaster.Lot_Number__c && !viewedCarelabelData.freetextData.LotNumber))
            {
                const toastEvent = new ShowToastEvent({
                    title: 'warning',
                    message: 'LotNumber is missing',
                    variant: 'warning'
                });
                this.dispatchEvent(toastEvent); 
                return;   
            }
         if((itemMaster.Supplier_Number__c && !viewedCarelabelData.freetextData.SupplierNumber))
            {
                const toastEvent = new ShowToastEvent({
                    title: 'warning',
                    message: 'Supplier Number is missing',
                    variant: 'warning'
                });
                this.dispatchEvent(toastEvent); 
                return;
            }
            if((itemMaster.Labelling_Code__c && !viewedCarelabelData.freetextData.LabellingCode))
            {
                const toastEvent = new ShowToastEvent({
                    title: 'warning',
                    message: 'Labelling Code is missing',
                    variant: 'warning'
                });
                this.dispatchEvent(toastEvent); 
                return;
            }
         if((itemMaster.Packaging_Code__c && !viewedCarelabelData.freetextData.PackagingCode))
            {
                const toastEvent = new ShowToastEvent({
                    title: 'warning',
                    message: 'Packaging Code is missing',
                    variant: 'warning'
                });
                this.dispatchEvent(toastEvent); 
                return;
            }
            if((itemMaster.Season_Month__c && !viewedCarelabelData.freetextData.SeasonMonth))
            {
                const toastEvent = new ShowToastEvent({
                    title: 'warning',
                    message: 'Season Month is missing',
                    variant: 'warning'
                });
                this.dispatchEvent(toastEvent); 
                return;
            }
             if((itemMaster.Season_Year__c && !viewedCarelabelData.freetextData.SeasonYear))
            {
                const toastEvent = new ShowToastEvent({
                    title: 'warning',
                    message: 'Season Year is missing',
                    variant: 'warning'
                });
                this.dispatchEvent(toastEvent); 
                return;
            }
             if((itemMaster.Item_Number__c && !viewedCarelabelData.freetextData.ItemNumber))
                {
                    const toastEvent = new ShowToastEvent({
                        title: 'warning',
                        message: 'Item_Number_is_missing',
                        variant: 'warning'
                    });
                    this.dispatchEvent(toastEvent); 
                    return;

               }
                if((itemMaster.Care_Instruction__c && !viewedCarelabelData.freetextData.careinstruct))
              {
                const toastEvent = new ShowToastEvent({
                    title: 'warning',
                    message: 'care instruction is missing',
                    variant: 'warning'
                });
                this.dispatchEvent(toastEvent); 
                return;
              }
            }
    
    else if(careLabelSelectedDataList[viewedIndex].freetextData)
    {
        viewedCarelabelData.freetextData=careLabelSelectedDataList[viewedIndex].freetextData;
    }
    viewedCarelabelData.Priceper100pc=careLabelSelectedDataList[viewedIndex].Priceper100pc;
        viewedCarelabelData.boxquantity=careLabelSelectedDataList[viewedIndex].boxquantity;
        viewedCarelabelData.color=careLabelSelectedDataList[viewedIndex].color;
        viewedCarelabelData.custRefModel=careLabelSelectedDataList[viewedIndex].custRefModel;
        viewedCarelabelData.fullboxquantity=careLabelSelectedDataList[viewedIndex].fullboxquantity;
        viewedCarelabelData.imgUrl=careLabelSelectedDataList[viewedIndex].imgUrl;
        viewedCarelabelData.localSKU=careLabelSelectedDataList[viewedIndex].localSKU;
        viewedCarelabelData.priceSpecId=careLabelSelectedDataList[viewedIndex].priceSpecId;
        viewedCarelabelData.printShop=careLabelSelectedDataList[viewedIndex].printShop;
        viewedCarelabelData.produDesc=careLabelSelectedDataList[viewedIndex].produDesc;
        viewedCarelabelData.productFamily=careLabelSelectedDataList[viewedIndex].productFamily;
        viewedCarelabelData.productName=careLabelSelectedDataList[viewedIndex].productName;
        viewedCarelabelData.soId=careLabelSelectedDataList[viewedIndex].soId;
        viewedCarelabelData.soliId=careLabelSelectedDataList[viewedIndex].soliId;
        console.log(viewedCarelabelData);
            var viewedIndex =this.viewedIndex;
            console.log('viewedIndex >>22'+viewedIndex); 
            var careLabelSelectedDataList =this.careLabelSelectedDataList;
            console.log('careLabelSelectedDataList >>'+JSON.stringify(careLabelSelectedDataList));
            for(var i=0;i<careLabelSelectedDataList.length && i!=viewedIndex;i++)
            {
                alert('inside for');
                var tempFab=careLabelSelectedDataList[i].FabricSelectedData;
                var fabMached=true;
                if(itemMaster.Fabric_Component__c){
                    if(tempFab.length==viewedCarelabelData.FabricSelectedData.length)
                    {
                        for(var j=0;j<tempFab.length;j++)
                        {
                            var fabId=tempFab[j]['fabId'];
                        delete tempFab[j]['fabId'];
                        var matched=false;
                        for(var k=0;k<viewedCarelabelData.FabricSelectedData.length;k++)
                        {
                            var fabId1=viewedCarelabelData.FabricSelectedData[k]['fabId'];
                            delete viewedCarelabelData.FabricSelectedData[k]['fabId'];
                            if(JSON.stringify(viewedCarelabelData.FabricSelectedData[k])===JSON.stringify(tempFab[j]))
                            {
                                matched=true;
                            }
                            viewedCarelabelData.FabricSelectedData[k]['fabId']=fabId1;
                        }
                        tempFab[j]['fabId']=fabId;
                        if(!matched)
                        {
                            fabMached=false;
                            break;
                        }
                        }
                        
                    }
                    else{
                    fabMached=false;
                    }
                    
                }
                var careInstMatch=true;
                if(this.Careinstruction.length>0)
                {
                    if(viewedCarelabelData.CareSelectedData.length==careLabelSelectedDataList[i].CareSelectedData.length)
                    {
                        var tempCareInstr=careLabelSelectedDataList[i].CareSelectedData;
                        for(var j=0;j<tempCareInstr.length;j++)
                        {
                            var careIdList=tempCareInstr[j]['careIdList'];
                            //alert('Bef>'+JSON.stringify(tempCareInstr));
                            delete tempCareInstr[j]['careIdList'];
                            var matched1=false;
                            for(var k=0;k<viewedCarelabelData.CareSelectedData.length;k++)
                            {
                                delete viewedCarelabelData.CareSelectedData[k]['careIdList'];
                                if(JSON.stringify(viewedCarelabelData.CareSelectedData[k])===JSON.stringify(tempCareInstr[j]))
                                {
                                    matched1=true;
                                }
                            }
                            tempCareInstr[j]['careIdList']=careIdList;
                            if(!matched1)
                            {
                                careInstMatch=false;
                                break;
                            }
                        }
                        
                    }
                    else{
                    careInstMatch=false;
                    }
                }
                var tempEx=careLabelSelectedDataList[i].exCareSelectedDataList;
            var exMatched=true;
            if(itemMaster.Excare_Instruction__c){
                if(tempEx.length==viewedCarelabelData.exCareSelectedDataList.length)
                {
                    for(var j=0;j<tempEx.length;j++)
                    {
                        var excareId=tempEx[j]['excareId'];
                        delete tempEx[j]['excareId'];
                        //alert(JSON.stringify(tempEx[j]));
                        var matched=false;
                        for(var k=0;k<viewedCarelabelData.exCareSelectedDataList.length;k++)
                        {
                            var excareId1=viewedCarelabelData.exCareSelectedDataList[k]['excareId'];
                            delete viewedCarelabelData.exCareSelectedDataList[k]['excareId'];
                            if(JSON.stringify(viewedCarelabelData.exCareSelectedDataList[k])===JSON.stringify(tempEx[j]))
                            {
                                matched=true;
                            } 
                            viewedCarelabelData.exCareSelectedDataList[k]['excareId']=excareId1;
                        }
                        tempEx[j]['excareId']=excareId;
                        if(!matched)
                        {
                            exMatched=false;
                            break;
                        }
                    }
                }
                else{
                    exMatched=false;
                }
            }
            var freeTextMatch=true;
            if(itemMaster.Free_Text__c){
                if((itemMaster.Style_Number__c && careLabelSelectedDataList[i].freetextData.StyleNumber!=viewedCarelabelData.freetextData.StyleNumber)
                   ||(itemMaster.RN_Number__c && careLabelSelectedDataList[i].freetextData.RNNumber!=viewedCarelabelData.freetextData.RNNumber)
                   ||(itemMaster.Lot_Number__c && careLabelSelectedDataList[i].freetextData.LotNumber!=viewedCarelabelData.freetextData.LotNumber)
                   ||(itemMaster.Care_Instruction__c && careLabelSelectedDataList[i].freetextData.careinstruct!=viewedCarelabelData.freetextData.careinstruct)
                   ||(itemMaster.Supplier_Number__c && careLabelSelectedDataList[i].freetextData.SupplierNumber!=viewedCarelabelData.freetextData.SupplierNumber)
                   ||(itemMaster.Labelling_Code__c && careLabelSelectedDataList[i].freetextData.LabellingCode!=viewedCarelabelData.freetextData.LabellingCode)
                   ||(itemMaster.Packaging_Code__c && careLabelSelectedDataList[i].freetextData.PackagingCode!=viewedCarelabelData.freetextData.PackagingCode)
                   ||(itemMaster.Season_Month__c && careLabelSelectedDataList[i].freetextData.SeasonMonth!=viewedCarelabelData.freetextData.SeasonMonth)
                   ||(itemMaster.Season_Year__c && careLabelSelectedDataList[i].freetextData.SeasonYear!=viewedCarelabelData.freetextData.SeasonYear)
                   ||(itemMaster.Item_Number__c && careLabelSelectedDataList[i].freetextData.ItemNumber!=viewedCarelabelData.freetextData.ItemNumber))
                {
                    freeTextMatch=false;
                }
            }
            var brandIconPresent=true;
            if(itemMaster.Brand_Icon__c)
            {
                if(careLabelSelectedDataList[i].brandIcondata.Id==viewedCarelabelData.brandIcondata.Id)
                {
                    brandIconPresent=true;
                }
                else
                {
                    brandIconPresent=false;
                }
            }
            var sizeChartPresent=true;
            if(itemMaster.Size_Chart__c)
            {
                if(careLabelSelectedDataList[i].sizeChartData.Id==viewedCarelabelData.sizeChartData.Id)
                {
                    sizeChartPresent=true;
                }
                else
                {
                    sizeChartPresent=false;
                }
            }
            var countryOfOriginPresent=true;
            if(itemMaster.Country_Of_Origin__c)
            {
                if(viewedCarelabelData.countryOriginData.selectedcountry==careLabelSelectedDataList[i].countryOriginData.selectedcountry)
                {
                    countryOfOriginPresent=true;
                }
                else
                {
                    countryOfOriginPresent=false;
                }
            }
            if(careLabelSelectedDataList[i].selectedLang==viewedCarelabelData.selectedLang &&
                careLabelSelectedDataList[i].quantity==viewedCarelabelData.quantity &&
                brandIconPresent &&
                sizeChartPresent &&
                fabMached &&
                careInstMatch &&
                exMatched &&
                freeTextMatch &&
                countryOfOriginPresent
               )
             {
                const toastEvent = new ShowToastEvent({
                    title: 'warning',
                    message: 'Data Already Present',
                    variant: 'warning'
                });
                this.dispatchEvent(toastEvent); 
                return;
             }
            }
            console.log('careLabelSelectedDataList>>'+JSON.stringify(viewedCarelabelData));
            careLabelSelectedDataList[viewedIndex]=viewedCarelabelData;
            careLabelSelectedDataList[viewedIndex].quantity=this.Quantity;
            console.log('controller Before set::'+this.careLabelSelectedDataList);
            this.careLabelSelectedDataList=careLabelSelectedDataList;
            console.log('controller after set::'+JSON.stringify(this.careLabelSelectedDataList));
              this.viewCarelabelFlag=false;
              const label='label';
              console.log('label >>>>333'+label);
              this.saveCareData(label);
 

           
}
changeTabColorBrandIcon(){
    this.succesborderforBrandIcon='success-border';
  
}
changeTabColorFabricComponent(){
    this.succesborderforFabric='success-border';
}
changeTabColorSizeChart(){
    this.succesborderforSize='success-border';
}
changeTabColorCountryOfOrigin(){
    this.succesborderforCountry='success-border';
}
changeTabColorCareInstructionDetails(){
    this.succesborderforCareInstruction='success-border';
}
changeTabColorFreeText(){
    this.succesborderforFreetext='success-border';
}
}