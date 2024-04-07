import {LightningElement,api,track,wire} from 'lwc';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import FetchCustData from '@salesforce/apex/PunchOutRequestController.FetchCustData';
import getAllCartDetails from '@salesforce/apex/PunchOutRequestController.getAllCartDetails';
import deleteProductFromCart from '@salesforce/apex/PunchOutRequestController.deleteProductFromCart';
import getWrapperData from '@salesforce/apex/SOController.getWrapperData';
import updateCartValue from '@salesforce/apex/PunchOutRequestController.updateCartValue';
import ClearCartDetails from '@salesforce/apex/PunchOutRequestController.ClearCartDetails';
import saveAsCareLabelData from '@salesforce/apex/SOController.saveAsCareLabelData';
import saveCareLabelData from '@salesforce/apex/SOController.saveCareLabelData';
import deletedCLLI from '@salesforce/apex/SOController.deletedCLLI';
import fetchCareLabelData from '@salesforce/apex/SOController.fetchCareLabelData';
import Mainetti_Model_Code from '@salesforce/label/c.Mainetti_Model_Code';
import Description from '@salesforce/label/c.Description';
import Color from '@salesforce/label/c.Color';
import Size from '@salesforce/label/c.Size';
import Box_Quantity from '@salesforce/label/c.Box_Quantity';
import Total_Order_Ammount from '@salesforce/label/c.Total_Order_Ammount';
import Care_Label_View_Edit from '@salesforce/label/c.Care_Label_View_Edit';
import {RefreshEvent} from 'lightning/refresh';
import checkAddAndCloneDataToDelete from '@salesforce/apex/PunchOutRequestController.checkAddAndCloneDataToDelete';
import checkLengthAddAndCloneDataToDelete from '@salesforce/apex/PunchOutRequestController.checkLengthAddAndCloneDataToDelete';
import {refreshApex} from '@salesforce/apex';
import {CurrentPageReference} from 'lightning/navigation';
import {fireEvent} from 'c/pubsub';
import ToastContainer from 'lightning/toastContainer';

export default class CatalogShippingCmpLwc extends LightningElement {

    @api labelName;
    @api description;
    @api retailerName;
    @api isShipcmp;
    @api selectedRetailer;
    @api selectedRetailercode;
    @api completeWrap;
    @api searchedCurrency;
    @api selectedCurrency;
    @api selectedTab;
    @api selectedRetailerName;
    @api parentcmp = false;
    @api getAddress = false;
    @api hideButtons = false;
    @api shipcmp = false;
    @api displayCustDetail;
    @api displayCartDetail = [];
    @api imgIndex;
    @api imgSrc;
    @api quantCount = 1;
    @api cartValue = 0;
    @track cartProducts = false;
    @api isOpen = false;
    // @api showRemarks = false;
    @track MOQ;

    @api totalOrderAmmount;
    @api renderTotalAmmount;
    @api currencyIso;
    @api loaded = false;
    @api showPriceInOrder;
    @api addandCone = 0;
    @api placeOrderBtn = false;
    @api confirmdataSection = false;
    @api viewCarelabelFlag = false;
    @api itemMasterForView;
    @api picvalueForView = [];
    @api BrandlistForView = [];
    @api sizelistForView;
    @api lstcmpnameForView = [];
    @api lstfabnameForView = [];
    @api lstcountrynameForView = [];
    @api selectedCountryForView;
    @api careinstructionForView;
    @api ExcareinstructionForView;
    @api ExcarecmpnameForView = [];
    @api viewedCarelabelData;
    @api careLabelSelectedDataList = [];
    @track careLabelSelectedDataList;
    @api picvalue;
    @api selectedBrand;
    @api quantity;
    @api uomOrder;
    @api finalViewedCarelabelData = {};
    @api selectedSize;
    @api careinstruction;
    @api viewedIndex;
    @track viewedpicList;
    @track selectedQuanty;
    @track selectedUmo;
    
    @api quickViewedProduct=[];
    @track saveAs=false;

    @api devSize = false;
    @api devFabric = false;
    @api devCountry = false;
    @api devCare = false;
    @api devExcare = false;
    @api devFree = false;
    @api devLogo = false;
    @api devViewEdit = false;
    @api logoGeneratorURL;
    @api saveAs = false;
    @api deletedCLLIIdList = [];
    @api moq = 0;
    @api fullboxQty = false;
    @api salesOrderId;
    @track parentcomponent = true;
    @track displayCartDetail;
    @track cartValue = 0;
    @track TotalOrderAmmount;
    @track showremarks = false;
    @track showPriceInOrder;

    @track viewCarelabelFlag = false;
    @track picvalue;
    @track isVariableDataProductYes;
    @track isSelectedTabLabelsAndTickets;
    @track Careinstructionlength = false;
    @track showSuccessToastMessage = false;
    @track showWarningToastMessage = false;
    @track showErrorToastMessage = false;
    @track showToastMessage;
    @track priceChanged = false;

    position = 'top-center';
    toastContainerObj = ToastContainer.instance();

    label = {
        some_products_selected_not_added_into_cart: 'Some Products Are Selected But Not Added into Cart',
        click_ok_to_add_pending_products_to_cart: 'Click OK to Add Pending Products to Cart',
        click_cancel_to: 'Click Cancel to',
        delete: 'DELETE',
        selected_products_and_proceed_to_create_order: 'Selected Products and Proceed to Create Order',
        okLabel: 'OK',
        cancelLabel: 'Cancel',
        Mainetti_Model_Code,
        Description,
        Color,
        Size,
        Box_Quantity,
        Total_Order_Ammount
     };




    @track displayCustDetail;
    @track cartValue;
    @track renderTotalAmmount = true;
    @track TotalOrderAmmount;
    @track CurrencyIso;
    @track loaded = false;
    @track showremarks;
    @track showPriceInOrder;
    @track hideButtons = false;
    @api catalogOrder = false;
    @track varprodct =[];
    @track cartDetailStatusActive =false;
    @track cartDetailStatusInactive =false;

    @wire(CurrentPageReference) pageRef;

    connectedCallback() {
       // alert('completeWrap --> '+JSON.stringify(this.completeWrap));
        if(this.selectedTab == 'Labels & Tickets'){
           this.isSelectedTabLabelsAndTickets = true;
        }else{
            this.isSelectedTabLabelsAndTickets = false;
        }
        this.catalogOrder = false;
        this.toGetcustomerData();
        const hideButtonsState = localStorage.getItem('hideButtons');
        if (hideButtonsState) {
            this.hideButtons = JSON.parse(hideButtonsState);
        }

    }

    handleClose(event) {
        var closePopup = event.detail.addressPopupFlag;
        console.log('closePopup -->' + event.detail.addressPopupFlag);
        if (closePopup == false) {
            this.getAddress = false;
        }
    }


    toGetcustomerData() {
        FetchCustData()
            .then(result1 => {
                console.log('result1>>>>>' + JSON.stringify(result1));
                this.displayCustDetail = result1.Customer_Information__c;
                console.log('displayCustDetail>>>>>' + JSON.stringify(this.displayCustDetail));
                
                this.getCartDetails();
            })
            .catch(error => {
                this.handleErrors(error);
            });
    }


    displayCartDetail = [];
    getCartDetails() {
        console.log('customerid>>>>>' + JSON.stringify(this.displayCustDetail));
        getAllCartDetails()
            .then(result2 => {
                console.log('result2 before>>>>>' + JSON.stringify(result2));
                if (result2) {

                if (result2.length > 0) {
                        this.cartValue = result2.length;
                        this.displayCartDetail = result2;
                        console.log('cartValue  length -->'+JSON.stringify(this.cartValue));
                        this.displayCartDetail = this.displayCartDetail.map(cartDetail => ({
                            ...cartDetail,
                            formattedValue: cartDetail.CurrencyIsoCode + ' ' + cartDetail.BlankString + ' ' + cartDetail.TotalPriceByCurrency
                        }));

                        var totalAmount = 0;
                       
                        for(var i=0; i<this.displayCartDetail.length; i++){

                            totalAmount += this.displayCartDetail[i].TotalPriceByCurrency;

                            if(this.displayCartDetail[i].Status == 'Active'){
                                this.cartDetailStatusActive = true;
                                console.log('cart Detail Status if Active' + this.cartDetailStatusActive);
                            }else{
                                this.cartDetailStatusActive = false;
                                console.log('cart Detail Status if Active' + this.cartDetailStatusActive);
                            }

                            if(this.displayCartDetail[i].Status == 'Inactive'){
                                this.cartDetailStatusInactive = true;
                                this.toastContainerObj.toastPosition = 'Top Center';
                                const toastEvent = new ShowToastEvent({
                                    title: 'InActive ModelID!',
                                    message: 'Model status is Inactive',
                                    variant: 'Error'
                                });
                                this.dispatchEvent(toastEvent);
                                return;
                            }else{
                                this.cartDetailStatusInactive = false;
                                console.log('cart Detail Status if InActive' + this.cartDetailStatusActive);
                            }

                            if(this.displayCartDetail[i].priceChanged == true){
                                this.toastContainerObj.toastPosition = 'Top Center';
                                const toastEvent = new ShowToastEvent({
                                    title: 'priceChanged',
                                    message: 'Price Changed in the model',
                                    variant: 'Info'
                                });
                                this.dispatchEvent(toastEvent);
                                return;
                            } 
                        }
                        totalAmount = totalAmount.toFixed(2);
                        totalAmount = Number(totalAmount).toLocaleString(undefined, {
                            minimumFractionDigits: 2
                        });
                        this.renderTotalAmmount = false;
                        this.renderTotalAmmount = true;
                        this.TotalOrderAmmount = totalAmount;
                        console.log('this.TotalOrderAmmount -->' + this.TotalOrderAmmount);
                        this.CurrencyIso = this.displayCartDetail[0].CurrencyIsoCode;
                        this.loaded = false;


                        if (this.cartValue != 0) 
                        {                    
                            this.showremarks = this.displayCartDetail[0].showremarks;
                            this.showPriceInOrder = this.displayCartDetail[0].ShowPriceInOrder;
                            this.cartProducts = true;
                            console.log('showPriceInOrder -->' + this.displayCartDetail[0].ShowPriceInOrder);
                            console.log('showremarks -->' + this.displayCartDetail[0].showremarks);

                          //  alert(this.displayCartDetail[0].variableDataProduct);
                            this.varprodct = this.displayCartDetail;
                            console.log('varprod >>>::'+JSON.stringify(this.varprodct));
                            var getparentwrapper = JSON.parse(JSON.stringify(this.varprodct));
            
                       getparentwrapper.forEach(element => {
                        if(element.variableDataProduct=='Yes'){
                            element.noVarProd = true;
                            console.log('element.noVarProd = true');
                        }else{
                            element.noVarProd = false;
                            console.log('element.noVarProd = false');
                        }

                    }); 
              
                    this.varprodct = getparentwrapper;
                    this.displayCartDetail = this.varprodct;
                    console.log('getparentwrapper after---'+JSON.stringify(this.displayCartDetail));

                    }
                }
                else {
                        if (this.cartValue === 0) {
                            this.hideButtons = true;
                        this.toastContainerObj.toastPosition = 'Top Center';
                        const event = new ShowToastEvent({
                            title: 'Warning',
                            message: 'No Product in Cart',
                            variant: 'Warning',
                        });
                        this.dispatchEvent(event);
                       
                        this.loaded = false;
                    }
                }
            }
            })
            .catch(error => {
                this.handleErrors(error);
            });
    }

    handleErrors(error) {
        console.error('Error: ', error);
        this.toastContainerObj.toastPosition = 'Top Center';
        const event = new ShowToastEvent({
            title: 'Error',
            message: 'An error occurred.',
            variant: 'error',
        });
        this.dispatchEvent(event);
    }

    toDeleteProductCart(index) {
        const CartDisplay = this.displayCartDetail;


        if (index >= 0 && index < CartDisplay.length) {
            const soliId = CartDisplay[index].Id;
            const soId = CartDisplay[index].SOid;


            deleteProductFromCart({soliId,soId})
                .then(result => {
                    console.log('deleteProductFromCart result:', JSON.stringify(result));


                    this.cartValue = result.length;
                    this.displayCartDetail = result;

                    if (this.cartValue === 0) {

                    }
                })
                .catch(error => {

                    this.handleErrors(error);
                });
        } else {
            console.error('Invalid index or item does not exist');

        }
    }


    handleDeleteProduct(event) {
       // alert('delete');
        this.date = event.target.value;
        let index = event.target.dataset.index;
        this.toDeleteProductCart(index);
        console.log('delete', index);
    }

    @track hideButtons = true;

    handleClearCart() {
        // alert('clear cart');
        this.hideButtons = false;

        ClearCartDetails()
            .then(result => {
                console.log('ClearCartDetails>>>>' + JSON.stringify(result));
                this.toastContainerObj.toastPosition = 'Top Center';
                const evt = new ShowToastEvent({
                    title: 'Success',
                    message: 'Cart Cleared Successfully',
                    variant: 'success',
                });
                this.dispatchEvent(evt);
                this.toGetcustomerData();
                //  return refreshApex(result); 
                localStorage.setItem('hideButtons', JSON.stringify(true));
                location.reload();
            })
            .catch(error => {
                this.toastContainerObj.toastPosition = 'Top Center';
                const toastEvent = new ShowToastEvent({
                    title: 'Error',
                    message: 'Contact System Admin',
                    variant: 'error',
                });
                this.dispatchEvent(toastEvent);
                console.error('Error message: ' + error.message);
            });
    }

   // @track displayCartDetail = [];
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

    handleUpdate() {
        var proName;
        var qtyval;
        for (let i = 0; i < this.newQtyArr.length; i++) {
            // console.log('this.newQtyArr[i].Qty'+this.newQtyArr[i].Qty);
            for (let k = 0; k < this.displayCartDetail.length; k++) {
                //  console.log('this.displayCartDetail[k].Quantity'+this.displayCartDetail[k].Quantity);
                if (this.displayCartDetail[k].Id === this.newQtyArr[i].id) {
                    this.displayCartDetail[k].Quantity = this.newQtyArr[i].Qty;
                    console.log('updated displayCartDetail' + JSON.stringify(this.displayCartDetail));
                } else {
                    console.log('No matching Id found in displayCartDetail.');
                }
            }
        }
        var temp = this.displayCartDetail;
        console.log('temp >>>>' + JSON.stringify(temp));
        for (let i = 0; i < temp.length; i++) {
            var newqty = temp[i].Quantity;
            // console.log('new Qty update--> '+newqty);
            var result = Math.ceil(temp[i].Quantity / temp[i].boxquantity) * temp[i].boxquantity;
            var boxqty = temp[i].boxquantity;
            var rem = ((newqty) % boxqty);
            if (newqty < temp[i].MOQ && temp[i].boxquantity && rem != 0 && temp[i].fullboxQty == true) {
                // console.log('inside MOQ and Box');
                result = Math.ceil(temp[i].MOQ / temp[i].boxquantity) * temp[i].boxquantity;
                if (confirm("Order Quantity for Mainetti Model Code") + temp[i].PSBP + ("is less then Minimum Order Quantity MOQ") + (temp[i].MOQ) + ("The nearest multiples of box quantity") + (result) + ("Click OK to confirm Order Quantity") + (result) + ("and add it in the CART")) {
                    temp[i].Quantity = result;
                    proName = temp[i].Name;
                    this.displayCartDetail = temp;
                    console.log('displayCartDetail inside if' + this.displayCartDetail);
                } else {
                    return;
                }
            } else if (newqty < temp[i].MOQ && temp[i].boxquantity && (temp[i].MOQ < temp[i].boxquantity || temp[i].MOQ % temp[i].boxquantity != 0) && temp[i].fullboxQty == true) {
                // console.log('inside else if MOQ and Box');
                result = Math.ceil(temp[i].MOQ / temp[i].boxquantity) * temp[i].boxquantity;
                if (confirm("Order Quantity for Mainetti Model Code") + temp[i].PSBP + ("is less then Minimum Order Quantity MOQ") + (temp[i].MOQ) + ("The nearest multiples of box quantity") + (result) + ("Click OK to confirm Order Quantity") + (result) + ("and add it in the CART")) {
                    temp[i].Quantity = result;
                    proName = temp[i].Name;
                    this.displayCartDetail = temp;
                    console.log('displayCartDetail inside if' + this.displayCartDetail);
                } else {
                    return;
                }
            } else if (newqty < temp[i].MOQ) {
                // console.log('inside else if newqty < temp[i].MOQ ');
                if (confirm(("Entered value for Mainetti Model Code") + temp[i].PSBP + ("is less then Minimum Order Quantity MOQ") + (temp[i].MOQ) + t("Click OK to confirm Order Quantity") + (temp[i].MOQ) + ("and add it in the CART"))) {
                    temp[i].Quantity = temp[i].MOQ;
                    proName = temp[i].Name;
                    this.displayCartDetail = temp;
                } else {
                    return;
                }
            }
            //only for box quantity 
            else if (temp[i].boxquantity) {
                //console.log('inside Box');
                // console.log('inside temp>>'+temp[i].boxquantity);
                var boxqty = temp[i].boxquantity;
                var rem = ((newqty) % boxqty);
                if (rem != 0 && temp[i].fullboxQty == true) {
                    // console.log('inside rem');
                    if (confirm(("Order Quantity for Mainetti Model Code") + temp[i].PSBP + ("is not the multiples of Box quantity") + ("The nearest multiples of box quantity") + (result) + ("Click OK to confirm Order Quantity") + (result) + ("and add it in the CART"))) {
                        temp[i].Quantity = result;
                        proName = temp[i].Name;
                        this.displayCartDetail = temp;
                    } else {
                        return;
                    }
                }
                if (!newqty || newqty <= 0) {
                    temp[i].Quantity = boxqty;
                }
            }
            if (!newqty || newqty <= 0) {
                qtyval = temp[i].Quantity;
            }
        }
        this.displayCartDetail = temp;
        if (qtyval || qtyval <= 0) {
            this.toastContainerObj.toastPosition = 'Top Center';
            const toastEvent = new ShowToastEvent({
                title: 'warning',
                message: 'Entered Product Quantity is not valid',
                variant: 'warning'
            });
            this.dispatchEvent(toastEvent);
            return;
        } else {

            this.displayCartDetail = temp;
            var CartDisplay = this.displayCartDetail;

            updateCartValue({
                    solilistjson: JSON.stringify(CartDisplay)
                })
                .then(result => {
                    console.log('updateCartValue result:', JSON.stringify(result));
                    this.toastContainerObj.toastPosition = 'Top Center';
                    const toastEvent = new ShowToastEvent({
                        title: 'Success',
                        message: 'Cart Updated Successfully',
                        variant: 'success',
                    });
                    this.dispatchEvent(toastEvent);
                    this.toGetcustomerData(); // After update, To Refresh the view calling toGetcustomerData
                })
                .catch(error => {
                    this.toastContainerObj.toastPosition = 'Top Center';
                    const toastEvent = new ShowToastEvent({
                        title: 'Error',
                        message: 'Contact System Admin',
                        variant: 'error',
                    });
                    this.dispatchEvent(toastEvent);
                    console.log('Error message: ' + error);
                });
        }

    }

    handlePlace() {
        //  alert('place order');
        var custid = this.displayCustDetail;
         console.log('displayCustDetail-->'+this.displayCustDetail);
         console.log('custid-->'+custid);
        checkLengthAddAndCloneDataToDelete({
                'customerid': custid
            })
            .then(result => {
                console.log('checkLengthAddAndCloneDataToDelete --> ' + JSON.stringify(result));
                this.cartValue = result.length;
                console.log('checkLengthAddAndCloneDataToDelete cart value --> '+result.length);
                if (result.length > 0) {
                    this.confirmdataSection = true;
                
                     console.log('confirmdata'+confirmdata);
                    if (confirmdata) {
                        console.log('inside confirmdata condition');
                        this.getAddress = false;
                        this.parentcmp = true;
                        this.shipcmp = false;
                        location. reload();
                        //eval("$A.get('e.force:refreshView').fire();");
                    } else {
                        console.log('inside else cond');
                        checkAddAndCloneDataToDelete({
                                customerid: this.displayCustDetail
                            })
                            .then(result => {
                                console.log('checkAddAndCloneDataToDelete--> ' + result);
                                this.calBoxQty();
                                // console.log('call calBoxQty');
                            })
                            .catch(error => {
                                this.error = error.message;
                                alert('error==>' + this.error);
                            })
                    }
                } else {
                    this.calBoxQty();
                }
            })

            .catch(error => {
                this.toastContainerObj.toastPosition = 'Top Center';
                const event = new ShowToastEvent({
                    title: 'ERROR OCCURED',
                    message: error.body.message,
                    variant: 'error'
                });
                this.dispatchEvent(event);
            })
    }


    calBoxQty() {
        // alert('callBoxQty');
        var proName;
        var qtyval;
        var temp = this.displayCartDetail;
        for (var i = 0; i < temp.length; i++) {
            //code to add the upper limit of box quantity by chandana 
            var result = Math.ceil(temp[i].Quantity / temp[i].boxquantity) * temp[i].boxquantity;
            var newqty = temp[i].Quantity;
            if (temp[i].boxquantity) {
                var boxqty = temp[i].boxquantity;
                var rem = ((newqty) % boxqty);
                if (rem != 0 && temp[i].fullboxQty == true) {
                    temp[i].Quantity = result;
                    proName = temp[i].Name;
                    break;
                } else if (!newqty || newqty <= 0) {
                    temp[i].Quantity = boxqty;
                }
            }
        }
        if (proName) {
            var temp = this.displayCartDetail;
            this.toastContainerObj.toastPosition = 'Top Center';
            const toastEvent = new ShowToastEvent({
                title: 'warning',
                message: 'One of the entered Quantity is not the multiple of box quantity Click Update Cart',
                variant: 'warning'
            });
            this.dispatchEvent(toastEvent);
            this.PlaceorderBtn = true;
            return;
        }
        if (qtyval) {
            this.toastContainerObj.toastPosition = 'Top Center';
            const toastEvent = new ShowToastEvent({
                title: 'warning',
                message: 'Entered Product Quantity is not valid',
                variant: 'warning'
            });
            this.dispatchEvent(toastEvent);
            return;
        } else {
            this.getAddress = true;
        }

    }
    @track Shipcmp = true;

    handleBackToCatalog() {
        // alert('Continue shopingg');
        this.parentcmp = true;
        this.Shipcmp = false;
        location. reload();
        // eval("$A.get('e.force:refreshView').fire();");
    }


    handleOkClick() {
        // alert('inside handleOk Click');
        this.getAddress = false;
        this.parentcmp = true;
        this.shipcmp = false;
        location. reload();
        // eval("$A.get('e.force:refreshView').fire();");
    }

    handleCancelClick() {
        var custid = this.displayCustDetail;
        checkLengthAddAndCloneDataToDelete({
                customerid: custid
            })
            .then(result => {
                console.log('checkLengthAddAndCloneDataToDelete result:', JSON.stringify(result));
                if (result.length > 0) {
                    checkAddAndCloneDataToDelete({
                            customerid: this.displayCustDetail
                        })
                        .then(result => {
                            console.log('checkAddAndCloneDataToDelete--> ' + result);
                            this.calBoxQty();
                        })
                        .catch(error => {
                            this.error = error.message;
                            alert('error==>' + this.error);
                        })
                } else {
                    this.calBoxQty();
                }
            })

            .catch(error => {
                this.toastContainerObj.toastPosition = 'Top Center';
                const event = new ShowToastEvent({
                    title: 'ERROR OCCURED',
                    message: error.body.message,
                    variant: 'error'
                });
                this.dispatchEvent(event);
            })
        this.confirmdataSection = false;
    }

    viewCareLabel(event){
        var viewInd = event.target.name;
        console.log('viewInd --> '+viewInd);

        var soliId = event.target.value;
        console.log('soliId --> '+soliId);

        var completeWrap = this.completeWrap;
        console.log('completeWrap --> '+JSON.stringify(completeWrap));

        console.log('display Cart Detail--> '+JSON.stringify(this.displayCartDetail));
        var prodId = this.displayCartDetail[viewInd].ProductId;

        console.log('prodId --> '+prodId);
        console.log('completeWrap.length --> '+completeWrap.productList.length);

        if(completeWrap.productList.length){
           // alert('inside if');
            for(var i=0;i<completeWrap.productList.length;i++){
               // alert('inside for');
                if(prodId == completeWrap.productList[i].Id){
                   // alert('inside if id');
                    this.quickViewedProduct = completeWrap.productList[i];
                    var selColor = completeWrap.productList[i].selectedColor;
                    console.log('selColor --> '+ JSON.stringify(selColor));
                    //alert(completeWrap.productList[i].tempMap[0].value.MOQ);
                    this.MOQ = completeWrap.productList[i].tempMap[0].value.MOQ;
                   // alert(JSON.stringify(this.MOQ));
                }
            }
            this.viewedIndex = viewInd;
            console.log("quickviewedProduct33::"+JSON.stringify(this.quickViewedProduct));
            console.log('careLabelSelectedDataList check json -->'+JSON.stringify(this.careLabelSelectedDataList));
            this.careLabelSelectedDataList ={exCareSelectedData:{},brandIcondata:{},sizeChartData:{},ChartData:{},countryOriginData:{},CareSelectedData:[],FabricSelectedData:[],freetextData:{} };
            console.log('careLabelSelectedDataList check json after -->'+JSON.stringify(this.careLabelSelectedDataList));
           
            this.careinstruction = [];
            this.careinstructionForView = [];
            this.finalViewedCarelabelData = {};
            this.deletedCLLIIdList = [];

           // alert('call getWrapperDataForView ');
            this.getWrapperDataForView(viewInd,prodId,soliId);
        
            const obj={closelogo:false};
            fireEvent(this.pageRef,"CloseLogoEvent",obj);
        }
    }


    handleLanguageChange(event){
        var selectedLangg = event.target.value;
        // alert('selectedLangg --> '+selectedLangg);
        this.viewedpicList = selectedLangg;
    }

    handleQuantity(event){
        var selQty = event.target.value;
        this.selectedQuanty = selQty;
    }

    handleUmo(event){
        this.selectedUmo = event.target.value;
    }
    

    getWrapperDataForView(viewInd,prodId,soliId){
        // alert('getWrapperDataForView called');

        console.log('retailerCode --> '+this.selectedRetailer);
        console.log('productname --> '+prodId);
        console.log('customerid --> '+this.displayCustDetail);

        getWrapperData({
            retailerCode:this.selectedRetailer,
            productname:prodId,
            customerid:this.displayCustDetail})

            .then(result=>{
                //  alert('result');
                console.log('getWrapperData result --> '+JSON.stringify(result));
                
                var mainwrapper =result;
                console.log('view wrapper -->'+JSON.stringify(mainwrapper));
                      this.itemMasterForView=mainwrapper.itemMaster;
                      console.log('itemMasterForView --->'+JSON.stringify(this.itemMasterForView));
                      this.picvalueForView = mainwrapper.LangCombList;
                      this.BrandlistForView=mainwrapper.BrandIcon;
                      this.sizelistForView =mainwrapper.sizechart;
                      console.log('sizelistForView --->'+JSON.stringify(this.sizelistForView));
                      this.lstcmpnameForView=mainwrapper.FabricComponent;
                      this.lstfabnameForView =mainwrapper.MaterialComponent;
                      this.lstcountrynameForView=mainwrapper.CountryofOrigin;
                      console.log('lstcountrynameForView --->'+JSON.stringify(this.lstcountrynameForView));
                    //   this.selectedcountryForView=mainwrapper.LangCountryList;
                    //   console.log('selectedcountryForView --->'+JSON.stringify(this.selectedcountryForView));
                      this.CareinstructionForView=mainwrapper.Careinstruction;
                      if( this.CareinstructionForView.length >0){
                        this.Careinstructionlength=true;
                       }
                      console.log('CareinstructionForView --->'+JSON.stringify(this.CareinstructionForView));
                      this.ExcareinstructionForView=mainwrapper.Excareinstruction;
                      console.log('ExcareinstructionForView --->'+JSON.stringify(this.ExcareinstructionForView));
                      this.CareLabelOrder = mainwrapper.careLabelSelectedDataList;

                      this.ExcarecmpnameForView =mainwrapper.ExcarePosition;
                      console.log('ExcarecmpnameForView --->'+JSON.stringify(this.ExcarecmpnameForView));

                      console.log('CareLabelOrder'+JSON.stringify(this.careLabelSelectedDataList[viewInd]));
                      this.viewedCarelabelData=this.careLabelSelectedDataList[viewInd];
                      console.log('viewedCarelabelData -->'+JSON.stringify(this.viewedCarelabelData));


                this.picvalue = mainwrapper.LangCombList;

                if(mainwrapper.careLabelSelectedDataList != null){

                    console.log("soliId>>"+soliId);
                    for(var i=0;i<mainwrapper.careLabelSelectedDataList.length;i++){
                        var selectedSoliId = mainwrapper.careLabelSelectedDataList[i].soliId;
                         console.log("selectedSoliId>>"+selectedSoliId+"<soliId>"+soliId);
                        if(soliId == selectedSoliId){
                            console.log("inside");
                            
                            this.viewedCarelabelData = mainwrapper.careLabelSelectedDataList[i];
                            this.careLabelSelectedDataList = mainwrapper.careLabelSelectedDataList[i];
                            break;
                        }
                    }
                }
                console.log('careLabelSelectedDataList check-->'+JSON.stringify(this.careLabelSelectedDataList));
                console.log('viewedCarelabelData exCareSelectedDataList-->'+JSON.stringify(this.viewedCarelabelData.exCareSelectedDataList));
                console.log('viewedCarelabelData countryOriginData-->'+JSON.stringify(this.careLabelSelectedDataList.countryOriginData.selectedcountry));
                console.log('viewedCarelabelData freetextData'+JSON.stringify(this.viewedCarelabelData.freetextData));
               
               
                this.viewCarelabelFlag = true;
                console.log('viewCarelabelFlag --> '+this.viewCarelabelFlag);
                this.careinstruction = mainwrapper.Careinstruction;
                console.log('careinstruction -->'+JSON.stringify(this.careinstruction));

                this.viewedpicList = this.viewedCarelabelData.selectedLang;
                this.selectedQuanty = this.viewedCarelabelData.quantity;
                this.uomOrder = this.displayCartDetail[viewInd].orderUom;

            })
            .catch(error=>{
                alert('ERROR OCCURED getWrapperData'+JSON.stringify(error));
            })
    }


    closeViewCareLabel() {
        this.viewCarelabelFlag = false;
    }

    newAddAndClone(){
        console.log("quickViewedProduct newAddAndClone::"+JSON.stringify(this.quickViewedProduct));
        this.saveAs =true;
        this.LatestSubmitViewedCareLabl();
    }

    SubmitViewedCareLabl(){
        this.saveAs=false;
        this.LatestSubmitViewedCareLabl();
    }

    @api
    LatestSubmitViewedCareLabl(){
        // var CareIns = this.viewedCarelabelData;
        // var CareIns = this.template.querySelectorAll('data-id');

        this.template.querySelector('c-care-label-order-brand-icon-lwc').viewSelectedBrand();
        this.template.querySelector('c-care-label-order-fabric-component-lwc').viewbindFabricData();
        this.template.querySelector('c-care-label-order-size-chart-lwc').viewselectedSize();           
        this.template.querySelector('c-care-label-country-component-lwc').viewFetchCountry();
        this.template.querySelector('c-care-label-care-instruction-component-lwc').viewbindSelectedData();
        this.template.querySelector('c-care-label-order-free-text-lwc').viewFreetextDatas();

        var itemMaster = this.itemMasterForView;
         console.log('itemMaster'+JSON.stringify(itemMaster));

            var tempViewedCarelabelData={};
            
            
           /* if(CareIns.length)
            {
                for(var i=0;i<CareIns.length;i++)
                {
                    var status=CareIns[i].viewSelectedData();
                    console.log('status'+JSON.stringify(status));
                    //tempViewedCarelabelData.status.WhichData=status.Data;
                }
            }
            else{
                var status=CareIns.viewSelectedData();
            }
        console.log('this.viewedCarelabelData>>'+JSON.stringify(this.viewedCarelabelData.sizeChartData)); */
        
        var viewedCarelabelData = this.viewedCarelabelData;
        console.log('viewedCarelabelData>>'+JSON.stringify(viewedCarelabelData.sizeChartData));
        var viewedIndex=0;
        var careLabelSelectedDataList = this.careLabelSelectedDataList;  
        console.log('LatestSubmitViewedCareLabl ::'+JSON.stringify(careLabelSelectedDataList));
        console.log('LatestSubmitViewedCareLabl  001::'+JSON.stringify(careLabelSelectedDataList.sizeChartData));
        var sizeChartDatas = careLabelSelectedDataList.sizeChartData;
        if( this.viewedpicList == ''){
            this.toastContainerObj.toastPosition = 'Top Center';
            const toastEvent = new ShowToastEvent({
                title: 'warning',
                message: 'Language is missing',
                variant: 'warning'
            });
            this.dispatchEvent(toastEvent);
            return;
        } else{
            viewedCarelabelData.selectedLang = this.viewedpicList;
        }
        if(!this.selectedQuanty || this.selectedQuanty <= 0){
            this.toastContainerObj.toastPosition = 'Top Center';
            const toastEvent = new ShowToastEvent({
                title: 'warning',
                message: 'Quantity is missing',
                variant: 'warning'
            });
            this.dispatchEvent(toastEvent);
            return;
        }else{
            //phase 2.1 MOQ enhansement on view/edit carelable 
            console.log('moq in edit >>'+this.MOQ);
            var result;
            if(this.selectedQuanty < this.MOQ && this.fullboxQty && this.viewedCarelabelData.boxquantity && this.selectedQuanty < this.viewedCarelabelData.boxquantity || (this.selectedQuanty % this.viewedCarelabelData.boxquantity) !=0){
                result = Math.ceil((this.selectedQuanty/this.viewedCarelabelData.boxquantity)*this.viewedCarelabelData.boxquantity);
                   if(confirm("Order Quantity for Product" + this.quickViewedProduct.Name + "is less then Minimum Order Quantity MOQ" + this.MOQ + "\n" + "The nearest multiples of box quantity" + (result) + "and add it in the CART")){
                    viewedCarelabelData.quantity = result;
                    this.selectedQuanty = viewedCarelabelData.quantity;
                    // this.selectedQuanty = result;
                   }
                   else{
                    return;
                   }
            }else if(this.selectedQuanty < this.MOQ && this.fullboxQty && this.viewedCarelabelData.boxquantity && this.MOQ < this.viewedCarelabelData.boxquantity || (this.MOQ % this.viewedCarelabelData.boxquantity) !=0){
                result = Math.ceil((this.MOQ/this.viewedCarelabelData.boxquantity)*this.viewedCarelabelData.boxquantity);
                if(confirm("Order Quantity for Product" + this.quickViewedProduct.Name + "is less then Minimum Order Quantity MOQ" + this.MOQ + "\n" + "The nearest multiples of box quantity" + (result) + "Click OK to confirm Order Quantity" + (result) + "and add it in the CART")){
                 viewedCarelabelData.quantity = result;
                 this.selectedQuanty = viewedCarelabelData.quantity;
                 // this.selectedQuanty = result;
                }
                else{
                 return;
                }
            }else if(this.selectedQuanty < this.MOQ){
                if(confirm("Order Quantity for Product" + this.quickViewedProduct.Name + "Click OK to confirm Order Quantity" + this.MOQ + "and add it in the CART")){
                viewedCarelabelData.quantity = this.MOQ;
                this.selectedQuanty = viewedCarelabelData.quantity;
                // this.selectedQuanty = result;
                }else{
                return;
                }
            }
            result = Math.ceil((this.selectedQuanty/this.viewedCarelabelData.boxquantity)*this.viewedCarelabelData.boxquantity);
           if(this.fullboxQty && this.viewedCarelabelData.boxquantity && this.selectedQuanty < this.viewedCarelabelData.boxquantity || (this.selectedQuanty % this.viewedCarelabelData.boxquantity) !=0){
            result = Math.ceil((this.selectedQuanty/this.viewedCarelabelData.boxquantity)*this.viewedCarelabelData.boxquantity);
            if(confirm("Order Quantity for Product" + this.quickViewedProduct.Name +"is less then Minimum Order Quantity MOQ" + "\n" + "The nearest multiples of box quantity" + (result) + "\n" +"Click OK to confirm Order Quantity" + (result) + "and add it in the CART")){
                viewedCarelabelData.quantity = result;
                this.selectedQuanty = viewedCarelabelData.quantity;
            }else{
                return;
            }
        }
        viewedCarelabelData.quantity = this.selectedQuanty;
    }
    if(viewedCarelabelData.brandIcondata){
        if(viewedCarelabelData.brandIcondata === '{}'){
            this.toastContainerObj.toastPosition = 'Top Center';
            const toastEvent = new ShowToastEvent({
                title: 'warning',
                message: 'Brand Icon is missing',
                variant: 'warning'
            });
            this.dispatchEvent(toastEvent);
            return;
        }
    }else if(itemMaster.Brand_Icon__c){
            viewedCarelabelData.brandIcondata=careLabelSelectedDataList.brandIcondata;
            
            console.log('viewedCarelabelData.brandIcondata --> '+JSON.stringify(viewedCarelabelData.brandIcondata));
        }
        if(viewedCarelabelData.FabricSelectedData){
            if(viewedCarelabelData.FabricSelectedData.length<1){
                this.toastContainerObj.toastPosition = 'Top Center';
                const toastEvent = new ShowToastEvent({
                    title: 'warning',
                    message: 'Fabric data is missing',
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
                    if(viewedCarelabelData.FabricSelectedData[i].Component)
                    {
                    if(!compCount[viewedCarelabelData.FabricSelectedData[i].Component])
                    compCount[viewedCarelabelData.FabricSelectedData[i].Component]=0;
                    compCount[viewedCarelabelData.FabricSelectedData[i].Component]+=viewedCarelabelData.FabricSelectedData[i].value;
                    }
                    if(!viewedCarelabelData.FabricSelectedData[i].Component)
                    {
                        total+=viewedCarelabelData.FabricSelectedData[i].value;
                        console.log('total --> '+total);
                    }
                }
                for(var key in compCount){
                    if(compCount[key]<100)
                    {
                        this.toastContainerObj.toastPosition = 'Top Center';
                        const toastEvent = new ShowToastEvent({
                            title: 'warning',
                            message: 'Component'+key+'has value lesser than 100 in Fabric',
                            variant: 'warning'
                        });
                        this.dispatchEvent(toastEvent);
                        return;
                    }
                }
                //for(var key in fabCount){
                if(total!=0 && (total<100 || total>100))
                {
                    this.toastContainerObj.toastPosition = 'Top Center';
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
            viewedCarelabelData.FabricSelectedData=careLabelSelectedDataList.FabricSelectedData;
            console.log('viewedCarelabelData.FabricSelectedData --> '+JSON.stringify(viewedCarelabelData.FabricSelectedData));
        }
        if(viewedCarelabelData.sizeChartData){
            if(viewedCarelabelData.sizeChartData==='{}'){
                this.toastContainerObj.toastPosition = 'Top Center';
                const toastEvent = new ShowToastEvent({
                    title: 'warning',
                    message: 'Size chart is missing',
                    variant: 'warning'
                });
                this.dispatchEvent(toastEvent);
                return;
            }
        }else if(itemMaster.Size_Chart__c){
            //alert("itemMaster.Size_Chart__c"+JSON.stringify(itemMaster.Size_Chart__c));
            viewedCarelabelData.sizeChartData=careLabelSelectedDataList.sizeChartData;
            console.log('viewedCarelabelData.sizeChartData --> '+JSON.stringify(viewedCarelabelData.sizeChartData));
        }            
        if(viewedCarelabelData.countryOriginData){
        if(viewedCarelabelData.countryOriginData.selectedcountry=='None'){
            this.toastContainerObj.toastPosition = 'Top Center';
            const toastEvent = new ShowToastEvent({
                title: 'warning',
                message: 'Country is missing',
                variant: 'warning'
            });
            this.dispatchEvent(toastEvent);
            return;
        }
        }else if(itemMaster.Country_Of_Origin__c){
            viewedCarelabelData.countryOriginData=careLabelSelectedDataList.countryOriginData;
            console.log('viewedCarelabelData.countryOriginData --> '+JSON.stringify(viewedCarelabelData.countryOriginData));
        }
        if(viewedCarelabelData.CareSelectedData){
            if(viewedCarelabelData.CareSelectedData.length<1){
                this.toastContainerObj.toastPosition = 'Top Center';
                const toastEvent = new ShowToastEvent({
                    title: 'warning',
                    message: 'Care instructions is missing',
                    variant: 'warning'
                });
                this.dispatchEvent(toastEvent);
                return;
            }
            var Careinstruction = this.careinstructionForView;
            if(Careinstruction == null)
            {
                this.toastContainerObj.toastPosition = 'Top Center';
                const toastEvent = new ShowToastEvent({
                    title: 'warning',
                    message: 'All the Care instructions have not been selected',
                    variant: 'warning'
                });
                this.dispatchEvent(toastEvent);
                return;
            }
        }
        else if(this.careinstructionForView.length >0){
            viewedCarelabelData.CareSelectedData=careLabelSelectedDataList[viewedIndex].CareSelectedData;
            console.log("viewedCarelabelData.CareSelectedData>>>>"+JSON.stringify( viewedCarelabelData.CareSelectedData));
        }
        if(itemMaster.Excare_Instruction__c)
        {
            if(viewedCarelabelData.exCareSelectedDataList)
            {
                if(viewedCarelabelData.exCareSelectedDataList.length==0)
                {
                    this.toastContainerObj.toastPosition = 'Top Center';
                    const toastEvent = new ShowToastEvent({
                        title: 'warning',
                        message: 'Excare instructions is missing',
                        variant: 'warning'
                    });
                    this.dispatchEvent(toastEvent);
                    return;
                }else{

                }
            } 
            else{
                    viewedCarelabelData.exCareSelectedDataList=careLabelSelectedDataList[viewedIndex].exCareSelectedDataList;
                    console.log('viewedCarelabelData.exCareSelectedDataList --> '+JSON.stringify(viewedCarelabelData.exCareSelectedDataList));
            }
        }  console.log(JSON.stringify(viewedCarelabelData.freetextData));
        if(viewedCarelabelData.freetextData)
        {
            if(JSON.stringify(viewedCarelabelData.freetextData)=='{}' ){
                this.toastContainerObj.toastPosition = 'Top Center';
                const toastEvent = new ShowToastEvent({
                    title: 'warning',
                    message: 'Free Text is missing',
                    variant: 'warning'
                });
                this.dispatchEvent(toastEvent);
                return;
            }
            if((itemMaster.Style_Number__c && !viewedCarelabelData.freetextData.StyleNumber)){
                this.toastContainerObj.toastPosition = 'Top Center';
                    const toastEvent = new ShowToastEvent({
                        title: 'warning',
                        message: 'Style Number is missing',
                        variant: 'warning'
                    });
                    this.dispatchEvent(toastEvent);
                    return;
                }
            if((itemMaster.RN_Number__c && !viewedCarelabelData.freetextData.RNNumber)){
                this.toastContainerObj.toastPosition = 'Top Center';
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
                this.toastContainerObj.toastPosition = 'Top Center';
                const toastEvent = new ShowToastEvent({
                    title: 'warning',
                    message: 'Lot Number is missing',
                    variant: 'warning'
                });
                this.dispatchEvent(toastEvent);
                return;
            }
            if((itemMaster.Supplier_Number__c && !viewedCarelabelData.freetextData.SupplierNumber)){
                this.toastContainerObj.toastPosition = 'Top Center';
                const toastEvent = new ShowToastEvent({
                    title: 'warning',
                    message: 'Supplier Number is missing',
                    variant: 'warning'
                });
                this.dispatchEvent(toastEvent);
                return;
            }
            if((itemMaster.Labelling_Code__c && !viewedCarelabelData.freetextData.LabellingCode)){
                this.toastContainerObj.toastPosition = 'Top Center';
                const toastEvent = new ShowToastEvent({
                    title: 'warning',
                    message: 'Labelling Code is missing',
                    variant: 'warning'
                });
                this.dispatchEvent(toastEvent);
                return;
            }if((itemMaster.Packaging_Code__c && !viewedCarelabelData.freetextData.PackagingCode)){
                this.toastContainerObj.toastPosition = 'Top Center';
                const toastEvent = new ShowToastEvent({
                    title: 'warning',
                    message: 'Packing Code is missing',
                    variant: 'warning'
                });
                this.dispatchEvent(toastEvent);
                return;
            }
            if((itemMaster.Season_Month__c && !viewedCarelabelData.freetextData.SeasonMonth)){
                this.toastContainerObj.toastPosition = 'Top Center';
                const toastEvent = new ShowToastEvent({
                    title: 'warning',
                    message: 'Season Month is missing',
                    variant: 'warning'
                });
                this.dispatchEvent(toastEvent);
                return;
            }
            if((itemMaster.Season_Year__c && !viewedCarelabelData.freetextData.SeasonYear)){
                this.toastContainerObj.toastPosition = 'Top Center';
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
        this.toastContainerObj.toastPosition = 'Top Center';
        const toastEvent = new ShowToastEvent({
            title: 'warning',
            message: 'Item Number is missing',
            variant: 'warning'
        });
        this.dispatchEvent(toastEvent);
        return;
        }  
        if((itemMaster.Care_Instruction__c && !viewedCarelabelData.freetextData.careinstruct)){
            const toastEvent = new ShowToastEvent({
                title: 'warning',
                message: 'Care_Instruction is missing',
                variant: 'warning'
            });
            this.dispatchEvent(toastEvent);
            return;
        }
    } 
    else if(careLabelSelectedDataList[viewedIndex].freetextData)
    {
        viewedCarelabelData.freetextData=careLabelSelectedDataList[viewedIndex].freetextData;
        //viewedCarelabelData.freetextData.careinstruct = careLabelSelectedDataList[viewedIndex].freetextData.careinstruct;
        //alert("viewedCarelabelData.freetextData.careinstruct>>"+viewedCarelabelData.freetextData.careinstruct);
    }
    //alert("viewedCarelabelData.freetextData.careinstruct>>"+viewedCarelabelData.freetextData.careinstruct);
    viewedCarelabelData.Priceper100pc = careLabelSelectedDataList.Priceper100pc;
    viewedCarelabelData.boxquantity = careLabelSelectedDataList.boxquantity;
    viewedCarelabelData.color = careLabelSelectedDataList.color;
    viewedCarelabelData.custRefModel = careLabelSelectedDataList.custRefModel;
    viewedCarelabelData.fullboxquantity = careLabelSelectedDataList.fullboxquantity;
    viewedCarelabelData.imgUrl = careLabelSelectedDataList.brandIcondata.Image__c;
    // viewedCarelabelData.localSKU = careLabelSelectedDataList.localSKU;
    viewedCarelabelData.priceSpecId = careLabelSelectedDataList.priceSpecId;
    viewedCarelabelData.printShop = careLabelSelectedDataList.printShop;
    viewedCarelabelData.produDesc = careLabelSelectedDataList.produDesc;
    viewedCarelabelData.productFamily = careLabelSelectedDataList.productFamily;
    viewedCarelabelData.productName = careLabelSelectedDataList.productName;
    viewedCarelabelData.soId = careLabelSelectedDataList.soId;
    viewedCarelabelData.soliId = careLabelSelectedDataList.soliId;
    console.log(viewedCarelabelData);

    var viewedIndex = this.viewedIndex;
    console.log('Parseandstringify(this.careLabelSelectedDataList)--> '+JSON.parse(JSON.stringify(this.careLabelSelectedDataList)));
    var careLabelSelectedDataList = JSON.parse(JSON.stringify(this.careLabelSelectedDataList));
    for(var i=0;i<careLabelSelectedDataList.length && i!=viewedIndex;i++)
    {  
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
            else
                fabMached=false;
        }
        var careInstMatch=true;
        if(this.careinstruction.length > 0){
            
             
            if(viewedCarelabelData.CareSelectedData.length==careLabelSelectedDataList[i].CareSelectedData.length)
            {
                var tempCareInstr=careLabelSelectedDataList[i].CareSelectedData;
                for(var j=0;j<tempCareInstr.length;j++)
                {
                    var careIdList=tempCareInstr[j]['careIdList'];
                    //alert('Bef>'+JSON.stringify(tempCareInstr));
                    //delete tempCareInstr[j]['careIdList'];
                    var matched1=false;
                    for(var k=0;k<viewedCarelabelData.CareSelectedData.length;k++)
                    {
                        //if(tempCareInstr[j].instGrp==viewedCarelabelData.CareSelectedData[k].instGrp)
                        //delete viewedCarelabelData.CareSelectedData[k]['careIdList'];
                        if(JSON.stringify(viewedCarelabelData.CareSelectedData[k])===JSON.stringify(tempCareInstr[j]))
                        {
                            matched1=true;
                        }
                    }
                    //tempCareInstr[j]['careIdList']=careIdList;
                    //alert('aft>'+JSON.stringify(tempCareInstr));
                    if(!matched1)
                    {
                        careInstMatch=false;
                        break;
                    }
                }
            }
            else
                careInstMatch=false;
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
                            //alert(JSON.stringify(viewedCarelabelData.exCareSelectedDataList[k]));
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
                else
                    exMatched=false;
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
                var saveAs = this.saveAs;
                    //alert("12>>"+itemMaster.Size_Chart__c);
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
                countryOfOriginPresent ){
                // const toastEvent = new ShowToastEvent({
                //     title: 'warning',
                //     message: 'Data Already Present',
                //     variant: 'warning'
                // });
                // this.dispatchEvent(toastEvent);
                // return;

                this.showToastMessage = 'Data Already Present';
                this.showWarningToastMessage = true;
                setTimeout(() => {
                    this.showWarningToastMessage = false;
                }, 3000);
            }
        }
        console.log('careLabelSelectedDataList>>'+JSON.stringify(viewedCarelabelData));
            careLabelSelectedDataList[viewedIndex] = viewedCarelabelData;
            careLabelSelectedDataList[viewedIndex].selectedLang = this.viewedpicList;
            careLabelSelectedDataList[viewedIndex].quantity = this.selectedQuanty
            careLabelSelectedDataList[viewedIndex].sizeChartData = sizeChartDatas;
            console.log('controller Before set::'+JSON.stringify(this.careLabelSelectedDataList[viewedIndex]));
            this.careLabelSelectedDataList = careLabelSelectedDataList[viewedIndex];
            console.log('controller After set::'+JSON.stringify(this.careLabelSelectedDataList));
            this.viewCarelabelFlag = false;
            this.saveCareData('Cart');
    }

    saveCareData(addTo){
        // alert('inside saveCareData ');
        var viewInd = this.viewedIndex;
        var saveOrSaveAs = this.saveAs;
        //To call a perticular method based on user selected option
        if(saveOrSaveAs){
            //on SaveAs button click saveAsCareLabelDat method will get called
            saveAsCareLabelData({"careLabelSelectedDataList":`[${JSON.stringify(this.careLabelSelectedDataList)}]`,
            "productId":this.displayCartDetail[viewInd].ProductId,
            "retailerId": this.selectedRetailer, 
            "completeWrap": JSON.stringify(this.quickViewedProduct),
            "customeid":this.displayCustDetail,
            "addTo": addTo,
            "selectedCurrency":this.selectedCurrency,
            "searchedCurrency":this.searchedCurrency,}) 
            .then(result =>{
                var resp = result;
                if(addTo=='Cart')
                {
                    console.log(JSON.stringify(this.deletedCLLIIdList));
                    
                    if(this.deletedCLLIIdList.length>0){
                        this.deleteCarelabelData();
                    }
                    else{
                        this.getExistingLabelData();
                    }
                    var message;
                    if(saveOrSaveAs){
                        message = "Successfully Updated In Cart";
                    }
                    this.toastContainerObj.toastPosition = 'Top Center';
                    const toastEvent = new ShowToastEvent({
                        title: 'success',
                        message: message,
                        variant: 'success'
                    });
                    this.dispatchEvent(toastEvent);
                    this.toGetcustomerData();
                    return;
                }
            })
            .catch(error=>{
              alert('ERROR OCCURED.'+JSON.stringify(error.body.message));
            })
        }else{
            ////on Save button click saveCareLabeldat method will get called
        //   alert('inside else saveCareData ');
          console.log('checkkkkk--->>> '+`[${JSON.stringify(this.careLabelSelectedDataList)}]`);

            saveCareLabelData({"careLabelSelectedDataList":`[${JSON.stringify(this.careLabelSelectedDataList)}]`,
            "productId":this.displayCartDetail[viewInd].ProductId,
            "retailerId": this.selectedRetailer, 
            "completeWrap": JSON.stringify(this.quickViewedProduct),
            "customeid":this.displayCustDetail,
            "addTo": addTo,
            "selectedCurrency":this.selectedCurrency,
            "searchedCurrency":this.searchedCurrency,}) 
            .then(result =>{
                console.log('result ==>>>> '+JSON.stringify(result));
                var resp = result;
                if(addTo=='Cart')
                {
                    console.log(JSON.stringify(this.deletedCLLIIdList));
                    
                    if(this.deletedCLLIIdList.length>0){
                        this.deleteCarelabelData();
                    }
                    else{
                        this.getExistingLabelData();
                    }
                    var message;
                    if(saveOrSaveAs){
                        message = "Successfully Updated In Cart";
                    }else{
                        message = "Successfully Saved In Cart";
                    }
                    this.toastContainerObj.toastPosition = 'Top Center';
                    const toastEvent = new ShowToastEvent({
                        title: 'success',
                        message: message,
                        variant: 'success'
                    });
                    this.dispatchEvent(toastEvent);
                    this.toGetcustomerData();
                    return;
                }
            })
            .catch(error=>{
              alert('ERROR OCCURED.'+JSON.stringify(error.body.message));
              console.log('ERROR OCCURED.'+JSON.stringify(error.body.message));
            })
        }
    }

    deleteCarelabelData(){
        deletedCLLI({"deletedCLLIList":this.deletedCLLIIdList})
        .then(rest=>{
            this.getExistingLabelData();
        })
        .catch(errr=>{
            alert('ERROR OCCURED111.'+JSON.stringify(errr.body.message));
        })
    }

    getExistingLabelData(){
        fetchCareLabelData({"retailerId": this.selectedRetailer,
        "customeid": this.displayCustDetail})
        .then(result=>{
            var returnValue = result;
            console.log('returnValue'+JSON.stringify(returnValue));
            this.careLabelSelectedDataList = returnValue;
        })
        .catch(error=>{
            alert('ERROR OCCURED.'+JSON.stringify(error.body.message));
        })
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
    
    this.careLabelSelectedDataList.countryOriginData = event.detail.viewselectedcountry;
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
    this.finalviewedCarelabelData.freetextData=event.detail.viewFreetextData;
}


    get Care_Label_View_Edit() {
        return Care_Label_View_Edit;
    }
    get careInstructionLength(){
        return careinstruction.length>0;
    }
    @track cartDetails = [{
        Id: '1'
    }];

}