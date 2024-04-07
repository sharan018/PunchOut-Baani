import { LightningElement,api,track} from 'lwc';
// import html2canvas from 'html2canvas';
import labelSize from '@salesforce/label/c.Size';
import labelBelowInformation from '@salesforce/label/c.Below_Information';
import labelBelowInformation02 from '@salesforce/label/c.Below_Information_02';
import FABRIC from '@salesforce/label/c.FABRIC';
import COUNTRY_OF_ORIGIN from '@salesforce/label/c.COUNTRY_OF_ORIGIN';
import EXCARE_INSTRUCTIONS from '@salesforce/label/c.EXCARE_INSTRUCTIONS';
import CARE_INSTRUCTION_DETAILS from '@salesforce/label/c.CARE_INSTRUCTION_DETAILS';
import FREE_TEXT from '@salesforce/label/c.FREE_TEXT';
import RN_Number from '@salesforce/label/c.RN_Number';
import Style_Number from '@salesforce/label/c.Style_Number';
import Lot_Number from '@salesforce/label/c.Lot_Number';
import Supplier_Number from '@salesforce/label/c.Supplier_Number';
import Labelling_Code from '@salesforce/label/c.Labelling_Code';
import Packaging_Code from '@salesforce/label/c.Packaging_Code';
import Season_Month from '@salesforce/label/c.Season_Month';
import Season_Year from '@salesforce/label/c.Season_Year';
import Item_Number from '@salesforce/label/c.Item_Number';
import Careinstructions from '@salesforce/label/c.Careinstructions';
import Close from '@salesforce/label/c.Close';
import Logo_View from '@salesforce/label/c.Logo_View';


export default class LogoGeneratorLwc extends LightningElement {
    @track size = 'Yellow-casual-shoes';
    @api code = 'Y-shoes';
    @api des = 'Use Shoe bags to prevent any stains or mildew';
    @api FontName = 'calibri';
    @api Fsize = 18;
    @api align ;
    @track align = 'center';

    @track FWidth = 'normal'; // Use 'bold' or other font-weight values as needed
    @track Left1 = 0;
    @track Top1 = 0;

    @api img;
    @api selectedFabricArray;
    @track ShowLogo = false;
    @api ShowLogo;
    @api selectedInstImage =[];
    @api selectedInstImageClone =[];
    @track selectedInstImageClone =[];
    @api exCareIns;
    @api freeText;
    @api freeTextclone;

    html2canvasLibrary = '/resource/html2canvas'; 

    @api ImgHeight = 100;
    @api ImgWidth = 100;
    @api FWidth = 300;
    @api Logo;

    @api Temp = 'Top';
    @api Top;
    @api Left;
    @api Top1;
    @track Left = 0;
    @track Top = 0;
    @api Left1;
    @api ImgDev ;
    @track ImgDev= true;
    @api Dev; 
    @track Dev= false;

    @api devSize;
    @api devFabric;
    @api devCountry;
    @api devCare=false;
    @track devCare= false;
    @api devCareclone ;
    @track devCareclone= false;
    @api devExcare;
    @api devFree;
    @track devFree = false;
    @api devFreeclone;
    @track devFreeclone = false;
    @api devlogo;
    @api devViewEdit;
    @track devViewEdit = false;
    @track devSize = false;
    @track devlogo = false;
    @track devCountry = false;
    @track devFabric = false;
    @track devExcare = false;
    @track devFreeclone = false;
    @track img;
    @track country;
    @track selectedFabricArray;
    @track selectedInstImage = [];
    @track exCareIns;
   /* @track freeText = {
        StyleNumber: '',
        RNNumber: '',
        LotNumber: '',
        careinstruct: '',
        SupplierNumber: '',
        LabellingCode: '',
        PackagingCode: '',
        SeasonMonth: '',
        SeasonYear: '',
        ItemNumber: '',
    };*/
@track Fsize = this.size;
 @api logo;
@api SelectedImage;
@api size;
@api country;


connectedCallback() {
    alert('this.freeText--> '+this.freeText);
    console.log('selectedInstImage >>'+JSON.stringify(this.selectedInstImage));
    this.processDevViewEdit();
}
    get labelSize(){
        return labelSize;
    }
    get computedStyles() {
        let styles = 'border: 1px solid grey; background-color: white; width: 700px;';
        // Add dynamic styles based on property values
        styles += `text-align: ${this.align};`;
        return styles;
    }
    get computedStyle() {
        return `font-family: ${this.FontName}; font-size: ${this.Fsize}px; font-weight: ${this.FWidth}; position: relative; left: ${this.Left1}px; top: ${this.Top1}px;`;
    }
   
    get labelBelowInformation(){
        return labelBelowInformation;
    }
    get labelBelowInformation02(){
        return labelBelowInformation02;
    }
    get FABRIC(){
        return FABRIC;
    }
    get COUNTRY_OF_ORIGIN(){
        return COUNTRY_OF_ORIGIN;
    }
    get CARE_INSTRUCTION_DETAILS(){
        return CARE_INSTRUCTION_DETAILS;
    }
    get FREE_TEXT(){
        return FREE_TEXT;
    }
    get EXCARE_INSTRUCTIONS(){
        return EXCARE_INSTRUCTIONS;
    }
    get Style_Number(){
        return Style_Number;
    }
    get RN_Number(){
        return RN_Number;
    }
    get Lot_Number(){
        return Lot_Number;
    }
    get Supplier_Number(){
        return Supplier_Number;
    }
    get Labelling_Code(){
        return Labelling_Code;
    }
    get Packaging_Code(){
        return Packaging_Code;
    }
    get Season_Month(){
        return Season_Month;
    }
    get Season_Year(){
        return Season_Year;
    }
    get Item_Number(){
        return Item_Number;
    }
    get Careinstructions(){
        return Careinstructions;
    }
    get Close(){
        return Close;
    }
    get Logo_View(){
        return Logo_View;
    }
    


    processDevViewEdit(){
        this.devViewEdit=true;
        if (this.devViewEdit) {
            if (this.size !== 'Yellow-casual-shoes') {
                this.devSize = true;
            }
            if (this.img!=undefined) {
                alert('img '+this.img);
                this.devlogo = true;
            }
            if (this.country!=undefined ) {
                this.devCountry = true;
            }
            if (this.selectedFabricArray != undefined) {
                alert('inside selectedFabricArray');
                this.devFabric = true;
                console.log('DevFabric --> '+this.devFabric);
                console.log(this.selectedFabricArray);
                console.log(JSON.stringify(this.selectedFabricArray));
            }
            if (this.selectedInstImage !=undefined) {
                var ImageList=[];
                this.selectedInstImage.forEach((item) => {
                   ImageList.push({
                        group: item.instGrp,
                        instr: item.instDetails,
                        descr: item.instDetails
                    });
                });
                this.selectedInstImageClone=ImageList;
                this.devCareclone = true;
            }
            if (this.exCareIns != undefined) {
                this.devExcare = true;
            }
            if (this.freeText != null) {
                console.log('this.freeText--> '+JSON.stringify(this.freeText));
                const freeTextTemp = [];
                const item = {
                    StyleNumber: this.freeText.StyleNumber,
                    RNNumber: this.freeText.RNNumber,
                    LotNumber: this.freeText.LotNumber,
                    careinstruct: this.freeText.careinstruct,
                    SupplierNumber: this.freeText.SupplierNumber,
                    LabellingCode: this.freeText.LabellingCode,
                    PackagingCode: this.freeText.PackagingCode,
                    SeasonMonth: this.freeText.SeasonMonth,
                    SeasonYear: this.freeText.SeasonYear,
                    ItemNumber: this.freeText.ItemNumber,
                };
                freeTextTemp.push(item);
                console.log('freeTextTemp --> '+JSON.stringify(freeTextTemp));
                this.freeTextclone = freeTextTemp;
                this.devFreeclone = true;
                // this.devFree=true;
            }
        }
    }
    
closeModel() {
    this.ShowLogo = false;
}
handleTempChange(event) {
    const x = event.target.value;
    if (x === '1') {
        this.ImgDev = true;
        this.Dev = false;
    } else {
        this.ImgDev = false;
        this.Dev = true;
    }
}

}