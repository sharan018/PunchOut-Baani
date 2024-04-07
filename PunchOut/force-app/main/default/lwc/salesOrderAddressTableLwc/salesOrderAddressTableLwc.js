import { LightningElement ,api,track,wire} from 'lwc';
import {CurrentPageReference} from 'lightning/navigation';
import {fireEvent} from 'c/pubsub';

export default class SalesOrderAddressTableLwc extends LightningElement {
    @api addressList;
    @api addressType;
    @api addressIndex;

    closeModal() {
        this.CSSToAddAddress = false;
        location. reload();
        // eval("$A.get('e.force:refreshView').fire();");
    }

    @wire(CurrentPageReference) pageRef;
    
    changeAddress(event, index) {
        var selectedValue = event.target.checked;
        var index = event.target.name;
        console.log("selectedValue-->"+selectedValue);
        this.addressList = this.addressList.map((address, i) => {
            if (i === index) {
                // If it's the clicked checkbox, update Is_Default__c
                return { ...address, Is_Default__c: selectedValue };
            } if(i != index) {
                // If it's not the clicked checkbox, uncheck Is_Default__c
                return { ...address, Is_Default__c: false };
            }
        });

        if (selectedValue) {
            var index = event.target.name;
            var checkVal = selectedValue;
            console.log('index name : '+index);
            console.log('index val : '+checkVal);
            // Firing an event to pass the index to the new selected address
            var addressType = this.addressType;
            // var compEvent = new CustomEvent("shippingvalue", {
            //     detail: {
            //         checkShippAddress:selectedValue
            //     }
            // });
            // this.dispatchEvent(compEvent);
            const obj={recordByEvent:index,
                       objectAPIName: index,
                       context: addressType,
                       checkShippAddress:selectedValue
                       };
            fireEvent(this.pageRef,"onaddressSelect",obj);
            console.log('fire event obj-->'+JSON.stringify(obj));
            }   
        }
}