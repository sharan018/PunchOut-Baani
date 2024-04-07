public class PunchOutCatalogOrderController {

    public Static Id CartRecordType = Schema.SObjectType.Base_Order__c.getRecordTypeInfosByName().get('Cart').getRecordTypeId();
    public Static Id OrderRecordType = Schema.SObjectType.Base_Order__c.getRecordTypeInfosByName().get('Order').getRecordTypeId();
    
      @AuraEnabled
    public static string addSizerToCart(String retailercode,String customerid)
    {
        String prodName = '';
        List<Base_Order_Detail__c> sizrList=getSizerList(retailercode,customerid,prodName);
        System.debug('sizrList.size()>>'+sizrList.size());
        if(sizrList.size()>0)
        {
            for(Base_Order_Detail__c sizer:sizrList)
            {
                sizer.Added_As_a_Label__c=false;
            }
            update sizrList;
        }
        return 'SUCCESS';
    }
    @AuraEnabled
    public static List<Base_Order_Detail__c> getSizerList(String  retailercode,String customerid, String prodName)
    {
       Id panoutId = PunchOutRequestController.getPunchoutRequestId();
        system.debug('retailercode>>>'+retailercode);
        system.debug('customerid>>>'+customerid);
        return [select id,name,Colour__c,Quantity__c,Size__c,Print__c,base_Order__c,Price_Specification_Book_Product__r.id,Customer_Ref_Model__c,Mainetti_Model_Code__c,Added_As_a_Label__c,BOX_QTY__c,Full_Box_Order__c,Business_Vertical__c from Base_Order_Detail__c where Base_Order__r.Retailer_Code1__c=:retailerCode AND Base_Order__r.Supplier__c=:customerid and Added_As_a_Label__c=true And Base_Order__r.PunchOut_Request__c=:panoutId];//And Products__r.Mainetti_Model__c=:prodName
    }
    
     @AuraEnabled
    public static string addSizerProduct(String obj,string addTo,string selectedCurrency,String searchedCurrency)
    {
        CatalogOrderController.SizerAddToCartWrap sizerCartDataToSaveDes =(CatalogOrderController.SizerAddToCartWrap)JSON.deserialize(obj , CatalogOrderController.SizerAddToCartWrap.class);
        system.debug('sizerCartDataToSaveDes>>'+sizerCartDataToSaveDes);
        addTo='';
        String res = PunchOutCatalogOrderController.saveSizerCart(sizerCartDataToSaveDes,addTo,selectedCurrency,searchedCurrency);
        return res;
    }
     public static Id saveSizerCart(CatalogOrderController.SizerAddToCartWrap sizerCartDataToSaveDes,String addTo,String selectedCurrency,String searchedCurrency)
    {
        //List<Retailer_Related_Data__c> ContRetailer = new List<Retailer_Related_Data__c>();
        //ContRetailer = [select id,Name,Supplier_Code__c,Customer_Information__c,Customer_Information__r.MagNET_Price_Code__c,Retailer_Code__c, Manufacturer_Factory_Code__c from Retailer_Related_Data__c where Customer_Information__c =:sizerCartDataToSaveDes.customeid AND Retailer_Code__c =:sizerCartDataToSaveDes.retailerCodeId AND Status__c='Active'];
        //system.debug('ContRetailer::'+ContRetailer);
        system.debug('sizerCartDataToSaveDes.customeid::'+sizerCartDataToSaveDes.customeid);
        system.debug('<<>>sizerCartDataToSaveDes>>'+sizerCartDataToSaveDes);
        system.debug('sizerCartDataToSaveDes::'+sizerCartDataToSaveDes.quantity);
        //select id,Name,Supplier_Code__c,Customer_Information__c from Retailer_Related_Data__c where Customer_Information__c='a10p0000002C8J9'
        //contact Retailercon = [Select id,name, Status__c, accountId, RetailerCode__c, Account_Record_Type_Id__c, Order_to_Company__c, Order_to_Company1__c, Preferred_Currency__c, Preferred_Currency1__c, Supplier_Code__c, Manufacturer_Code__c, Email, Customer_Information__c from Contact where RetailerCode__c =: retailercode];
        //system.debug('Retailercon>>'+Retailercon);
        
        Price_Specification_Book_Product__c prodData =new Price_Specification_Book_Product__c();
        Price_Product_by_Currency__c priceproductbycurrency;
        
        prodData =[select id,Product_Unique_ID__c,CurrencyIsoCode,Product_Unique_ID__r.Business_Vertical__c, Local_SKU__c,Color__c,Retailer_Code__c,Retailer_Code__r.Full_Box_Order__c,BOX_QTY__c,Description__c,Price_100pcs__c,Price_1000pcs__c,Product_image_url__c,Product_Size__c,Order_to_Company__c,Print_Shop__c,Product_Family__c,Customer_Ref_Model__c ,EUR_Rebate_pc__c,Sizer_Print__c,EUR_Reuse_Rebate_pc__c,USD_Rebate_pc__c,USD_Reuse_Rebate_pc__c,Variable_Data_Product__c from Price_Specification_Book_Product__c where id =:sizerCartDataToSaveDes.pricebookId];
        // system.debug('prodData>>>>'+prodData);
        if(sizerCartDataToSaveDes.pricebycur!=null){
            priceproductbycurrency = [select id,Name,CurrencyIsoCode,Price_Book_Product__c,Local_ERP_customer_code__c,Price_100_pcs__c,MagNET_Price_Code__c from Price_Product_by_Currency__c where id =:sizerCartDataToSaveDes.pricebycur];
             system.debug('priceproductbycurrency>>>>'+priceproductbycurrency);
        }
        List<Base_Order__c> SOList=new List<Base_Order__c>();
        List<Base_Order_Detail__c> SoliList=new List<Base_Order_Detail__c>();
        SOList =[select id, name, Retailer_Code1__c,Product__r.Business_Vertical__c,Status__c,CurrencyIsoCode,Supplier_Code__c,Enquiry_Status__c,Link_To_ERP__c from Base_Order__c where Supplier__c =:sizerCartDataToSaveDes.customeid AND recordtypeId =:CartRecordType ];
        // system.debug('SOList>>'+SOList);
        //system.debug('SOList.size>>'+SOList.size());
        
        //to get label value of the API name of picklist
        Schema.DescribeFieldResult companyResult = Online_Enquiry__c.Order_Country__c.getDescribe();
        List<Schema.PicklistEntry> companyvalues = companyResult.getPicklistValues();
        for( Schema.PicklistEntry comp : companyvalues) 
        {
            System.debug('comp PicklistEntry name '+comp.getLabel()+' API name '+comp.getValue()+' '+prodData.Order_to_Company__c);
            if(comp.getValue() == prodData.Order_to_Company__c)
            {
                prodData.Order_to_Company__c = comp.getLabel();
                break;
            }
        }
        
        Contact loggedInContact = FetchCustData();
        Contact con = CatalogOrderController.getcostomerinfo(sizerCartDataToSaveDes.retailerCodeId);
        // system.debug('searchedCurrency>>'+ searchedCurrency);
        // system.debug('selectedCurrency>>'+ selectedCurrency);
        if(searchedCurrency!=selectedCurrency)
        {
            prodData.CurrencyIsoCode=searchedCurrency.split('-')[0];
        }else if(selectedCurrency!=null && sizerCartDataToSaveDes.pricebycur==null)
        {
            prodData.CurrencyIsoCode=selectedCurrency.split('-')[0];
        }
        else
        { 
            prodData.CurrencyIsoCode=con.Preferred_Currency__c.split('-')[0];
        }
        //added by tony 2023-02-02
        List<Retailer_Related_Data__c> ContRetailer = new List<Retailer_Related_Data__c>();
        ContRetailer = [select id,Name,Supplier_Code__c,Customer_Information__c,Customer_Information__r.MagNET_Price_Code__c,Retailer_Code__c, Manufacturer_Factory_Code__c from Retailer_Related_Data__c where Customer_Information__c =:sizerCartDataToSaveDes.customeid AND Retailer_Code__c =:sizerCartDataToSaveDes.retailerCodeId AND Status__c='Active' AND Order_to_Company__c =:prodData.Order_to_Company__c];
        system.debug('ContRetailer::'+ContRetailer);        
        Id panoutId = PunchOutRequestController.getPunchoutRequestId();
        if(SOList.size()==0)                                    // if no data on the respective customer then insert the new SO and SOLI
        {
            
            Base_Order__c So=new Base_Order__c();
            //So.Retailer__c = Retailercon.Customer_Information__c;
            So.Supplier__c =sizerCartDataToSaveDes.customeid;
            So.Supplier_Contact__c = loggedInContact.Id;
            So.RecordtypeId = CartRecordType;
            So.PunchOut_Request__c=panoutId;
            So.PunchOut_Status__c = 'Product Added';
            So.Processing_Status__c = 'Failed';
             So.SupplierParty_CNUF__c = 'SupplierParty';
            So.CustomerParty_Name__c = 'CustomerParty';
            So.Retailer_Code1__c =sizerCartDataToSaveDes.retailerCodeId;
            So.Status__c = 'New Order';
            So.OrderSource__c = 'Catalog Order';
            So.Vertical__c = prodData.Product_Unique_ID__r.Business_Vertical__c;
            So.Company__c = prodData.Order_to_Company__c;
            if(priceproductbycurrency!=null){
                So.CurrencyIsoCode = priceproductbycurrency.CurrencyIsoCode;
            }
            else
            {
                So.CurrencyIsoCode =prodData.CurrencyIsoCode;
            }
            //So.CurrencyIsoCode = priceproductbycurrency.CurrencyIsoCode;
            So.Enquiry_Status__c ='';
            So.Link_To_ERP__c ='';
            if(ContRetailer.size() !=0)
            {
                So.Supplier_Code__c = ContRetailer[0].Supplier_Code__c;
            }
            // code to fetch the custom setting and update ownerid by chandana  
            Map<string,CommunityConfiguration__c> ConfigSettings = CommunityConfiguration__c.getAll();
            CommunityConfiguration__c config = null;
            if(ConfigSettings.containsKey('CommunityConfiguration'))
            {
                config = ConfigSettings.get('CommunityConfiguration');
            }
            if(ContRetailer.size() !=0)
            {
                So.Supplier_Code__c = ContRetailer[0].Supplier_Code__c;
                So.Manufacturer_Code__c = ContRetailer[0].Manufacturer_Factory_Code__c;
            }
            //So.OwnerId =config.SalesOrder_OwnerId__c; 
            system.debug('So>>>>'+So);
            insert So;        
            Base_Order_Detail__c soli=new Base_Order_Detail__c();
            soli.Base_Order__c=So.id;
            if(addTo=='Cart')
                soli.Added_As_a_Label__c=false;
            else if(addTo=='label')
                soli.Added_As_a_Label__c=true;
            soli.Products__c = prodData.Product_Unique_ID__c;
            soli.Product_Description__c = prodData.Description__c;
            soli.Size__c = prodData.Product_Size__c;
            soli.Colour__c = prodData.Color__c;
            soli.Local_SKU__c = prodData.Local_SKU__c;
            soli.print__c = sizerCartDataToSaveDes.size;
            soli.Quantity__c =(sizerCartDataToSaveDes.quantity);
            soli.Ordered_Quantity__c = Integer.valueOf(sizerCartDataToSaveDes.quantity);
            soli.Supply_Quantity__c = String.valueOf(sizerCartDataToSaveDes.quantity);
            soli.Supply_Quantity_num__c = Integer.valueOf(sizerCartDataToSaveDes.quantity);
            soli.Remaining_Qty__c = Integer.valueOf(sizerCartDataToSaveDes.quantity);
            soli.Full_Box_Order__c =prodData.Retailer_Code__r.Full_Box_Order__c;
            soli.variable_data_product__c=prodData.Variable_Data_Product__c;
            soli.BOX_QTY__c =prodData.BOX_QTY__c;
            soli.Product_image_url__c=prodData.Product_image_url__c;
            soli.Price_Specification_Book_Product__c = prodData.Id;
            soli.Printshop_Pick__c = prodData.Print_Shop__c;
            soli.Family__c = prodData.Product_Family__c;
            if(priceproductbycurrency!=null){
                if(priceproductbycurrency.MagNET_Price_Code__c != null){
                    soli.Price_Product_by_Currency__c = priceproductbycurrency.id;
                    soli.Price_per_100_pc__c = priceproductbycurrency.Price_100_pcs__c;
                    soli.Price_100_pcs__c =String.valueof(priceproductbycurrency.Price_100_pcs__c);
                    soli.Price_1000_pcs__c =String.valueof((priceproductbycurrency.Price_100_pcs__c)*10);
                }
                else{
                    soli.Price_Product_by_Currency__c = priceproductbycurrency.id;
                    soli.Price_per_100_pc__c = priceproductbycurrency.Price_100_pcs__c;
                    soli.Price_100_pcs__c =String.valueof(priceproductbycurrency.Price_100_pcs__c);
                    soli.Price_1000_pcs__c =String.valueof((priceproductbycurrency.Price_100_pcs__c)*10);
                }   
            }
            else
            {
                soli.Price_100_pcs__c =String.valueof(0.00);
                soli.Price_1000_pcs__c =String.valueof(0.00); 
            }
            Soli.EUR_Rebate_pc__c = prodData.EUR_Rebate_pc__c;
            Soli.EUR_Reuse_Rebate_pc__c = prodData.EUR_Reuse_Rebate_pc__c;
            Soli.USD_Rebate_pc__c = prodData.USD_Rebate_pc__c;
            Soli.USD_Reuse_Rebate_pc__c = prodData.USD_Reuse_Rebate_pc__c;
            Soli.Status__c = 'Order Submitted';
            Soli.Production_Status__c='';
            Soli.Online_Detail_Status__c ='';
            soli.Customer_Ref_Model__c = prodData.Customer_Ref_Model__c;            // need to add price,vertical,curreny,company
            soli.CurrencyIsoCode = So.CurrencyIsoCode;
            soli.Added_As_a_Label__c=true;
            insert soli;
            
        }
        else                                                    // insert only SOLI
        {
            //SoliList =[select id, name,Sales_Order__c,Products__c,Local_SKU__c,Colour__c,Quantity__c,Product_image_url__c,Full_Box_Order__c,BOX_QTY__c,Price_Product_by_Currency__c,Customer_Ref_Model__c,Ordered_Quantity__c,Supply_Quantity__c,Supply_Quantity_num__c from Sales_Order_Line_Items__c where Sales_Order__c=:SOList[0].id AND Colour__c=:prodData.Color__c AND Products__c=:prodData.Product_Unique_ID__c];
            SoliList =[select id, name,Base_Order__c,Products__c,Local_SKU__c,Colour__c,Quantity__c,Product_image_url__c,Full_Box_Order__c,BOX_QTY__c,Price_Product_by_Currency__c,Customer_Ref_Model__c,print__c,Ordered_Quantity__c,Supply_Quantity__c,Supply_Quantity_num__c,Production_Status__c,Online_Detail_Status__c from Base_Order_Detail__c where Base_Order__c=:SOList[0].id AND Colour__c=:sizerCartDataToSaveDes.color AND print__c =: sizerCartDataToSaveDes.size AND Price_Specification_Book_Product__c=:prodData.Id];
            system.debug('SoliList>>>>'+SoliList);
            system.debug('SoliList.size>>'+SoliList.size());
            if(SoliList.size()==0)                                  // if no data on the respective SKU and color then insert the SO and SOLI
            {
                system.debug('SoliList in if>>'+SoliList);
                Base_Order_Detail__c soli=new Base_Order_Detail__c();
                if(addTo=='Cart')
                    soli.Added_As_a_Label__c=false;
                else if(addTo=='label')
                    soli.Added_As_a_Label__c=true;
                soli.Base_Order__c=SOList[0].id;
                soli.Products__c = prodData.Product_Unique_ID__c;
                soli.Product_Description__c = prodData.Description__c;
                soli.Size__c = prodData.Product_Size__c;
                soli.Colour__c = prodData.Color__c;
                soli.Local_SKU__c = prodData.Local_SKU__c;
                soli.print__c = sizerCartDataToSaveDes.size;
                soli.Quantity__c =sizerCartDataToSaveDes.quantity;
                soli.Ordered_Quantity__c = Integer.valueOf(sizerCartDataToSaveDes.quantity);
                soli.Supply_Quantity__c = String.valueOf(sizerCartDataToSaveDes.quantity);
                soli.Supply_Quantity_num__c = Integer.valueOf(sizerCartDataToSaveDes.quantity);
                soli.Remaining_Qty__c = Integer.valueOf(sizerCartDataToSaveDes.quantity);
                soli.Full_Box_Order__c =prodData.Retailer_Code__r.Full_Box_Order__c;
                soli.BOX_QTY__c =prodData.BOX_QTY__c;
                soli.Product_image_url__c=prodData.Product_image_url__c;
                soli.variable_data_product__c=prodData.Variable_Data_Product__c;
                soli.Price_Specification_Book_Product__c = prodData.Id;
                soli.Printshop_Pick__c = prodData.Print_Shop__c;
                soli.Family__c = prodData.Product_Family__c;
                if(priceproductbycurrency!=null){
                    if(priceproductbycurrency.MagNET_Price_Code__c != null){
                        soli.Price_Product_by_Currency__c = priceproductbycurrency.id;
                        soli.Price_per_100_pc__c = priceproductbycurrency.Price_100_pcs__c;
                        soli.Price_100_pcs__c =String.valueof(priceproductbycurrency.Price_100_pcs__c);
                        soli.Price_1000_pcs__c =String.valueof((priceproductbycurrency.Price_100_pcs__c)*10);
                    }
                    else{
                        soli.Price_Product_by_Currency__c = priceproductbycurrency.id;
                        soli.Price_per_100_pc__c = priceproductbycurrency.Price_100_pcs__c;
                        soli.Price_100_pcs__c =String.valueof(priceproductbycurrency.Price_100_pcs__c);
                        soli.Price_1000_pcs__c =String.valueof((priceproductbycurrency.Price_100_pcs__c)*10);
                    }   
                }
                else
                {
                    soli.Price_100_pcs__c =String.valueof(0.00);
                    soli.Price_1000_pcs__c =String.valueof(0.00); 
                }
                soli.Status__c = 'Order Submitted';
                soli.Production_Status__c ='';
                soli.Online_Detail_Status__c ='';
                soli.Customer_Ref_Model__c = prodData.Customer_Ref_Model__c;
                soli.CurrencyIsoCode = SOList[0].CurrencyIsoCode;
                soli.Added_As_a_Label__c=true;
                insert soli;
                
                
                Base_Order__c So=new Base_Order__c();
                So.Id = SOList[0].id;
                So.Vertical__c = prodData.Product_Unique_ID__r.Business_Vertical__c;
                So.Company__c = prodData.Order_to_Company__c;
                Update So;
                
            }   
            else                                                    //if data is there upsert thesame SOLI
            { 
                system.debug('SoliList in else >>'+SoliList[0]);
                SoliList[0].Products__c = prodData.Product_Unique_ID__c;
                SoliList[0].Product_Description__c = prodData.Description__c;
                SoliList[0].Size__c = prodData.Product_Size__c;
                SoliList[0].Colour__c = prodData.Color__c;
                SoliList[0].Full_Box_Order__c =prodData.Retailer_Code__r.Full_Box_Order__c;
                SoliList[0].BOX_QTY__c =prodData.BOX_QTY__c;
                SoliList[0].Local_SKU__c = prodData.Local_SKU__c;
                SoliList[0].print__c = sizerCartDataToSaveDes.size;
                SoliList[0].Product_image_url__c=prodData.Product_image_url__c;
                SoliList[0].variable_data_product__c=prodData.Variable_Data_Product__c;
                if(priceproductbycurrency!=null){
                    if(priceproductbycurrency.MagNET_Price_Code__c != null){
                        SoliList[0].Price_Product_by_Currency__c = priceproductbycurrency.id;
                        SoliList[0].Price_per_100_pc__c = priceproductbycurrency.Price_100_pcs__c;
                        SoliList[0].Price_100_pcs__c =String.valueof(priceproductbycurrency.Price_100_pcs__c);
                        SoliList[0].Price_1000_pcs__c =String.valueof((priceproductbycurrency.Price_100_pcs__c)*10);
                    }
                    else{
                        SoliList[0].Price_Product_by_Currency__c = priceproductbycurrency.id;
                        SoliList[0].Price_per_100_pc__c = priceproductbycurrency.Price_100_pcs__c;
                        SoliList[0].Price_100_pcs__c =String.valueof(priceproductbycurrency.Price_100_pcs__c);
                        SoliList[0].Price_1000_pcs__c =String.valueof((priceproductbycurrency.Price_100_pcs__c)*10);
                    }
                }
                else
                {
                    SoliList[0].Price_100_pcs__c =String.valueof(0.00);
                    SoliList[0].Price_1000_pcs__c =String.valueof(0.00); 
                }
                SoliList[0].Customer_Ref_Model__c = prodData.Customer_Ref_Model__c;
                SoliList[0].CurrencyIsoCode = SOList[0].CurrencyIsoCode;
                system.debug('Quantity__c>>>'+SoliList[0].Quantity__c);
                system.debug('Quantity__c>'+sizerCartDataToSaveDes.quantity);
                
                if(SoliList[0].Quantity__c != null || SoliList[0].Ordered_Quantity__c != null || SoliList[0].Supply_Quantity__c != null || SoliList[0].Supply_Quantity_num__c != null)
                {
                    integer convertedqty = integer.ValueOf(SoliList[0].Quantity__c);
                    SoliList[0].Quantity__c = convertedqty + sizerCartDataToSaveDes.quantity; 
                    
                    integer convertedqty1 = integer.ValueOf(SoliList[0].Ordered_Quantity__c);
                    SoliList[0].Ordered_Quantity__c = convertedqty1 +sizerCartDataToSaveDes.quantity; 
                    
                    integer convertedqty2 = integer.ValueOf(SoliList[0].Supply_Quantity__c);
                    SoliList[0].Supply_Quantity__c = String.valueOf(convertedqty2 + sizerCartDataToSaveDes.quantity); 
                    
                    integer convertedqty3 = integer.ValueOf(SoliList[0].Supply_Quantity_num__c);
                    SoliList[0].Supply_Quantity_num__c = convertedqty3 + sizerCartDataToSaveDes.quantity; // need to add price,url,retailer code 
                }
                else{
                    system.debug('inside else');
                    SoliList[0].Quantity__c = sizerCartDataToSaveDes.quantity;
                    SoliList[0].Ordered_Quantity__c = sizerCartDataToSaveDes.quantity;
                    SoliList[0].Supply_Quantity__c = String.valueOf(sizerCartDataToSaveDes.quantity);
                    SoliList[0].Supply_Quantity_num__c = sizerCartDataToSaveDes.quantity;
                }
                SoliList[0].Remaining_Qty__c = SoliList[0].Supply_Quantity_num__c;
                SoliList[0].Added_As_a_Label__c=true;
                system.debug('SoliList[0]>>'+SoliList[0]);
                upsert SoliList[0];
            }
            
        }
        
        return panoutId;
    }
     
   @AuraEnabled
    public static contact FetchCustData()
    {
        contact contactid=UtilityClass.getCurrentUserContact();
        system.debug('contactid'+contactid);
        return contactid;  
    }  
    
     @AuraEnabled
    public static void deleteRow(String idTODalete)
    {
        system.debug('idTODalete>>'+idTODalete);
        Base_Order_Detail__c soli=[select id,Base_Order__c from Base_Order_Detail__c where id=:idTODalete];
        String soId=soli.Base_Order__c;
        delete soli;
        Base_Order__c soData=new Base_Order__c();
        soData=[select id,(select id from Base_Order_Details__r) from Base_Order__c where id=:soId];
        if(soData.Base_Order_Details__r.size()==0)
        {
            delete soData;
        }
    }
    
}