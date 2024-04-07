public without sharing class SOController 
{
    public Static Id CartRecordType = Schema.SObjectType.Sales_Order__c.getRecordTypeInfosByName().get('Cart').getRecordTypeId();
    public Static Id OrderRecordType = Schema.SObjectType.Sales_Order__c.getRecordTypeInfosByName().get('Order').getRecordTypeId();
    
    @AuraEnabled
    public static String getUIThemeDescription()
    {
        String theme = UserInfo.getUiThemeDisplayed();
        //system.debug('theme:::'+theme);
        return theme;
    }
    
    @AuraEnabled
    public static contact FetchCustData()
    {
        contact contactid=UtilityClass.getCurrentUserContact();
        system.debug('contactid'+contactid);
        return contactid;  
    } 
    //save the cart value by creating MG and MGLI with "CART" record type
    @AuraEnabled
    public static string saveCart(id customerData,id retailercode, string quantity,id priceBookProId,id priceByCurr,string custRefModel,string selectedCurrency,String searchedCurrency)
    {
        system.debug('customerData==='+customerData);
        system.debug('retailerData==='+retailercode);
        system.debug('priceBookProId==='+priceBookProId);
        system.debug('quantity==='+quantity);
        system.debug('priceByCurr==='+priceByCurr);
        system.debug('custRefModel==='+custRefModel);
        system.debug('selectedCurrency==='+selectedCurrency);
        system.debug('searchedCurrency==='+searchedCurrency);
        //List<Retailer_Related_Data__c> ContRetailer = new List<Retailer_Related_Data__c>();
        //ContRetailer = [select id,Name,Supplier_Code__c,Customer_Information__c,Retailer_Code__c, Manufacturer_Factory_Code__c from Retailer_Related_Data__c where Customer_Information__c =: customerData AND Retailer_Code__c =: retailercode AND Status__c='Active'];
        //system.debug('ContRetailer::'+ContRetailer);
        
        Price_Specification_Book_Product__c prodData =new Price_Specification_Book_Product__c();
        Price_Product_by_Currency__c priceproductbycurrency;
        
        prodData =[select id,DisplayModel__c,Product_Unique_ID__c,CurrencyIsoCode,Product_Unique_ID__r.Business_Vertical__c, Local_SKU__c,Color__c,Retailer_Code__c,Retailer_Code__r.Full_Box_Order__c,BOX_QTY__c,Description__c,Price_100pcs__c,Price_1000pcs__c,Product_image_url__c,Product_Size__c,Order_to_Company__c,Print_Shop__c,Product_Family__c,Customer_Ref_Model__c ,EUR_Rebate_pc__c,EUR_Reuse_Rebate_pc__c,USD_Rebate_pc__c,USD_Reuse_Rebate_pc__c,Sizer_Print__c,Variable_Data_Product__c from Price_Specification_Book_Product__c where id =:priceBookProId];
        //system.debug('prodData>>>>'+prodData);
        if(priceByCurr!=null)
        {  
            priceproductbycurrency = [select id,Name,CurrencyIsoCode,Price_Book_Product__c,Local_ERP_customer_code__c,Price_100_pcs__c from Price_Product_by_Currency__c where id =:priceByCurr];
            //system.debug('priceproductbycurrency>>>>'+priceproductbycurrency);
        }
        
        List<Sales_Order__c> SOList=new List<Sales_Order__c>();
        List<Sales_Order_Line_Items__c> SoliList=new List<Sales_Order_Line_Items__c>();
        SOList =[select id, name, Retailer_Code1__c,Retailer__c,Product__r.Business_Vertical__c,Status__c,CurrencyIsoCode,Supplier_Code__c,Enquiry_Status__c,Link_To_ERP__c from Sales_Order__c where Supplier__c =:customerData AND recordtypeId =:CartRecordType ];
        //system.debug('SOList>>'+SOList);
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
        Contact con = CatalogOrderController.getcostomerinfo(retailercode);
        if(searchedCurrency!=selectedCurrency)
        {
            prodData.CurrencyIsoCode=searchedCurrency.split('-')[0];
        }else if(selectedCurrency!=null && priceByCurr==null)
        {
            prodData.CurrencyIsoCode=selectedCurrency.split('-')[0];
        }
        else{
            prodData.CurrencyIsoCode=con.Preferred_Currency__c.split('-')[0];
        }
        system.debug('prodData.CurrencyIsoCode>>>'+prodData.CurrencyIsoCode);
        if(SOList.size()==0)                                    // if no data on the respective customer then insert the new SO and SOLI
        {
            
            Sales_Order__c So=new Sales_Order__c();
            So.Supplier__c = customerData;
            So.Supplier_Contact__c = loggedInContact.Id;
            So.RecordtypeId = CartRecordType;
            So.Retailer_Code1__c = retailercode;
            So.Status__c = 'New Order';
            So.OrderSource__c = 'Catalog Order';
            So.Vertical__c = prodData.Product_Unique_ID__r.Business_Vertical__c;
            So.Company__c = prodData.Order_to_Company__c;
            if(priceproductbycurrency!=null){
                So.CurrencyIsoCode = priceproductbycurrency.CurrencyIsoCode;
                system.debug('if>>'+So.CurrencyIsoCode);
            }
            else
            {
                So.CurrencyIsoCode =prodData.CurrencyIsoCode;
            }
            So.Enquiry_Status__c ='';
            So.Link_To_ERP__c ='';
            //added by tony RD
            List<Retailer_Related_Data__c> ContRetailer = new List<Retailer_Related_Data__c>();
            ContRetailer = [select id,Name,Supplier_Code__c,Customer_Information__c,Retailer_Code__c, Manufacturer_Factory_Code__c from Retailer_Related_Data__c where Customer_Information__c =: customerData AND Retailer_Code__c =: retailercode AND Status__c='Active' AND Order_to_Company__c=:prodData.Order_to_Company__c];
            system.debug('ContRetailer::'+ContRetailer);            
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
            So.OwnerId =config.SalesOrder_OwnerId__c; 
            // system.debug('So>>>>'+So);
            insert So;                                                            
            
            Sales_Order_Line_Items__c soli=new Sales_Order_Line_Items__c();
            soli.Sales_Order__c=So.id;
            soli.Products__c = prodData.Product_Unique_ID__c;
            soli.Product_Description__c = prodData.Description__c;
            soli.Size__c = prodData.Product_Size__c;
            soli.print__c = prodData.Sizer_Print__c;
            soli.Colour__c = prodData.Color__c;
            soli.Local_SKU__c = prodData.Local_SKU__c;
            soli.variable_data_product__c=prodData.Variable_Data_Product__c;
            soli.Quantity__c = quantity;
            soli.Ordered_Quantity__c = Integer.valueOf(quantity);
            soli.Supply_Quantity__c = quantity;
            soli.Supply_Quantity_num__c = Integer.valueOf(quantity);
            soli.Remaining_Qty__c = Integer.valueOf(quantity);
            soli.Full_Box_Order__c =prodData.Retailer_Code__r.Full_Box_Order__c;
            soli.BOX_QTY__c =prodData.BOX_QTY__c;
            soli.Product_image_url__c=prodData.Product_image_url__c;
            soli.Price_Specification_Book_Product__c = prodData.Id;
            soli.Printshop_Pick__c = prodData.Print_Shop__c;
            soli.Family__c = prodData.Product_Family__c;
            if(priceByCurr!=null)
            { 
                soli.Price_Product_by_Currency__c = priceproductbycurrency.id;
                Soli.Price_per_100_pc__c = priceproductbycurrency.Price_100_pcs__c;
                Soli.Price_100_pcs__c =String.valueof(priceproductbycurrency.Price_100_pcs__c);
                Soli.Price_1000_pcs__c =String.valueof((priceproductbycurrency.Price_100_pcs__c)*10);
            }
            else
            {
                Soli.Price_100_pcs__c=String.valueof(0.00);
                Soli.Price_1000_pcs__c =String.valueof(0.00);
            }
            Soli.EUR_Rebate_pc__c = prodData.EUR_Rebate_pc__c;
            Soli.EUR_Reuse_Rebate_pc__c = prodData.EUR_Reuse_Rebate_pc__c;
            Soli.USD_Rebate_pc__c = prodData.USD_Rebate_pc__c;
            Soli.USD_Reuse_Rebate_pc__c = prodData.USD_Reuse_Rebate_pc__c;
            Soli.Status__c = 'Order Submitted';
            Soli.Production_Status__c='';
            Soli.Online_Detail_Status__c ='';
            soli.Customer_Ref_Model__c = prodData.Customer_Ref_Model__c;
			soli.CurrencyIsoCode = So.CurrencyIsoCode;
            insert soli;
            
        }
        else                                                    // insert only SOLI
        {
            //SoliList =[select id, name,Sales_Order__c,Products__c,Local_SKU__c,Colour__c,Quantity__c,Product_image_url__c,Full_Box_Order__c,BOX_QTY__c,Price_Product_by_Currency__c,Customer_Ref_Model__c,Ordered_Quantity__c,Supply_Quantity__c,Supply_Quantity_num__c from Sales_Order_Line_Items__c where Sales_Order__c=:SOList[0].id AND Colour__c=:prodData.Color__c AND Products__c=:prodData.Product_Unique_ID__c];
            SoliList =[select id, name,Sales_Order__c,Products__c,Local_SKU__c,Colour__c,Quantity__c,Product_image_url__c,Full_Box_Order__c,BOX_QTY__c,Price_Product_by_Currency__c,Customer_Ref_Model__c,Ordered_Quantity__c,Supply_Quantity__c,Supply_Quantity_num__c,Production_Status__c,Online_Detail_Status__c from Sales_Order_Line_Items__c where Sales_Order__c=:SOList[0].id AND Colour__c=:prodData.Color__c AND Price_Specification_Book_Product__c=:prodData.Id];
            // system.debug('SoliList>>>>'+SoliList);
            //system.debug('SoliList.size>>'+SoliList.size());
            if(SoliList.size()==0)                                  // if no data on the respective SKU and color then insert the SO and SOLI
            {
                system.debug('SoliList in if>>'+SoliList);
                Sales_Order_Line_Items__c soli=new Sales_Order_Line_Items__c();
                soli.Sales_Order__c=SOList[0].id;
                soli.Products__c = prodData.Product_Unique_ID__c;
                soli.Product_Description__c = prodData.Description__c;
                soli.Size__c = prodData.Product_Size__c;
                soli.print__c = prodData.Sizer_Print__c;
                soli.Colour__c = prodData.Color__c;
                soli.Local_SKU__c = prodData.Local_SKU__c;
                soli.variable_data_product__c=prodData.Variable_Data_Product__c;
                soli.Quantity__c = quantity;                           
                soli.Ordered_Quantity__c = Integer.valueOf(quantity);
                soli.Supply_Quantity__c = quantity;
                soli.Supply_Quantity_num__c = Integer.valueOf(quantity);
                soli.Remaining_Qty__c = Integer.valueOf(quantity);
                soli.Full_Box_Order__c =prodData.Retailer_Code__r.Full_Box_Order__c;
                soli.BOX_QTY__c =prodData.BOX_QTY__c;
                soli.Product_image_url__c=prodData.Product_image_url__c;
                soli.Price_Specification_Book_Product__c = prodData.Id;
                soli.Printshop_Pick__c = prodData.Print_Shop__c;
                soli.Family__c = prodData.Product_Family__c;
                if(priceByCurr!=null)
                { 
                    soli.Price_Product_by_Currency__c = priceproductbycurrency.id;
                    Soli.Price_per_100_pc__c = priceproductbycurrency.Price_100_pcs__c;
                    Soli.Price_100_pcs__c =String.valueof(priceproductbycurrency.Price_100_pcs__c);
                    Soli.Price_1000_pcs__c =String.valueof((priceproductbycurrency.Price_100_pcs__c)*10);
                }
                else
                {
                    Soli.Price_100_pcs__c=String.valueof(0.00);
                    Soli.Price_1000_pcs__c =String.valueof(0.00);
                }
                Soli.Status__c = 'Order Submitted';
                Soli.Production_Status__c ='';
                Soli.Online_Detail_Status__c ='';
                soli.Customer_Ref_Model__c = prodData.Customer_Ref_Model__c;
                soli.CurrencyIsoCode = SOList[0].CurrencyIsoCode;
                insert soli;
                
                
                Sales_Order__c So=new Sales_Order__c();
                So.Id = SOList[0].id;
                So.Vertical__c = prodData.Product_Unique_ID__r.Business_Vertical__c;
                So.Company__c = prodData.Order_to_Company__c;
                Update So;
                
            }   
            else                                                    //if data is there upsert the same SOLI
            { 
                system.debug('SoliList in else >>'+SoliList[0]);
                SoliList[0].Products__c = prodData.Product_Unique_ID__c;
                SoliList[0].Product_Description__c = prodData.Description__c;
                SoliList[0].Size__c = prodData.Product_Size__c;
                SoliList[0].print__c = prodData.Sizer_Print__c;
                SoliList[0].Colour__c = prodData.Color__c;
                SoliList[0].Full_Box_Order__c =prodData.Retailer_Code__r.Full_Box_Order__c;
                SoliList[0].BOX_QTY__c =prodData.BOX_QTY__c;
                SoliList[0].Local_SKU__c = prodData.Local_SKU__c;
                SoliList[0].variable_data_product__c=prodData.Variable_Data_Product__c;
                SoliList[0].Product_image_url__c=prodData.Product_image_url__c;
                if(priceByCurr!=null)
                { 
                    SoliList[0].Price_Product_by_Currency__c = priceproductbycurrency.id;
                    SoliList[0].Price_per_100_pc__c = priceproductbycurrency.Price_100_pcs__c;
                    SoliList[0].Price_100_pcs__c =String.valueof(priceproductbycurrency.Price_100_pcs__c);
                    SoliList[0].Price_1000_pcs__c =String.valueof((priceproductbycurrency.Price_100_pcs__c)*10);
                }
                else
                {
                    SoliList[0].Price_100_pcs__c=String.valueof(0.00);
                    SoliList[0].Price_1000_pcs__c =String.valueof(0.00);
                }
                SoliList[0].Customer_Ref_Model__c = prodData.Customer_Ref_Model__c;
                SoliList[0].CurrencyIsoCode = SOList[0].CurrencyIsoCode;
                system.debug('Quantity__c>>>'+SoliList[0].Quantity__c);
                system.debug('Quantity__c>'+integer.ValueOf(quantity));
                
                if(SoliList[0].Quantity__c != null || SoliList[0].Ordered_Quantity__c != null || SoliList[0].Supply_Quantity__c != null || SoliList[0].Supply_Quantity_num__c != null)
                {
                    integer convertedqty = integer.ValueOf(SoliList[0].Quantity__c);
                    SoliList[0].Quantity__c = String.valueOf(convertedqty + (integer.ValueOf(quantity))); 
                    
                    integer convertedqty1 = integer.ValueOf(SoliList[0].Ordered_Quantity__c);
                    SoliList[0].Ordered_Quantity__c = convertedqty1 +(integer.ValueOf(quantity)); 
                    
                    integer convertedqty2 = integer.ValueOf(SoliList[0].Supply_Quantity__c);
                    SoliList[0].Supply_Quantity__c = String.valueOf(convertedqty2 + (integer.ValueOf(quantity))); 
                    
                    integer convertedqty3 = integer.ValueOf(SoliList[0].Supply_Quantity_num__c);
                    SoliList[0].Supply_Quantity_num__c = convertedqty3 + (integer.ValueOf(quantity)); // need to add price,url,retailer code 
                }
                else{
                    system.debug('inside else');
                    SoliList[0].Quantity__c = quantity;
                    SoliList[0].Ordered_Quantity__c = Integer.valueOf(quantity);
                    SoliList[0].Supply_Quantity__c = quantity;
                    SoliList[0].Supply_Quantity_num__c = Integer.valueOf(quantity);
                }
                SoliList[0].Remaining_Qty__c = SoliList[0].Supply_Quantity_num__c;
                system.debug('SoliList[0]>>'+SoliList[0]);
                upsert SoliList[0];
            }
            
        }
        
        return 'socontroller';
    }
    /*Added by seema for bulk add to cart: --START--*/
    @AuraEnabled
    public static string saveBulkCart(String custid,String retailerCodeId,List<CatalogOrderController.BulkAddToCartWrap> bulkCartDataToSaveDes,string selectedCurrency,String searchedCurrency)
    {
        //List<Retailer_Related_Data__c> ContRetailer = new List<Retailer_Related_Data__c>();
        //ContRetailer = [select id,Name,Supplier_Code__c,Customer_Information__c,Retailer_Code__c, Manufacturer_Factory_Code__c from Retailer_Related_Data__c where Customer_Information__c =: custid AND Retailer_Code__c =: retailerCodeId AND Status__c='Active'];
        //system.debug('ContRetailer::'+ContRetailer);
        
        List<Id> pricebookSpecIdList=new List<Id>();
        List<String> colorList=new List<String>();
        List<String> priceByCurr=new List<String>();
        Map<Id,Price_Product_by_Currency__c> priceproductbycurrencyMap;
        for(CatalogOrderController.BulkAddToCartWrap singleCartData:bulkCartDataToSaveDes)
        {
            pricebookSpecIdList.add(singleCartData.pricebookId);
            priceByCurr.add(singleCartData.cur);
            colorList.add(singleCartData.color);
        }
        //system.debug('pricebookSpecIdList>>>>'+pricebookSpecIdList);
        Map<Id,Price_Specification_Book_Product__c> prodDataMap =new Map<Id,Price_Specification_Book_Product__c>([select id,CurrencyIsoCode,Product_Unique_ID__c,Product_Unique_ID__r.Business_Vertical__c, Local_SKU__c,Color__c,Retailer_Code__c,Retailer_Code__r.Full_Box_Order__c,BOX_QTY__c,Description__c,Price_100pcs__c,Price_1000pcs__c,Product_image_url__c,Product_Size__c,Order_to_Company__c,Print_Shop__c,Product_Family__c,Customer_Ref_Model__c,Sizer_Print__c,Variable_Data_Product__c  from Price_Specification_Book_Product__c where id =:pricebookSpecIdList]);
        
        if(priceByCurr!=null){
            priceproductbycurrencyMap = new Map<Id,Price_Product_by_Currency__c>([select id,Name,CurrencyIsoCode,Price_Book_Product__c,Local_ERP_customer_code__c,Price_100_pcs__c from Price_Product_by_Currency__c where id =:priceByCurr]);
            
            // system.debug('prodDataMap>>>>'+prodDataMap);
            
            // system.debug('priceproductbycurrencyMap>>>>'+priceproductbycurrencyMap);
        }
        List<Sales_Order_Line_Items__c> SoliList=new List<Sales_Order_Line_Items__c>();
        List<Sales_Order__c> SOList=new List<Sales_Order__c>();
        SOList =[select id, name, Retailer_Code1__c,Retailer__c,Product__r.Business_Vertical__c,Status__c,CurrencyIsoCode,Supplier_Code__c,Enquiry_Status__c,Link_To_ERP__c from Sales_Order__c where Supplier__c =:custid AND recordtypeId =:CartRecordType ];
        
        Schema.DescribeFieldResult companyResult = Online_Enquiry__c.Order_Country__c.getDescribe();
        List<Schema.PicklistEntry> companyvalues = companyResult.getPicklistValues();
        for( Schema.PicklistEntry comp : companyvalues) 
        {
            for(Id key:prodDataMap.keySet())
                if(comp.getValue() == prodDataMap.get(key).Order_to_Company__c)
            {
                prodDataMap.get(key).Order_to_Company__c = comp.getLabel();
                //break;
            }
        }
        Contact loggedInContact = FetchCustData();
        Contact con = CatalogOrderController.getcostomerinfo(retailerCodeId);
        if(searchedCurrency!=selectedCurrency)
        {
            prodDataMap.values()[0].CurrencyIsoCode=searchedCurrency.split('-')[0];
        }else if(selectedCurrency!=null && priceByCurr==null)
        {
            prodDataMap.values()[0].CurrencyIsoCode=selectedCurrency.split('-')[0];
        }else if(searchedCurrency==selectedCurrency)
        {
            prodDataMap.values()[0].CurrencyIsoCode=searchedCurrency.split('-')[0];
        }else
        {  
            prodDataMap.values()[0].CurrencyIsoCode=con.Preferred_Currency__c.split('-')[0];
        }
        //tony added 2023-02-02 RD
        List<Retailer_Related_Data__c> ContRetailer = new List<Retailer_Related_Data__c>();
        ContRetailer = [select id,Name,Supplier_Code__c,Customer_Information__c,Retailer_Code__c, Manufacturer_Factory_Code__c from Retailer_Related_Data__c where Customer_Information__c =: custid AND Retailer_Code__c =: retailerCodeId AND Status__c='Active' AND Order_to_Company__c=:prodDataMap.values()[0].Order_to_Company__c];
        system.debug('ContRetailer::'+ContRetailer);        
        if(SOList.size()==0)                                    // if no data on the respective customer then insert the new SO and SOLI
        {
            
            Sales_Order__c So=new Sales_Order__c();
            //So.Retailer__c = Retailercon.Customer_Information__c;
            So.Supplier__c = custid;
            So.Supplier_Contact__c = loggedInContact.Id;
            So.RecordtypeId = CartRecordType;
            So.Retailer_Code1__c = retailerCodeId;
            So.Status__c = 'New Order';
            So.OrderSource__c = 'Catalog Order';
            So.Vertical__c = prodDataMap.values()[0].Product_Unique_ID__r.Business_Vertical__c;
            So.Company__c = prodDataMap.values()[0].Order_to_Company__c;
            for(CatalogOrderController.BulkAddToCartWrap singleCartData:bulkCartDataToSaveDes)
            {
                if(priceproductbycurrencyMap.containskey(singleCartData.cur)){
                    So.CurrencyIsoCode = priceproductbycurrencyMap.values()[0].CurrencyIsoCode;
                }
                else
                {
                    So.CurrencyIsoCode =prodDataMap.values()[0].CurrencyIsoCode;
                }
            }
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
            So.OwnerId =config.SalesOrder_OwnerId__c; 
            system.debug('So>>>>'+So);
            insert So;                                                          // need to add Billing and shipping address 
            List<Sales_Order_Line_Items__c> soliListToInsert=new List<Sales_Order_Line_Items__c>();
            for(CatalogOrderController.BulkAddToCartWrap singleCartData:bulkCartDataToSaveDes)
            {
                Sales_Order_Line_Items__c soli=new Sales_Order_Line_Items__c();
                soli.Sales_Order__c=So.id;
                soli.Products__c = prodDataMap.get(singleCartData.pricebookId).Product_Unique_ID__c;
                soli.Product_Description__c = prodDataMap.get(singleCartData.pricebookId).Description__c;
                soli.Size__c = prodDataMap.get(singleCartData.pricebookId).Product_Size__c;
                soli.print__c = prodDataMap.get(singleCartData.pricebookId).Sizer_Print__c;
                soli.Colour__c = prodDataMap.get(singleCartData.pricebookId).Color__c;
                soli.Local_SKU__c = prodDataMap.get(singleCartData.pricebookId).Local_SKU__c;
                soli.Quantity__c = singleCartData.quantity+'';
                soli.variable_data_product__c=prodDataMap.get(singleCartData.pricebookId).Variable_Data_Product__c;
                soli.Ordered_Quantity__c = Integer.valueOf(singleCartData.quantity);
                soli.Supply_Quantity__c = singleCartData.quantity+'';
                soli.Supply_Quantity_num__c = Integer.valueOf(singleCartData.quantity);
                soli.Remaining_Qty__c = Integer.valueOf(singleCartData.quantity);
                soli.Full_Box_Order__c =prodDataMap.get(singleCartData.pricebookId).Retailer_Code__r.Full_Box_Order__c;
                soli.BOX_QTY__c =prodDataMap.get(singleCartData.pricebookId).BOX_QTY__c;
                soli.Product_image_url__c=prodDataMap.get(singleCartData.pricebookId).Product_image_url__c;
                soli.Price_Specification_Book_Product__c = prodDataMap.get(singleCartData.pricebookId).Id;
                soli.Printshop_Pick__c = prodDataMap.get(singleCartData.pricebookId).Print_Shop__c;
                soli.Family__c = prodDataMap.get(singleCartData.pricebookId).Product_Family__c;
                if(priceproductbycurrencyMap.containskey(singleCartData.cur)){
                    soli.Price_Product_by_Currency__c = singleCartData.cur;
                    
                    soli.Price_per_100_pc__c = priceproductbycurrencyMap.get(singleCartData.cur).Price_100_pcs__c;
                    soli.Price_100_pcs__c=String.valueof(priceproductbycurrencyMap.get(singleCartData.cur).Price_100_pcs__c);
                    soli.Price_1000_pcs__c =String.valueof((priceproductbycurrencyMap.get(singleCartData.cur).Price_100_pcs__c)*10);
                }
                else
                {
                    soli.Price_100_pcs__c =String.valueof(0.00);
                    soli.Price_1000_pcs__c =String.valueof(0.00); 
                }
                soli.Status__c = 'Order Submitted';
                soli.Production_Status__c='';
                soli.Online_Detail_Status__c ='';
                soli.Customer_Ref_Model__c = prodDataMap.get(singleCartData.pricebookId).Customer_Ref_Model__c;            // need to add price,vertical,curreny,company
                soli.CurrencyIsoCode = So.CurrencyIsoCode;
                soliListToInsert.add(soli);
            }
            insert soliListToInsert;
        }
        else                                                    // insert only SOLI
        {
            //SoliList =[select id, name,Sales_Order__c,Products__c,Local_SKU__c,Colour__c,Quantity__c,Product_image_url__c,Full_Box_Order__c,BOX_QTY__c,Price_Product_by_Currency__c,Customer_Ref_Model__c,Ordered_Quantity__c,Supply_Quantity__c,Supply_Quantity_num__c from Sales_Order_Line_Items__c where Sales_Order__c=:SOList[0].id AND Colour__c=:prodData.Color__c AND Products__c=:prodData.Product_Unique_ID__c];
            //SoliList =[select id, name,Sales_Order__c,Products__c,Local_SKU__c,Colour__c,Quantity__c,Product_image_url__c,Full_Box_Order__c,BOX_QTY__c,Price_Product_by_Currency__c,Customer_Ref_Model__c,Ordered_Quantity__c,Supply_Quantity__c,Supply_Quantity_num__c,Production_Status__c,Online_Detail_Status__c from Sales_Order_Line_Items__c where Sales_Order__c=:SOList[0].id AND Price_Specification_Book_Product__c=:prodDataMap.keySet() AND Colour__c in :colorList];
            //system.debug('SoliList>>>>'+SoliList);
            //system.debug('SoliList.size>>'+SoliList.size());
            //if(SoliList.size()==0)                                  // if no data on the respective SKU and color then insert the SO and SOLI
            //{
            List<Sales_Order_Line_Items__c> soliListToInsert=new List<Sales_Order_Line_Items__c>();
            for(CatalogOrderController.BulkAddToCartWrap singleCartData:bulkCartDataToSaveDes)
            {
                system.debug('SoliList in if>>'+SoliList);
                Sales_Order_Line_Items__c soli=new Sales_Order_Line_Items__c();
                soli.Sales_Order__c=SOList[0].id;
                soli.Products__c = prodDataMap.get(singleCartData.pricebookId).Product_Unique_ID__c;
                soli.Product_Description__c = prodDataMap.get(singleCartData.pricebookId).Description__c;
                soli.Size__c = prodDataMap.get(singleCartData.pricebookId).Product_Size__c;
                soli.print__c = prodDataMap.get(singleCartData.pricebookId).Sizer_Print__c;
                soli.Colour__c = prodDataMap.get(singleCartData.pricebookId).Color__c;
                soli.Local_SKU__c = prodDataMap.get(singleCartData.pricebookId).Local_SKU__c;
                soli.variable_data_product__c=prodDataMap.get(singleCartData.pricebookId).Variable_Data_Product__c;
                soli.Quantity__c = singleCartData.quantity+'';                            // need to add size,price,img url
                soli.Ordered_Quantity__c = Integer.valueOf(singleCartData.quantity);
                soli.Supply_Quantity__c = singleCartData.quantity+'';
                soli.Supply_Quantity_num__c = Integer.valueOf(singleCartData.quantity);
                soli.Remaining_Qty__c = Integer.valueOf(singleCartData.quantity);
                soli.Full_Box_Order__c =prodDataMap.get(singleCartData.pricebookId).Retailer_Code__r.Full_Box_Order__c;
                soli.BOX_QTY__c =prodDataMap.get(singleCartData.pricebookId).BOX_QTY__c;
                soli.Product_image_url__c=prodDataMap.get(singleCartData.pricebookId).Product_image_url__c;
                soli.Price_Specification_Book_Product__c = prodDataMap.get(singleCartData.pricebookId).Id;
                soli.Printshop_Pick__c = prodDataMap.get(singleCartData.pricebookId).Print_Shop__c;
                soli.Family__c = prodDataMap.get(singleCartData.pricebookId).Product_Family__c;
                if(priceproductbycurrencyMap.containskey(singleCartData.cur)){
                    soli.Price_Product_by_Currency__c = singleCartData.cur;
                    soli.Price_per_100_pc__c = priceproductbycurrencyMap.get(singleCartData.cur).Price_100_pcs__c;
                    soli.Price_100_pcs__c=String.valueof(priceproductbycurrencyMap.get(singleCartData.cur).Price_100_pcs__c);
                    soli.Price_1000_pcs__c =String.valueof((priceproductbycurrencyMap.get(singleCartData.cur).Price_100_pcs__c)*10);
                }
                else
                {
                    soli.Price_100_pcs__c =String.valueof(0.00);
                    soli.Price_1000_pcs__c =String.valueof(0.00); 
                }
                soli.Status__c = 'Order Submitted';
                soli.Production_Status__c ='';
                soli.Online_Detail_Status__c ='';
                soli.Customer_Ref_Model__c = prodDataMap.get(singleCartData.pricebookId).Customer_Ref_Model__c;
                soli.CurrencyIsoCode = SOList[0].CurrencyIsoCode;
                soliListToInsert.add(soli);
            }
            insert soliListToInsert;  
        }
        return 'Success';
    }
    /*Bulk add to cart: --END--*/
    
    public static string saveSizerCart(CatalogOrderController.SizerAddToCartWrap sizerCartDataToSaveDes,String addTo,String selectedCurrency,String searchedCurrency)
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
        List<Sales_Order__c> SOList=new List<Sales_Order__c>();
        List<Sales_Order_Line_Items__c> SoliList=new List<Sales_Order_Line_Items__c>();
        SOList =[select id, name, Retailer_Code1__c,Retailer__c,Product__r.Business_Vertical__c,Status__c,CurrencyIsoCode,Supplier_Code__c,Enquiry_Status__c,Link_To_ERP__c from Sales_Order__c where Supplier__c =:sizerCartDataToSaveDes.customeid AND recordtypeId =:CartRecordType ];
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
        
        if(SOList.size()==0)                                    // if no data on the respective customer then insert the new SO and SOLI
        {
            
            Sales_Order__c So=new Sales_Order__c();
            //So.Retailer__c = Retailercon.Customer_Information__c;
            So.Supplier__c =sizerCartDataToSaveDes.customeid;
            So.Supplier_Contact__c = loggedInContact.Id;
            So.RecordtypeId = CartRecordType;
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
            So.OwnerId =config.SalesOrder_OwnerId__c; 
            system.debug('So>>>>'+So);
            insert So;        
            Sales_Order_Line_Items__c soli=new Sales_Order_Line_Items__c();
            soli.Sales_Order__c=So.id;
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
            soli.Quantity__c =String.valueOf(sizerCartDataToSaveDes.quantity);
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
            SoliList =[select id, name,Sales_Order__c,Products__c,Local_SKU__c,Colour__c,Quantity__c,Product_image_url__c,Full_Box_Order__c,BOX_QTY__c,Price_Product_by_Currency__c,Customer_Ref_Model__c,print__c,Ordered_Quantity__c,Supply_Quantity__c,Supply_Quantity_num__c,Production_Status__c,Online_Detail_Status__c from Sales_Order_Line_Items__c where Sales_Order__c=:SOList[0].id AND Colour__c=:sizerCartDataToSaveDes.color AND print__c =: sizerCartDataToSaveDes.size AND Price_Specification_Book_Product__c=:prodData.Id];
            system.debug('SoliList>>>>'+SoliList);
            system.debug('SoliList.size>>'+SoliList.size());
            if(SoliList.size()==0)                                  // if no data on the respective SKU and color then insert the SO and SOLI
            {
                system.debug('SoliList in if>>'+SoliList);
                Sales_Order_Line_Items__c soli=new Sales_Order_Line_Items__c();
                if(addTo=='Cart')
                    soli.Added_As_a_Label__c=false;
                else if(addTo=='label')
                    soli.Added_As_a_Label__c=true;
                soli.Sales_Order__c=SOList[0].id;
                soli.Products__c = prodData.Product_Unique_ID__c;
                soli.Product_Description__c = prodData.Description__c;
                soli.Size__c = prodData.Product_Size__c;
                soli.Colour__c = prodData.Color__c;
                soli.Local_SKU__c = prodData.Local_SKU__c;
                soli.print__c = sizerCartDataToSaveDes.size;
                soli.Quantity__c =String.valueOf(sizerCartDataToSaveDes.quantity);
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
                
                
                Sales_Order__c So=new Sales_Order__c();
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
                    SoliList[0].Quantity__c = String.valueOf(convertedqty + sizerCartDataToSaveDes.quantity); 
                    
                    integer convertedqty1 = integer.ValueOf(SoliList[0].Ordered_Quantity__c);
                    SoliList[0].Ordered_Quantity__c = convertedqty1 +sizerCartDataToSaveDes.quantity; 
                    
                    integer convertedqty2 = integer.ValueOf(SoliList[0].Supply_Quantity__c);
                    SoliList[0].Supply_Quantity__c = String.valueOf(convertedqty2 + sizerCartDataToSaveDes.quantity); 
                    
                    integer convertedqty3 = integer.ValueOf(SoliList[0].Supply_Quantity_num__c);
                    SoliList[0].Supply_Quantity_num__c = convertedqty3 + sizerCartDataToSaveDes.quantity; // need to add price,url,retailer code 
                }
                else{
                    system.debug('inside else');
                    SoliList[0].Quantity__c = String.valueOf(sizerCartDataToSaveDes.quantity);
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
        
        return 'success';
    }
    
    //fetch all the cart details         TotalPriceByCurrencyInCart
     @AuraEnabled
    
    public static List<SOLIWrapper>  getAllCartDetails(id customerid)
    {
        List<Sales_Order__c> SOList=new List<Sales_Order__c>();
        List<Sales_Order_Line_Items__c> SOliList=new List<Sales_Order_Line_Items__c>();
        List<SOLIWrapper> prodwrapList = new List<SOLIWrapper>();
        
        system.debug('customerid>>'+customerid);
        system.debug('CartRecordType>>'+CartRecordType);
        /*Added Sales_Order__r.Retailer_Code1__r.Show_Box_Qty__c   Ivy Lee 8 Jun 2023*/
        SOList =[select id, name, Retailer_Code1__c,Retailer_Code1__r.name,Retailer_Code1__r.Show_Price_in_Order__c,Retailer_Code1__r.Show_Box_Qty__c,Retailer__c,Product__r.Business_Vertical__c from Sales_Order__c where Supplier__c =: customerid AND RecordTypeId =: CartRecordType];
        
        Decimal TotalCartprice = 0.0;
        System.debug('SOList.size()>>'+SOList.size());
        
        if(SOList.size()>0)  
        {	/*Added Sales_Order__r.Retailer_Code1__r.Show_Box_Qty__c   Price_Specification_Book_Product__r.DisplayModel__c     Added Ivy Lee 8 Jun 2023*/
            SOliList =[select id,Supply_Quantity__c,Price_100_pcs__c,name,Sales_Order__c,Products__c,Print__c,Products__r.Name,Sales_Order__r.RecordType.Name,Quantity__c,Size__c,Colour__c,Local_SKU__c,Product_Description__c,Product_image_url__c,Sales_Order__r.Retailer_Code1__r.name,Sales_Order__r.Retailer_Code1__r.Show_Box_Qty__c,Sales_Order__r.Retailer_Code1__r.Show_Price_in_Order__c,Sales_Order__r.Retailer_Code1__r.Remarks__c,Full_Box_Order__c,BOX_QTY__c,Price_Specification_Book_Product__c,Price_Specification_Book_Product__r.Name,Price_Specification_Book_Product__r.DisplayModel__c,Price_Specification_Book_Product__r.Id, Price_Specification_Book_Product__r.MOQ__c,Products__r.Id,Price_Specification_Book_Product__r.UOM_Price__c, Products__r.Sub_category__c,Remarks__c,CurrencyIsoCode,Price_Product_by_Currency__r.MagNET_Price_Code__c,Price_Product_by_Currency__r.UOM_Price__c,Order_UOM__c,variable_data_product__c from Sales_Order_Line_Items__c where Sales_Order__r.RecordTypeID =: CartRecordType AND Sales_Order__c =:SOList[0].id  AND Added_As_a_Label__c=false];//  AND Added_As_a_Label__c=false Added by seema .
            system.debug(' SOliList>>'+ SOliList);
            for(Sales_Order_Line_Items__c SOLI:SOliList)
            {
                SOLIWrapper productobj = new SOLIWrapper();
                productobj.id = SOLI.id;
                productobj.SOid = SOLI.Sales_Order__c;
                productobj.Name=SOLI.Products__r.Name;
                productobj.Quantity=SOLI.Quantity__c;
                productobj.Color=SOLI.Colour__c;
                productobj.LocalSKU=SOLI.Local_SKU__c;
                productobj.fullboxQty=SOLI.Full_Box_Order__c;
                productobj.ShowBoxQty=SOLI.Sales_Order__r.Retailer_Code1__r.Show_Box_Qty__c; //Added 8 Jun 2023 Ivy Lee
                productobj.boxquantity=SOLI.BOX_QTY__c;
                productobj.Description=SOLI.Product_Description__c;
                productobj.Productimage=SOLI.Product_image_url__c;
                productobj.Remarks=SOLI.Remarks__c;
                productobj.retailerName = SOLI.Sales_Order__r.Retailer_Code1__r.name;
                productobj.showremarks = SOLI.Sales_Order__r.Retailer_Code1__r.Remarks__c;
                productobj.PSBP = SOLI.Price_Specification_Book_Product__r.Name;
                productobj.DisplayModel = SOLI.Price_Specification_Book_Product__r.DisplayModel__c; //Added 7 Jun 2023 Ivy Lee
                productobj.ProductId = SOLI.Products__r.Id;
                productobj.MOQ = SOLI.Price_Specification_Book_Product__r.MOQ__c; 
                productobj.orderUom = SOLI.Order_UOM__c;
                productobj.ShowPriceInOrder = SOLI.Sales_Order__r.Retailer_Code1__r.Show_Price_in_Order__c;
                productobj.variableDataProduct = SOLI.variable_data_product__c;
                // Decimal.ValueOf(str)
                //  system.debug(' SOLI.Price_Specification_Book_Product__r.UOM_Price__c :::'+ SOLI.Price_Specification_Book_Product__r.UOM_Price__c);
                // system.debug(' SOLI.Quantity__c :::'+ SOLI.Quantity__c);
                //system.debug(' SOLI.Id :::'+ SOLI.Id);
                //system.debug(' SOLI.Id :::'+ SOLI.Products__r.Name);
                
                //If the user is perticular user then perticular price is set added By raghu starts
                system.debug(' SOLI.Price_Product_by_Currency__r.MagNET_Price_Code__c :::'+ SOLI.Price_Product_by_Currency__r.MagNET_Price_Code__c);
                if(SOLI.Price_Product_by_Currency__r.MagNET_Price_Code__c != null){
                    // system.debug(' SOLI.Supply_Quantity__c>>'+ SOLI.Supply_Quantity__c);
                    system.debug(' SOLI.Price_100_pcs__c>>'+ SOLI.Price_100_pcs__c);
                    system.debug('SOLI.COLOUR>>'+SOLI.Colour__c);
                    productobj.TotalPriceByCurrency = ((Decimal.ValueOf(SOLI.Supply_Quantity__c))/100) * Decimal.ValueOf(SOLI.Price_100_pcs__c);
                    // productobj.TotalPriceByCurrency = (SOLI.Price_Product_by_Currency__r.UOM_Price__c) *  (Decimal.ValueOf(SOLI.Quantity__c) );
                    system.debug(' productobj.TotalPriceByCurrency>>'+ productobj.TotalPriceByCurrency);
                }
                else {
                    if(SOLI.Supply_Quantity__c != Null){ 
                        //system.debug(' SOLI.Supply_Quantity__c>>'+ SOLI.Supply_Quantity__c);
                        system.debug(' SOLI.Price_100_pcs__c>>'+ SOLI.Price_100_pcs__c);
                        system.debug('SOLI.COLOUR>>'+SOLI.Colour__c);
                        productobj.TotalPriceByCurrency = ((Decimal.ValueOf(SOLI.Supply_Quantity__c))/100) * Decimal.ValueOf(SOLI.Price_100_pcs__c);
                        system.debug('productobj.TotalPriceByCurrency:::'+productobj.TotalPriceByCurrency);
                        // productobj.TotalPriceByCurrency = (SOLI.Price_Specification_Book_Product__r.UOM_Price__c) *  (Decimal.ValueOf(SOLI.Quantity__c) ); 
                        system.debug(' (if) productobj.TotalPriceByCurrency>>'+ productobj.TotalPriceByCurrency);
                    }
                }
                // added By raghu ends
                system.debug(' productobj.TotalPriceByCurrency :::'+ productobj.TotalPriceByCurrency);
                productobj.CurrencyIsoCode = SOLI.CurrencyIsoCode;
                productobj.BlankString = '  ';
                //if(SOLI.Products__r.Sub_category__c == 'STICKER' || SOLI.Products__r.Sub_category__c == 'SIZER')          // added by chandana on 03/26/2020
                if(SOLI.variable_data_product__c == 'YES')
                {
                    productobj.Size=SOLI.print__c;
                }
                else{
                    productobj.Size=SOLI.Size__c;
                }
                system.debug(' productobj :::'+ productobj);
                prodwrapList.add(productobj);
            }
            return prodwrapList;
        }
        else 
        {
            return null;
        }
    }
    // Delete product from the cart
    @AuraEnabled
    public static list<SOLIWrapper>  deleteProductFromCart(string soliId, string soId)
    {
        system.debug('soliId>>'+ soliId);
        system.debug('soId>>'+ soId);
        Sales_Order_Line_Items__c soliObject = new Sales_Order_Line_Items__c();
        soliObject.Id = soliId;
        
        delete soliObject;        
        /*Price_Specification_Book_Product__r.DisplayModel__c    Sales_Order__r.Retailer_Code1__r.Show_Box_Qty__c  Added Ivy Lee 8 Jun 2023*/
        list<Sales_Order_Line_Items__c> remainingrec = [select id,name,Products__c,Products__r.Name,BOX_QTY__c,Size__c,Sales_Order__r.RecordType.Name,Sales_Order__c,Sales_Order__r.Retailer_Code1__r.Show_Box_Qty__c,Sales_Order__r.Retailer_Code1__c,Quantity__c,Colour__c,Local_SKU__c,Product_Description__c,Product_image_url__c,Price_Specification_Book_Product__r.Name,Price_Specification_Book_Product__r.DisplayModel__c,Full_Box_Order__c,Added_As_a_Label__c,Price_Product_by_Currency__r.MagNET_Price_Code__c,Price_Product_by_Currency__r.UOM_Price__c, Price_Specification_Book_Product__r.MOQ__c,Price_Specification_Book_Product__r.UOM_Price__c,CurrencyIsoCode  from Sales_Order_Line_Items__c where Sales_Order__r.RecordType.Name ='Cart' AND Sales_Order__c=:soId];
        //system.debug('remainingrec>>'+ remainingrec);
        list<SOLIWrapper> prodwrapList = new list<SOLIWrapper>();
        
        if(remainingrec.size()==0)
        {
            Sales_Order__c SOToDelete = new Sales_Order__c();
            SOToDelete.id= soId;
            delete SOToDelete;
        }
        for(Sales_Order_Line_Items__c SOLI:remainingrec)
        {
            if(SOLI.Added_As_a_Label__c==false)
            {
                SOLIWrapper productobj = new SOLIWrapper();
                productobj.id = SOLI.id;
                productobj.SOid = SOLI.Sales_Order__c;
                productobj.Name=SOLI.Products__r.Name;
                productobj.Quantity=SOLI.Quantity__c;
                productobj.Color=SOLI.Colour__c;
                productobj.LocalSKU=SOLI.Local_SKU__c;
                productobj.Size=SOLI.Size__c;
                productobj.Description=SOLI.Product_Description__c;
                productobj.Productimage=SOLI.Product_image_url__c;
                productobj.PSBP=SOLI.Price_Specification_Book_Product__r.Name;
                productobj.boxquantity=SOLI.BOX_QTY__c;
                productobj.fullboxQty=SOLI.Full_Box_Order__c;                               //added by chandana for After delete in the cart to check boxqty 
                productobj.ShowBoxQty=SOLI.Sales_Order__r.Retailer_Code1__r.Show_Box_Qty__c; //Added 8 Jun 2023 Ivy Lee
                productobj.DisplayModel = SOLI.Price_Specification_Book_Product__r.DisplayModel__c; //Added 7 Jun 2023 Ivy Lee
                productobj.MOQ = SOLI.Price_Specification_Book_Product__r.MOQ__c;
                //If the user is perticular user then perticular price is set added By raghu on 15/11/2021 starts
                if(SOLI.Price_Product_by_Currency__r.MagNET_Price_Code__c != null){
                    productobj.TotalPriceByCurrency = (SOLI.Price_Product_by_Currency__r.UOM_Price__c) *  (Decimal.ValueOf(SOLI.Quantity__c) );
                }
                else {
                    productobj.TotalPriceByCurrency = (SOLI.Price_Specification_Book_Product__r.UOM_Price__c) *  (Decimal.ValueOf(SOLI.Quantity__c) ); 
                }
                system.debug(' productobj.TotalPriceByCurrency :::'+ productobj.TotalPriceByCurrency);
                productobj.CurrencyIsoCode = SOLI.CurrencyIsoCode;
                productobj.BlankString = '  ';
                // added By raghu on  15/11/2021 ends
                prodwrapList.add(productobj);
                system.debug('prodwrapList>>>'+prodwrapList);
            }
        }
        system.debug('prodwrapList>>'+prodwrapList);
        return prodwrapList;
    }
    
    // Delete all the products from Cart 
    @AuraEnabled
    public static void ClearCartDetails()//parameter => string customerId removed by Vidit
    {
        List<Sales_Order__c> SOobject=new List<Sales_Order__c>();
        Contact CustomerContact = UtilityClass.getCurrentUserContact(); 
        Id conId = CustomerContact.Id;
        
        SOobject =[select id, name, Retailer_Code1__c,Retailer__c,Product__r.Business_Vertical__c from Sales_Order__c where Supplier_Contact__c =: conId AND RecordtypeId =: CartRecordType limit 1];
        
        if(SOobject != null)
            delete SOobject;
        
    }
    //Added by seema 
    @AuraEnabled
    public static List<Sales_Order_Line_Items__c> checkLengthAddAndCloneDataToDelete(string customerid)    
    {
        List<Sales_Order_Line_Items__c> soli=[select id,Added_As_a_Label__c,Sales_Order__r.Supplier__c from Sales_Order_Line_Items__c where Added_As_a_Label__c=true And Sales_Order__r.Supplier__c=:customerid];
        system.debug('soli>>>>.'+soli);
        return soli;
    }   
    @AuraEnabled
    public static void checkAddAndCloneDataToDelete(string customerid)    
    {
        List<Sales_Order_Line_Items__c> soli=[select id,Added_As_a_Label__c,Sales_Order__r.Supplier__c from Sales_Order_Line_Items__c where Added_As_a_Label__c=true And Sales_Order__r.Supplier__c=:customerid];
        system.debug('soli>>>>.'+soli);
        delete soli;
    }
    // Update product to the cart
    @AuraEnabled 
    public static string updateCartValue(String solilistjson)
    {
        try{
            list<SOLIWrapper> prodwrapList = new list<SOLIWrapper>();
            list<Sales_Order_Line_Items__c> Solilist = new list<Sales_Order_Line_Items__c>();
            list<SOLIWrapper> solideserlist = (list<SOLIWrapper>)JSON.deserialize(solilistjson , list<SOLIWrapper>.class);
            
            for(SOLIWrapper SOLIwrap:solideserlist)
            {
                Sales_Order_Line_Items__c Soliobj = new Sales_Order_Line_Items__c();
                Soliobj.id = SOLIwrap.id;
                Soliobj.Ordered_Quantity__c=Integer.valueOf(SOLIwrap.Quantity);
                Soliobj.Supply_Quantity__c=SOLIwrap.Quantity;
                Soliobj.Remaining_Qty__c=Integer.valueOf(SOLIwrap.Quantity);
                Soliobj.Quantity__c=SOLIwrap.Quantity;
                Soliobj.Colour__c=SOLIwrap.Color;
                Soliobj.Local_SKU__c=SOLIwrap.LocalSKU;
                Soliobj.Size__c=SOLIwrap.Size;
                Soliobj.Remarks__c=SOLIwrap.Remarks;
                Solilist.add(Soliobj);
            }
            upsert Solilist;
            return 'SUCCESS';
        }
        catch (Exception e)
        {
            System.debug('e:::'+e);
            System.debug(LoggingLevel.ERROR, e.getMessage());
            return 'ERROR';
            // return e.getMessage();
        }
    }
    
    /*****************************************************************************************************************************************************/
    /***    Cart Ends | Order Starts    ***/
    /*****************************************************************************************************************************************************/
    //to convert PO to SO
    @AuraEnabled
    public static String convertPOstoSo(Sales_Order__c SO, String slctRec,Ship_Bill_Address__c BillAddress,Ship_Bill_Address__c shipAddress,Ship_Bill_Address__c invoiceAddress,Ship_Bill_Address__c buyerAddress,boolean suzhouFlag,boolean onlyvalidate)
    {
        String returnVal = '';
        if(!onlyvalidate){
            returnVal = 'Success';
        }
        system.debug('SO: '+SO+' BillAddress: '+BillAddress+' shipAddress: '+shipAddress+' invoiceAddress: '+invoiceAddress+' buyerAddress: '+buyerAddress+' suzhouFlag: '+suzhouFlag+  'onlyvalidate >>>>>'+onlyvalidate);
        system.debug('Company: '+SO.Company__c+' Retailer: '+SO.Retailer_Code1__c);
        
        //getting current user customer information Id
        contact contactid=UtilityClass.getCurrentUserContact();
        system.debug('Customer Info ID for Product>>>>'+contactid.Customer_Information__c); 
        List<Customer_Information__c> CustProdID=[select MagNET_Price_Code__c from Customer_Information__c where Id=: contactid.Customer_Information__c ];
        system.debug('Customer Info Product code>>>>'+CustProdID);
        
        String CompanyAPIName;
        Map<String,String> companyNameandAPI = UtilityClass.getOrderToCompanyPicklist(false);
        if(companyNameandAPI.containskey(SO.Company__c))
        {
            CompanyAPIName = companyNameandAPI.get(SO.Company__c);
        }
        
        String [] currencySplit = SO.CurrencyIsoCode.split('-');
        String ResCurr = currencySplit[0].trim();
        System.debug('currencySplit:'+ResCurr);
        SO.CurrencyIsoCode = ResCurr;
        
        String SupplierId;
        String RetailerId;
        List<Sales_Order__c> SOListToInsert = new List<Sales_Order__c>();
        List<Sales_Order_Line_Items__c>  SOLItoInsert = new List<Sales_Order_Line_Items__c>();
        List<PurchaseOrder__c>  POIDList = new List<PurchaseOrder__c>();
        POtoSOWrap SOWrapData = new POtoSOWrap();           //#2.1 ENH
        SOWrapData = POViewPageHandler.POtoSOConversion(slctRec);       //#2.1 ENH
        system.debug('SOWrapData>>: '+SOWrapData);
        
        if(SOWrapData==null)
        {
            returnVal = 'An error occured while converting Purchase Order to Sales Order. Please contact your adminstrator';
            return returnVal;
        }
        SOListToInsert = SOWrapData.SOList;
        SOLItoInsert = SOWrapData.SOLIList;
        Set<Id> seToPoIds = new Set<Id>();  //to store ids of POs
        for(PurchaseOrder__c POids:SOWrapData.PoList)
        {
            seToPoIds.add(POids.id);
        }   
        // code to fetch the custom setting and update ownerid by chandana  
        Map<string,CommunityConfiguration__c> ConfigSettings = CommunityConfiguration__c.getAll();
        CommunityConfiguration__c config = null;
        if(ConfigSettings.containsKey('CommunityConfiguration'))
        {
            config = ConfigSettings.get('CommunityConfiguration');
        }
        
        for(Sales_Order__c newSO : SOListToInsert)      //#2.1 ENH
        {
            newSO.OwnerId =config.SalesOrder_OwnerId__c;
            newSO.Expected_Delivery_Date__c = SO.Expected_Delivery_Date__c;
            newSO.Expected_Completion_Date__c = SO.Expected_Delivery_Date__c;
            
            newSO.Company__c = SO.Company__c;
            newSO.CurrencyIsoCode = SO.CurrencyIsoCode;
            newSO.Delivery_Instructions__c = SO.Delivery_Instructions__c;
            newSO.Factory_Internal_PO__c = SO.Factory_Internal_PO__c;
            newSO.Season__c = SO.Season__c;
            newSO.Season_Year__c = SO.Season_Year__c;
            newSO.Division__c = SO.Division__c;
            newSO.Brand_Label__c = SO.Brand_Label__c;
            newSO.Remarks__c = SO.Remarks__c;
            if(SO.Transportation_Details__c!=null && SO.Transportation_Details__c.contains('_space'))
                SO.Transportation_Details__c = SO.Transportation_Details__c.replace('_space', '\n');
            
            if(SO.Shipping_Mark__c!=null && SO.Shipping_Mark__c.contains('_space'))
                SO.Shipping_Mark__c = SO.Shipping_Mark__c.replace('_space', '\n');
            
            newSO.Transportation_Details__c = SO.Transportation_Details__c;
            newSO.Shipping_Mark__c = SO.Shipping_Mark__c;
            newSO.Manufacturer_Code__c = SO.Manufacturer_Code__c;
            newSO.Supplier_Code__c = SO.Supplier_Code__c;
            
            newSO = UtilityClass.assignBillToAdd(newSO,BillAddress);
            newSO = UtilityClass.assignShipToAdd(newSO,shipAddress);
            
            RetailerId = newSO.Retailer_Code1__c;
            SupplierId = newSO.Supplier__c;
            
            if(suzhouFlag == true && buyerAddress != null)
            {
                newSO.Buyer_Address__c = buyerAddress.Id;
            }
            if(suzhouFlag == true && invoiceAddress != null)
            {
                newSO.Invoice_To_Address__c = invoiceAddress.Id;
            }
        }
        system.debug('SOListToInsert>>: '+SOListToInsert);
        
        Set<string> customerRefModelSet = new Set<string>();    //to store set of customer ref model from POLI
        //to update dynamic fields
        List<PO_to_SO_field_Mapping__mdt> additionalFields = [Select id, API_in_PO__c, API_in_SO__c from PO_to_SO_field_Mapping__mdt];
        system.debug('additionalFields: '+additionalFields);
        if(additionalFields.size()>0)
        {
            DescribeSObjectResult describePOResult = Purchase_Order_LineItem__c.getSObjectType().getDescribe();
            String qryfields = ',';
            for(PO_to_SO_field_Mapping__mdt field :additionalFields)
            {
                if(describePOResult.fields.getMap().containsKey(field.API_in_PO__c))
                {
                    qryfields += field.API_in_PO__c+',';
                }
            }
            String query ='select id, name ';
            if(qryfields!=null)
                query+=qryfields;
            query+='Order_Number__c,Customer_Ref_Model__c from Purchase_Order_LineItem__c where Purchase_Order__c IN:seToPoIds';
            System.debug('query>>'+query);
            // return generic list of sobjects or typecast to expected type
            List<Purchase_Order_LineItem__c> PoLineList = Database.query( query );
            
            if(qryfields!=null)
            {
                Map<Id,Purchase_Order_LineItem__c> poliMap = new Map<Id,Purchase_Order_LineItem__c>();
                for(Purchase_Order_LineItem__c poli:PoLineList)
                {
                    poliMap.put(poli.Id,poli);
                    customerRefModelSet.add(poli.Customer_Ref_Model__c);
                }
                
                for(Sales_Order_Line_Items__c Soli:SOLItoInsert)
                {
                    System.debug('poli data>>'+poliMap.get((Id)Soli.POLI_Text_Ids__c));
                    for(PO_to_SO_field_Mapping__mdt field :additionalFields)
                    {
                        System.debug('poli data>>'+poliMap.get((Id)Soli.POLI_Text_Ids__c).get(field.API_in_PO__c));
                        Soli.put(field.API_in_SO__c,poliMap.get((Id)Soli.POLI_Text_Ids__c).get(field.API_in_PO__c) );
                        System.debug('Soli>>>'+Soli);
                    }
                    
                }
            }
        }
        //to update dynamic fields ends
        system.debug('customerRefModelSet>>'+customerRefModelSet);
        system.debug('customerRefModelSet.size()>>'+customerRefModelSet.size());
        if(customerRefModelSet.size()==0)
        {
            for(Sales_Order_Line_Items__c Soli:SOLItoInsert)
            {
                customerRefModelSet.add(Soli.Customer_Ref_Model__c);
            }
        }
        system.debug('customerRefModelSet>>>'+customerRefModelSet);
        
        //Special Price Starts | currency of customer and ERP customer code should match in product price by currency object
        Id billToRecordType = Schema.SObjectType.Ship_Bill_Address__c.getRecordTypeInfosByName().get('Bill To').getRecordTypeId();  //bill to records id of billtoShip to address object
        Id billToLockedRecordType = Schema.SObjectType.Ship_Bill_Address__c.getRecordTypeInfosByName().get('Bill to Locked').getRecordTypeId();  //bill to records id of billtoShip to address object
        system.debug('SupplierId>>>'+SupplierId);
        //to store customer code from Bill to ERP link object
        Set<String> ERPCustomerCode = new Set<String>();    
        //to store pricebook id from listofprod list
        Set<Id> pbIdSet = new Set<Id>();    
        for(Bill_to_ERP_Link__c ERPLink:[select id, name, Local_ERP_customer_code__c, Local_ERP_Payment_Code__c, Locked_Bill_To__c, Mainetti_Company__c, Mainetti_Company__r.name from Bill_to_ERP_Link__c where Parent_Bill_To__r.Customer_Information__c =: SupplierId and Parent_Bill_To__r.Is_Default__c =: true AND (Parent_Bill_To__r.RecordTypeId =: billToRecordType OR Parent_Bill_To__r.RecordTypeId =: billToLockedRecordType)])
        {
            ERPCustomerCode.add(ERPLink.Local_ERP_customer_code__c);
        }
        system.debug('ERPCustomerCode>>>'+ERPCustomerCode);
        
        //pricebook data accumlation
        Map<String,Map<String,Price_Specification_Book_Product__c>> proColourPriceBookMap = new Map<String,Map<String,Price_Specification_Book_Product__c>>();  //cust ref model => color =>pricebook data
        List<Price_Specification_Book_Product__c> priceBookProList =  new List<Price_Specification_Book_Product__c>();
        priceBookProList=[select Id,Name,MOQ__c, Product_Unique_ID__c, Description__c, Order_to_Company__c, Print_Shop__c, Retailer_Code__c, Color__c, Customer_Ref_Model__c, Local_SKU__c, BOX_QTY__c, USD_Rebate_pc__c, EUR_Rebate_pc__c, USD_Reuse_Rebate_pc__c, EUR_Reuse_Rebate_pc__c,Product_image_url__c, Sizer_Print__c, Product_Family__c
                          from Price_Specification_Book_Product__c
                          where Active__c = true and  Product_Unique_ID__r.Status__c=:'Active' and Retailer_Code__c =:RetailerId
                          and Order_to_Company__c =:CompanyAPIName AND Customer_Ref_Model__c IN: customerRefModelSet];
        
        system.debug('priceBookProList>>>'+priceBookProList);
        for(Price_Specification_Book_Product__c PSBP :priceBookProList)
        {
            system.debug('PSBP>>>'+PSBP);
            if(proColourPriceBookMap.containskey(PSBP.Customer_Ref_Model__c))
            {
                system.debug('inside outer if');
                Map<String,Price_Specification_Book_Product__c> tempcolorPbMap = new Map<String,Price_Specification_Book_Product__c>();
                tempcolorPbMap = proColourPriceBookMap.get(PSBP.Customer_Ref_Model__c);
                if(tempcolorPbMap.containskey(PSBP.Color__c.toLowerCase()))
                {
                    system.debug('inside if');
                    System.debug(' Assuming there will colors will not repeat for same product ');
                }
                else
                {
                    system.debug('inside else');
                    tempcolorPbMap.put(PSBP.Color__c.toLowerCase(),PSBP);
                    proColourPriceBookMap.put(PSBP.Customer_Ref_Model__c,tempcolorPbMap);
                }
            }
            else
            {
                system.debug('inside outer else');
                Map<String,Price_Specification_Book_Product__c> tempcolorPbMap = new Map<String,Price_Specification_Book_Product__c>();
                tempcolorPbMap.put(PSBP.Color__c.toLowerCase(),PSBP);
                proColourPriceBookMap.put(PSBP.Customer_Ref_Model__c,tempcolorPbMap);
            }
            system.debug('proColourPriceBookMap>>>'+proColourPriceBookMap);
            pbIdSet.add(psbp.Id);
        }
        // system.debug('proColourPriceBookMap: '+proColourPriceBookMap);
        
        //Map<Id,Price_Product_by_Currency__c> pbIdSpecialPriceMap = new Map<Id,Price_Product_by_Currency__c>();  //key=> pbsp id and value => special product price for customer
        Map<Id,Price_Product_by_Currency__c> priceBookCurrencyMap = new Map<Id,Price_Product_by_Currency__c>();
        Map<Id,Price_Product_by_Currency__c> pbIdSpecialDiscountPriceMap = new Map<Id,Price_Product_by_Currency__c>();  //Key=> Product ID and Value => Maagnet Price code for Customer
        for(Price_Product_by_Currency__c procurr : [select id,name, CurrencyIsoCode, Local_ERP_customer_code__c, Price_100_pcs__c, Price_1000_pcs__c,Price_Book_Product__c,MagNET_Price_Code__c from Price_Product_by_Currency__c where Price_Book_Product__c IN:pbIdSet AND CurrencyIsoCode =:SO.CurrencyIsoCode ])
        {
            IF(procurr.MagNET_Price_Code__c == null || procurr.MagNET_Price_Code__c == ''){
                priceBookCurrencyMap.put(procurr.Price_Book_Product__c,procurr);
            }
            //priceBookCurrencyMap.put(procurr.Price_Book_Product__c,procurr);
            
            system.debug('ERPCustomerCode: '+ERPCustomerCode.contains(procurr.Local_ERP_customer_code__c));
            /*if(SO.CurrencyIsoCode.contains(procurr.CurrencyIsoCode) && ERPCustomerCode.contains(procurr.Local_ERP_customer_code__c) )    //if special price is defined for current customer
{
pbIdSpecialPriceMap.put(procurr.Price_Book_Product__c,procurr);
}
else*/ if(SO.CurrencyIsoCode.contains(procurr.CurrencyIsoCode) && procurr.MagNET_Price_Code__c == CustProdID[0].MagNET_Price_Code__c){
    pbIdSpecialDiscountPriceMap.put(procurr.Price_Book_Product__c,procurr);
}
        }
        system.debug('priceBookCurrencyMap: '+priceBookCurrencyMap);
        //system.debug('pbIdSpecialPriceMap: '+pbIdSpecialPriceMap);
        
        //pricebook data ends
        
        //to show pricebook validation in UI, added on 21 Aug 2019
        List<Retailer_Code__c> retailerVal= [select id,name,Full_Box_Order__c from Retailer_Code__c where Id =: RetailerId]; //Added for SO getting saved if SOLI BOX_quantity is missing.04/06/2021 
        for(Sales_Order_Line_Items__c Soli:SOLItoInsert)
        {
            if(proColourPriceBookMap.containskey(Soli.Customer_Ref_Model__c) )
            {
                system.debug('pricebook for matched product: '+proColourPriceBookMap.get(Soli.Customer_Ref_Model__c));
                Map<String,Price_Specification_Book_Product__c> tempcolorPbMap = proColourPriceBookMap.get(Soli.Customer_Ref_Model__c);
                //If condition is added on 11-04-22 to Handle the null exception if Soli.Colour__c value is null
                if(Soli.Colour__c != null){
                    if( tempcolorPbMap.containskey(Soli.Colour__c.toLowerCase()) )
                    {
                        Soli.Price_Specification_Book_Product__c = tempcolorPbMap.get(Soli.Colour__c.toLowerCase()).Id;
                        
                        //SO getting saved if SOLI BOX_quantity is missing.04/06/2021
                        if(tempcolorPbMap.get(Soli.Colour__c.toLowerCase()).BOX_QTY__c == null)
                            tempcolorPbMap.get(Soli.Colour__c.toLowerCase()).BOX_QTY__c = 0;
                        Integer tempBoxQty = Integer.ValueOf(tempcolorPbMap.get(Soli.Colour__c.toLowerCase()).BOX_QTY__c);
                        if( retailerVal[0].Full_Box_Order__c == true && tempBoxQty == 0 )
                        {
                            returnVal = 'Couldn\'t find box quantity in the Price specification book for Customer Ref Model '+Soli.Customer_Ref_Model__c+ ' with color '+Soli.Colour__c;
                            return returnVal;
                        }
                    }
                    else
                    {
                        returnVal = 'Cannot find Price specification book for Customer Ref Model '+Soli.Customer_Ref_Model__c+ ' with color '+Soli.Colour__c;
                        return returnVal;
                    }
                    if(Soli.Customer_Ref_Model__c == tempcolorPbMap.get(Soli.Colour__c.toLowerCase()).Customer_Ref_Model__c)
                    {
                        
                    }
                    else
                    {
                        returnVal = 'Cannot find Price specification book for Customer Ref Model '+Soli.Customer_Ref_Model__c;
                        return returnVal;
                    }
                }
                //to Handle exception if Soli.Color__c value is null
                else{ 
                    returnVal = 'Cannot find Price specification book for Customer Ref Model '+Soli.Customer_Ref_Model__c+ ' WITHOUT Color ';
                    return returnVal;
                }
                
                
            }
            else
            {
                returnVal = 'Cannot find Price specification book for Customer Ref Model '+Soli.Customer_Ref_Model__c;
                return returnVal;
            }
            system.debug('pricebook in soli: '+Soli.Price_Specification_Book_Product__c);
            /*if(pbIdSpecialPriceMap.containskey(Soli.Price_Specification_Book_Product__c))
{

}
else*/ if(priceBookCurrencyMap.containskey(Soli.Price_Specification_Book_Product__c))
{
    
}
            else
            {
                Soli.Price_per_100_pc__c = 0;
                returnVal = 'Couldn\'t find Price Price Product By Currency for currency '+SO.CurrencyIsoCode;
                return returnVal;
            }
        }
        system.debug('Inside checkonly true');
        //inserting sales order
        if(!onlyvalidate){
            system.debug('Inside checkonly true');
            system.debug(' 1247 Before Insert SOListToInsert: '+SOListToInsert);
            insert SOListToInsert;
        }
        
        //#2.1 ENH
        Map<Id,Sales_Order__c> SalesOrderMap = new Map<Id,Sales_Order__c>();    //key => so id, Value => so rec
        Map<Id,Id> PoIdnSoIdMap = new Map<Id,Id>(); //key => po id, Value => so id
        String soIdForEmail = '';
        for(Sales_Order__c newSO : SOListToInsert)
        {
            SalesOrderMap.put(newSO.Id,newSO);
            PoIdnSoIdMap.put(newSO.Purchase_Order__c,newSO.Id);
            soIdForEmail += newSO.Id+',';
        }
        system.debug('SalesOrderMap: '+SalesOrderMap);
        system.debug('PoIdnSoIdMap: '+PoIdnSoIdMap);
        
        //#2.1 ENH
        List<Retailer_Code__c> retailer= [select id,name,Full_Box_Order__c from Retailer_Code__c where Id =: RetailerId];
        system.debug('retailer: '+retailer);
        //Order Lines validations
        String boxQtyChangeAlert;
        boolean isMOQMissing = false;
        for(Sales_Order_Line_Items__c Soli:SOLItoInsert)
        {
            system.debug('poli id: '+Soli.POLI_Text_Ids__c);
            system.debug('containskey poli id: '+SOWrapData.PoliPOIdMap.containsKey((Id)Soli.POLI_Text_Ids__c));
            system.debug('contains po id: '+PoIdnSoIdMap.get(SOWrapData.PoliPOIdMap.get((Id)Soli.POLI_Text_Ids__c).Purchase_Order__c));
            Soli.Sales_Order__c = PoIdnSoIdMap.get(SOWrapData.PoliPOIdMap.get((Id)Soli.POLI_Text_Ids__c).Purchase_Order__c);
            Soli.CurrencyIsoCode = SalesOrderMap.get(Soli.Sales_Order__c).CurrencyIsoCode;  //#2.1 ENH
            //Soli.Expected_Delivery_Date__c = SOtoInsert.Expected_Delivery_Date__c;
            if(proColourPriceBookMap.containskey(Soli.Customer_Ref_Model__c) )
            {
                Map<String,Price_Specification_Book_Product__c> tempcolorPbMap = proColourPriceBookMap.get(Soli.Customer_Ref_Model__c);
                //If condition is added on 13-04-22 to Handle the null exception if Soli.Colour__c value is null
                if(Soli.Colour__c != null){
                    if(tempcolorPbMap.containskey(Soli.Colour__c.toLowerCase()) )
                    {
                        Soli.Price_Specification_Book_Product__c = tempcolorPbMap.get(Soli.Colour__c.toLowerCase()).Id;
                        Soli.Product_Description__c = tempcolorPbMap.get(Soli.Colour__c.toLowerCase()).Description__c;
                        Soli.Products__c = tempcolorPbMap.get(Soli.Colour__c.toLowerCase()).Product_Unique_ID__c;
                        Soli.Printshop_Pick__c = tempcolorPbMap.get(Soli.Colour__c.toLowerCase()).Print_Shop__c;
                        Soli.Local_SKU__c = tempcolorPbMap.get(Soli.Colour__c.toLowerCase()).Local_SKU__c;
                        Soli.USD_Rebate_pc__c = tempcolorPbMap.get(Soli.Colour__c.toLowerCase()).USD_Rebate_pc__c;
                        Soli.EUR_Rebate_pc__c = tempcolorPbMap.get(Soli.Colour__c.toLowerCase()).EUR_Rebate_pc__c;
                        Soli.USD_Reuse_Rebate_pc__c = tempcolorPbMap.get(Soli.Colour__c.toLowerCase()).USD_Reuse_Rebate_pc__c;
                        Soli.EUR_Reuse_Rebate_pc__c = tempcolorPbMap.get(Soli.Colour__c.toLowerCase()).EUR_Reuse_Rebate_pc__c;
                        Soli.Product_image_url__c = tempcolorPbMap.get(Soli.Colour__c.toLowerCase()).Product_image_url__c;
                        Soli.Print__c = tempcolorPbMap.get(Soli.Colour__c.toLowerCase()).Sizer_Print__c;
                        Soli.Family__c = tempcolorPbMap.get(Soli.Colour__c.toLowerCase()).Product_Family__c;
                        Integer tempQty = Integer.ValueOf(Soli.Supply_Quantity__c);
                          system.debug('tempQty >>>>>>>'+tempQty);
                        if(tempcolorPbMap.get(Soli.Colour__c.toLowerCase()).BOX_QTY__c == null)
                            tempcolorPbMap.get(Soli.Colour__c.toLowerCase()).BOX_QTY__c = 0;
                        Integer tempBoxQty ;
                          tempBoxQty  = Integer.ValueOf(tempcolorPbMap.get(Soli.Colour__c.toLowerCase()).BOX_QTY__c);
                        system.debug('tempBoxQty >>>>>>>'+tempBoxQty);
                         if(tempBoxQty == null){
                            tempBoxQty = 0;
                        }
                          Integer tempMOQQty;
                              tempMOQQty = Integer.ValueOf(tempcolorPbMap.get(Soli.Colour__c.toLowerCase()).MOQ__c);
                        system.debug('tempMOQQty >>>>>>>'+tempMOQQty);
                        if(tempMOQQty == null){
                            tempMOQQty = 0;
                        }

                        
                        //added on 17 Mar 2020 to populate values even if correction in qty is not required
                        Soli.Full_Box_Order__c = retailer[0].Full_Box_Order__c;
                        if(Soli.Full_Box_Order__c)
                            Soli.BOX_QTY__c = tempBoxQty;
                        
                        if( retailer[0].Full_Box_Order__c == true && tempBoxQty == 0 )
                        {
                            returnVal = 'Couldn\'t find box quantity in the Price specification book for Customer Ref Model '+Soli.Customer_Ref_Model__c+ ' with color '+Soli.Colour__c;
                            return returnVal;
                        }
                       /* if(!onlyvalidate){
                            if( retailer[0].Full_Box_Order__c == true && tempBoxQty != null && (math.mod(tempQty, tempBoxQty)) != 0 )
                            {
                                
                                //system.debug('Soli.Remaining_Qty__c: '+Soli.Remaining_Qty__c);
                                //system.debug('boxQty: '+tempcolorPbMap.get(Soli.Colour__c.toLowerCase()).BOX_QTY__c);
                                system.debug('poli name: '+SOWrapData.PoliPOIdMap.get((Id)Soli.POLI_Text_Ids__c));
                                Double vboxQty = (Math.ceil(Soli.Remaining_Qty__c/tempcolorPbMap.get(Soli.Colour__c.toLowerCase()).BOX_QTY__c))*tempcolorPbMap.get(Soli.Colour__c.toLowerCase()).BOX_QTY__c;
                                Soli.Quantity__c = String.ValueOf(Integer.ValueOf(vboxQty));    //text
                                Soli.Ordered_Quantity__c = Integer.ValueOf(vboxQty);    //number
                                Soli.Supply_Quantity_num__c = Integer.ValueOf(vboxQty); //number
                                Soli.Remaining_Qty__c = Integer.ValueOf(vboxQty);   //number
                                Soli.Supply_Quantity__c = String.ValueOf(Integer.ValueOf(vboxQty)); //text
                                if(boxQtyChangeAlert == null)
                                    boxQtyChangeAlert = 'Order quantity of '+Soli.Customer_Ref_Model__c+' in '+SOWrapData.PoliPOIdMap.get((Id)Soli.POLI_Text_Ids__c).Name+' is changed to '+String.ValueOf(Integer.ValueOf(vboxQty));
                                else
                                    boxQtyChangeAlert = ' And Order quantity of '+Soli.Customer_Ref_Model__c+' in '+SOWrapData.PoliPOIdMap.get((Id)Soli.POLI_Text_Ids__c).Name+' is changed to '+String.ValueOf(Integer.ValueOf(vboxQty));
                                
                            }
                        }
                                              if(tempMOQQty > tempQty ){
                            system.debug('Inside Minimum order Quantity');
                            if(!onlyvalidate){
                                Soli.Quantity__c = String.valueof(tempMOQQty);    //text
                                Soli.Ordered_Quantity__c = tempMOQQty;    //number
                                Soli.Supply_Quantity_num__c = tempMOQQty; //number
                                Soli.Remaining_Qty__c = tempMOQQty;   //number
                                Soli.Supply_Quantity__c = String.valueof(tempMOQQty); //text
                            }else{
                                
                                isMOQMissing = true;
                                returnVal += 'The Order quantity of '+Soli.Customer_Ref_Model__c +' is less than Minimum Order Quantity '+tempMOQQty+'\n';
                                // return   returnVal;    
                            }
                        }*/
                        
                        
                        //if(tempQty < tempMOQQty)
                        //{
                        integer MoqNFullBoxqty;
                        if(retailer[0].Full_Box_Order__c == true){
                            if(!(tempQty >= tempMOQQty)){
                                if(tempBoxQty > 0){
                                    decimal mathmodval = math.mod(tempMOQQty, tempBoxQty);
                                    system.debug('mathmodval >>>>>>'+mathmodval);
                                    if(mathmodval == 0){
                                        MoqNFullBoxqty = ((integer)math.ceil(tempMOQQty/ tempBoxQty))*tempBoxQty;
                                        system.debug('MoqNFullBoxqty >>>>>>'+MoqNFullBoxqty);
                                        if(onlyvalidate){
                                            isMOQMissing = true;
                                            returnVal +=  'The Order quantity of  '+Soli.Customer_Ref_Model__c+' is less than Minimum Order Quantity '+tempMOQQty+'.The nearest multiples of box quantity is '+MoqNFullBoxqty+'\n';
                                        }
                                    }
                                    else{//When tempMOQQty is not evenly divisible by tempBoxQty
                                        for(integer i =1 ; i<=500 ;i++){
                                            integer tempVal = i*tempBoxQty;
                                            system.debug('tempVal >>>>>>'+tempVal);
                                            integer mathmodceilval = (integer)math.ceil(tempMOQQty/ tempVal);
                                            system.debug('mathmodceilval >>>>>>'+mathmodceilval);
                                            
                                            if(mathmodceilval == 0 ){
                                                MoqNFullBoxqty = tempVal;
                                                system.debug('MoqNFullBoxqty inside Input Qty is Less than MOQ >>>>>>'+MoqNFullBoxqty);
                                                if(onlyvalidate){
                                                    isMOQMissing = true;
                                                    returnVal +='The Order quantity of  '+Soli.Customer_Ref_Model__c+' is less than Minimum Order Quantity '+tempMOQQty+'.The nearest multiples of box quantity is '+MoqNFullBoxqty+'\n';
                                                }
                                                break;
                                            }
                                        }
                                    }
                                }
                                else{//When BoxQty is Zero
                                    MoqNFullBoxqty = tempMOQQty;
                                    system.debug(' MoqNFullBoxqty>>>>>'+MoqNFullBoxqty);
                                    if(onlyvalidate){
                                        isMOQMissing = true;
                                        returnVal += 'The Order quantity of '+ Soli.Customer_Ref_Model__c+'  is less than Minimum Order Quantity '+MoqNFullBoxqty+'\n';
                                    }
                                    
                                }
                            }
                            else{//When InputQty is Less than MOQ
                                if(tempBoxQty > 0){
                                    decimal mathmodval = math.mod(tempQty, tempBoxQty);
                                    system.debug('mathmodval >>>>>>'+mathmodval);
                                    if(mathmodval == 0){
                                        MoqNFullBoxqty = ((integer)math.ceil(tempQty/ tempBoxQty))*tempBoxQty;
                                        system.debug('MoqNFullBoxqty >>>>>>'+MoqNFullBoxqty);
                                        if(onlyvalidate && tempQty != tempBoxQty){
                                            if(!(tempQty > tempBoxQty)){
                                            isMOQMissing = true;
                                            returnVal += 'The Order quantity of '+ Soli.Customer_Ref_Model__c+'  should match the Full Box Quantity.The nearest multiples of box quantity is '+MoqNFullBoxqty+'\n';
                                            }
                                            }
                                    }
                                    else{//When tempMOQQty is not evenly divisible by tempBoxQty
                                        for(integer i =1 ; i<=500 ;i++){
                                            integer tempVal = i*tempBoxQty;
                                            system.debug('tempVal >>>>>>'+tempVal);
                                            integer mathmodceilval = (integer)math.ceil(tempQty/ tempVal);
                                            system.debug('mathmodceilval >>>>>>'+mathmodceilval);
                                            
                                            if(mathmodceilval == 0 ){
                                                MoqNFullBoxqty = tempVal;
                                                system.debug('MoqNFullBoxqty inside Input Qty is Less than MOQ >>>>>>'+MoqNFullBoxqty);
                                                if(onlyvalidate){
                                                     if(!(tempQty > tempBoxQty)){
                                                    isMOQMissing = true;
                                                    returnVal += 'The Order quantity of '+Soli.Customer_Ref_Model__c+'  is less than Full Box Quantity.The nearest multiples of box quantity is '+MoqNFullBoxqty+'\n';
                                                     }
                                                    else{
                                                         isMOQMissing = true;
                                                    returnVal += 'The Order quantity of '+Soli.Customer_Ref_Model__c+' should match the Full Box Quantity.The nearest multiples of box quantity is '+MoqNFullBoxqty+'\n';
                                                   
                                                    }
                                                     }
                                                break;
                                            }
                                        }
                                    } 
                                }
                                else{//When BoxQty is Zero
                                    MoqNFullBoxqty = tempQty;
                                    system.debug(' MoqNFullBoxqty>>>>>'+MoqNFullBoxqty);
                                    
                                }
                            }
                        }
                        else{
                            if(tempMOQQty > 0){
                                if(!(tempQty > tempMOQQty)){
                                    MoqNFullBoxqty = tempMOQQty;
                                    if(onlyvalidate){
                                        isMOQMissing = true;
                                        returnVal += 'The Order quantity of '+Soli.Customer_Ref_Model__c+' is less than Minimum Order Quantity'+MoqNFullBoxqty+'\n';
                                        system.debug('MoqNFullBoxqty>>>>>>'+MoqNFullBoxqty);
                                    }
                                }
                                else{
                                    MoqNFullBoxqty = tempQty;
                                    system.debug('MoqNFullBoxqty>>>>>>'+MoqNFullBoxqty);
                                }
                            }
                            else{
                                MoqNFullBoxqty = tempQty;
                                system.debug('MoqNFullBoxqty>>>>>>'+MoqNFullBoxqty);
                            }
                            
                        }
                        system.debug('MoqNFullBoxqty>>>>>>'+MoqNFullBoxqty);
                        if(!onlyvalidate){
                            Soli.Quantity__c = String.valueof(MoqNFullBoxqty);    //text
                            Soli.Ordered_Quantity__c = MoqNFullBoxqty;    //number
                            Soli.Supply_Quantity_num__c = MoqNFullBoxqty; //number
                            Soli.Remaining_Qty__c = MoqNFullBoxqty;   //number
                            Soli.Supply_Quantity__c = String.valueof(MoqNFullBoxqty); //text
                        }
                        // }    
                        
                        
                        
                    }
                    else
                    {
                        returnVal = 'Couldn\'t find Price specification book for Customer Ref Model '+Soli.Customer_Ref_Model__c+ ' with color '+Soli.Colour__c;
                        return returnVal;
                    }
                }
                //To handle the Exception if Soli.Color__c value is null
                else{
                    returnVal = 'Cannot find Price specification book for Customer Ref Model '+Soli.Customer_Ref_Model__c+ ' WITHOUT color ';
                    return returnVal;
                }
            }
            system.debug('psbp: '+Soli.Price_Specification_Book_Product__c);
            /*if(pbIdSpecialPriceMap.containskey(Soli.Price_Specification_Book_Product__c))
{
Soli.Price_Product_by_Currency__c = pbIdSpecialPriceMap.get(Soli.Price_Specification_Book_Product__c).Id;
Soli.Price_per_100_pc__c = pbIdSpecialPriceMap.get(Soli.Price_Specification_Book_Product__c).Price_100_pcs__c;
Soli.Price_100_pcs__c =String.valueof(pbIdSpecialPriceMap.get(Soli.Price_Specification_Book_Product__c).Price_100_pcs__c);
Soli.Price_1000_pcs__c =String.valueof((pbIdSpecialPriceMap.get(Soli.Price_Specification_Book_Product__c).Price_100_pcs__c)*10);
}
else*/ if(pbIdSpecialDiscountPriceMap.containskey(Soli.Price_Specification_Book_Product__c)){
    Soli.Price_Product_by_Currency__c = pbIdSpecialDiscountPriceMap.get(Soli.Price_Specification_Book_Product__c).Id;
    Soli.Price_per_100_pc__c = pbIdSpecialDiscountPriceMap.get(Soli.Price_Specification_Book_Product__c).Price_100_pcs__c;
    Soli.Price_100_pcs__c =String.valueof(pbIdSpecialDiscountPriceMap.get(Soli.Price_Specification_Book_Product__c).Price_100_pcs__c);
    Soli.Price_1000_pcs__c =String.valueof((pbIdSpecialDiscountPriceMap.get(Soli.Price_Specification_Book_Product__c).Price_100_pcs__c)*10);
}
            else if(priceBookCurrencyMap.containskey(Soli.Price_Specification_Book_Product__c))
            {
                Soli.Price_Product_by_Currency__c = priceBookCurrencyMap.get(Soli.Price_Specification_Book_Product__c).Id;
                Soli.Price_per_100_pc__c = priceBookCurrencyMap.get(Soli.Price_Specification_Book_Product__c).Price_100_pcs__c;
                Soli.Price_100_pcs__c =String.valueof(priceBookCurrencyMap.get(Soli.Price_Specification_Book_Product__c).Price_100_pcs__c);
                Soli.Price_1000_pcs__c =String.valueof((priceBookCurrencyMap.get(Soli.Price_Specification_Book_Product__c).Price_100_pcs__c)*10);
            }
            else
            {
                Soli.Price_per_100_pc__c = 0;
                returnVal = 'Couldn\'t find Price Price Product By Currency for currency '+SO.CurrencyIsoCode;
                return returnVal;
            }
            
            Soli.Expected_Delivery_Date__c = SalesOrderMap.get(Soli.Sales_Order__c).Expected_Delivery_Date__c;  //added on 16 Dec 2019
            Soli.Expected_Completion_Date__c = SalesOrderMap.get(Soli.Sales_Order__c).Expected_Delivery_Date__c;    //added on 16 Dec 2019
        }
        system.debug('Inside checkonly true');
        if(!onlyvalidate){
            system.debug('Inside checkonly true');
            system.debug('Before insert SOLItoInsert: '+SOLItoInsert);
            system.debug('Before SOLItoInsert Name: '+SOLItoInsert[0].Name);
            insert SOLItoInsert;
            system.debug('SOLItoInsert: '+SOLItoInsert[0].Name);
        }
        Set<String> SoIdsforName =new Set<String>();
        for(Sales_Order__c newSO : SOListToInsert)
        {
            SoIdsforName.add(newSO.id);
            
        }
        system.debug('SoIdsforName: '+SoIdsforName);
        /* code for RFID generation by Alvin*/
        if(!onlyvalidate){
            Set<Id> Ids_1 = (new Map<Id,Sales_Order_Line_Items__c>(SOLItoInsert)).keySet();
            List<Sales_Order_Line_Items__c> SoliList_1 = [select id, name, Sales_Order__c, Sales_Order__r.Retailer_Code1__c, Supply_Quantity__c, Quantity__c, Expected_Delivery_Date__c, Status__c, Price_Product_by_Currency__c,Online_Detail_Status__c, Price_Product_by_Currency__r.Price_100_pcs__c, Price_Specification_Book_Product__r.USD_Rebate_pc__c, Price_Specification_Book_Product__r.EUR_Rebate_pc__c, Price_Specification_Book_Product__r.USD_Reuse_Rebate_pc__c, Price_Specification_Book_Product__r.EUR_Reuse_Rebate_pc__c,Price_Specification_Book_Product__r.RFIDSerial__c  from Sales_Order_Line_Items__c where Id IN :Ids_1];
            //SoliList_2 =[select Id,Price_Specification_Book_Product__r.RFIDSerial__c , Start_Num__c from Sales_Order_Line_Items__c where Id IN resultIds];
            Boolean IsRevised1 = false;
            Map<Sales_Order_Line_Items__c,boolean> ReviseMap1;
            string retailcode1 = SO.Retailer_Code1__c;
            System.enqueueJob(new RFIDNumGeneartion(SoliList_1, IsRevised1,ReviseMap1,retailcode1));
        }
        /* code for RFID generation END*/ 
        
        if(boxQtyChangeAlert!=null)
        {
            returnVal = 'Quantity is updated to nearest Box Quantity value.';
        }
        system.debug('returnVal: '+returnVal);
        system.debug('isMOQMissing: '+isMOQMissing);
        if(isMOQMissing){
            returnVal += 'Click Ok to Place the Order with Minimum Order Quantity and Full Box Quantity.';
            return returnVal;
        }
        
        for(PurchaseOrder__c po:SOWrapData.PoList)
        {
            po.SO__c = PoIdnSoIdMap.get(po.Id);
            //po.SO_Num__c = newCommonSO.Name;
        }
        system.debug('Inside checkonly true');
        if(!onlyvalidate){
            system.debug('Inside checkonly true');
            // system.debug('1390 Before Upadte SOWrapData.PoList: '+SOWrapData.PoList);
            update SOWrapData.PoList;
            // system.debug('1392 Before Upadte SOWrapData.PoliPOIdMap.values(): '+SOWrapData.PoliPOIdMap.values());
            update SOWrapData.PoliPOIdMap.values();
            //System.debug('after update POupdate>>>>>>'+SOWrapData.PoList.size()+SOWrapData.PoList);
            List<String> listStringsSOids = new List<String>(SoIdsforName);
            // System.debug('listStringsSOids>>>>>>'+listStringsSOids);
            SOController.toupdateSalesOrderList(listStringsSOids);
            //to send email to retailers
            adminEmailAfterPOtoSOconversion(SalesOrderMap);
            
            returnVal += ' Id='+soIdForEmail.substringBeforeLast(',');
        }
        return returnVal;
    }
    
    //This method Updates the Sales Order List ,when a sales order is created and shows the SO history in PO and POLI records
    @AuraEnabled
    public static void toupdateSalesOrderList( List<String> SOids)
    {
        List<Sales_Order__c> SOList = new List<Sales_Order__c>();
        List<Sales_Order_Line_Items__c>  newSOLIList = new List<Sales_Order_Line_Items__c>();
        List<PurchaseOrder__c> PO = new List<PurchaseOrder__c>();
        List<PurchaseOrder__c> PurchaseOrders = new List<PurchaseOrder__c>();
        List<Purchase_Order_LineItem__c> POLI = new  List<Purchase_Order_LineItem__c>();
        List<Purchase_Order_LineItem__c> POLIList = new  List<Purchase_Order_LineItem__c>();
        Set<String> POidsList = new Set<String>();
        SOList = [Select Id,Name,Purchase_Orders__c From Sales_Order__c WhERE Id IN :SOids];
        system.debug('SOList ::'+SOList);
        Map<Id,String> PONameMap = new  Map<Id,String>();
        List<String> lstPOids = new List<String>();
        for(Sales_Order__c SO : SOList){
            PONameMap.put(SO.id, SO.Name);   
        }
        system.debug('PONameMap ::'+PONameMap);
        // Query to Update PO Sales Order List 
        PO = [Select Id , SO__c ,Status__c,Sales_Order_List__c,Converted_PO__c From PurchaseOrder__c where SO__c IN :SOids];
        system.debug('PO ::'+PO);
        for(PurchaseOrder__c POList :PO)
        {
            POList.Converted_PO__c = True;
            if(String.isBlank(POList.Sales_Order_List__c)){
                POList.Sales_Order_List__c = PONameMap.get(POList.SO__c) + ',';
                system.debug('After  POList.Sales_Order_List__c ::::'+ POList.Sales_Order_List__c);
                
            }
            else{
                POList.Sales_Order_List__c += PONameMap.get(POList.SO__c) + ',';
                system.debug('After  POList.Sales_Order_List__c ::::'+ POList.Sales_Order_List__c);
            } 
        }
        system.debug('After  PO ::::'+ PO);
        
        newSOLIList = [Select Id ,Sales_Order__c, Status__c,Purchase_Order_LineItem__c,POLI_Text_Name__c From Sales_Order_Line_Items__c where Sales_Order__c IN :SOids];
        system.debug('newSOLIList ::'+newSOLIList);
        List<String> lstPOLIids = new List<String>();
        for(Sales_Order_Line_Items__c soliIds :newSOLIList){
            if(soliIds.POLI_Text_Name__c != Null){
                String POLIids = soliIds.POLI_Text_Name__c;
                system.debug('POLIids ::'+POLIids);
                lstPOLIids.addAll(POLIids.split(','));
                system.debug('lstPOLIids ::'+lstPOLIids);
            }
        }
        Id UserId=UserInfo.getUserId();
        System.debug('UserId in storingPoCheckbox>>>>>>>>>>>'+UserId);
        // Query to Update POLI Sales Order List 
        POLI = [Select Id ,Status__c,Purchase_Order__c ,Purchase_Order__r.SO__c ,Purchase_Order__r.Status__c ,Sales_Order_List__c,UserId__c From Purchase_Order_LineItem__c Where Name IN : lstPOLIids];
        system.debug('POLI ::'+POLI);
        for(Purchase_Order_LineItem__c lstPOLi :POLI)
        {
            
            lstPOLi.UserId__c=UserId;
            if(String.isBlank(lstPOLi.Sales_Order_List__c)){
                if(PONameMap.get(lstPOLi.Purchase_Order__r.SO__c) != null){
                    lstPOLi.Sales_Order_List__c = PONameMap.get(lstPOLi.Purchase_Order__r.SO__c) + ',';
                    system.debug('After  lstPOLi.Sales_Order_List__c ::::'+ lstPOLi.Sales_Order_List__c);
                }
            }
            else{
                if(PONameMap.get(lstPOLi.Purchase_Order__r.SO__c) != null){
                    lstPOLi.Sales_Order_List__c += PONameMap.get(lstPOLi.Purchase_Order__r.SO__c) + ',';
                    system.debug('After  lstPOLi.Sales_Order_List__c ::::'+ lstPOLi.Sales_Order_List__c);
                }
            }
        }
        system.debug('After  POLI ::::'+ POLI);
        try{
            update POLI;   
            update PO;
        }
        catch (Exception e)
        {
            System.debug('The following exception has occurred::' + e);
        }
        
        // Query to Update PO Status 'Open' when POLI Status is 'Open'
        
        POLIList = [Select Id ,Status__c,Purchase_Order__c ,Purchase_Order__r.SO__c,UserId__c From Purchase_Order_LineItem__c Where Purchase_Order__r.SO__c IN : SOids];
        system.debug('POLIList ::'+POLIList);
        for(Purchase_Order_LineItem__c lstPOLi :POLIList)
        {
            if(lstPOLi.Status__c=='Open'){
                POidsList.add(lstPOLi.Purchase_Order__c);
            }
        }
        system.debug('POidsList 1 ::'+POidsList);
        PurchaseOrders = [Select Id , SO__c ,Status__c,Sales_Order_List__c,Converted_PO__c From PurchaseOrder__c where Id IN :POidsList];
        system.debug('PurchaseOrders ::'+PurchaseOrders);
        for(PurchaseOrder__c POList :PurchaseOrders)
        {
            POList.Status__c = 'Open';
            
        }
        system.debug('PurchaseOrders ::'+PurchaseOrders);
        update PurchaseOrders;
    }
    //to convert PO to Single SO
    @AuraEnabled
    public static String convertPOstoSingleSo(Sales_Order__c SO, String slctRec,Ship_Bill_Address__c BillAddress,Ship_Bill_Address__c shipAddress,Ship_Bill_Address__c invoiceAddress,Ship_Bill_Address__c buyerAddress,boolean suzhouFlag,boolean onlyvalidate)
    {
        String returnVal = '';
        if(!onlyvalidate){
            returnVal= 'Success';
        }
        
        system.debug('SO: '+SO+' BillAddress: '+BillAddress+' shipAddress: '+shipAddress+' invoiceAddress: '+invoiceAddress+' buyerAddress: '+buyerAddress+' suzhouFlag: '+suzhouFlag + '    onlyvalidate >>>>>>'+onlyvalidate);
        system.debug('Company: '+SO.Company__c+' Retailer: '+SO.Retailer_Code1__c);
        
        //getting current user customer information Id
        contact contactid=UtilityClass.getCurrentUserContact();
        system.debug('Customer Info ID for Product>>>>'+contactid.Customer_Information__c); 
        List<Customer_Information__c> CustProdID=[select MagNET_Price_Code__c from Customer_Information__c where Id=: contactid.Customer_Information__c ];
        system.debug('Customer Info Product code>>>>'+CustProdID);
        
        String CompanyAPIName;
        Map<String,String> companyNameandAPI = UtilityClass.getOrderToCompanyPicklist(false);
        if(companyNameandAPI.containskey(SO.Company__c))
        {
            CompanyAPIName = companyNameandAPI.get(SO.Company__c);
        }
        
        String [] currencySplit = SO.CurrencyIsoCode.split('-');
        String ResCurr = currencySplit[0].trim();
        System.debug('currencySplit:'+ResCurr);
        SO.CurrencyIsoCode = ResCurr;
        
        String SupplierId;
        String RetailerId;
        List<Sales_Order__c> SOListToInsert = new List<Sales_Order__c>();
        List<Sales_Order_Line_Items__c>  SOLItoInsert = new List<Sales_Order_Line_Items__c>();
        List<PurchaseOrder__c>  POIDList = new List<PurchaseOrder__c>();
        POtoSOWrap SOWrapData = new POtoSOWrap();           //#2.1 ENH
        SOWrapData = POViewPageHandler.POtoSingleSOConversion(slctRec);     //#2.1 ENH
        if(SOWrapData==null)
        {
            returnVal = 'An error occured while converting Purchase Order to Sales Order. Please contact your adminstrator';
            return returnVal;
        }
        SOListToInsert = SOWrapData.SOList;
        system.debug('SOListToInsert from POviewPage>>: '+SOListToInsert);
        SOLItoInsert = SOWrapData.SOLIList;
        system.debug('SOLItoInsert  from POviewPage>>: '+SOLItoInsert);
        Set<Id> seToPoIds = new Set<Id>();  //to store ids of POs
        for(PurchaseOrder__c POids:SOWrapData.PoList)
        {
            seToPoIds.add(POids.id);
        }   
        // code to fetch the custom setting and update ownerid by chandana  
        Map<string,CommunityConfiguration__c> ConfigSettings = CommunityConfiguration__c.getAll();
        CommunityConfiguration__c config = null;
        if(ConfigSettings.containsKey('CommunityConfiguration'))
        {
            config = ConfigSettings.get('CommunityConfiguration');
        }
        
        for(Sales_Order__c newSO : SOListToInsert)      //#2.1 ENH
        {
            newSO.OwnerId =config.SalesOrder_OwnerId__c;
            newSO.Expected_Delivery_Date__c = SO.Expected_Delivery_Date__c;
            newSO.Expected_Completion_Date__c = SO.Expected_Delivery_Date__c;
            
            newSO.Company__c = SO.Company__c;
            newSO.CurrencyIsoCode = SO.CurrencyIsoCode;
            newSO.Delivery_Instructions__c = SO.Delivery_Instructions__c;
            newSO.Factory_Internal_PO__c = SO.Factory_Internal_PO__c;
            newSO.Season__c = SO.Season__c;
            newSO.Season_Year__c = SO.Season_Year__c;
            newSO.Division__c = SO.Division__c;
            newSO.Brand_Label__c = SO.Brand_Label__c;
            newSO.Remarks__c = SO.Remarks__c;
            
            if(SO.Transportation_Details__c!=null && SO.Transportation_Details__c.contains('_space'))
                SO.Transportation_Details__c = SO.Transportation_Details__c.replace('_space', '\n');
            
            if(SO.Shipping_Mark__c!=null && SO.Shipping_Mark__c.contains('_space'))
                SO.Shipping_Mark__c = SO.Shipping_Mark__c.replace('_space', '\n');
            
            newSO.Transportation_Details__c = SO.Transportation_Details__c;
            newSO.Shipping_Mark__c = SO.Shipping_Mark__c;
            newSO.Manufacturer_Code__c = SO.Manufacturer_Code__c;
            newSO.Supplier_Code__c = SO.Supplier_Code__c;
            
            newSO = UtilityClass.assignBillToAdd(newSO,BillAddress);
            newSO = UtilityClass.assignShipToAdd(newSO,shipAddress);
            
            RetailerId = newSO.Retailer_Code1__c;
            SupplierId = newSO.Supplier__c;
            
            if(suzhouFlag == true && buyerAddress != null)
            {
                newSO.Buyer_Address__c = buyerAddress.Id;
            }
            if(suzhouFlag == true && invoiceAddress != null)
            {
                newSO.Invoice_To_Address__c = invoiceAddress.Id;
            }
        }
        system.debug('SOListToInsert>>: '+SOListToInsert);
        
        Set<string> customerRefModelSet = new Set<string>();    //to store set of customer ref model from POLI
        //to update dynamic fields
        List<PO_to_SO_field_Mapping__mdt> additionalFields = [Select id, API_in_PO__c, API_in_SO__c from PO_to_SO_field_Mapping__mdt];
        system.debug('additionalFields: '+additionalFields);
        if(additionalFields.size()>0)
        {
            DescribeSObjectResult describePOResult = Purchase_Order_LineItem__c.getSObjectType().getDescribe();
            String qryfields = ',';
            for(PO_to_SO_field_Mapping__mdt field :additionalFields)
            {
                if(describePOResult.fields.getMap().containsKey(field.API_in_PO__c))
                {
                    qryfields += field.API_in_PO__c+',';
                }
            }
            String query ='select id, name ';
            if(qryfields!=null)
                query+=qryfields;
            query+='Order_Number__c,Customer_Ref_Model__c from Purchase_Order_LineItem__c where Purchase_Order__c IN:seToPoIds';
            System.debug('query>>'+query);
            // return generic list of sobjects or typecast to expected type
            List<Purchase_Order_LineItem__c> PoLineList = Database.query( query );
            
            if(qryfields!=null)
            {
                Map<Id,Purchase_Order_LineItem__c> poliMap = new Map<Id,Purchase_Order_LineItem__c>();
                for(Purchase_Order_LineItem__c poli:PoLineList)
                {
                    poliMap.put(poli.Id,poli);
                    customerRefModelSet.add(poli.Customer_Ref_Model__c);
                }
                
                for(Sales_Order_Line_Items__c Soli:SOLItoInsert)
                {
                    System.debug('poli data>>'+poliMap.get(Soli.Purchase_Order_LineItem__c));
                    for(PO_to_SO_field_Mapping__mdt field :additionalFields)
                    {
                        String poliIds=Soli.POLI_Text_Ids__c;
                        
                        if(poliIds !=null && poliIds.contains(',')){                            
                            System.debug('poli data>>'+poliMap.get((Id)poliIds.split(',')[0]).get(field.API_in_PO__c));
                            Soli.put(field.API_in_SO__c,poliMap.get((Id)poliIds.split(',')[0]).get(field.API_in_PO__c) );
                            System.debug('Soli>>>'+Soli);                            
                        }else{
                            System.debug('poli data>>'+poliMap.get((Id)poliIds).get(field.API_in_PO__c));
                            Soli.put(field.API_in_SO__c,poliMap.get((Id)poliIds).get(field.API_in_PO__c) );
                            System.debug('Soli>>>'+Soli);
                        }
                        
                    }
                    
                }
            }
        }
        //to update dynamic fields ends
        
        if(customerRefModelSet.size()==0)
        {
            for(Sales_Order_Line_Items__c Soli:SOLItoInsert)
            {
                customerRefModelSet.add(Soli.Customer_Ref_Model__c);
            }
        }
        system.debug('customerRefModelSet>>>'+customerRefModelSet);
        
        //Special Price Starts | currency of customer and ERP customer code should match in product price by currency object
        Id billToRecordType = Schema.SObjectType.Ship_Bill_Address__c.getRecordTypeInfosByName().get('Bill To').getRecordTypeId();  //bill to records id of billtoShip to address object
        Id billToLockedRecordType = Schema.SObjectType.Ship_Bill_Address__c.getRecordTypeInfosByName().get('Bill to Locked').getRecordTypeId();  //bill to records id of billtoShip to address object
        system.debug('SupplierId>>>'+SupplierId);
        //to store customer code from Bill to ERP link object
        Set<String> ERPCustomerCode = new Set<String>();    
        //to store pricebook id from listofprod list
        Set<Id> pbIdSet = new Set<Id>();    
        for(Bill_to_ERP_Link__c ERPLink:[select id, name, Local_ERP_customer_code__c, Local_ERP_Payment_Code__c, Locked_Bill_To__c, Mainetti_Company__c, Mainetti_Company__r.name from Bill_to_ERP_Link__c where Parent_Bill_To__r.Customer_Information__c =: SupplierId and Parent_Bill_To__r.Is_Default__c =: true AND (Parent_Bill_To__r.RecordTypeId =: billToRecordType OR Parent_Bill_To__r.RecordTypeId =: billToLockedRecordType)])
        {
            ERPCustomerCode.add(ERPLink.Local_ERP_customer_code__c);
        }
        system.debug('ERPCustomerCode>>>'+ERPCustomerCode);
        
        //pricebook data accumlation
        Map<String,Map<String,Price_Specification_Book_Product__c>> proColourPriceBookMap = new Map<String,Map<String,Price_Specification_Book_Product__c>>();  //cust ref model => color =>pricebook data
        List<Price_Specification_Book_Product__c> priceBookProList =  new List<Price_Specification_Book_Product__c>();
        priceBookProList=[select Id,Name, Product_Unique_ID__c,MOQ__c, Description__c, Order_to_Company__c, Print_Shop__c, Retailer_Code__c, Color__c, Customer_Ref_Model__c, Local_SKU__c, BOX_QTY__c, USD_Rebate_pc__c, EUR_Rebate_pc__c, USD_Reuse_Rebate_pc__c, EUR_Reuse_Rebate_pc__c,Product_image_url__c, Sizer_Print__c, Product_Family__c
                          from Price_Specification_Book_Product__c
                          where Active__c = true and  Product_Unique_ID__r.Status__c=:'Active' and Retailer_Code__c =:RetailerId
                          and Order_to_Company__c =:CompanyAPIName AND Customer_Ref_Model__c IN: customerRefModelSet];
        
        system.debug('priceBookProList>>>'+priceBookProList);
        for(Price_Specification_Book_Product__c PSBP :priceBookProList)
        {
            system.debug('PSBP>>>'+PSBP);
            if(proColourPriceBookMap.containskey(PSBP.Customer_Ref_Model__c))
            {
                system.debug('inside outer if');
                Map<String,Price_Specification_Book_Product__c> tempcolorPbMap = new Map<String,Price_Specification_Book_Product__c>();
                tempcolorPbMap = proColourPriceBookMap.get(PSBP.Customer_Ref_Model__c);
                if(tempcolorPbMap.containskey(PSBP.Color__c.toLowerCase()))
                {
                    system.debug('inside if');
                    System.debug(' Assuming there will colors will not repeat for same product ');
                }
                else
                {
                    system.debug('inside else');
                    tempcolorPbMap.put(PSBP.Color__c.toLowerCase(),PSBP);
                    proColourPriceBookMap.put(PSBP.Customer_Ref_Model__c,tempcolorPbMap);
                }
            }
            else
            {
                system.debug('inside outer else');
                Map<String,Price_Specification_Book_Product__c> tempcolorPbMap = new Map<String,Price_Specification_Book_Product__c>();
                tempcolorPbMap.put(PSBP.Color__c.toLowerCase(),PSBP);
                proColourPriceBookMap.put(PSBP.Customer_Ref_Model__c,tempcolorPbMap);
            }
            system.debug('proColourPriceBookMap>>>'+proColourPriceBookMap);
            pbIdSet.add(psbp.Id);
        }
        system.debug('proColourPriceBookMap: '+proColourPriceBookMap);
        
        //Map<Id,Price_Product_by_Currency__c> pbIdSpecialPriceMap = new Map<Id,Price_Product_by_Currency__c>();  //key=> pbsp id and value => special product price for customer
        Map<Id,Price_Product_by_Currency__c> priceBookCurrencyMap = new Map<Id,Price_Product_by_Currency__c>();
        Map<Id,Price_Product_by_Currency__c> pbIdSpecialDiscountPriceMap = new Map<Id,Price_Product_by_Currency__c>();  //Key=> Product ID and Value => magnet Price code for Customer
        for(Price_Product_by_Currency__c procurr : [select id,name, CurrencyIsoCode, Local_ERP_customer_code__c, Price_100_pcs__c, Price_1000_pcs__c,Price_Book_Product__c,MagNET_Price_Code__c from Price_Product_by_Currency__c where Price_Book_Product__c IN:pbIdSet AND CurrencyIsoCode =:SO.CurrencyIsoCode ])
        {
            IF(procurr.MagNET_Price_Code__c == null || procurr.MagNET_Price_Code__c == ''){
                priceBookCurrencyMap.put(procurr.Price_Book_Product__c,procurr);
            }
            system.debug('ERPCustomerCode: '+ERPCustomerCode.contains(procurr.Local_ERP_customer_code__c));
            /*if(SO.CurrencyIsoCode.contains(procurr.CurrencyIsoCode) && ERPCustomerCode.contains(procurr.Local_ERP_customer_code__c) )    //if special price is defined for current customer
{
pbIdSpecialPriceMap.put(procurr.Price_Book_Product__c,procurr);
}
else*/ if(SO.CurrencyIsoCode.contains(procurr.CurrencyIsoCode) && procurr.MagNET_Price_Code__c == CustProdID[0].MagNET_Price_Code__c){
    pbIdSpecialDiscountPriceMap.put(procurr.Price_Book_Product__c,procurr);
}
        }
        system.debug('priceBookCurrencyMap: '+priceBookCurrencyMap);
        //system.debug('pbIdSpecialPriceMap: '+pbIdSpecialPriceMap);
        
        //pricebook data ends
        
        //to show pricebook validation in UI, added on 21 Aug 2019
        List<Retailer_Code__c> retailerVal= [select id,name,Full_Box_Order__c from Retailer_Code__c where Id =: RetailerId]; //Added for SO getting saved if SOLI BOX_quantity is missing.04/06/2021 
        for(Sales_Order_Line_Items__c Soli:SOLItoInsert)
        {
            if(proColourPriceBookMap.containskey(Soli.Customer_Ref_Model__c) )
            {
                system.debug('pricebook for matched product: '+proColourPriceBookMap.get(Soli.Customer_Ref_Model__c));
                Map<String,Price_Specification_Book_Product__c> tempcolorPbMap = proColourPriceBookMap.get(Soli.Customer_Ref_Model__c);
                //If condition is added on 13-04-22 to Handle the null exception if Soli.Colour__c value is null
              if(Soli.Colour__c != null){
                if( tempcolorPbMap.containskey(Soli.Colour__c.toLowerCase()) )
                {
                    Soli.Price_Specification_Book_Product__c = tempcolorPbMap.get(Soli.Colour__c.toLowerCase()).Id;
                    
                    //SO getting saved if SOLI BOX_quantity is missing.04/06/2021
                    if(tempcolorPbMap.get(Soli.Colour__c.toLowerCase()).BOX_QTY__c == null)
                        tempcolorPbMap.get(Soli.Colour__c.toLowerCase()).BOX_QTY__c = 0;
                    Integer tempBoxQty = Integer.ValueOf(tempcolorPbMap.get(Soli.Colour__c.toLowerCase()).BOX_QTY__c);
                    if( retailerVal[0].Full_Box_Order__c == true && tempBoxQty == 0 )
                    {
                        returnVal = 'Couldn\'t find box quantity in the Price specification book for Customer Ref Model '+Soli.Customer_Ref_Model__c+ ' with color '+Soli.Colour__c;
                        return returnVal;
                    }
                }
                else
                {
                    returnVal = 'Cannot find Price specification book for Customer Ref Model '+Soli.Customer_Ref_Model__c+ ' with color '+Soli.Colour__c;
                    return returnVal;
                }
                if(Soli.Customer_Ref_Model__c == tempcolorPbMap.get(Soli.Colour__c.toLowerCase()).Customer_Ref_Model__c)
                {
                    
                }
                else
                {
                    returnVal = 'Cannot find Price specification book for Customer Ref Model '+Soli.Customer_Ref_Model__c;
                    return returnVal;
                }
            }
                //To handle the Exception if Soli.Color__c value is null
                else{
                    returnVal = 'Cannot find Price specification book for Customer Ref Model '+Soli.Customer_Ref_Model__c+ ' WITHOUT Color ';
                    return returnVal;
                }
            }
            else
            {
                returnVal = 'Cannot find Price specification book for Customer Ref Model '+Soli.Customer_Ref_Model__c;
                return returnVal;
            }
            system.debug('pricebook in soli: '+Soli.Price_Specification_Book_Product__c);
            /*if(pbIdSpecialPriceMap.containskey(Soli.Price_Specification_Book_Product__c))
{

}
else*/ if(priceBookCurrencyMap.containskey(Soli.Price_Specification_Book_Product__c))
{
    
}
            else
            {
                Soli.Price_per_100_pc__c = 0;
                returnVal = 'Couldn\'t find Price Price Product By Currency for currency '+SO.CurrencyIsoCode;
                return returnVal;
            }
        }
        
        //inserting sales order
        if(!onlyvalidate){
            system.debug('Inside checkonly true');
            system.debug('1686 Before Insert SOListToInsert: '+SOListToInsert);
            insert SOListToInsert;
        }
        // system.debug('SOListToInsert: '+SOListToInsert);
        
        //#2.1 ENH
        Map<Id,Sales_Order__c> SalesOrderMap = new Map<Id,Sales_Order__c>();    //key => so id, Value => so rec
        // Map<Id,Id> PoIdnSoIdMap = new Map<Id,Id>();  //key => po id, Value => so id
        String soIdForEmail = '';
        String soId='';
        for(Sales_Order__c newSO : SOListToInsert)
        {
            SalesOrderMap.put(newSO.Id,newSO);
            //PoIdnSoIdMap.put(newSO.Purchase_Order__c,newSO.Id);
            soIdForEmail = newSO.Id;
            soId = newSO.Id;
        }
        system.debug('SalesOrderMap: '+SalesOrderMap);
        //system.debug('PoIdnSoIdMap: '+PoIdnSoIdMap);
        
        //#2.1 ENH
        List<Retailer_Code__c> retailer= [select id,name,Full_Box_Order__c from Retailer_Code__c where Id =: RetailerId];
        //Order Lines validations
        String boxQtyChangeAlert;  
        boolean isMOQMissing = false;
        for(Sales_Order_Line_Items__c Soli:SOLItoInsert)
        {
            //system.debug('poli id: '+Soli.Purchase_Order_LineItem__c);
            //system.debug('containskey poli id: '+SOWrapData.PoliPOIdMap.containsKey(Soli.Purchase_Order_LineItem__c));
            //system.debug('contains po id: '+PoIdnSoIdMap.get(SOWrapData.PoliPOIdMap.get(Soli.Purchase_Order_LineItem__c).Purchase_Order__c));
            //Soli.Sales_Order__c = SOListToInsert   PoIdnSoIdMap.get(SOWrapData.PoliPOIdMap.get(Soli.Purchase_Order_LineItem__c).Purchase_Order__c);
            Soli.Sales_Order__c = soId;
            Soli.CurrencyIsoCode = SalesOrderMap.get(Soli.Sales_Order__c).CurrencyIsoCode;  //#2.1 ENH
            //Soli.Expected_Delivery_Date__c = SOtoInsert.Expected_Delivery_Date__c;
            if(proColourPriceBookMap.containskey(Soli.Customer_Ref_Model__c) )
            {
                Map<String,Price_Specification_Book_Product__c> tempcolorPbMap = proColourPriceBookMap.get(Soli.Customer_Ref_Model__c);
                //If condition is added on 13-04-22 to Handle the null exception if Soli.Colour__c value is null
                if(Soli.Colour__c != null){
                if(tempcolorPbMap.containskey(Soli.Colour__c.toLowerCase()) )
                {
                    Soli.Price_Specification_Book_Product__c = tempcolorPbMap.get(Soli.Colour__c.toLowerCase()).Id;
                    Soli.Product_Description__c = tempcolorPbMap.get(Soli.Colour__c.toLowerCase()).Description__c;
                    Soli.Products__c = tempcolorPbMap.get(Soli.Colour__c.toLowerCase()).Product_Unique_ID__c;
                    Soli.Printshop_Pick__c = tempcolorPbMap.get(Soli.Colour__c.toLowerCase()).Print_Shop__c;
                    Soli.Local_SKU__c = tempcolorPbMap.get(Soli.Colour__c.toLowerCase()).Local_SKU__c;
                    Soli.USD_Rebate_pc__c = tempcolorPbMap.get(Soli.Colour__c.toLowerCase()).USD_Rebate_pc__c;
                    Soli.EUR_Rebate_pc__c = tempcolorPbMap.get(Soli.Colour__c.toLowerCase()).EUR_Rebate_pc__c;
                    Soli.USD_Reuse_Rebate_pc__c = tempcolorPbMap.get(Soli.Colour__c.toLowerCase()).USD_Reuse_Rebate_pc__c;
                    Soli.EUR_Reuse_Rebate_pc__c = tempcolorPbMap.get(Soli.Colour__c.toLowerCase()).EUR_Reuse_Rebate_pc__c;
                    Soli.Product_image_url__c = tempcolorPbMap.get(Soli.Colour__c.toLowerCase()).Product_image_url__c;
                    Soli.Print__c = tempcolorPbMap.get(Soli.Colour__c.toLowerCase()).Sizer_Print__c;
                    Soli.Family__c = tempcolorPbMap.get(Soli.Colour__c.toLowerCase()).Product_Family__c;  
                    Integer tempQty = Integer.ValueOf(Soli.Supply_Quantity__c);
                    
                    if(tempcolorPbMap.get(Soli.Colour__c.toLowerCase()).BOX_QTY__c == null)
                        tempcolorPbMap.get(Soli.Colour__c.toLowerCase()).BOX_QTY__c = 0;
                    Integer tempBoxQty ;
                          tempBoxQty  = Integer.ValueOf(tempcolorPbMap.get(Soli.Colour__c.toLowerCase()).BOX_QTY__c);
                        system.debug('tempBoxQty >>>>>>>'+tempBoxQty);
                         if(tempBoxQty == null){
                            tempBoxQty = 0;
                        }
                          Integer tempMOQQty;
                              tempMOQQty = Integer.ValueOf(tempcolorPbMap.get(Soli.Colour__c.toLowerCase()).MOQ__c);
                        system.debug('tempMOQQty >>>>>>>'+tempMOQQty);
                        if(tempMOQQty == null){
                            tempMOQQty = 0;
                        }
                    
                    //added on 17 Mar 2020 to populate values even if correction in qty is not required
                    Soli.Full_Box_Order__c = retailer[0].Full_Box_Order__c;
                    if(Soli.Full_Box_Order__c)
                        Soli.BOX_QTY__c = tempBoxQty;
                    
                    if( retailer[0].Full_Box_Order__c == true && tempBoxQty == 0 )
                    {
                        returnVal = 'Couldn\'t find box quantity in the Price specification book for Customer Ref Model '+Soli.Customer_Ref_Model__c+ ' with color '+Soli.Colour__c;
                        return returnVal;
                    }
                  /*  if(!onlyvalidate){
                        if( retailer[0].Full_Box_Order__c == true && tempBoxQty != null && (math.mod(tempQty, tempBoxQty)) != 0 )
                        {
                            
                            //system.debug('Soli.Remaining_Qty__c: '+Soli.Remaining_Qty__c);
                            //system.debug('boxQty: '+tempcolorPbMap.get(Soli.Colour__c.toLowerCase()).BOX_QTY__c);
                            //system.debug('poli name: '+SOWrapData.PoliPOIdMap.get(Soli.Purchase_Order_LineItem__c));
                            Double vboxQty = (Math.ceil(Soli.Remaining_Qty__c/tempcolorPbMap.get(Soli.Colour__c.toLowerCase()).BOX_QTY__c))*tempcolorPbMap.get(Soli.Colour__c.toLowerCase()).BOX_QTY__c;
                            Soli.Quantity__c = String.ValueOf(Integer.ValueOf(vboxQty));    //text
                            Soli.Ordered_Quantity__c = Integer.ValueOf(vboxQty);    //number
                            Soli.Supply_Quantity_num__c = Integer.ValueOf(vboxQty); //number
                            Soli.Remaining_Qty__c = Integer.ValueOf(vboxQty);   //number
                            Soli.Supply_Quantity__c = String.ValueOf(Integer.ValueOf(vboxQty)); //text
                            if(boxQtyChangeAlert == null)
                                boxQtyChangeAlert = 'Order quantity of '+Soli.Customer_Ref_Model__c+' in '+Soli.POLI_Text_Name__c+' is changed to '+String.ValueOf(Integer.ValueOf(vboxQty));
                            else
                                boxQtyChangeAlert = ' And Order quantity of '+Soli.Customer_Ref_Model__c+' in '+Soli.POLI_Text_Name__c+' is changed to '+String.ValueOf(Integer.ValueOf(vboxQty));
                            
                        }
                    }
                    Integer tempMOQQty = Integer.ValueOf(tempcolorPbMap.get(Soli.Colour__c.toLowerCase()).MOQ__c);
                    system.debug('tempMOQQty >>>>>>>'+tempMOQQty);
                    
                    if(tempMOQQty > tempQty ){
                        system.debug('Inside Minimum order Quantity');
                        
                        if(!onlyvalidate){
                            Soli.Quantity__c = String.valueof(tempMOQQty);    //text
                            Soli.Ordered_Quantity__c = tempMOQQty;    //number
                            Soli.Supply_Quantity_num__c = tempMOQQty; //number
                            Soli.Remaining_Qty__c = tempMOQQty;   //number
                            Soli.Supply_Quantity__c = String.valueof(tempMOQQty); //text
                        }else{
                            isMOQMissing = true;
                            returnVal+= 'The Order quantity of '+Soli.Customer_Ref_Model__c +' is less than Minimum Order Quantity '+tempMOQQty+'\n';
                            //return  returnVal;      
                        }
                    }*/
                       integer MoqNFullBoxqty;
                        if(retailer[0].Full_Box_Order__c == true){
                            if(!(tempQty >= tempMOQQty)){
                                if(tempBoxQty > 0){
                                    decimal mathmodval = math.mod(tempMOQQty, tempBoxQty);
                                    system.debug('mathmodval >>>>>>'+mathmodval);
                                    if(mathmodval == 0){
                                        MoqNFullBoxqty = ((integer)math.ceil(tempMOQQty/ tempBoxQty))*tempBoxQty;
                                        system.debug('MoqNFullBoxqty >>>>>>'+MoqNFullBoxqty);
                                        if(onlyvalidate){
                                            isMOQMissing = true;
                                            returnVal +=  'The Order quantity of  '+Soli.Customer_Ref_Model__c+' is less than Minimum Order Quantity '+tempMOQQty+'.The nearest multiples of box quantity is '+MoqNFullBoxqty+'\n';
                                        }
                                    }
                                    else{//When tempMOQQty is not evenly divisible by tempBoxQty
                                        for(integer i =1 ; i<=500 ;i++){
                                            integer tempVal = i*tempBoxQty;
                                            system.debug('tempVal >>>>>>'+tempVal);
                                            integer mathmodceilval = (integer)math.ceil(tempMOQQty/ tempVal);
                                            system.debug('mathmodceilval >>>>>>'+mathmodceilval);
                                            
                                            if(mathmodceilval == 0 ){
                                                MoqNFullBoxqty = tempVal;
                                                system.debug('MoqNFullBoxqty inside Input Qty is Less than MOQ >>>>>>'+MoqNFullBoxqty);
                                                if(onlyvalidate){
                                                    isMOQMissing = true;
                                                    returnVal +='The Order quantity of  '+Soli.Customer_Ref_Model__c+' is less than Minimum Order Quantity '+tempMOQQty+'.The nearest multiples of box quantity is '+MoqNFullBoxqty+'\n';
                                                }
                                                break;
                                            }
                                        }
                                    }
                                }
                                else{//When BoxQty is Zero
                                    MoqNFullBoxqty = tempMOQQty;
                                    system.debug(' MoqNFullBoxqty>>>>>'+MoqNFullBoxqty);
                                    if(onlyvalidate){
                                        isMOQMissing = true;
                                        returnVal += 'The Order quantity of '+ Soli.Customer_Ref_Model__c+'  is less than Minimum Order Quantity '+MoqNFullBoxqty+'\n';
                                    }
                                    
                                }
                            }
                            else{//When InputQty is Less than MOQ
                                if(tempBoxQty > 0){
                                    decimal mathmodval = math.mod(tempQty, tempBoxQty);
                                    system.debug('mathmodval >>>>>>'+mathmodval);
                                    if(mathmodval == 0){
                                        MoqNFullBoxqty = ((integer)math.ceil(tempQty/ tempBoxQty))*tempBoxQty;
                                        system.debug('MoqNFullBoxqty >>>>>>'+MoqNFullBoxqty);
                                        if(onlyvalidate && tempQty != tempBoxQty){
                                             if(!(tempQty > tempBoxQty)){
                                            isMOQMissing = true;
                                            returnVal += 'The Order quantity of '+ Soli.Customer_Ref_Model__c+' should match the Full Box Quantity.The nearest multiples of box quantity is '+MoqNFullBoxqty+'\n';
                                             }
                                             }
                                    }
                                    else{//When tempMOQQty is not evenly divisible by tempBoxQty
                                        for(integer i =1 ; i<=500 ;i++){
                                            integer tempVal = i*tempBoxQty;
                                            system.debug('tempVal >>>>>>'+tempVal);
                                            integer mathmodceilval = (integer)math.ceil(tempQty/ tempVal);
                                            system.debug('mathmodceilval >>>>>>'+mathmodceilval);
                                            
                                            if(mathmodceilval == 0 ){
                                                MoqNFullBoxqty = tempVal;
                                                system.debug('MoqNFullBoxqty inside Input Qty is Less than MOQ >>>>>>'+MoqNFullBoxqty);
                                                if(onlyvalidate){
                                                    if(!(tempQty > tempBoxQty)){
                                                    isMOQMissing = true;
                                                    returnVal += 'The Order quantity of '+Soli.Customer_Ref_Model__c+'  is less than Full Box Quantity.The nearest multiples of box quantity is '+MoqNFullBoxqty+'\n';
                                                     }
                                                    else{
                                                         isMOQMissing = true;
                                                    returnVal += 'The Order quantity of '+Soli.Customer_Ref_Model__c+' should match the Full Box Quantity.The nearest multiples of box quantity is '+MoqNFullBoxqty+'\n';
                                                   
                                                    } }
                                                break;
                                            }
                                        }
                                    } 
                                }
                                else{//When BoxQty is Zero
                                    MoqNFullBoxqty = tempQty;
                                    system.debug(' MoqNFullBoxqty>>>>>'+MoqNFullBoxqty);
                                    
                                }
                            }
                        }
                        else{
                            if(tempMOQQty > 0){
                                if(!(tempQty > tempMOQQty)){
                                    MoqNFullBoxqty = tempMOQQty;
                                    if(onlyvalidate){
                                        isMOQMissing = true;
                                        returnVal += 'The Order quantity of '+Soli.Customer_Ref_Model__c+' is less than Minimum Order Quantity'+MoqNFullBoxqty+'\n';
                                        system.debug('MoqNFullBoxqty>>>>>>'+MoqNFullBoxqty);
                                    }
                                }
                                else{
                                    MoqNFullBoxqty = tempQty;
                                    system.debug('MoqNFullBoxqty>>>>>>'+MoqNFullBoxqty);
                                }
                            }
                            else{
                                MoqNFullBoxqty = tempQty;
                                system.debug('MoqNFullBoxqty>>>>>>'+MoqNFullBoxqty);
                            }
                            
                        }
                        system.debug('MoqNFullBoxqty>>>>>>'+MoqNFullBoxqty);
                        if(!onlyvalidate){
                             Soli.Quantity__c = String.valueof(MoqNFullBoxqty);    //text
                                Soli.Ordered_Quantity__c = MoqNFullBoxqty;    //number
                                Soli.Supply_Quantity_num__c = MoqNFullBoxqty; //number
                                Soli.Remaining_Qty__c = MoqNFullBoxqty;   //number
                                Soli.Supply_Quantity__c = String.valueof(MoqNFullBoxqty); //text
                    }
                }
                else
                {
                    returnVal = 'Couldn\'t find Price specification book for Customer Ref Model '+Soli.Customer_Ref_Model__c+ ' with color '+Soli.Colour__c;
                    return returnVal;
                }
                }
                //To handle the Exception if Soli.Color__c value is null
                else{
                    returnVal = 'Cannot find Price specification book for Customer Ref Model '+Soli.Customer_Ref_Model__c+ ' WITHOUT color ';
                    return returnVal;
                }
            }
            system.debug('psbp: '+Soli.Price_Specification_Book_Product__c);
            /*if(pbIdSpecialPriceMap.containskey(Soli.Price_Specification_Book_Product__c))
{
Soli.Price_Product_by_Currency__c = pbIdSpecialPriceMap.get(Soli.Price_Specification_Book_Product__c).Id;
Soli.Price_per_100_pc__c = pbIdSpecialPriceMap.get(Soli.Price_Specification_Book_Product__c).Price_100_pcs__c;
Soli.Price_100_pcs__c =String.valueof(pbIdSpecialPriceMap.get(Soli.Price_Specification_Book_Product__c).Price_100_pcs__c);
Soli.Price_1000_pcs__c =String.valueof((pbIdSpecialPriceMap.get(Soli.Price_Specification_Book_Product__c).Price_100_pcs__c)*10);
}
else*/ if(pbIdSpecialDiscountPriceMap.containskey(Soli.Price_Specification_Book_Product__c)){
    Soli.Price_Product_by_Currency__c = pbIdSpecialDiscountPriceMap.get(Soli.Price_Specification_Book_Product__c).Id;
    Soli.Price_per_100_pc__c = pbIdSpecialDiscountPriceMap.get(Soli.Price_Specification_Book_Product__c).Price_100_pcs__c;
    Soli.Price_100_pcs__c =String.valueof(pbIdSpecialDiscountPriceMap.get(Soli.Price_Specification_Book_Product__c).Price_100_pcs__c);
    Soli.Price_1000_pcs__c =String.valueof((pbIdSpecialDiscountPriceMap.get(Soli.Price_Specification_Book_Product__c).Price_100_pcs__c)*10);
}
            else if(priceBookCurrencyMap.containskey(Soli.Price_Specification_Book_Product__c))
            {
                Soli.Price_Product_by_Currency__c = priceBookCurrencyMap.get(Soli.Price_Specification_Book_Product__c).Id;
                Soli.Price_per_100_pc__c = priceBookCurrencyMap.get(Soli.Price_Specification_Book_Product__c).Price_100_pcs__c;
                Soli.Price_100_pcs__c =String.valueof(priceBookCurrencyMap.get(Soli.Price_Specification_Book_Product__c).Price_100_pcs__c);
                Soli.Price_1000_pcs__c =String.valueof((priceBookCurrencyMap.get(Soli.Price_Specification_Book_Product__c).Price_100_pcs__c)*10);
            }
            else
            {
                Soli.Price_per_100_pc__c = 0;
                returnVal = 'Couldn\'t find Price Price Product By Currency for currency '+SO.CurrencyIsoCode;
                return returnVal;
            }
            
            Soli.Expected_Delivery_Date__c = SalesOrderMap.get(Soli.Sales_Order__c).Expected_Delivery_Date__c;  //added on 16 Dec 2019
            Soli.Expected_Completion_Date__c = SalesOrderMap.get(Soli.Sales_Order__c).Expected_Delivery_Date__c;    //added on 16 Dec 2019
            
        }
        if(!onlyvalidate){
            system.debug('Inside checkonly true');
            insert SOLItoInsert;
            
            /* code for RFID generation by Alvin*/
            Set<Id> Ids_2 = (new Map<Id,Sales_Order_Line_Items__c>(SOLItoInsert)).keySet();
            List<Sales_Order_Line_Items__c> SoliList_2 = [select id, name, Sales_Order__c, Sales_Order__r.Retailer_Code1__c, Supply_Quantity__c ,Quantity__c, Expected_Delivery_Date__c, Status__c, Price_Product_by_Currency__c,Online_Detail_Status__c, Price_Product_by_Currency__r.Price_100_pcs__c, Price_Specification_Book_Product__r.USD_Rebate_pc__c, Price_Specification_Book_Product__r.EUR_Rebate_pc__c, Price_Specification_Book_Product__r.USD_Reuse_Rebate_pc__c, Price_Specification_Book_Product__r.EUR_Reuse_Rebate_pc__c,Price_Specification_Book_Product__r.RFIDSerial__c  from Sales_Order_Line_Items__c where Id IN :Ids_2];
            //SoliList_2 =[select Id,Price_Specification_Book_Product__r.RFIDSerial__c , Start_Num__c from Sales_Order_Line_Items__c where Id IN resultIds];
            Boolean IsRevised1 = false;
            Map<Sales_Order_Line_Items__c,boolean> ReviseMap1;
            string retailcode2 = SO.Retailer_Code1__c;
            System.enqueueJob(new RFIDNumGeneartion(SoliList_2, IsRevised1,ReviseMap1,retailcode2));
            /* code for RFID generation END*/ 
        }
        if(boxQtyChangeAlert!=null)
        {
            returnVal = 'Quantity is updated to nearest Box Quantity value.';
        }
        system.debug('returnVal: '+returnVal);
        system.debug('isMOQMissing: '+isMOQMissing);
        if(isMOQMissing){
            returnVal += 'Click Ok to place the order with Minimum Order Quantity and Full Box Quantity';
            return returnVal;
        }
        
        Set<String> SoIdsforName =new Set<String>();
        for(Sales_Order__c newSO : SOListToInsert)
        {
            SoIdsforName.add(newSO.id);
            
        }
        system.debug('SoIdsforName: '+SoIdsforName);
        
        for(PurchaseOrder__c po:SOWrapData.PoList)
        {
            po.SO__c = soId;
            //po.SO_Num__c = newCommonSO.Name;
        }
        if(onlyvalidate){
            system.debug('Inside checkonly true');
        }else{
            // system.debug('Before update SOWrapData.PoList: '+SOWrapData.PoList);
            update SOWrapData.PoList;
            // system.debug('Before update SOWrapData.PoliPOIdMap.values(): '+SOWrapData.PoliPOIdMap.values());
            update SOWrapData.PoliPOIdMap.values();
            // System.debug('after update POupdate>>>>>>'+SOWrapData.PoList.size()+SOWrapData.PoList);
            List<String> listStringsSOids = new List<String>(SoIdsforName);
            // System.debug('listStringsSOids>>>>>>'+listStringsSOids);
            SOController.toupdateSalesOrderList(listStringsSOids);
            //to send email to retailers
            adminEmailAfterPOtoSOconversion(SalesOrderMap);
            
            returnVal += ' Id='+soIdForEmail.substringBeforeLast(',');
        }
        return returnVal;
    }
    
    @auraEnabled
    public static void customerEmailAfterPOtoSOconversion(String soIdForEmail)
    {
        List<String> SOIDSet = soIdForEmail.split(',');
        try
        {
            List<Sales_Order__c> soList = [Select id,name,Company__c,Supplier1__c,Retailer_Code1__c,Retailer_Code1__r.Name,Retailer_Code1__r.Market_Segment__c,Retailer_Code1__r.Attach_PDF_in_MagNET_Email__c,Supplier__r.Name,Supplier__c, OrderSource__c, Supplier_Email__c, Supplier_Contact__r.name,Sales_Order_Number_For_Report__c,Retailer_Code2__c,Expected_Delivery_Date__c,
                                           Bill_to_Factory__c,Bill_To_Address1__c,Bill_to_City__c,Bill_to_State__c,Bill_to_Postcode__c,Bill_to_Country__c,Bill_To_Contact__c,Bill_to_Tel__c,Ship_to_Factory__c,Ship_to_Address1__c,Ship_to_City__c,Ship_to_State__c,Ship_to_Postcode__c,Ship_to_Country__c,Ship_To_Contact__c,Ship_to_Tel__c 
                                           from Sales_Order__c where Id IN: SOIDSet];
            System.debug('soList>>'+soList);
            Integer numOfSo = soList.size();
            System.debug('soList.size()>>'+soList.size());
            Map<String,String> companyNameandAPI = UtilityClass.getOrderToCompanyPicklist(false);
            
            
            Map<string,CommunityConfiguration__c> ConfigSettings = CommunityConfiguration__c.getAll();
            CommunityConfiguration__c config = null;
            if(ConfigSettings.containsKey('CommunityConfiguration'))
            {
                config = ConfigSettings.get('CommunityConfiguration');
            }  
            System.debug(config.Organization_Wide_Email_Address__c);
            System.debug([select Id,Address,DisplayName from OrgWideEmailAddress]);
            OrgWideEmailAddress owd = [select Id,Address,DisplayName from OrgWideEmailAddress where DisplayName=:config.Organization_Wide_Email_Address__c  limit 1];
            System.debug(owd);
            // Map<String,String> companyNameandAPI = UtilityClass.getOrderToCompanyPicklist(false);
            List<string> companynames = new List<string>();
            List<string> retailerMarketSegment = new List<string>();
            for(Sales_Order__c newSOList : [Select id,name,Company__c,Supplier1__c,Retailer_Code1__c,Retailer_Code1__r.Name,Retailer_Code1__r.Market_Segment__c,Retailer_Code1__r.Attach_PDF_in_MagNET_Email__c,Supplier__r.Name,Supplier__c, OrderSource__c, Supplier_Email__c, Supplier_Contact__r.name,Sales_Order_Number_For_Report__c,Retailer_Code2__c,Expected_Delivery_Date__c,
                                            Bill_to_Factory__c,Bill_To_Address1__c,Bill_to_City__c,Bill_to_State__c,Bill_to_Postcode__c,Bill_to_Country__c,Bill_To_Contact__c,Bill_to_Tel__c,Ship_to_Factory__c,Ship_to_Address1__c,Ship_to_City__c,Ship_to_State__c,Ship_to_Postcode__c,Ship_to_Country__c,Ship_To_Contact__c,Ship_to_Tel__c 
                                            from Sales_Order__c where Id IN: SOIDSet])
            {
                string orderToCompanytoconv = companyNameandAPI.get(newSOList.Company__c);
                companynames.add(companyNameandAPI.get(newSOList.Company__c));
                retailerMarketSegment.add(newSOList.Retailer_Code1__r.Market_Segment__c);
                // RegistrationService.ToEmailandCCEmailWrapper Regwrap = RegistrationService.getMailAddressesBulkify(companynames, retailerMarketSegment ,config);
                //system.debug('Regwrap>>'+Regwrap);
            }
            system.debug('companynames???'+companynames);
            system.debug('retailerMarketSegment???'+retailerMarketSegment);
            RegistrationService.ToEmailandCCEmailWrapper Regwrap = RegistrationService.getMailAddressesBulkify(companynames, retailerMarketSegment ,config);
            
            
            
            
            
            
            if(numOfSo > 0 && soList[0].Retailer_Code1__r.Attach_PDF_in_MagNET_Email__c)    //if retailer allows to attach so PDF in the mail, send mails for individual orders
            {
                List<Messaging.SingleEmailMessage> mails =  new List<Messaging.SingleEmailMessage>();
                for(Sales_Order__c mailSO : soList)
                {
                    Date EXFactoryDate = mailSO.Expected_Delivery_Date__c;
                    string BillTovalue = mailSO.Bill_to_Postcode__c!=null?mailSO.Bill_to_Postcode__c:'';
                    
                    string ShipTovalue = mailSO.Ship_to_Postcode__c!=null?mailSO.Ship_to_Postcode__c:'';
                    
                    /*    Map<string,CommunityConfiguration__c> ConfigSettings = CommunityConfiguration__c.getAll();
CommunityConfiguration__c config = null;
if(ConfigSettings.containsKey('CommunityConfiguration'))
{
config = ConfigSettings.get('CommunityConfiguration');
} 

string orderToCompanytoconv = companyNameandAPI.get(mailSO.Company__c); 
RegistrationService.ToEmailandCCEmailWrapper Regwrap = RegistrationService.getMailAddresses(orderToCompanytoconv, mailSO.Retailer_Code1__r.Market_Segment__c ,config);
system.debug('Regwrap>>'+Regwrap);
*/  
                    string subject = 'MagNET Order has been Created for '+mailSO.Sales_Order_Number_For_Report__c+' (Retailer code: '+ mailSO.Retailer_Code2__c +')';
                    
                    string  emailBody = 'Dear '+mailSO.Supplier_Contact__r.name+', <br />'+'<br />Thank you for using MagNET. Your submitted order is received and under processing by Mainetti.' + 
                        '<br /><br />'+'Customer Contact: '+mailSO.Supplier1__c+' / '+mailSO.Supplier_Email__c+
                        '<br /><br />'+'Retailer code: '+ mailSO.Retailer_Code2__c +
                        '<br /><br />'+'MagNET Order: '+mailSO.Sales_Order_Number_For_Report__c+
                        '<br /><br />'+'Expected Ex-Factory Date: '+EXFactoryDate.format()+
                        '<br /><br />'+'Order to Company: '+mailSO.Company__c+
                        '<br /><br />'+'Bill To: '+
                        '<br />'+mailSO.Bill_to_Factory__c+
                        '<br />'+mailSO.Bill_To_Address1__c+
                        '<br />'+mailSO.Bill_to_City__c+
                        '<br />'+mailSO.Bill_to_State__c+
                        '<br />'+BillTovalue+
                        '<br />'+mailSO.Bill_to_Country__c+
                        '<br />'+mailSO.Bill_To_Contact__c+
                        '<br />'+mailSO.Bill_to_Tel__c+
                        
                        '<br /><br />'+'Ship To: '+
                        '<br />'+mailSO.Ship_to_Factory__c+
                        '<br />'+mailSO.Ship_to_Address1__c+
                        '<br />'+mailSO.Ship_to_City__c+
                        '<br />'+mailSO.Ship_to_State__c+
                        '<br />'+ShipTovalue+
                        '<br />'+mailSO.Ship_to_Country__c+
                        '<br />'+mailSO.Ship_To_Contact__c+
                        '<br />'+mailSO.Ship_to_Tel__c+
                        
                        '<br /><br />' +'Mainetti Sales/CS Team will get back to you for order details soon.'+
                        '<br /><br />' +'Thanks.'+
                        '<br /><br />' +'MagNET Team';
                    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                    
                    /*** Creating email attachment starts ***/
                    
                    PageReference pdf = Page.SOConfirmationPDF;
                    pdf.getParameters().put('id',mailSO.Id);
                    pdf.setRedirect(true);
                    
                    try
                    {
                        if(mailSO.Retailer_Code1__r.Attach_PDF_in_MagNET_Email__c)
                        {
                            // Take the PDF content
                            Blob b = pdf.getContent();
                            system.debug('b>>'+b);
                            Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
                            String filename = mailSO.Name +'.pdf';
                            efa.setFileName(filename);
                            efa.setBody(b);
                            System.debug('efa>>>'+efa);
                            mail.setFileAttachments(new Messaging.EmailFileAttachment[] {efa});
                        }
                        /*** Creating email attachment starts ***/
                    }
                    catch(Exception e)
                    {
                        System.debug('Inside exception>>>'+e.getMessage());
                        System.debug('Inside exception LineNumber >>>'+e.getLineNumber());
                        System.debug('Inside exception getTypeName>>>'+e.getTypeName());
                        System.debug('Inside exception getStackTraceString>>>'+e.getStackTraceString());
                    }
                    String sendTo;
                    //mail.setCCAddresses(Regwrap.toCCAddresses);
                    String[] toAddresses = new String[] {mailSO.Supplier_Email__c};
                        //  OrgWideEmailAddress owd = [select Id,Address,DisplayName from OrgWideEmailAddress where DisplayName=:config.Organization_Wide_Email_Address__c  limit 1];
                        System.debug('owd>>>'+owd);             
                    System.debug('toAddresses>>>'+toAddresses);
                    mail.setOrgWideEmailAddressId(owd.id); 
                    mail.setToAddresses(toAddresses);
                    mail.setSubject(subject);
                    mail.setHtmlBody(emailBody);
                    //mail.setSenderDisplayName('Sales order submitted');        // from name in the mail 
                    mail.setSaveAsActivity(false);
                    mails.add(mail);
                }
                Messaging.SendEmailResult[] results = Messaging.sendEmail(mails);
                
                //Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);
                if (results[0].success) 
                {
                    System.debug('The email was sent successfully.');
                } 
                else
                {
                    
                    System.debug('The email failed to send:'+results[0].errors[0].message);
                }
                
            }
            
            else if(numOfSo > 1)    //if attachment in pdf is disabled and more than 1 SO are there
            {
                List<Messaging.SingleEmailMessage> mails =  new List<Messaging.SingleEmailMessage>();
                String orderNames = '';
                Sales_Order__c mailSO = new Sales_Order__c();
                for(Sales_Order__c SO : soList)
                {
                    orderNames += SO.Name+',    &emsp;';
                    mailSO = SO;
                }
                orderNames = orderNames.substringBeforeLast(',');
                Date EXFactoryDate = mailSO.Expected_Delivery_Date__c;
                string BillTovalue = mailSO.Bill_to_Postcode__c!=null?mailSO.Bill_to_Postcode__c:'';
                
                string ShipTovalue = mailSO.Ship_to_Postcode__c!=null?mailSO.Ship_to_Postcode__c:'';
                
                /*    Map<string,CommunityConfiguration__c> ConfigSettings = CommunityConfiguration__c.getAll();
CommunityConfiguration__c config = null;
if(ConfigSettings.containsKey('CommunityConfiguration'))
{
config = ConfigSettings.get('CommunityConfiguration');
}  

string orderToCompanytoconv = companyNameandAPI.get(mailSO.Company__c); 
RegistrationService.ToEmailandCCEmailWrapper Regwrap = RegistrationService.getMailAddresses(orderToCompanytoconv, mailSO.Retailer_Code1__r.Market_Segment__c ,config);
system.debug('Regwrap>>'+Regwrap);
*/   
                string subject = 'Sales Orders are Created for Retailer code: '+ mailSO.Retailer_Code2__c;
                
                string  emailBody = 'Dear '+mailSO.Supplier_Contact__r.name+', <br />'+'<br />Thank you for using MagNET. Your submitted order is received and under processing by Mainetti.' + 
                    '<br /><br />'+'Customer Contact: '+mailSO.Supplier1__c+' / '+mailSO.Supplier_Email__c+
                    '<br /><br />'+'Retailer code: '+ mailSO.Retailer_Code2__c +
                    '<br /><br />'+'MagNET Order: '+orderNames+
                    '<br /><br />'+'Expected Ex-Factory Date: '+EXFactoryDate.format()+
                    '<br /><br />'+'Order to Company: '+mailSO.Company__c+
                    '<br /><br />'+'Bill To: '+
                    '<br />'+mailSO.Bill_to_Factory__c+
                    '<br />'+mailSO.Bill_To_Address1__c+
                    '<br />'+mailSO.Bill_to_City__c+
                    '<br />'+mailSO.Bill_to_State__c+
                    '<br />'+BillTovalue+
                    '<br />'+mailSO.Bill_to_Country__c+
                    '<br />'+mailSO.Bill_To_Contact__c+
                    '<br />'+mailSO.Bill_to_Tel__c+
                    
                    '<br /><br />'+'Ship To: '+
                    '<br />'+mailSO.Ship_to_Factory__c+
                    '<br />'+mailSO.Ship_to_Address1__c+
                    '<br />'+mailSO.Ship_to_City__c+
                    '<br />'+mailSO.Ship_to_State__c+
                    '<br />'+ShipTovalue+
                    '<br />'+mailSO.Ship_to_Country__c+
                    '<br />'+mailSO.Ship_To_Contact__c+
                    '<br />'+mailSO.Ship_to_Tel__c+
                    
                    '<br /><br />' +'Mainetti Sales/CS Team will get back to you for order details soon.'+
                    '<br /><br />' +'Thanks.'+
                    '<br /><br />' +'MagNET Team';
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                
                
                String sendTo;
                String[] toAddresses = new String[] {mailSO.Supplier_Email__c};
                    // OrgWideEmailAddress owd = [select Id,Address,DisplayName from OrgWideEmailAddress where DisplayName=:config.Organization_Wide_Email_Address__c  limit 1];
                    System.debug('owd>>>'+owd);             
                System.debug('toAddresses>>>'+toAddresses);
                mail.setOrgWideEmailAddressId(owd.id); 
                mail.setToAddresses(toAddresses);
                mail.setSubject(subject);
                mail.setHtmlBody(emailBody);
                mail.setSaveAsActivity(false);
                
                mails.add(mail);
                Messaging.SendEmailResult[] results = Messaging.sendEmail(mails);
                
                if (results[0].success) 
                {
                    System.debug('The email was sent successfully.');
                } 
                else
                {
                    
                    System.debug('The email failed to send:'+results[0].errors[0].message);
                }
            }
            else    //if attachment in pdf is disabled and only 1 SO is there
            {
                List<Messaging.SingleEmailMessage> mails =  new List<Messaging.SingleEmailMessage>();
                String orderNames = '';
                Sales_Order__c mailSO = new Sales_Order__c();
                for(Sales_Order__c SO : soList)
                {
                    orderNames += SO.Name+',';
                    mailSO = SO;
                }
                orderNames = orderNames.substringBeforeLast(',');
                Date EXFactoryDate = mailSO.Expected_Delivery_Date__c;
                string BillTovalue = mailSO.Bill_to_Postcode__c!=null?mailSO.Bill_to_Postcode__c:'';
                
                string ShipTovalue = mailSO.Ship_to_Postcode__c!=null?mailSO.Ship_to_Postcode__c:'';
                
                /*      Map<string,CommunityConfiguration__c> ConfigSettings = CommunityConfiguration__c.getAll();
CommunityConfiguration__c config = null;
if(ConfigSettings.containsKey('CommunityConfiguration'))
{
config = ConfigSettings.get('CommunityConfiguration');
}  

string orderToCompanytoconv = companyNameandAPI.get(mailSO.Company__c); 
RegistrationService.ToEmailandCCEmailWrapper Regwrap = RegistrationService.getMailAddresses(orderToCompanytoconv, mailSO.Retailer_Code1__r.Market_Segment__c ,config);
system.debug('Regwrap>>'+Regwrap);
*/   
                string subject = 'MagNET Order has been Created for '+orderNames+' (Retailer code: '+ mailSO.Retailer_Code2__c +')';
                
                string  emailBody = 'Dear '+mailSO.Supplier_Contact__r.name+', <br />'+'<br />Thank you for using MagNET. Your submitted order is received and under processing by Mainetti.' + 
                    '<br /><br />'+'Customer Contact: '+mailSO.Supplier1__c+' / '+mailSO.Supplier_Email__c+
                    '<br /><br />'+'Retailer code: '+ mailSO.Retailer_Code2__c +
                    '<br /><br />'+'MagNET Order: '+orderNames+
                    '<br /><br />'+'Expected Ex-Factory Date: '+EXFactoryDate.format()+
                    '<br /><br />'+'Order to Company: '+mailSO.Company__c+
                    '<br /><br />'+'Bill To: '+
                    '<br />'+mailSO.Bill_to_Factory__c+
                    '<br />'+mailSO.Bill_To_Address1__c+
                    '<br />'+mailSO.Bill_to_City__c+
                    '<br />'+mailSO.Bill_to_State__c+
                    '<br />'+BillTovalue+
                    '<br />'+mailSO.Bill_to_Country__c+
                    '<br />'+mailSO.Bill_To_Contact__c+
                    '<br />'+mailSO.Bill_to_Tel__c+
                    
                    '<br /><br />'+'Ship To: '+
                    '<br />'+mailSO.Ship_to_Factory__c+
                    '<br />'+mailSO.Ship_to_Address1__c+
                    '<br />'+mailSO.Ship_to_City__c+
                    '<br />'+mailSO.Ship_to_State__c+
                    '<br />'+ShipTovalue+
                    '<br />'+mailSO.Ship_to_Country__c+
                    '<br />'+mailSO.Ship_To_Contact__c+
                    '<br />'+mailSO.Ship_to_Tel__c+
                    
                    '<br /><br />' +'Mainetti Sales/CS Team will get back to you for order details soon.'+
                    '<br /><br />' +'Thanks.'+
                    '<br /><br />' +'MagNET Team';
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                
                
                String sendTo;
                String[] toAddresses = new String[] {mailSO.Supplier_Email__c};
                    //   OrgWideEmailAddress owd = [select Id,Address,DisplayName from OrgWideEmailAddress where DisplayName=:config.Organization_Wide_Email_Address__c  limit 1];
                    System.debug('owd>>>'+owd);             
                System.debug('toAddresses>>>'+toAddresses);
                mail.setOrgWideEmailAddressId(owd.id); 
                mail.setToAddresses(toAddresses);
                mail.setSubject(subject);
                mail.setHtmlBody(emailBody);
                mail.setSaveAsActivity(false);
                
                mails.add(mail);
                Messaging.SendEmailResult[] results = Messaging.sendEmail(mails);
                
                if (results[0].success) 
                {
                    System.debug('The email was sent successfully.');
                } 
                else
                {
                    
                    System.debug('The email failed to send:'+results[0].errors[0].message);
                }
            }
            
        }
        catch(Exception e)
        {
            
            System.debug('Inside exception>>>'+e.getMessage());
            System.debug('Inside exception LineNumber >>>'+e.getLineNumber());
            System.debug('Inside exception getTypeName>>>'+e.getTypeName());
            System.debug('Inside exception getStackTraceString>>>'+e.getStackTraceString());
            
        }
    } 
    
    //method to send emails to retailers after po is converted to SO
    
    public static void adminEmailAfterPOtoSOconversion(Map<Id,Sales_Order__c> SalesOrderMap)
    {
        try{
            List<Messaging.SingleEmailMessage> mails =  new List<Messaging.SingleEmailMessage>();
            
            Map<string,CommunityConfiguration__c> ConfigSettings = CommunityConfiguration__c.getAll();
            CommunityConfiguration__c config = null;
            if(ConfigSettings.containsKey('CommunityConfiguration'))
            {
                config = ConfigSettings.get('CommunityConfiguration');
            }  
            
            Map<String,String> companyNameandAPI = UtilityClass.getOrderToCompanyPicklist(false);
            List<string> companynames = new List<string>();
            List<string> retailerMarketSegment = new List<string>();
            for(Sales_Order__c newSOList : [Select id,name,Company__c,Retailer_Code1__c,Retailer_Code1__r.Name,Retailer_Code1__r.Market_Segment__c,Supplier__r.Name,Supplier__c,Supplier_Contact__r.Name,Supplier_Contact__r.Email,Expected_Delivery_Date__c,
                                            Bill_to_Factory__c, Bill_To_Address1__c, Bill_to_City__c, Bill_to_State__c, Bill_to_Postcode__c, Bill_to_Country__c, Bill_to_Tel__c, Bill_To_Contact__c,
                                            Ship_to_Factory__c, Ship_to_Address1__c, Ship_to_City__c, Ship_to_State__c, Ship_to_Postcode__c, Ship_to_Country__c, Ship_to_Tel__c, Ship_To_Contact__c
                                            from Sales_Order__c where Id IN: SalesOrderMap.keyset()])
            {
                string orderToCompanytoconv = companyNameandAPI.get(newSOList.Company__c);
                companynames.add(companyNameandAPI.get(newSOList.Company__c));
                retailerMarketSegment.add(newSOList.Retailer_Code1__r.Market_Segment__c);
                // RegistrationService.ToEmailandCCEmailWrapper Regwrap = RegistrationService.getMailAddressesBulkify(companynames, retailerMarketSegment ,config);
                //system.debug('Regwrap>>'+Regwrap);
            }
            system.debug('companynames???'+companynames);
            system.debug('retailerMarketSegment???'+retailerMarketSegment);
            RegistrationService.ToEmailandCCEmailWrapper Regwrap = RegistrationService.getMailAddressesBulkify(companynames, retailerMarketSegment ,config);
            
            
            for(Sales_Order__c newSO : [Select id,name,Company__c,Retailer_Code1__c,Retailer_Code1__r.Name,Retailer_Code1__r.Market_Segment__c,Supplier__r.Name,Supplier__c,Supplier_Contact__r.Name,Supplier_Contact__r.Email,Expected_Delivery_Date__c,
                                        Bill_to_Factory__c, Bill_To_Address1__c, Bill_to_City__c, Bill_to_State__c, Bill_to_Postcode__c, Bill_to_Country__c, Bill_to_Tel__c, Bill_To_Contact__c,
                                        Ship_to_Factory__c, Ship_to_Address1__c, Ship_to_City__c, Ship_to_State__c, Ship_to_Postcode__c, Ship_to_Country__c, Ship_to_Tel__c, Ship_To_Contact__c
                                        from Sales_Order__c where Id IN: SalesOrderMap.keyset()])
            {
                
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                date EXFactory = newSO.Expected_Delivery_Date__c;
                string orderToCompanytoconv = companyNameandAPI.get(newSO.Company__c); 
                
                //RegistrationService.ToEmailandCCEmailWrapper Regwrap = RegistrationService.getMailAddresses(orderToCompanytoconv, newSO.Retailer_Code1__r.Market_Segment__c ,config);
                system.debug('Regwrap>>'+Regwrap);
                
                String RecordsLink='';
                
                string subject = 'Sales Order has been Created for '+newSO.Name+'(Retailer code: '+ newSO.Retailer_Code1__r.Name +')';
                RecordsLink += '<a href= '+config.My_Domain__c+'/'+newSO.Id+'>'+newSO.Name+'</a>'+'<br/><br />';
                
                string BillToPostCode = newSO.Bill_to_Postcode__c!=null?newSO.Bill_to_Postcode__c:'';
                string ShipToPostCode = newSO.Ship_to_Postcode__c!=null?newSO.Ship_to_Postcode__c:'';
                
                
                string  emailBody = 'Dear all, <br /><br />'+newSO.Supplier_Contact__r.Name+' has Submitted below MagNET Order, please reference to the link below for the order details.' + '<br /><br />' +
                    +RecordsLink+
                    '<br />'+'Customer Contact: '+newSO.Supplier_Contact__r.Name+' / '+newSO.Supplier_Contact__r.Email+
                    '<br /><br />'+'Retailer code: '+ newSO.Retailer_Code1__r.Name +
                    '<br /><br />'+'MagNET Order: '+newSO.Name+
                    '<br /><br />'+'Expected Ex-Factory Date: '+EXFactory.format()+
                    '<br /><br />'+'Order to Company: '+newSO.Company__c+
                    '<br /><br />'+'Bill To: '+
                    '<br />'+newSO.Bill_to_Factory__c+
                    '<br />'+newSO.Bill_To_Address1__c+
                    '<br />'+newSO.Bill_to_City__c+
                    '<br />'+newSO.Bill_to_State__c+
                    '<br />'+BillToPostCode+
                    '<br />'+newSO.Bill_to_Country__c+
                    '<br />'+newSO.Bill_To_Contact__c+
                    '<br />'+newSO.Bill_to_Tel__c+
                    
                    '<br /><br />'+'Ship To: '+
                    '<br />'+newSO.Ship_to_Factory__c+
                    '<br />'+newSO.Ship_to_Address1__c+
                    '<br />'+newSO.Ship_to_City__c+
                    '<br />'+newSO.Ship_to_State__c+
                    '<br />'+ShipToPostCode+
                    '<br />'+newSO.Ship_to_Country__c+
                    '<br />'+newSO.Ship_To_Contact__c+
                    '<br />'+newSO.Ship_to_Tel__c+
                    
                    '<br /><br />' +'Thanks.'+
                    '<br /><br />' +'MagNET Team';
                
                String sendTo;
                mail.setCCAddresses(Regwrap.toCCAddresses);
                mail.setToAddresses(Regwrap.toAddresses);
                mail.setSubject(subject);
                mail.setHtmlBody(emailBody);
                mail.setSenderDisplayName('Sales order submitted');        // from name in the mail 
                mail.setSaveAsActivity(false);
                mails.add(mail);
            }
            Messaging.SendEmailResult[] results = Messaging.sendEmail(mails);
            
            //Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);
            if (results[0].success) 
            {
                System.debug('The email was sent successfully.');  
            } else
            {
                System.debug('The email failed to send:'+results[0].errors[0].message);
            }
            
        }
        catch(Exception e)
        {
            System.debug('Inside exception>>>'+e.getMessage());
            System.debug('Inside exception LineNumber >>>'+e.getLineNumber());
            System.debug('Inside exception getTypeName>>>'+e.getTypeName());
            System.debug('Inside exception getStackTraceString>>>'+e.getStackTraceString());
            
        }
    }
    
    //to cancel PO changes when pressed cancel in the SO confirmation page
    @auraEnabled
    public static void cancelPOChanges(String POString)
    {
        POViewPageHandler.revertPOChanges(POString);
    }
    
    // Added by Vidit to save Catalog Orders
    @AuraEnabled
    public static String SaveOrder(String custInfoid, Sales_Order__c SO, Ship_Bill_Address__c BillAddress, Ship_Bill_Address__c shipAddress,Ship_Bill_Address__c invoiceAddress,Ship_Bill_Address__c buyerAddress)
    {
        boolean suzhouFlag = false;
        
        system.debug('SO : '+SO);
        
        
        Sales_Order__c cartSO = UtilityClass.getSORecordAsCart(custInfoid);
        Sales_Order__c cartToOrder = new Sales_Order__c();
        system.debug('cartSO>>'+cartSO);
        if(cartSO.Id != null)
            cartToOrder.Id = cartSO.Id;
        List<Contact> RetailerCon = [select id, name, RetailerCode__c, Customer_Information__c from contact where RetailerCode__c =: cartSO.Retailer_Code1__c limit 1];
        system.debug('RetailerCon>>'+RetailerCon);
        if(RetailerCon.size()>0)
        {
            cartToOrder.Retailer_Contact__c = RetailerCon[0].id;
            cartToOrder.Retailer__c = RetailerCon[0].Customer_Information__c;
        }
        
        if(cartSO.Company__c.contains('Suzhou'))
        {
            suzhouFlag = true;
        }
        system.debug('cartToOrder>>>'+cartToOrder);
        cartToOrder.Supplier__c = custInfoid;
        cartToOrder.recordtypeId = OrderRecordType;
        cartToOrder.Status__c = 'Order Submitted';  
        cartToOrder.Enquiry_Status__c = 'Order submitted';  
        cartToOrder.Link_To_ERP__c = 'New'; 
        cartToOrder.Expected_Delivery_Date__c = SO.Expected_Delivery_Date__c;
        cartToOrder.Expected_Completion_Date__c = SO.Expected_Delivery_Date__c;
        cartToOrder.Delivery_Instructions__c = SO.Delivery_Instructions__c;
        cartToOrder.Factory_Internal_PO__c = SO.Factory_Internal_PO__c;
        // override suplier code and Manufacture Code
        cartToOrder.Supplier_Code__c = SO.Supplier_Code__c;
        cartToOrder.Manufacturer_Code__c = SO.Manufacturer_Code__c;
        cartToOrder.Season__c = SO.Season__c;
        cartToOrder.Season_Year__c = SO.Season_Year__c;
        cartToOrder.Division__c = SO.Division__c;
        cartToOrder.Brand_Label__c = SO.Brand_Label__c;
        cartToOrder.Remarks__c = SO.Remarks__c;
        cartToOrder.Transportation_Details__c = SO.Transportation_Details__c;
        cartToOrder.Shipping_Mark__c = SO.Shipping_Mark__c;
        cartToOrder.Order_Number__c = SO.Order_Number__c;
        system.debug('SO : '+SO+' cartToOrder:: '+cartToOrder);
        
        cartToOrder = UtilityClass.assignBillToAdd(cartToOrder,BillAddress);
        cartToOrder = UtilityClass.assignShipToAdd(cartToOrder,shipAddress);
        
        if(suzhouFlag == true && buyerAddress != null)
        {
            cartToOrder.Buyer_Address__c = buyerAddress.Id;
        }
        if(suzhouFlag == true && invoiceAddress != null)
        {
            cartToOrder.Invoice_To_Address__c = invoiceAddress.Id;
        }   
        
        upsert cartToOrder;
        System.debug('after update'+cartToOrder);
        List<Sales_Order_Line_Items__c> SoliList=new List<Sales_Order_Line_Items__c>();
        SoliList =[select id, name, Sales_Order__c, Sales_Order__r.Retailer_Code1__c,Supply_Quantity__c, Quantity__c, Expected_Delivery_Date__c, Status__c, Price_Product_by_Currency__c,Online_Detail_Status__c, Price_Product_by_Currency__r.Price_100_pcs__c, Price_Specification_Book_Product__r.USD_Rebate_pc__c, Price_Specification_Book_Product__r.EUR_Rebate_pc__c, Price_Specification_Book_Product__r.USD_Reuse_Rebate_pc__c, Price_Specification_Book_Product__r.EUR_Reuse_Rebate_pc__c,Price_Specification_Book_Product__r.RFIDSerial__c  from Sales_Order_Line_Items__c where Sales_Order__c=:cartToOrder.id ];
        system.debug('SoliList>>>>'+SoliList);
        
        for( Sales_Order_Line_Items__c soli : SoliList) 
        {
            Soli.Expected_Delivery_Date__c = cartToOrder.Expected_Delivery_Date__c;
            Soli.Expected_Completion_Date__c = cartToOrder.Expected_Delivery_Date__c;
            Soli.Status__c = 'Order Submitted';
            Soli.Online_Detail_Status__c = 'Order submitted';
            //condition added by seema
            if(soli.Price_Product_by_Currency__r.Price_100_pcs__c!=null){
                Soli.Price_100_pcs__c = String.valueof(soli.Price_Product_by_Currency__r.Price_100_pcs__c);
                Soli.Price_1000_pcs__c = String.valueof((soli.Price_Product_by_Currency__r.Price_100_pcs__c)*10);
            }
            Soli.USD_Rebate_pc__c = soli.Price_Specification_Book_Product__r.USD_Rebate_pc__c;
            Soli.EUR_Rebate_pc__c = soli.Price_Specification_Book_Product__r.EUR_Rebate_pc__c;
            Soli.USD_Reuse_Rebate_pc__c = soli.Price_Specification_Book_Product__r.USD_Reuse_Rebate_pc__c;
            Soli.EUR_Reuse_Rebate_pc__c = soli.Price_Specification_Book_Product__r.EUR_Reuse_Rebate_pc__c;
        }
        upsert SoliList;
        System.debug('after update'+SoliList);
        
        /*Phase 2.1 Code For carelabel Export by  seema*/
        if(cartSO.OrderSource__c=='Cloned')
        { 
            CarelabelExportCloneController.saveCarelabelCloneDetails(cartSO,cartSO.Retailer_Code1__c,cartToOrder.Supplier__c);
        }
        else{ 
            system.debug('Inside Else Condition');
            CareLabelExportController.saveCarelabelDetails(cartSO,cartSO.Retailer_Code1__c,cartToOrder.Supplier__c);
        }
        /*Code For carelabel Export Object END*/
        
        /* code for RFID generation by chandana */
        Boolean IsRevised = false;
        Map<Sales_Order_Line_Items__c,boolean> ReviseMap;
        string retailcode = SoliList[0].Sales_Order__r.Retailer_Code1__c;
        System.enqueueJob(new RFIDNumGeneartion(SoliList, IsRevised,ReviseMap,retailcode));
        /* code for RFID generation END*/ 
        
        /*data from So to Mail to customer*/
        string ordertocompany= cartSO.Company__c ;
        string RetailerSegment= cartSO.Retailer_Code1__r.Market_Segment__c;
        string RetailerName = cartSO.Retailer_Code2__c;
        string BillContact = BillAddress.Contact__c;
        string shipContact = shipAddress.Contact__c;
        string SOName = cartSO.Sales_Order_Number_For_Report__c;
        Id SOID = cartSO.Id;
        string CustomerName = cartSO.Supplier1__c;
        string customerEmail = cartSO.Supplier_Contact__r.Email;
        
        string mailresponce = sendSOEmail(ordertocompany,RetailerSegment,SOName,CustomerName,SOID,RetailerName,cartToOrder,shipContact,BillContact,customerEmail);
        system.debug('mailresponce>>'+mailresponce);
        
        return cartSO.Id;
    }
    //After the submittion of SO (Email functionality) by chandana
    public static string sendSOEmail(string ordertocompany,string RetailerSegment,string SOName,String CustomerName,Id SOID, string RetailerName,Sales_Order__c SOdetails,string shipContact,string BillContact,string customerEmail)
    {
        String returnString;
        try{
            date EXFactory = SOdetails.Expected_Delivery_Date__c;
            Map<string,CommunityConfiguration__c> ConfigSettings = CommunityConfiguration__c.getAll();
            CommunityConfiguration__c config = null;
            if(ConfigSettings.containsKey('CommunityConfiguration'))
            {
                config = ConfigSettings.get('CommunityConfiguration');
            }  
            
            Map<String,String> companyNameandAPI = UtilityClass.getOrderToCompanyPicklist(false);
            string orderToCompanytoconv = companyNameandAPI.get(ordertocompany); 
            String RecordsLink='';
            RegistrationService.ToEmailandCCEmailWrapper Regwrap = RegistrationService.getMailAddresses(orderToCompanytoconv, RetailerSegment ,config);
            
            List<Messaging.SingleEmailMessage> mails =  new List<Messaging.SingleEmailMessage>();
            string subject = 'Sales Order has been Created for '+SOName+'(Retailer code: '+ RetailerName +')';
            RecordsLink += '<a href= '+config.My_Domain__c+'/'+SOID+'>'+SOName+'</a>'+'<br/><br />';
            
            string BillToPostCode = SOdetails.Bill_to_Postcode__c!=null?SOdetails.Bill_to_Postcode__c:'';
            string ShipToPostCode = SOdetails.Ship_to_Postcode__c!=null?SOdetails.Ship_to_Postcode__c:'';
            
            string  emailBody = 'Dear all, <br /><br />'+CustomerName+' has Submitted below MagNET Order, please reference to the link below for the order details.' + '<br /><br />' +
                +RecordsLink+
                '<br />'+'Customer Contact: '+CustomerName+' / '+customerEmail+
                '<br /><br />'+'Retailer code: '+ RetailerName +
                '<br /><br />'+'MagNET Order: '+SOName+
                '<br /><br />'+'Expected Ex-Factory Date: '+EXFactory.format()+
                '<br /><br />'+'Order to Company: '+ordertocompany+
                '<br /><br />'+'Bill To: '+
                '<br />'+SOdetails.Bill_to_Factory__c+
                '<br />'+SOdetails.Bill_To_Address1__c+
                '<br />'+SOdetails.Bill_to_City__c+
                '<br />'+SOdetails.Bill_to_State__c+
                '<br />'+BillToPostCode+
                '<br />'+SOdetails.Bill_to_Country__c+
                '<br />'+BillContact+
                '<br />'+SOdetails.Bill_to_Tel__c+
                
                '<br /><br />'+'Ship To: '+
                '<br />'+SOdetails.Ship_to_Factory__c+
                '<br />'+SOdetails.Ship_to_Address1__c+
                '<br />'+SOdetails.Ship_to_City__c+
                '<br />'+SOdetails.Ship_to_State__c+
                '<br />'+ShipToPostCode+
                '<br />'+SOdetails.Ship_to_Country__c+
                '<br />'+shipContact+
                '<br />'+SOdetails.Ship_to_Tel__c+
                
                '<br /><br />' +'Thanks.'+
                '<br /><br />' +'MagNET Team';
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            
            String sendTo;
            mail.setCCAddresses(Regwrap.toCCAddresses);
            mail.setToAddresses(Regwrap.toAddresses);
            mail.setSubject(subject);
            mail.setHtmlBody(emailBody);
            mail.setSenderDisplayName('Sales order submitted');        // from name in the mail 
            mail.setSaveAsActivity(false);
            mails.add(mail);
            Messaging.SendEmailResult[] results = Messaging.sendEmail(mails);
            
            if (results[0].success) 
            {
                System.debug('The email was sent successfully.');
                returnString = 'success';   
            } else
            {
                
                System.debug('The email failed to send:'+results[0].errors[0].message);
                returnString = 'Error During Email sending to the registered customer';
            }
            
        }
        catch(Exception e)
        {
            
            returnString = e.getMessage() + e.getLineNumber();
            System.debug('Inside exception>>>'+e.getMessage());
            System.debug('Inside exception LineNumber >>>'+e.getLineNumber());
            System.debug('Inside exception getTypeName>>>'+e.getTypeName());
            System.debug('Inside exception getStackTraceString>>>'+e.getStackTraceString());
            
        }
        return returnString;
    } 
    
    //sending email to customers on confirming order
    @auraEnabled
    public static string sendSOEmailToCustomer(Id SOID)
    {
        Sales_Order__c mailSO = [Select id,name,Company__c,Supplier1__c,Retailer_Code1__c,Retailer_Code1__r.Name,Retailer_Code1__r.Market_Segment__c,Retailer_Code1__r.Attach_PDF_in_MagNET_Email__c,Supplier__r.Name,Supplier__c, OrderSource__c, Supplier_Email__c, Supplier_Contact__r.name,Sales_Order_Number_For_Report__c,Retailer_Code2__c,Expected_Delivery_Date__c,Bill_to_Factory__c,Bill_To_Address1__c,Bill_to_City__c,Bill_to_State__c,Bill_to_Postcode__c,Bill_to_Country__c,Bill_To_Contact__c,Bill_to_Tel__c,Ship_to_Factory__c,Ship_to_Address1__c,Ship_to_City__c,Ship_to_State__c,Ship_to_Postcode__c,Ship_to_Country__c,Ship_To_Contact__c,Ship_to_Tel__c from Sales_Order__c where Id =: SOID];    //query made to get name of SO
        system.debug('mailSO>>'+mailSO);
        // code to send the Email once the So is created by chandana 
        string ordertocompany= mailSO.Company__c ;
        string RetailerSegment= mailSO.Retailer_Code1__r.Market_Segment__c;
        string SOName = mailSO.Name;
        string RetailerName = mailSO.Retailer_Code2__c;
        string CustomerName = mailSO.Supplier__r.Name;
        String source = mailSO.OrderSource__c;
        String SONumberForReport = mailSO.Sales_Order_Number_For_Report__c;
        Date EXFactoryDate = mailSO.Expected_Delivery_Date__c;
        
        string BillTovalue = mailSO.Bill_to_Postcode__c!=null?mailSO.Bill_to_Postcode__c:'';
        string ShipTovalue = mailSO.Ship_to_Postcode__c!=null?mailSO.Ship_to_Postcode__c:'';
        
        String returnString = 'success';
        try{
            Map<string,CommunityConfiguration__c> ConfigSettings = CommunityConfiguration__c.getAll();
            
            CommunityConfiguration__c config = null;
            if(ConfigSettings.containsKey('CommunityConfiguration'))
            {
                config = ConfigSettings.get('CommunityConfiguration');
            }  
            
            Map<String,String> companyNameandAPI = UtilityClass.getOrderToCompanyPicklist(false);
            string orderToCompanytoconv = companyNameandAPI.get(ordertocompany); 
            String RecordsLink='';
            RegistrationService.ToEmailandCCEmailWrapper Regwrap = RegistrationService.getMailAddresses(orderToCompanytoconv, RetailerSegment ,config);
            List<Messaging.SingleEmailMessage> mails =  new List<Messaging.SingleEmailMessage>();
            string subject = 'MagNET Order has been Created for '+SONumberForReport+' (Retailer code: '+ RetailerName +')';
            RecordsLink += '<a href= '+config.My_Domain__c+'/'+SOID+'>'+SOName+'</a>'+'<br/><br />';
            
            string  emailBody = 'Dear '+mailSO.Supplier_Contact__r.name+', <br />'+'<br />Thank you for using MagNET. Your submitted order is received and under processing by Mainetti.' + 
                '<br /><br />'+'Customer Contact: '+mailSO.Supplier1__c+' / '+mailSO.Supplier_Email__c+
                '<br /><br />'+'Retailer code: '+ RetailerName +
                '<br /><br />'+'MagNET Order: '+SONumberForReport+
                '<br /><br />'+'Expected Ex-Factory Date: '+EXFactoryDate.format()+
                '<br /><br />'+'Order to Company: '+ordertocompany+
                '<br /><br />'+'Bill To: '+
                '<br />'+mailSO.Bill_to_Factory__c+
                '<br />'+mailSO.Bill_To_Address1__c+
                '<br />'+mailSO.Bill_to_City__c+
                '<br />'+mailSO.Bill_to_State__c+
                '<br />'+BillTovalue+
                '<br />'+mailSO.Bill_to_Country__c+
                '<br />'+mailSO.Bill_To_Contact__c+
                '<br />'+mailSO.Bill_to_Tel__c+
                
                '<br /><br />'+'Ship To: '+
                '<br />'+mailSO.Ship_to_Factory__c+
                '<br />'+mailSO.Ship_to_Address1__c+
                '<br />'+mailSO.Ship_to_City__c+
                '<br />'+mailSO.Ship_to_State__c+
                '<br />'+ShipTovalue+
                '<br />'+mailSO.Ship_to_Country__c+
                '<br />'+mailSO.Ship_To_Contact__c+
                '<br />'+mailSO.Ship_to_Tel__c+
                
                '<br /><br />' +'Mainetti Sales/CS Team will get back to you for order details soon.'+
                '<br /><br />' +'Thanks.'+
                '<br /><br />' +'MagNET Team';
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            
            /*** Creating email attachment starts ***/
            
            PageReference pdf = Page.SOConfirmationPDF;
            pdf.getParameters().put('id',SOID);
            pdf.setRedirect(true);
            
            try
            {
                if(mailSO.Retailer_Code1__r.Attach_PDF_in_MagNET_Email__c)
                {
                    // Take the PDF content
                    Blob b = pdf.getContent();
                    
                    Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
                    String filename = SOName +'.pdf';
                    efa.setFileName(filename);
                    efa.setBody(b);
                    System.debug('efa>>>'+efa);
                    mail.setFileAttachments(new Messaging.EmailFileAttachment[] {efa});
                }
                /*** Creating email attachment starts ***/
            }
            catch(Exception e)
            {
                System.debug('Inside exception>>>'+e.getMessage());
                System.debug('Inside exception LineNumber >>>'+e.getLineNumber());
                System.debug('Inside exception getTypeName>>>'+e.getTypeName());
                System.debug('Inside exception getStackTraceString>>>'+e.getStackTraceString());
            }
            String sendTo;
            String[] toAddresses = new String[] {mailSO.Supplier_Email__c};
                OrgWideEmailAddress owd = [select Id,Address,DisplayName from OrgWideEmailAddress where DisplayName=:config.Organization_Wide_Email_Address__c  limit 1];
            mail.setOrgWideEmailAddressId(owd.id); 
            mail.setToAddresses(toAddresses);
            mail.setSubject(subject);
            mail.setHtmlBody(emailBody);
            //mail.setSenderDisplayName('Sales order submitted');        // from name in the mail 
            mail.setSaveAsActivity(false);
            mails.add(mail);
            Messaging.SendEmailResult[] results = Messaging.sendEmail(mails);
            
            if (results[0].success) 
            {
                System.debug('The email was sent successfully.');
                returnString = 'success';   
            } else
            {
                System.debug('The email failed to send:'+results[0].errors[0].message);
                returnString = 'Error During Email sending to the registered customer';
            }
            
        }
        catch(Exception e)
        { 
            returnString = e.getMessage() + e.getLineNumber();
            System.debug('Inside exception>>>'+e.getMessage());
            System.debug('Inside exception LineNumber >>>'+e.getLineNumber());
            System.debug('Inside exception getTypeName>>>'+e.getTypeName());
            System.debug('Inside exception getStackTraceString>>>'+e.getStackTraceString());
            
        }
        return returnString;
    } 
    // Added by Vidit fetch Shipping and Billing address
    @AuraEnabled
    public static addressWrapper FetchCustAdd(String custInfoid,String retailer, String retailercodeId, String orderSource, String supplierCode)
    {
        system.debug('orderSource>>>>'+orderSource);
        Map<String, List<String>> CompanyAndItsShippingTerms = new Map<String, List<String>>();
        Online_Enquiry__c oe = new Online_Enquiry__c();
        CompanyAndItsShippingTerms = RegistrationService.getDependentMap(oe,'Order_Country__c','Delivery_Instruction__c');
        Contact con = UtilityClass.getCurrentUserContact();
        String CompName;
        String currencyName;
        boolean iscloned = false;
        Sales_Order__c cartSO = new Sales_Order__c();
        
        for(Retailer_Related_Data__c rrd:[Select Id,Order_to_Company__c,Preferred_Currency__c from Retailer_Related_Data__c where ContactID__c =:con.Id AND Status__c = 'Active' AND Retailer_Code__c =:retailercodeId ])
        {
            system.debug('rrd getcostomerinfo'+rrd);
            //contactid.Order_to_Company1__c=companyNameandAPI.get(contactid.Order_to_Company1__c);
            con.Order_to_Company__c=rrd.Order_to_Company__c;
            con.Preferred_Currency__c=rrd.Preferred_Currency__c;
            
        }
        
        system.debug('comapny>>>>'+con.Order_to_Company__c+'currency>>>>'+con.Preferred_Currency__c);
        system.debug('CompanyAndItsShippingTerms>>>>'+CompanyAndItsShippingTerms);
        if(orderSource == 'PO')
        {
            Map<String,String> companyAPIandName = UtilityClass.getOrderToCompanyPicklist(true);
            if(companyAPIandName.containskey(con.Order_to_Company__c))
            {
                CompName=companyAPIandName.get(con.Order_to_Company__c);
            }
            else if(con.Order_to_Company__c != null)
            {
                CompName = con.Order_to_Company__c;
            }
            
            String CurrCode;
            if(con.Preferred_Currency__c.contains('-'))
            {
                String [] currencySplit = con.Preferred_Currency__c.split('-');
                
                if(currencySplit.size()>1)
                {
                    String ResCurr = currencySplit[0].trim();
                    CurrCode = ResCurr;
                }
            }
            else
            {
                CurrCode = con.Preferred_Currency__c;
            }
            
            Map<String,String> currencyAPIandName = UtilityClass.getPreferredCurrencyPicklist(true);
            system.debug('CurrCode>>>>'+CurrCode);
            if(currencyAPIandName.containskey(CurrCode))
            {
                currencyName=currencyAPIandName.get(CurrCode);
            }
        }
        else
        {
            cartSO = UtilityClass.getSORecordAsCart(custInfoid);
            system.debug('cartSO>>>>'+cartSO);
            
            Schema.DescribeFieldResult companyResult = Online_Enquiry__c.Order_Country__c.getDescribe();
            List<Schema.PicklistEntry> values = companyResult.getPicklistValues();
            
            for( Schema.PicklistEntry v : values) 
            {
                if(v.getLabel() == cartSO.Company__c)
                {
                    System.debug('PicklistEntry name'+v.getLabel()+' API name '+v.getValue());
                    CompName = v.getLabel();
                    break;
                }
            }
            
            String [] currencySplit = cartSO.CurrencyIsoCode.split('-');
            String CurrCode;
            if(currencySplit.size()>1)
            {
                String ResCurr = currencySplit[0].trim();
                CurrCode = ResCurr;
            }
            else
            {
                CurrCode = cartSO.CurrencyIsoCode;
            }
            
            Map<String,String> currencyAPIandName = UtilityClass.getPreferredCurrencyPicklist(true);
            system.debug('CurrCode>>>>'+CurrCode);
            if(currencyAPIandName.containskey(CurrCode))
            {
                currencyName=currencyAPIandName.get(CurrCode);
            }
            system.debug('OrderSource>>>>'+cartSO.OrderSource__c);
            if(cartSO.OrderSource__c == 'Cloned')
            {
                iscloned = true;
            }
        }
        system.debug('CompName>>>>'+CompName);
        system.debug('currencyName>>>>'+currencyName);
        addressWrapper addWrap = new addressWrapper();
        List<Ship_Bill_Address__c> billAddress = new List<Ship_Bill_Address__c>();
        List<Ship_Bill_Address__c> shipAddress = new List<Ship_Bill_Address__c>();
        List<Ship_Bill_Address__c> buyerAddress = new List<Ship_Bill_Address__c>();
        List<Ship_Bill_Address__c> invoiceAddress = new List<Ship_Bill_Address__c>();
        
        //fetching address realted to customer and grouping them by their record types
        List<Ship_Bill_Address__c> custAddress= [select id,name,recordtype.name,Is_Default__c,Company_Name__c,Address_1__c,City__c,State__c,Country__c,Postcode__c,Factory_Name__c,Contact__c,Tel_No__c,Email_Address__c, Fax_No__c from Ship_Bill_Address__c where Customer_Information__c =: custInfoid AND Bill_Ship_Status__c=:'Active'];
        for(Ship_Bill_Address__c addss:custAddress)
        {
            if(addss.recordtype.name == 'Bill To' || addss.recordtype.name == 'Bill To Locked')
            {
                billAddress.add(addss);
            }
            else if(addss.recordtype.name == 'Ship To')
            {
                shipAddress.add(addss);
            }
            else if(addss.recordtype.name == 'Buyer')
            {
                buyerAddress.add(addss);
            }
            else if(addss.recordtype.name == 'Invoice To')
            {
                invoiceAddress.add(addss);
            }
        }
        addWrap.billAddList = billAddress;
        addWrap.shipAddList = shipAddress;
        addWrap.buyerAddList = buyerAddress;
        addWrap.invoiceAddList = invoiceAddress;
        addWrap.defaultCompany = CompName;
        addWrap.defaultCurrency = currencyName;
        
        
        
        if(CompanyAndItsShippingTerms.containskey(CompName))
        {
            addWrap.shipTermList = CompanyAndItsShippingTerms.get(CompName);
        }
        //addWrap.SuzhouFlag = con.Order_to_Company__c.contains('Suzhou');
        
        addWrap.SuzhouFlag = CompName.contains('Suzhou');
        
        //changes for retailer information section
        //to get division list values
        List<string> listValuesOfDivision = new List<string>();
        listValuesOfDivision = DependentPicklist(retailer,'Retailer_Code_Hidden__c','Division__c');
        System.debug(' listValuesOfDivision:: '+listValuesOfDivision);

        //to get Brand_Label list values
        List<string> listValuesOfBrandLabel = new List<string>();
        listValuesOfBrandLabel = DependentPicklist(retailer,'Retailer_Code_Hidden__c','Brand_Label__c');
        System.debug(' listValuesOfBrandLabel:: '+listValuesOfBrandLabel);
        
        //to get season list values
        List<string> listValuesOfSeason = new List<string>();
        listValuesOfSeason = DependentPicklist(retailer,'Retailer_Code_Hidden__c','Season__c');
        System.debug(' listValuesOfSeason:: '+listValuesOfSeason);
        
        //to get season year list values
        Schema.DescribeFieldResult seasonYearResult = Online_Enquiry__c.Season_Year__c.getDescribe();
        List<Schema.PicklistEntry> seasonYearvalues = seasonYearResult.getPicklistValues();
        List<string> listValuesOfSeasonYear = new List<string>();
        for( Schema.PicklistEntry v : seasonYearvalues) 
        {
            System.debug('PicklistEntry name'+v.getLabel()+' API name '+v.getValue());
            listValuesOfSeasonYear.add(v.getLabel());
        }
        System.debug(' listValuesOfSeasonYear:: '+listValuesOfSeasonYear);
        listValuesOfSeasonYear.sort();  //to sort years in ascending order
        
        addWrap.seasonsList = listValuesOfSeason;
        addWrap.seasonsYearList = listValuesOfSeasonYear;
        addWrap.divisionList = listValuesOfDivision;
        addWrap.brandLabelList = listValuesOfBrandLabel;
        addWrap.leadTime = 123;
        //to get suppiel code and manufacturing code
        List<Retailer_Related_Data__c> ContRetailer = new List<Retailer_Related_Data__c>();
        List<Retailer_Related_Data__c> ManfCode= [Select id,Supplier_Code__c,Manufacturer_Factory_Code__c from Retailer_Related_Data__c where Supplier_Code__c =: supplierCode and  Customer_Information__c =: custInfoid AND Retailer_Code__c =: retailercodeId];
        system.debug('ManfCode>>'+ManfCode);
        ContRetailer = [select id,Name,Supplier_Code__c,Retailer_Code__r.Supplier_Code_UnMask__c,Retailer_Code__r.Manufacturer_Code_UnMask__c,Customer_Information__c,Retailer_Code__c,Manufacturer_Factory_Code__c from Retailer_Related_Data__c where Customer_Information__c =: custInfoid AND Retailer_Code__c =: retailercodeId];
        
        if(ContRetailer[0].Retailer_Code__c != null){
            addWrap.SOUnMask = ContRetailer[0].Retailer_Code__r.Supplier_Code_UnMask__c;
            addWrap.MOUnMask = ContRetailer[0].Retailer_Code__r.Manufacturer_Code_UnMask__c;
        }
        else{
            addWrap.SOUnMask = false;
            addWrap.MOUnMask = false;
        }
        //Fetching Checkbox values for mandatory feilds according to retailer code
        List<Retailer_Code__c> MandatoryCheck = new List<Retailer_Code__c>();
        MandatoryCheck = [Select Season_Mandatory__c , Season_Year_Mandatory__c ,Retailer_PO_Mandatory__c,Division_Mandatory__c,Brand_Label_Mandatory__c,MG_Remarks_Mandatory__c from Retailer_Code__c where Id =: retailercodeId ];
        addWrap.MandatoryCheckFields=MandatoryCheck;
        
        
        system.debug('iscloned::'+iscloned);
        Sales_Order__c prototypeSO = new Sales_Order__c();
        if(iscloned)
        {
            prototypeSO = [Select Id, Name, Expected_Delivery_Date__c, Delivery_Instructions__c, Division__c,Brand_Label__c,Remarks__c, Season__c, Season_Year__c, OrderSource__c, Transportation_Details__c, Shipping_Mark__c, Bill_to_Address__c, Buyer_Address__c, Invoice_To_Address__c, Ship_to_Address__c from Sales_Order__c where Id =: cartSO.Id];
            //prototypeSO.Expected_Delivery_Date__c = Date.today();
            system.debug('today\'s date::'+System.today());
            system.debug(' date todate ::'+Date.today());
        }
        system.debug('prototypeSO::'+prototypeSO);
        prototypeSO.Supplier_Code__c=supplierCode;
        prototypeSO.Manufacturer_Code__c=ManfCode[0].Manufacturer_Factory_Code__c;
        prototypeSO.Id = cartSO.Id;
        addWrap.protoSO = prototypeSO;
        
        return addWrap;
    }
    
    //Kinda resets the order if cancelled from confirmation page
    @AuraEnabled
    public static void toCancelOrder(Sales_Order__c dOrder)
    {
        dOrder = [Select Id, name, OrderSource__c, Supplier__c, Parent_Order__c, Parent_Order__r.Bill_to_Address__c, Parent_Order__r.Ship_to_Address__c, Parent_Order__r.Buyer_Address__c, Parent_Order__r.Invoice_To_Address__c from Sales_Order__c where Id =: dOrder.Id];
        System.debug('dOrder results:'+dOrder);
        
        Ship_Bill_Address__c billAddress = new Ship_Bill_Address__c();
        Ship_Bill_Address__c shipAddress = new Ship_Bill_Address__c();
        Ship_Bill_Address__c buyerAddress = new Ship_Bill_Address__c();
        Ship_Bill_Address__c invoiceAddress = new Ship_Bill_Address__c();
        
        
        if(dOrder.OrderSource__c == 'Cloned' && dOrder.Parent_Order__c != null)
        {
            Set<Id> ParentAddId = new Set<Id>();
            ParentAddId.add(dOrder.Parent_Order__r.Bill_to_Address__c);
            ParentAddId.add(dOrder.Parent_Order__r.Ship_to_Address__c);
            ParentAddId.add(dOrder.Parent_Order__r.Buyer_Address__c);
            ParentAddId.add(dOrder.Parent_Order__r.Invoice_To_Address__c);
            
            for(Ship_Bill_Address__c addss:[select id,name,recordtype.name,Is_Default__c,Company_Name__c,Address_1__c,City__c,State__c,Country__c,Postcode__c,Factory_Name__c,Contact__c,Tel_No__c,Email_Address__c, Fax_No__c from Ship_Bill_Address__c where ID IN: ParentAddId])
            {
                if(addss.recordtype.name == 'Bill To' || addss.recordtype.name == 'Bill To Locked')
                {
                    billAddress = addss;
                }
                else if(addss.recordtype.name == 'Ship To')
                {
                    shipAddress = addss;
                }
                else if(addss.recordtype.name == 'Buyer')
                {
                    buyerAddress = addss;
                }
                else if(addss.recordtype.name == 'Invoice To')
                {
                    invoiceAddress = addss;
                }
            }
        }
        else if(dOrder.OrderSource__c == 'Catalog Order')
        {
            for(Ship_Bill_Address__c addss:[select id,name,recordtype.name,Is_Default__c,Company_Name__c,Address_1__c,City__c,State__c,Country__c,Postcode__c,Factory_Name__c,Contact__c,Tel_No__c,Email_Address__c, Fax_No__c from Ship_Bill_Address__c where Customer_Information__c =: dOrder.Supplier__c AND Bill_Ship_Status__c=:'Active' AND Is_Default__c = true])
            {
                if(addss.recordtype.name == 'Bill To' || addss.recordtype.name == 'Bill To Locked')
                {
                    billAddress = addss;
                }
                else if(addss.recordtype.name == 'Ship To')
                {
                    shipAddress = addss;
                }
                else if(addss.recordtype.name == 'Buyer')
                {
                    buyerAddress = addss;
                }
                else if(addss.recordtype.name == 'Invoice To')
                {
                    invoiceAddress = addss;
                }
            }
        }
        dOrder = UtilityClass.assignBillToAdd(dOrder,BillAddress);
        dOrder = UtilityClass.assignShipToAdd(dOrder,shipAddress);
        dOrder.Buyer_Address__c = buyerAddress.Id;
        dOrder.Invoice_To_Address__c = invoiceAddress.Id;
        
        update dOrder;
    }
    
    //to get dependent picklist values of company, or retailer codes etc
    @AuraEnabled
    public static List<string> DependentPicklist(String controllingValue, String controllingFields, String dependentField)
    {
        List<string> listToReturn = new List<string>();
        //listToReturn.add('aaa');listToReturn.add('bbb');listToReturn.add('ccc');listToReturn.add('ddd');
        
        Map<String, List<String>> ControllersAndDependents = new Map<String, List<String>>();
        Online_Enquiry__c oe = new Online_Enquiry__c();
        ControllersAndDependents = RegistrationService.getDependentMap(oe,controllingFields,dependentField);
        
        if(ControllersAndDependents.containskey(controllingValue))
        {
            listToReturn = ControllersAndDependents.get(controllingValue);
        }
        else
        {
            System.debug('retailer '+controllingValue+' not found in '+ControllersAndDependents.keyset());
        }
        return listToReturn;
    }
    
    //fetch all the salesorder in the order history tab 
    @auraEnabled
    public static ResponseWrapper FetchSalesOrders(String Status,Decimal pageNumber,String searchTxt)
    {
        System.debug('Status :'+Status+' pageNumber:'+pageNumber);
        ResponseWrapper response = new ResponseWrapper(); 
        try
        {
            
            Contact CustomerContact = UtilityClass.getCurrentUserContact();
            String CustomerInfoId = CustomerContact.Customer_Information__c;
            Id conId = CustomerContact.Id;
            Integer pageRecSize = 25;
            Integer offset = ((Integer)pageNumber - 1) * pageRecSize;
            System.debug('offset>>>>>>'+offset);
            String key  = '%'+searchTxt+'%';
            
            String SOquery;
            String SOCount;
            
            if(searchTxt==null){
                SOquery='Select Id, Name, Reference__c, Revise_Version__c,OrderSource__c,Purchase_Orders__c, Order_Number__c,CreatedDate, LastModifiedDate, Company__c, Shipment_Terms__c, Delivery_Instructions__c, Expected_Delivery_Date__c, Expected_Completion_Date__c,Status__c, Link_To_ERP__c, Enquiry_Status__c, Retailer__c, Retailer__r.Name, Retailer_Contact__c, Retailer_Contact__r.Name, Supplier__c, Supplier__r.Name, Retailer_Code1__c, Retailer_Code1__r.Name,Retailer_Code1__r.Market_Segment__c, Retailer_Code1__r.Remarks__c, Priority__c, Mainetti_Email__c, Mainetti_SO_SC__c, Ship_to_Company__c,Ship_to_Address__c,Ship_to_Address__r.Name,Ship_to_Address__r.Contact__c,Ship_to_Country__c,Ship_to_Tel__c,Ship_to_Email__c,Ship_to_Factory__c,Ship_to_Address1__c,Ship_to_State__c,Ship_to_Postcode__c,Ship_to_City__c,Factory_Internal_PO__c,Shipping_Mark__c,Transportation_Details__c';
                //SOquery+=',(Select Id, Name, CreatedDate, LastModifiedDate, Quantity__c, Expected_Delivery_Date__c, Supply_Quantity__c, Mainetti_Model_Code__c,Full_Box_Order__c,BOX_QTY__c, Ordered_Quantity__c, Products__c, Products__r.Name, Price_Specification_Book_Product__r.Name, APN__c, DEPT_DESC__c, Style_No__c, Colour__c, Size__c, Status__c, Online_Detail_Status__c, Production_Status__c, Due_Date_TXT__c, LOCN_TXT__c, Printshop_Pick__c,Test_date_and_time__c from Sales_Order_Line_Items__r)';
                system.debug('SOquery>>'+SOquery);
                SOquery+=' from Sales_Order__c where (Supplier_Contact__c=:conId) AND recordtypeId =: OrderRecordType ';
                system.debug('SOquery>>'+SOquery);
                SOCount='SELECT count(id) totalCount FROM Sales_Order__c where (Supplier_Contact__c =:conId) AND recordtypeId =: OrderRecordType';
                if(Status!=null && Status!='NULL')
                {
                    SOquery+=' And Status__c =: Status ';
                    SOCount+=' And Status__c =: Status ';
                    
                }
                SOquery+=' Order By CreatedDate DESC';
                SOquery+=' Limit 25 OFFSET:offset';
                system.debug('SOquery>>'+SOquery);
            }
            else{
                SOquery='Select Id, Name, Reference__c, Revise_Version__c,OrderSource__c,Purchase_Orders__c, Order_Number__c,CreatedDate, LastModifiedDate, Company__c, Shipment_Terms__c, Delivery_Instructions__c, Expected_Delivery_Date__c, Expected_Completion_Date__c, Status__c, Link_To_ERP__c, Enquiry_Status__c, Retailer__c, Retailer__r.Name, Retailer_Contact__c, Retailer_Contact__r.Name, Supplier__c, Supplier__r.Name, Retailer_Code1__c, Retailer_Code1__r.Name,Retailer_Code1__r.Market_Segment__c, Retailer_Code1__r.Remarks__c, Priority__c, Mainetti_Email__c, Mainetti_SO_SC__c, Ship_to_Company__c,Ship_to_Address__c,Ship_to_Address__r.Name,Ship_to_Address__r.Contact__c,Ship_to_Country__c,Ship_to_Tel__c,Ship_to_Email__c,Ship_to_Factory__c,Ship_to_Address1__c,Ship_to_State__c,Ship_to_Postcode__c,Ship_to_City__c,Factory_Internal_PO__c,Shipping_Mark__c,Transportation_Details__c';
                
                SOquery+=' from Sales_Order__c where (Supplier_Contact__c=:conId) AND recordtypeId =: OrderRecordType ';
                //SOCount='SELECT count(id) totalCount FROM Sales_Order__c where (Supplier_Contact__c =:conId) AND (Mainetti_SO_SC__c LIKE :key OR Name LIKE :key) AND recordtypeId =: OrderRecordType';
                
                if(Status!=null && Status!='NULL')
                {
                    SOquery+=' And Status__c =: Status ';
                    //SOCount+=' And Status__c =: Status ';
                }
                SOquery+=' Order By CreatedDate DESC';
                SOquery+=' Limit 10000';
                
            }
            
            //response.totalRecords = Integer.valueOf(Database.query(SOCount)[0].get('totalCount'));
            response.pageSize = pageRecSize;
            response.page = (Integer) pageNumber;
            system.debug('SOquery>>'+SOquery);
            List<Sales_Order__c> soList = Database.query(SOquery);
            system.debug('soList>>>>>'+soList);
            Set<Id> soIdSet = new Set<Id>();
            Integer searchCounter =0;
            system.debug('searchTxt????????????'+searchTxt);
            if(searchTxt ==null){
                system.debug('if??????');
                for(Sales_Order__c order :soList)
                {
                    soIdSet.add(order.Id);
                    
                }
                
                response.totalRecords = Integer.valueOf(Database.query(SOCount)[0].get('totalCount')); 
            }else{
                system.debug('else?????');
                
                system.debug('searchTxt????????????'+searchTxt);
                for(Sales_Order__c order :soList)
                {
                    
                    if((string.isNotEmpty(order.Mainetti_SO_SC__c) && order.Mainetti_SO_SC__c.containsIgnoreCase(searchTxt)) ||
                       (string.isNotEmpty(order.Order_Number__c) && order.Order_Number__c.containsIgnoreCase(searchTxt)) ||
                       (string.isNotEmpty(order.Name) && order.Name.containsIgnoreCase(searchTxt)) ||
                       (string.isNotEmpty(order.Factory_Internal_PO__c) && order.Factory_Internal_PO__c.containsIgnoreCase(searchTxt))
                      ){
                          system.debug('if?????');
                          searchCounter++;
                          if(soIdSet.size() < 25){
                              soIdSet.add(order.Id);
                          }
                          
                      }
                    
                }
                response.totalRecords = searchCounter;
            }
            
            
            //fetching sales order lines and grouping them according to their sales order
            Map<Id,List<Sales_Order_Line_Items__c>> SOnSOLIListMap = new Map<Id,List<Sales_Order_Line_Items__c>>();
            /* Added Customer_Ref_Model__c , Price_Specification_Book_Product__r.DisplayModel__c    Ivy Lee 8 Jun 2023*/
            for(Sales_Order_Line_Items__c soli :[Select Id, Name, Sales_Order__c, CreatedDate, LastModifiedDate, Quantity__c, Expected_Delivery_Date__c, Supply_Quantity__c, Customer_Ref_Model__c,Mainetti_Model_Code__c,Full_Box_Order__c,BOX_QTY__c, Ordered_Quantity__c, Products__c, Products__r.Name, Price_Specification_Book_Product__r.Name, Price_Specification_Book_Product__r.DisplayModel__c, APN__c, DEPT_DESC__c, Style_No__c, Colour__c, Size__c, Status__c, Online_Detail_Status__c, Production_Status__c, Due_Date_TXT__c, LOCN_TXT__c, Printshop_Pick__c,Test_date_and_time__c,Expected_Completion_Date__c,Purchase_Order_LineItem__c,POLI_Text_Ids__c,POLI_Text_Name__c,variable_data_product__c,print__c, Price_Specification_Book_Product__r.MOQ__c,Remarks__c from Sales_Order_Line_Items__c where Sales_Order__c IN:soIdSet ])
            {
                if(SOnSOLIListMap.containsKey(soli.Sales_Order__c))
                {
                    SOnSOLIListMap.get(soli.Sales_Order__c).add(soli);
                }
                else
                {
                    List<Sales_Order_Line_Items__c> soliList = new List<Sales_Order_Line_Items__c>();
                    soliList.add(soli);
                    SOnSOLIListMap.put(soli.Sales_Order__c,soliList);
                }
            }
            
            List<SalesOrderWrap> SOWrapList = new List<SalesOrderWrap>();
            for(Sales_Order__c order :soList)
            {
                if(soIdSet.contains(order.Id)){
                    SalesOrderWrap SOWrap = new SalesOrderWrap();
                    SOWrap.SO = order;
                    if(SOnSOLIListMap.containsKey(order.Id))
                        SOWrap.SOLI = SOnSOLIListMap.get(order.Id);
                    SOWrapList.add(SOWrap);
                }
                
            }
            response.SOList = SOWrapList;
            
            List<String> statusList=new List<String>(); 
            Schema.SObjectType targetType = Schema.getGlobalDescribe().get('Sales_Order__c');
            Sobject Object_name = targetType.newSObject(); 
            Schema.sObjectType sobject_type = Object_name.getSObjectType(); //grab the sobject that was passed 
            Schema.DescribeSObjectResult sobject_describe = sobject_type.getDescribe(); //describe the sobject 
            Map<String, Schema.SObjectField> field_map = sobject_describe.fields.getMap(); //get a map of fields for the passed sobject 
            List<Schema.PicklistEntry> pick_list_values = field_map.get('Status__c').getDescribe().getPickListValues(); //grab the list of picklist values for the passed field on the sobject 
            
            //fetching status values to show in the order history tab
            for (Schema.PicklistEntry a : pick_list_values) 
            {
                if(a.getValue() == 'New Order' || a.getValue() == 'Customer Code Issues' || a.getValue() == 'Order Confirmed' || a.getValue() == 'Pending for change')
                {
                    //add the value to our final list 
                }
                else
                {
                    statusList.add(a.getValue());
                }
            }
            System.debug('statusList>>>'+statusList.size()+' '+statusList);
            response.ListOfStatus = statusList;
            System.debug('final response>>>'+response);
            return response;
        }
        catch (Exception e)
        {
            System.debug('e:::'+e);
            
            createErrorLog.insertError('Diasplay Sales Order and its Line Items',e.getMessage(),'Method - FetchSalesOrders',null,'',e.getStackTraceString(),UserInfo.getUserId());
            return null;
            // return e.getMessage();
        }
        //return response;
    } 
    
    //updating sales order before generating PDF to get latest changes
    @AuraEnabled
    public static String updateSalesOrderForPDF(String custInfoid, Sales_Order__c SO, Ship_Bill_Address__c BillAddress, Ship_Bill_Address__c shipAddress,Ship_Bill_Address__c invoiceAddress,Ship_Bill_Address__c buyerAddress,boolean suzhouFlag)
    {
        system.debug('SO : '+SO+' suzhouFlag: '+suzhouFlag);
        String returnVal = 'SUCCESS';
        Sales_Order__c cartSO = UtilityClass.getSORecordAsCart(custInfoid);
        Sales_Order__c soRec = new Sales_Order__c();
        
        if(cartSO.Id != null)
        {
            soRec.Id = cartSO.Id;
        }
        soRec.Expected_Delivery_Date__c = SO.Expected_Delivery_Date__c;
        soRec.Delivery_Instructions__c = SO.Delivery_Instructions__c;
        
        soRec = UtilityClass.assignBillToAdd(soRec,BillAddress);
        soRec = UtilityClass.assignShipToAdd(soRec,shipAddress);
        
        if(buyerAddress != null && suzhouFlag == true)
        {
            soRec.Buyer_Address__c = buyerAddress.Id;
        }
        if(invoiceAddress != null && suzhouFlag == true)
        {
            soRec.Invoice_To_Address__c = invoiceAddress.Id;
        }
        
        
        soRec.Division__c = SO.Division__c;
        soRec.Remarks__c = SO.Remarks__c;
        soRec.Brand_Label__c = SO.Brand_Label__c;
        soRec.Season__c = SO.Season__c;
        soRec.Season_Year__c = SO.Season_Year__c;
        soRec.Factory_Internal_PO__c = SO.Factory_Internal_PO__c;
        soRec.Transportation_Details__c = SO.Transportation_Details__c;
        soRec.Shipping_Mark__c = SO.Shipping_Mark__c;
        soRec.Order_Number__c = SO.Order_Number__c;
        try 
        {  
            upsert soRec;
            System.debug('after update'+soRec);
            returnVal = soRec.Id;
            
        }
        catch (Exception e) {
            system.debug('Exception in the last Exception');
            returnVal = e.getMessage();
        }
        return returnVal;
    }
    
    @AuraEnabled
    public static String saveCatalogSOPDF(ID SOid) 
    {
        System.debug('inside saveCatalogSOPDF::'+SOid);
        if (SOid !=NULL) 
        {
            
            Sales_Order__c soPDF = [select id,name from Sales_Order__c where id =: SOid];
            List<Attachment> pdfs = new List<Attachment>([SELECT Id, Name, ParentId, Parent.Type FROM Attachment where ParentId =: SOid]);
            //code to save SO PDF
            PageReference pdf = Page.SOConfirmationPDF;
            // create the new attachment
            Attachment attach = new Attachment();
            pdf.getParameters().put('id',SOid);
            // the contents of the attachment from the pdf
            Blob body;
            
            try 
            {
                
                // returns the output of the page as a PDF
                body = pdf.getContentAsPDF();
                system.debug('body should be fine');
                
                // need to pass unit test -- current bug    
            } 
            catch (VisualforceException e) 
            {
                system.debug('in the catch block');
                body = Blob.valueOf('Some Text');
            }
            
            attach.Body = body;
            Integer versionName = pdfs.size()+1;
            // add the user entered name
            attach.Name = soPDF.Name + ' v' + versionName +'.pdf';
            attach.IsPrivate = false;
            // attach the pdf to the account
            attach.ParentId = SOid;
            insert attach;
            system.debug('attach::'+attach);
            //initialised=true;
            return attach.Id;
        }
        else
        {
            return 'No Id found';
        }
        
    }
    @AuraEnabled
    public static String updatePOLinesForPDF(List<String> POLIQtyString)
    {
        system.debug('POLIQtyString : '+POLIQtyString);
        List<Purchase_Order_LineItem__c> POLIList = new List<Purchase_Order_LineItem__c>();
        
        for (String polistr : POLIQtyString) 
        {
            Purchase_Order_LineItem__c poli = new Purchase_Order_LineItem__c();
            String [] polistrArr = polistr.split('-');
            poli.Id = polistrArr[0];
            poli.Quantity__c = polistrArr[1];
            POLIList.add(poli);
        }       
        update POLIList;
        System.debug('after update::'+POLIList);
        
        return 'SUCCESS';
    }
    //Code for PDF ends
    
    //************* code for revise order START****************/
    @AuraEnabled
    public static ReviseOrderRequestWrap fetchRevOrderwrap(Sales_Order__c salesOrder,list<Sales_Order_Line_Items__c> salesOrderline)
    {        
        List<Revise_Order__c> reviseOrder=new List<Revise_Order__c>();
        List<orderlineitem> wraplist=new List<orderlineitem>();
        List<Revise_Order__c> ROlist=new List<Revise_Order__c>();
        ReviseOrderRequestWrap revO = new ReviseOrderRequestWrap();
        
        revO.revSO = salesOrder;
        revO.SOLI = salesOrderline;
        if(revO.revSO.Status__c != 'Order Under Processing')                   // condition for Change request only accept change of Header  when order is Confirmed 
        {
            for(Sales_Order_Line_Items__c SOLIListitem :revO.SOLI)
            {
                if(SOLIListitem.Status__c !='Cancelled' && SOLIListitem.Production_Status__c !='Under Manufacturing' && SOLIListitem.Production_Status__c !='Shipped')
                {
                    Revise_Order__c reviseOrderSOLI = new Revise_Order__c();
                    reviseOrderSOLI.Mainetti_SO__c = SOLIListitem.Sales_Order__c;
                    reviseOrderSOLI.Mainetti_SOLI__c = SOLIListitem.Id;
                    reviseOrderSOLI.Old_Quantity__c = SOLIListitem.Supply_Quantity__c;
             //   Original Ivy Lee 8 Jun 2023    reviseOrderSOLI.Customer_Refe_Model__c = SOLIListitem.Mainetti_Model_Code__c;
                    reviseOrderSOLI.Customer_Refe_Model__c = SOLIListitem.Price_Specification_Book_Product__r.DisplayModel__c;
                    reviseOrderSOLI.Box_Quantity__c = SOLIListitem.BOX_QTY__c;
                    reviseOrderSOLI.Full_Box_Quantity__c =SOLIListitem.Full_Box_Order__c ;
                    if(SOLIListitem.Purchase_Order_LineItem__c != null)
                        reviseOrderSOLI.Purchase_Orders__c =SOLIListitem.Purchase_Order_LineItem__c;
                    if(SOLIListitem.POLI_Text_Ids__c != null)
                        reviseOrderSOLI.Purchase_Orders__c =SOLIListitem.POLI_Text_Ids__c ;
                    //reviseOrderSOLI.POLI_Name_Text__c=SOLIListitem.POLI_Text_Name__c;
                    reviseOrderSOLI.variable_data_product__c =SOLIListitem.variable_data_product__c ;
                    reviseOrderSOLI.Color__c =SOLIListitem.Colour__c; 
                    reviseOrderSOLI.print__c =SOLIListitem.print__c ;
                    reviseOrderSOLI.What_to_Revise__c ='';
                    reviseOrderSOLI.Revised__c =false;
                    reviseOrderSOLI.MOQ__c =SOLIListitem.Price_Specification_Book_Product__r.MOQ__c; 
                    ROlist.add(reviseOrderSOLI); 
                }
            }  
        }
        
        revO.OrderLineList.reviseOrder = ROlist;
        List<String> pickList = new List<String>();
        Schema.DescribeFieldResult fieldResult = Revise_Order__c.Reason_to_Cancel__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for( Schema.PicklistEntry pickListVal : ple){
            if(pickListVal.getLabel() != 'Revise Order To Company' && pickListVal.getLabel() !='Revise Currency'){
                pickList.add(pickListVal.getLabel());
                System.debug('Values in Rating are: '+pickList);
            }
        } 
        revO.pickListValuesList = pickList;
        return revO;
    }
    @AuraEnabled
    public static List<Ship_Bill_Address__c> fetchShiptoAddressdetails(ID custid, ID SalesOrderAddressId)
    {
        system.debug('custid>>'+custid);
        system.debug('SalesOrderAddressId>>'+SalesOrderAddressId);
        List<Sales_Order__c> SOaddressId = [Select Supplier_Contact__r.Customer_Information__c from Sales_Order__c where Id=:custid];
        system.debug('SOaddressId>>'+SOaddressId);
        List<Customer_Information__c> CustInfoName =[Select Name From Customer_Information__c where Id=:SOaddressId[0].Supplier_Contact__r.Customer_Information__c];
        system.debug('CustInfoName>>'+CustInfoName);
        System.debug('SOaddressId>>>>'+SOaddressId[0].Supplier_Contact__r.Customer_Information__c);
        //List<Ship_Bill_Address__c> Addressdetails = [SELECT id, Name,Factory_Name__c,Address_1__c,Address_2__c,Bill_Ship_Status__c,City__c,Company_Name__c,Contact__c,Country__c,Customer_Information__c,Customer_Information__r.id,Customer_Registry__c,Email_Address__c,Fax_No__c,Is_Default__c,Other_Country_Name__c,Postcode__c,Remark__c,State__c,Tel_No__c,recordtype.name FROM Ship_Bill_Address__c WHERE Customer_Information__r.id=:custid AND recordtype.name='ship to' AND Bill_Ship_Status__c='Active'];
        List<Ship_Bill_Address__c> Addressdetails = [SELECT id, Name,Factory_Name__c,Address_1__c,Address_2__c,Bill_Ship_Status__c,City__c,Company_Name__c,Contact__c,Country__c,Customer_Information__c,Customer_Information__r.id,Customer_Registry__c,Email_Address__c,Fax_No__c,Is_Default__c,Other_Country_Name__c,Postcode__c,Remark__c,State__c,Tel_No__c,recordtype.name FROM Ship_Bill_Address__c WHERE Customer_Information__r.id=:SOaddressId[0].Supplier_Contact__r.Customer_Information__c AND Id!=:SalesOrderAddressId AND recordtype.name='ship to' AND Bill_Ship_Status__c='Active'];
        return Addressdetails;
    }
    //method to save the revise orders and set to approval process
    @AuraEnabled
    public static string SaveRevOrder(string revOrder, string ordertocompany,string RetailerCode,Date CancelDate)
    {
        if(revOrder == null)
            return 'failure';
        
        List<Revise_Order__c> desobj = (List<Revise_Order__c>)JSON.deserialize(revOrder, List<Revise_Order__c>.class);
        
        Sales_Order__c Salesorder = [select id, Name,Revise_Version__c,Status__c,Enquiry_Status__c,Link_To_ERP__c from Sales_Order__c where id =: desobj[0].Mainetti_SO__c];
        system.debug('Salesorder:::'+Salesorder);
        
        List<Revise_Order__c> roList = new List<Revise_Order__c>(); 
        Sales_Order__c so = new Sales_Order__c();
        List<Sales_Order_Line_Items__c> soli = new List<Sales_Order_Line_Items__c>();
        
        try{
            //Logic-->once the printshop downloads and customer revise the order
            //once print shop downloads only date and address needs to revise
            if(Salesorder.Status__c == 'Order Under Processing' && Salesorder.Enquiry_Status__c == 'Under Manufacturing')
            {
                for(Revise_Order__c Ro:desobj)
                {
                    Revise_Order__c roobj = new Revise_Order__c();
                    if(Ro.Revised__c == true)
                    {   
                        so.id =Ro.Mainetti_SO__c;
                        so.Enquiry_Status__c ='Pending for change approval';
                        so.Link_To_ERP__c ='Resend';
                        
                        if(Ro.What_to_Revise__c == 'Ship Date' && Ro.New_Expected_Delivery_Date__c !=null)
                        {
                            roobj.id = Ro.id;
                            roobj.Mainetti_SO__c = Ro.Mainetti_SO__c;
                            roobj.Status__c ='Approve Pending' ;
                            roobj.What_to_Revise__c =Ro.What_to_Revise__c;
                            roobj.New_Expected_Delivery_Date__c = Ro.New_Expected_Delivery_Date__c!=null?Ro.New_Expected_Delivery_Date__c:null;
                            roobj.Old_Expected_Delivery_Date__c = Ro.Old_Expected_Delivery_Date__c!=null?Ro.Old_Expected_Delivery_Date__c:null;
                            roobj.Revise_req_Version__c = Salesorder.Revise_Version__c+1;
                            roList.add(roobj);
                        }
                        else if(Ro.What_to_Revise__c == 'Ship To' && Ro.Mainetti_SO__c !=null)
                        { 
                            roobj.Mainetti_SO__c = Ro.Mainetti_SO__c;
                            roobj.Status__c ='Approve Pending' ;
                            roobj.What_to_Revise__c =Ro.What_to_Revise__c;
                            roobj.New_Bill_to_Ship_to_Address__c = Ro.New_Bill_to_Ship_to_Address__c!=null?Ro.New_Bill_to_Ship_to_Address__c:'';
                            roobj.Old_Bill_to_Ship_to_Address__c = Ro.Old_Bill_to_Ship_to_Address__c!=null?Ro.Old_Bill_to_Ship_to_Address__c:'';
                            roobj.New_Ship_to_Company__c = Ro.New_Ship_to_Company__c!=null?Ro.New_Ship_to_Company__c:'';
                            roobj.Old_Ship_to_Company__c = Ro.Old_Ship_to_Company__c!=null?Ro.Old_Ship_to_Company__c:'';
                            roobj.New_Ship_to_Address1__c = Ro.New_Ship_to_Address1__c!=null?Ro.New_Ship_to_Address1__c:'';
                            roobj.Old_Ship_to_Address1__c = Ro.Old_Ship_to_Address1__c!=null?Ro.Old_Ship_to_Address1__c:'';
                            roobj.New_Ship_to_State__c = Ro.New_Ship_to_State__c!=null?Ro.New_Ship_to_State__c:'';
                            roobj.Old_Ship_to_State__c = Ro.Old_Ship_to_State__c!=null?Ro.Old_Ship_to_State__c:'';
                            roobj.New_Ship_to_City__c = Ro.New_Ship_to_City__c!=null?Ro.New_Ship_to_City__c:'';
                            roobj.Old_Ship_to_City__c = Ro.Old_Ship_to_City__c!=null?Ro.Old_Ship_to_City__c:'';
                            roobj.New_Ship_to_Country__c = Ro.New_Ship_to_Country__c!=null?Ro.New_Ship_to_Country__c:'';
                            roobj.Old_Ship_to_Country__c = Ro.Old_Ship_to_Country__c!=null?Ro.Old_Ship_to_Country__c:'';
                            roobj.New_Ship_to_Postcode__c = Ro.New_Ship_to_Postcode__c!=null?Ro.New_Ship_to_Postcode__c:'';
                            roobj.Old_Ship_to_Postcode__c = Ro.Old_Ship_to_Postcode__c!=null?Ro.Old_Ship_to_Postcode__c:'';
                            roobj.New_Ship_to_Tel__c = Ro.New_Ship_to_Tel__c!=null?Ro.New_Ship_to_Tel__c:'';
                            roobj.Old_Ship_to_Tel__c = Ro.Old_Ship_to_Tel__c!=null?Ro.Old_Ship_to_Tel__c:'';
                            roobj.Old_Ship_to_Email__c = Ro.Old_Ship_to_Email__c!=null?Ro.Old_Ship_to_Email__c:'';
                            roobj.New_Ship_to_Email__c = Ro.New_Ship_to_Email__c!=null?Ro.New_Ship_to_Email__c:'';
                            roobj.Old_Ship_to_Contact_Name__c = Ro.Old_Ship_to_Contact_Name__c!=null?Ro.Old_Ship_to_Contact_Name__c:'';
                            roobj.New_Ship_to_Contact_Name__c = Ro.New_Ship_to_Contact_Name__c!=null?Ro.New_Ship_to_Contact_Name__c:'';
                            roobj.Revise_req_Version__c = Salesorder.Revise_Version__c+1;
                            roList.add(roobj);
                            system.debug('Ro11>>>'+Ro);
                        }
                    }
                }   
            }
            else                                                                            //else loop for before print shop downloads the order  
            {
                for(Revise_Order__c Ro:desobj)
                {
                    system.debug('Ro>>'+Ro);
                    Revise_Order__c roobj = new Revise_Order__c();
                    if(Ro.Revised__c == true)
                    {   
                        so.id =Ro.Mainetti_SO__c;
                        so.Status__c='Approve Pending';
                        so.Enquiry_Status__c ='Pending for change approval';
                        so.Link_To_ERP__c ='Resend';
                        
                        if(Ro.What_to_Revise__c == 'Ship Date' && Ro.New_Expected_Delivery_Date__c !=null)
                        {
                            roobj.id = Ro.id;
                            roobj.Mainetti_SO__c = Ro.Mainetti_SO__c;
                            roobj.Status__c ='Approve Pending' ;
                            roobj.What_to_Revise__c =Ro.What_to_Revise__c;
                            roobj.New_Expected_Delivery_Date__c = Ro.New_Expected_Delivery_Date__c!=null?Ro.New_Expected_Delivery_Date__c:null;
                            roobj.Old_Expected_Delivery_Date__c = Ro.Old_Expected_Delivery_Date__c!=null?Ro.Old_Expected_Delivery_Date__c:null;
                            roobj.Revise_req_Version__c = Salesorder.Revise_Version__c+1;
                            roList.add(roobj);
                        }
                        else if(Ro.What_to_Revise__c == 'Ship To' && Ro.Mainetti_SO__c !=null)
                        { 
                            roobj.Mainetti_SO__c = Ro.Mainetti_SO__c;
                            roobj.Status__c ='Approve Pending' ;
                            roobj.What_to_Revise__c =Ro.What_to_Revise__c;
                            roobj.New_Bill_to_Ship_to_Address__c = Ro.New_Bill_to_Ship_to_Address__c!=null?Ro.New_Bill_to_Ship_to_Address__c:'';
                            roobj.Old_Bill_to_Ship_to_Address__c = Ro.Old_Bill_to_Ship_to_Address__c!=null?Ro.Old_Bill_to_Ship_to_Address__c:'';
                            roobj.New_Ship_to_Company__c = Ro.New_Ship_to_Company__c!=null?Ro.New_Ship_to_Company__c:'';
                            roobj.Old_Ship_to_Company__c = Ro.Old_Ship_to_Company__c!=null?Ro.Old_Ship_to_Company__c:'';
                            roobj.New_Ship_to_Address1__c = Ro.New_Ship_to_Address1__c!=null?Ro.New_Ship_to_Address1__c:'';
                            roobj.Old_Ship_to_Address1__c = Ro.Old_Ship_to_Address1__c!=null?Ro.Old_Ship_to_Address1__c:'';
                            roobj.New_Ship_to_State__c = Ro.New_Ship_to_State__c!=null?Ro.New_Ship_to_State__c:'';
                            roobj.Old_Ship_to_State__c = Ro.Old_Ship_to_State__c!=null?Ro.Old_Ship_to_State__c:'';
                            roobj.New_Ship_to_City__c = Ro.New_Ship_to_City__c!=null?Ro.New_Ship_to_City__c:'';
                            roobj.Old_Ship_to_City__c = Ro.Old_Ship_to_City__c!=null?Ro.Old_Ship_to_City__c:'';
                            roobj.New_Ship_to_Country__c = Ro.New_Ship_to_Country__c!=null?Ro.New_Ship_to_Country__c:'';
                            roobj.Old_Ship_to_Country__c = Ro.Old_Ship_to_Country__c!=null?Ro.Old_Ship_to_Country__c:'';
                            roobj.New_Ship_to_Postcode__c = Ro.New_Ship_to_Postcode__c!=null?Ro.New_Ship_to_Postcode__c:'';
                            roobj.Old_Ship_to_Postcode__c = Ro.Old_Ship_to_Postcode__c!=null?Ro.Old_Ship_to_Postcode__c:'';
                            roobj.New_Ship_to_Tel__c = Ro.New_Ship_to_Tel__c!=null?Ro.New_Ship_to_Tel__c:'';
                            roobj.Old_Ship_to_Tel__c = Ro.Old_Ship_to_Tel__c!=null?Ro.Old_Ship_to_Tel__c:'';
                            roobj.Old_Ship_to_Email__c = Ro.Old_Ship_to_Email__c!=null?Ro.Old_Ship_to_Email__c:'';
                            roobj.New_Ship_to_Email__c = Ro.New_Ship_to_Email__c!=null?Ro.New_Ship_to_Email__c:'';
                            roobj.Old_Ship_to_Contact_Name__c = Ro.Old_Ship_to_Contact_Name__c!=null?Ro.Old_Ship_to_Contact_Name__c:'';
                            roobj.New_Ship_to_Contact_Name__c = Ro.New_Ship_to_Contact_Name__c!=null?Ro.New_Ship_to_Contact_Name__c:'';
                            roobj.Revise_req_Version__c = Salesorder.Revise_Version__c+1;
                            roList.add(roobj);
                            system.debug('Ro11>>>'+Ro);
                        }
                        else if(Ro.What_to_Revise__c == 'Factory Internal PO' && Ro.New_Factory_Internal_PO__c !=null)
                        {
                            roobj.id = Ro.id;
                            roobj.Mainetti_SO__c = Ro.Mainetti_SO__c;
                            roobj.Status__c ='Approve Pending' ;
                            roobj.What_to_Revise__c =Ro.What_to_Revise__c;
                            roobj.New_Factory_Internal_PO__c = Ro.New_Factory_Internal_PO__c!=null?Ro.New_Factory_Internal_PO__c:null;
                            roobj.Old_Factory_Internal_PO__c = Ro.Old_Factory_Internal_PO__c!=null?Ro.Old_Factory_Internal_PO__c:null;
                            roobj.Revise_req_Version__c = Salesorder.Revise_Version__c+1;
                            roList.add(roobj);
                        }
                        else if(Ro.What_to_Revise__c == 'Shipping Mark/Special Instruction' && Ro.New_Shipping_Mark__c !=null)
                        {
                            roobj.id = Ro.id;
                            roobj.Mainetti_SO__c = Ro.Mainetti_SO__c;
                            roobj.Status__c ='Approve Pending' ;
                            roobj.What_to_Revise__c =Ro.What_to_Revise__c;
                            if(Ro.New_Shipping_Mark__c !=null && Ro.New_Shipping_Mark__c.contains('_space'))
                                roobj.New_Shipping_Mark__c = Ro.New_Shipping_Mark__c.replace('_space', '\n');
                            else{
                                roobj.New_Shipping_Mark__c = Ro.New_Shipping_Mark__c!=null?Ro.New_Shipping_Mark__c:null;
                            }
                            if(Ro.Old_Shipping_Mark__c !=null && Ro.Old_Shipping_Mark__c.contains('_space'))
                                roobj.Old_Shipping_Mark__c = Ro.Old_Shipping_Mark__c.replace('_space', '\n');
                            else{
                                roobj.Old_Shipping_Mark__c = Ro.Old_Shipping_Mark__c!=null?Ro.Old_Shipping_Mark__c:null;
                            }
                            
                            roobj.Revise_req_Version__c = Salesorder.Revise_Version__c+1;
                            roList.add(roobj);
                        }
                        if(Ro.What_to_Revise__c == 'Forwarder/Transportation Details' && Ro.New_Forwarder_Transportation_Details__c !=null)
                        {
                            roobj.id = Ro.id;
                            roobj.Mainetti_SO__c = Ro.Mainetti_SO__c;
                            roobj.Status__c ='Approve Pending' ;
                            roobj.What_to_Revise__c =Ro.What_to_Revise__c;
                            
                            if(Ro.New_Forwarder_Transportation_Details__c !=null && Ro.New_Forwarder_Transportation_Details__c.contains('_space'))
                                roobj.New_Forwarder_Transportation_Details__c = Ro.New_Forwarder_Transportation_Details__c.replace('_space', '\n');
                            else
                                roobj.New_Forwarder_Transportation_Details__c = Ro.New_Forwarder_Transportation_Details__c!=null?Ro.New_Forwarder_Transportation_Details__c:null;
                            
                            if(Ro.Old_Forwarder_Transportation_Details__c !=null && Ro.Old_Forwarder_Transportation_Details__c.contains('_space'))
                                roobj.Old_Forwarder_Transportation_Details__c = Ro.Old_Forwarder_Transportation_Details__c.replace('_space', '\n');
                            else
                                roobj.Old_Forwarder_Transportation_Details__c = Ro.Old_Forwarder_Transportation_Details__c!=null?Ro.Old_Forwarder_Transportation_Details__c:null;
                            
                            roobj.Revise_req_Version__c = Salesorder.Revise_Version__c+1;
                            roList.add(roobj);
                        }
                        else if(Ro.Mainetti_SOLI__c !=null && Ro.What_to_Revise__c == 'Quantity')
                        {   
                            Sales_Order_Line_Items__c soliobj = new Sales_Order_Line_Items__c();
                            soliobj.id=Ro.Mainetti_SOLI__c;                                        // check for multiple SOLI
                            soliobj.Online_Detail_Status__c='Pending for change approval';
                            soliobj.Production_Status__c = 'Open';
                            
                            roobj.Mainetti_SOLI__c = Ro.Mainetti_SOLI__c;
                            roobj.Mainetti_SO__c = Ro.Mainetti_SO__c;
                            roobj.Customer_Refe_Model__c = Ro.Customer_Refe_Model__c;
                            roobj.Color__c = Ro.Color__c;
                            roobj.Status__c ='Approve Pending' ;
                            if(Ro.New_Quantity__c !=null)
                            {
                                roobj.What_to_Revise__c =Ro.What_to_Revise__c;
                                roobj.New_Quantity__c =Ro.New_Quantity__c;
                                roobj.Old_Quantity__c =Ro.Old_Quantity__c;
                            }
                            system.debug('roobj>>'+roobj);
                            roobj.Revise_req_Version__c = Salesorder.Revise_Version__c+1;
                            roList.add(roobj);
                            soli.add(soliobj);
                            
                        }
                        else if(Ro.What_to_Revise__c == 'Cancel Order')         //header level    
                        {
                            roobj.Mainetti_SO__c = Ro.Mainetti_SO__c;
                            roobj.Mainetti_SOLI__c = Ro.Mainetti_SOLI__c;       
                            roobj.Status__c='Approve Pending';
                            roobj.What_to_Revise__c = Ro.What_to_Revise__c;
                            roobj.Reason_to_Cancel__c = Ro.Reason_to_Cancel__c;
                            roobj.Cancel_Order_Date__c = CancelDate;
                            roobj.Revise_req_Version__c = Salesorder.Revise_Version__c+1;
                            roList.add(roobj);
                        }
                        else if(Ro.Mainetti_SOLI__c !=null && Ro.What_to_Revise__c == 'Cancel Line Item')       //line level
                        {
                            Sales_Order_Line_Items__c solicancelobj = new Sales_Order_Line_Items__c();
                            solicancelobj.id=Ro.Mainetti_SOLI__c;                                           
                            solicancelobj.Online_Detail_Status__c='Pending for change approval';
                            solicancelobj.Production_Status__c = 'Open';
                            
                            roobj.Mainetti_SO__c = Ro.Mainetti_SO__c;
                            roobj.Mainetti_SOLI__c = Ro.Mainetti_SOLI__c;
                            roobj.Status__c='Approve Pending';
                            roobj.What_to_Revise__c = Ro.What_to_Revise__c;
                            roobj.Color__c = Ro.Color__c;
                            roobj.Customer_Refe_Model__c = Ro.Customer_Refe_Model__c;
                            roobj.New_Quantity__c =Ro.New_Quantity__c;
                            roobj.Old_Quantity__c =Ro.Old_Quantity__c;
                            roobj.Revise_req_Version__c = Salesorder.Revise_Version__c+1;
                            roList.add(roobj);
                            soli.add(solicancelobj);
                        }
                    }
                } 
                upsert soli;
            }
            if(Salesorder.Revise_Version__c == 0 || Salesorder.Revise_Version__c == null )
            {
                so.Revise_Version__c = 1;
            }
            else{
                so.Revise_Version__c = Salesorder.Revise_Version__c+1;
            }
            upsert roList;
            so.Revise_Order_Created_Date__c = Date.parse(system.today().format());
            if(roList.size() != 0)
            {
                upsert so;
                sendEmail(ordertocompany,RetailerCode,roList);
                sendEmailToCustomer(ordertocompany,RetailerCode,roList);
                return 'success';
            }
            return 'ERROR'; 
        }
        catch (Exception e)
        {
            System.debug('e:::'+e);
            System.debug(LoggingLevel.ERROR, e.getMessage());
            return 'ERROR';
        }
    }
    //send email for revised orders for sales team
    public static string sendEmail(string ordertocompany,string RetailerCode,List<Revise_Order__c> roList)
    {
        String returnString;
        try{
            
            Map<string,CommunityConfiguration__c> ConfigSettings = CommunityConfiguration__c.getAll();
            CommunityConfiguration__c config = null;
            if(ConfigSettings.containsKey('CommunityConfiguration'))
            {
                config = ConfigSettings.get('CommunityConfiguration');
            }  
            
            Map<String,String> companyNameandAPI = UtilityClass.getOrderToCompanyPicklist(false);
            string orderToCompanytoconv = companyNameandAPI.get(ordertocompany); 
            String ReviseDataRecordsLink='';
            RegistrationService.ToEmailandCCEmailWrapper Regwrap = RegistrationService.getMailAddresses(orderToCompanytoconv, RetailerCode ,config);
            
            List<Messaging.SingleEmailMessage> mails =  new List<Messaging.SingleEmailMessage>();
            List<Revise_Order__c> Reviseorderlist = [SELECT id, Name,Mainetti_SO__r.Customer_Type__c,Mainetti_SO__c,Mainetti_SO__r.Name,Mainetti_SOLI__c,Mainetti_SO__r.Supplier__c,Mainetti_SO__r.Supplier__r.Name,Mainetti_SO__r.Retailer_Code1__r.Name,Mainetti_SO__r.Sales_Order_Number_For_Report__c,Mainetti_SO__r.Retailer_Code2__c,Mainetti_SO__r.Supplier_Email__c,Mainetti_SO__r.Mainetti_SO_SC__c,Mainetti_SO__r.Bill_to_Factory__c,Mainetti_SO__r.Bill_To_Address1__c,Mainetti_SO__r.Bill_to_City__c,Mainetti_SO__r.Bill_to_State__c,Mainetti_SO__r.Bill_to_Postcode__c,Mainetti_SO__r.Bill_to_Country__c,Mainetti_SO__r.Bill_To_Contact__c,Mainetti_SO__r.Bill_to_Tel__c,Mainetti_SO__r.Ship_to_Factory__c,Mainetti_SO__r.Ship_to_Address1__c,Mainetti_SO__r.Ship_to_City__c,Mainetti_SO__r.Ship_to_State__c,Mainetti_SO__r.Ship_to_Postcode__c,Mainetti_SO__r.Ship_to_Country__c,Mainetti_SO__r.Ship_To_Contact__c,Mainetti_SO__r.Ship_to_Tel__c,Mainetti_SO__r.Expected_Completion_Date__c FROM Revise_Order__c WHERE id IN :roList ];
            
            string CustomerName = Reviseorderlist[0].Mainetti_SO__r.Supplier__r.Name;
            string RetailerName = Reviseorderlist[0].Mainetti_SO__r.Retailer_Code2__c;
            date expDate = Reviseorderlist[0].Mainetti_SO__r.Expected_Completion_Date__c;
            string subject;string  emailBody;
            If(Reviseorderlist[0].Mainetti_SO__r.Customer_Type__c !='Distributor'){
                subject = 'Sales Order Change Request Submitted for '+Reviseorderlist[0].Mainetti_SO__r.Sales_Order_Number_For_Report__c+' (Retailer Code: '+RetailerName+')';
                
                ReviseDataRecordsLink += '<a href= '+config.My_Domain__c+'/'+'lightning/n/Revise_Order'+'>'+'Bulk RO Approval'+'</a>'+'<br/><br />';
                emailBody = 'Dear all, '+'<br /><br />'+CustomerName+' has submitted MagNET order change request, please reference to the link below for the RO details'+
                    +'<br />'+ReviseDataRecordsLink +
                    '<br />'+'Customer Contact: '+CustomerName+' / '+Reviseorderlist[0].Mainetti_SO__r.Supplier_Email__c+
                    '<br /><br />'+'Retailer code: '+ RetailerName +
                    '<br /><br />'+'MagNET Order: '+Reviseorderlist[0].Mainetti_SO__r.Sales_Order_Number_For_Report__c+
                    '<br /><br />'+'Order to Company: '+ordertocompany+
                    '<br /><br />'+'Mainetti SO/SC#: '+Reviseorderlist[0].Mainetti_SO__r.Mainetti_SO_SC__c+
                    '<br /><br />'+'Expected Completion Date: '+expDate.format()+
                    '<br /><br />'+'Bill to Factory: '+Reviseorderlist[0].Mainetti_SO__r.Bill_to_Factory__c +
                    
                    '<br /><br />' +'Thanks.'+
                    '<br /><br />' +'MagNET Team';
            }
            If(Reviseorderlist[0].Mainetti_SO__r.Customer_Type__c =='Distributor'){
                subject = 'MainettiCare: Customer revised an order'+Reviseorderlist[0].Mainetti_SO__r.Sales_Order_Number_For_Report__c;
                
                ReviseDataRecordsLink += '<a href= '+config.My_Domain__c+'/'+'lightning/n/Revise_Order'+'>'+'Bulk RO Approval'+'</a>'+'<br/><br />';
                emailBody = 'Hi Sales Team, '+'<br /><br />'+CustomerName+' has submitted change request for below MainettiCare order, please reference to the link for details.'+
                    +'<br />'+ReviseDataRecordsLink +
                    '<br />'+'Company Name/Contact: '+CustomerName+' / '+Reviseorderlist[0].Mainetti_SO__r.Supplier_Email__c+
                    '<br /><br />'+'Retailer code: '+ RetailerName +
                    //'<br /><br />'+'MagNET Order: '+Reviseorderlist[0].Mainetti_SO__r.Sales_Order_Number_For_Report__c+
                    '<br /><br />'+'Order to Company: '+ordertocompany+
                    '<br /><br />'+'Mainetti SO/SC#: '+Reviseorderlist[0].Mainetti_SO__r.Mainetti_SO_SC__c+
                    '<br /><br />'+'Expected Completion Date: '+expDate.format()+
                    '<br /><br />'+'Bill to: '+Reviseorderlist[0].Mainetti_SO__r.Bill_to_Factory__c +
                    '<br /><br />'+'Ship To: '+Reviseorderlist[0].Mainetti_SO__r.Ship_to_Factory__c +
                    
                    
                    '<br /><br />' +'Thanks.'+
                    '<br /><br />' +'MainettiCare';
            }
            
            
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            
            String sendTo;
            mail.setCCAddresses(Regwrap.toCCAddresses);
            mail.setToAddresses(Regwrap.toAddresses);
            mail.setSubject(subject);
            mail.setHtmlBody(emailBody);
            mail.setSenderDisplayName('Revise order submitted');        // from name in the mail 
            mail.setSaveAsActivity(false);
            mails.add(mail);
            Messaging.SendEmailResult[] results = Messaging.sendEmail(mails);
            
            if (results[0].success) 
            {
                System.debug('The email was sent successfully.');
                returnString = 'success';   
            } else
            {
                
                System.debug('The email failed to send:'+results[0].errors[0].message);
                returnString = 'Error During Email sending to the registered customer';
            }
            
        }
        catch(Exception e)
        {
            
            returnString = e.getMessage() + e.getLineNumber();
            System.debug('Inside exception>>>'+e.getMessage());
            System.debug('Inside exception LineNumber >>>'+e.getLineNumber());
            System.debug('Inside exception getTypeName>>>'+e.getTypeName());
            System.debug('Inside exception getStackTraceString>>>'+e.getStackTraceString());
            
        }
        return returnString;
    }
    //send email for revised orders for Customer
    public static string sendEmailToCustomer(string ordertocompany,string RetailerCode,List<Revise_Order__c> roList)
    {
        String returnString;
        try{
            system.debug('sendEmailToCustomer From reverse order?????');
            Map<string,CommunityConfiguration__c> ConfigSettings = CommunityConfiguration__c.getAll();
            CommunityConfiguration__c config = null;
            if(ConfigSettings.containsKey('CommunityConfiguration'))
            {
                config = ConfigSettings.get('CommunityConfiguration');
            }  
            
            Map<String,String> companyNameandAPI = UtilityClass.getOrderToCompanyPicklist(false);
            string orderToCompanytoconv = companyNameandAPI.get(ordertocompany); 
            String ReviseDataRecordsLink='';
            RegistrationService.ToEmailandCCEmailWrapper Regwrap = RegistrationService.getMailAddresses(orderToCompanytoconv, RetailerCode ,config);
            
            List<Messaging.SingleEmailMessage> mails =  new List<Messaging.SingleEmailMessage>();
            List<Revise_Order__c> Reviseorderlist = [SELECT id,New_Ship_to_Company__c,New_Ship_to_Address1__c,New_Ship_to_City__c,New_Ship_to_State__c,New_Ship_to_Country__c,
                                                     New_Ship_to_Postcode__c,New_Ship_to_Tel__c,New_Ship_to_Email__c,Old_Ship_to_Company__c,Old_Ship_to_Address1__c,
                                                     Old_Ship_to_City__c,Old_Ship_to_State__c,Old_Ship_to_Country__c,Old_Ship_to_Postcode__c,Old_Ship_to_Tel__c,Old_Ship_to_Email__c,Old_Forwarder_Transportation_Details__c,New_Forwarder_Transportation_Details__c,New_Shipping_Mark__c,Old_Shipping_Mark__c,Old_Factory_Internal_PO__c,New_Factory_Internal_PO__c,Mainetti_SO__r.Supplier_Contact__r.name, Name,Old_Expected_Delivery_Date__c,New_Expected_Delivery_Date__c,New_Quantity__c,Old_Quantity__c,Mainetti_SOLI__r.Name,
                                                     Mainetti_SOLI__r.Customer_Ref_Model__c,What_to_Revise__c,Mainetti_SO__r.Customer_Type__c,Mainetti_SO__c,Mainetti_SO__r.Name,Mainetti_SOLI__c,Mainetti_SO__r.Supplier__c,Mainetti_SO__r.Supplier__r.Name,
                                                     Mainetti_SO__r.Retailer_Code1__r.Name,Mainetti_SO__r.Sales_Order_Number_For_Report__c,Mainetti_SO__r.Retailer_Code2__c,Mainetti_SO__r.Supplier_Email__c,Mainetti_SO__r.Mainetti_SO_SC__c,Mainetti_SO__r.Bill_to_Factory__c,
                                                     Mainetti_SO__r.Bill_To_Address1__c,Mainetti_SO__r.Bill_to_City__c,Mainetti_SO__r.Bill_to_State__c,Mainetti_SO__r.Bill_to_Postcode__c,Mainetti_SO__r.Bill_to_Country__c,Mainetti_SO__r.Bill_To_Contact__c,
                                                     Mainetti_SO__r.Bill_to_Tel__c,Mainetti_SO__r.Ship_to_Factory__c,Mainetti_SO__r.Ship_to_Address1__c,Mainetti_SO__r.Ship_to_City__c,Mainetti_SO__r.Ship_to_State__c,Mainetti_SO__r.Ship_to_Postcode__c,
                                                     Mainetti_SO__r.Ship_to_Country__c,Mainetti_SO__r.Ship_To_Contact__c,Mainetti_SO__r.Ship_to_Tel__c,Mainetti_SO__r.Expected_Completion_Date__c FROM Revise_Order__c WHERE id IN :roList ];
            
            string CustomerName = Reviseorderlist[0].Mainetti_SO__r.Supplier__r.Name;
            string RetailerName = Reviseorderlist[0].Mainetti_SO__r.Retailer_Code2__c;
            date expDate = Reviseorderlist[0].Mainetti_SO__r.Expected_Completion_Date__c;
            string subject;string  emailBody;
            //MCare revise order for customers
            If(Reviseorderlist[0].Mainetti_SO__r.Customer_Type__c =='Distributor'){
                string reviseemailist;
                for(Revise_Order__c reviseorderobj : Reviseorderlist){
                    string emailbodylist ='';
                    if(reviseorderobj.Mainetti_SOLI__c !=null){
                        emailbodylist ='<br /><br />'+'Approved Revise Order Details'+
                            '<br />'+'Order No.: '+reviseorderobj.Mainetti_SO__r.Name+
                            '<br />'+'What to Revise: '+reviseorderobj.What_to_Revise__c +
                            '<br />'+'Model: '+reviseorderobj.Mainetti_SOLI__r.Name +
                            '<br />'+'Line Number: '+reviseorderobj.Mainetti_SOLI__r.Customer_Ref_Model__c +
                            '<br />'+'New Quantity: '+reviseorderobj.New_Quantity__c +
                            '<br />'+'Old Quantity: '+reviseorderobj.Old_Quantity__c;
                        if(reviseemailist == null){
                            reviseemailist = emailbodylist;
                        }else{
                            reviseemailist = reviseemailist + emailbodylist;
                        }
                        
                    }
                    if(reviseorderobj.What_to_Revise__c =='Ship Date'){
                        emailbodylist ='<br /><br />'+'Approved Revise Order Details'+
                            '<br />'+'Order No.: '+reviseorderobj.Mainetti_SO__r.Name+
                            '<br />'+'What to Revise: '+reviseorderobj.What_to_Revise__c +
                            //'<br />'+'Model: '+reviseorderobj.Mainetti_SOLI__r.Name +
                            //'<br />'+'Line Number: '+reviseorderobj.Mainetti_SOLI__r.Customer_Ref_Model__c +
                            '<br />'+'New Expected Delivery Date: '+reviseorderobj.New_Expected_Delivery_Date__c +
                            '<br />'+'Old Expected Delivery Date: '+reviseorderobj.Old_Expected_Delivery_Date__c;
                        if(reviseemailist == null){
                            reviseemailist = emailbodylist;
                        }else{
                            reviseemailist = reviseemailist + emailbodylist;
                        }
                    }
                    if(reviseorderobj.What_to_Revise__c =='Factory Internal PO'){
                        emailbodylist ='<br /><br />'+'Approved Revise Order Details'+
                            '<br />'+'Order No.: '+reviseorderobj.Mainetti_SO__r.Name+
                            '<br />'+'What to Revise: '+reviseorderobj.What_to_Revise__c +
                            //'<br />'+'Model: '+reviseorderobj.Mainetti_SOLI__r.Name +
                            //'<br />'+'Line Number: '+reviseorderobj.Mainetti_SOLI__r.Customer_Ref_Model__c +
                            '<br />'+'New Factory Internal PO: '+reviseorderobj.New_Factory_Internal_PO__c +
                            '<br />'+'Old Factory Internal PO: '+reviseorderobj.Old_Factory_Internal_PO__c;
                        if(reviseemailist == null){
                            reviseemailist = emailbodylist;
                        }else{
                            reviseemailist = reviseemailist + emailbodylist;
                        }
                    }
                    if(reviseorderobj.What_to_Revise__c =='Forwarder/Transportation Details '){
                        emailbodylist ='<br /><br />'+'Approved Revise Order Details'+
                            '<br />'+'Order No.: '+reviseorderobj.Mainetti_SO__r.Name+
                            '<br />'+'What to Revise: '+reviseorderobj.What_to_Revise__c +
                            //'<br />'+'Model: '+reviseorderobj.Mainetti_SOLI__r.Name +
                            //'<br />'+'Line Number: '+reviseorderobj.Mainetti_SOLI__r.Customer_Ref_Model__c +
                            '<br />'+'New Forwarder/Transportation Details: '+reviseorderobj.New_Forwarder_Transportation_Details__c +
                            '<br />'+'Old Forwarder/Transportation Details: '+reviseorderobj.Old_Forwarder_Transportation_Details__c;
                        if(reviseemailist == null){
                            reviseemailist = emailbodylist;
                        }else{
                            reviseemailist = reviseemailist + emailbodylist;
                        }
                    }
                    if(reviseorderobj.What_to_Revise__c =='Ship To'){
                        emailbodylist ='<br /><br />'+'Approved Revise Order Details'+
                            '<br />'+'Order No.: '+reviseorderobj.Mainetti_SO__r.Name+
                            '<br />'+'What to Revise: '+reviseorderobj.What_to_Revise__c +
                            //'<br />'+'Model: '+reviseorderobj.Mainetti_SOLI__r.Name +
                            //'<br />'+'Line Number: '+reviseorderobj.Mainetti_SOLI__r.Customer_Ref_Model__c +
                            '<br />'+'New Ship to :'+
                            '<br />'+'New Ship to Factory: '+reviseorderobj.New_Ship_to_Company__c +
                            '<br />'+'New Ship to Street: '+reviseorderobj.New_Ship_to_Address1__c +
                            '<br />'+'New Ship to City: '+reviseorderobj.New_Ship_to_City__c     +
                            '<br />'+'New Ship to State: '+reviseorderobj.New_Ship_to_State__c   +
                            '<br />'+'New Ship to Country: '+reviseorderobj.New_Ship_to_Country__c +
                            '<br />'+'New Ship to Postcode: '+reviseorderobj.New_Ship_to_Postcode__c +
                            '<br />'+'New Ship to Contact Number: '+reviseorderobj.New_Ship_to_Tel__c +
                            '<br />'+'New Ship to Contact Email: '+reviseorderobj.New_Ship_to_Email__c +
                            '<br /><br />'+'Old Ship to :'+
                            '<br />'+'Old Ship to Factory: '+reviseorderobj.Old_Ship_to_Company__c +
                            '<br />'+'Old Ship to Street: '+reviseorderobj.Old_Ship_to_Address1__c +
                            '<br />'+'Old Ship to City: '+reviseorderobj.Old_Ship_to_City__c     +
                            '<br />'+'Old Ship to State: '+reviseorderobj.Old_Ship_to_State__c   +
                            '<br />'+'Old Ship to Country: '+reviseorderobj.Old_Ship_to_Country__c +
                            '<br />'+'Old Ship to Postcode: '+reviseorderobj.Old_Ship_to_Postcode__c +
                            '<br />'+'Old Ship to Contact Number: '+reviseorderobj.Old_Ship_to_Tel__c +
                            '<br />'+'Old Ship to Contact Email: '+reviseorderobj.Old_Ship_to_Email__c;
                        
                        if(reviseemailist == null){
                            reviseemailist = emailbodylist;
                        }else{
                            reviseemailist = reviseemailist + emailbodylist;
                        }
                    }
                    
                }
                subject = 'MainettiCare: Revised Order Status  '+Reviseorderlist[0].Mainetti_SO__r.Sales_Order_Number_For_Report__c;
                
                ReviseDataRecordsLink += '<a href= '+config.My_Domain__c+'/'+'lightning/n/Revise_Order'+'>'+'Bulk RO Approval'+'</a>'+'<br/><br />';
                emailBody = 'Hi '+ Reviseorderlist[0].Mainetti_SO__r.Supplier_Contact__r.name +'<br /><br />'+' Thank you for using MainettiCare, please note below order change request(s) status.'+
                    
                    '<br />' +reviseemailist +
                    
                    
                    '<br /><br />' +'Thanks.'+
                    '<br /><br />' +'MainettiCare';
            }
            System.debug('emailBody>>>'+emailBody);
            /*** Creating email attachment starts ***/
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();     
            PageReference pdf = Page.SOConfirmationPDF;
            pdf.getParameters().put('id',Reviseorderlist[0].Mainetti_SO__r.Id);
            pdf.setRedirect(true);
            Blob b = pdf.getContent();
            Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
            String filename = Reviseorderlist[0].Mainetti_SO__r.Name +'.pdf';
            efa.setFileName(filename);
            efa.setBody(b);
            System.debug('efa>>>'+efa);
            mail.setFileAttachments(new Messaging.EmailFileAttachment[] {efa});
            
            String sendTo;
            String[] toadd = new String[] {Reviseorderlist[0].Mainetti_SO__r.Supplier_Email__c};
                //toadd.add('sandhya.ramba@crmit.com');
                // mail.setCCAddresses(toadd);
                mail.setToAddresses(toadd);
            mail.setSubject(subject);
            mail.setHtmlBody(emailBody);
            // mail.setSenderDisplayName('Revise order submitted');        // from name in the mail 
            mail.setSaveAsActivity(false);
            mails.add(mail);
            Messaging.SendEmailResult[] results = Messaging.sendEmail(mails);
            
            if (results[0].success) 
            {
                System.debug('The email was sent successfully.');
                returnString = 'success';   
            } else
            {
                
                System.debug('The email failed to send:'+results[0].errors[0].message);
                returnString = 'Error During Email sending to the registered customer';
            }
            
        }
        catch(Exception e)
        {
            
            returnString = e.getMessage() + e.getLineNumber();
            System.debug('Inside exception>>>'+e.getMessage());
            System.debug('Inside exception LineNumber >>>'+e.getLineNumber());
            System.debug('Inside exception getTypeName>>>'+e.getTypeName());
            System.debug('Inside exception getStackTraceString>>>'+e.getStackTraceString());
            
        }
        return returnString;
    }
    
    // code for revise order END
    //New Code to view revise Orders requests
    @AuraEnabled
    public static List<ReviseReqVersionsWrap> toGetReviseOrderRequests(String SoId)
    {
        List<ReviseReqVersionsWrap> ReviseReqVrnList = new List<ReviseReqVersionsWrap>();
        Map<Decimal,ReviseReqVersionsWrap> revReqVerReconcileMap = new Map<Decimal,ReviseReqVersionsWrap>();    //key=>version number, value=>ReviseReqVersionsWrap class
        
        Map<Id,Decimal> soliIdBoxQtyMap = new Map<Id,Decimal>();
        Map<Id,Decimal> soliIdMOQMap = new Map<Id,Decimal>();
        
        Sales_Order__c MgSo = [Select id, Name, Retailer_Code1__c, Retailer_Code1__r.Full_Box_Order__c, (select id,name,Price_Specification_Book_Product__c, Price_Specification_Book_Product__r.BOX_QTY__c,Price_Specification_Book_Product__r.MOQ__c, BOX_QTY__c, Full_Box_Order__c from Sales_Order_Line_Items__r) from Sales_Order__c where Id =: SoId];
        
        for(Sales_Order_Line_Items__c soli: MgSo.Sales_Order_Line_Items__r)
        {
            system.debug('MOQ>>'+soli.Price_Specification_Book_Product__r.MOQ__c);
            soliIdMOQMap.put(soli.id,soli.Price_Specification_Book_Product__r.MOQ__c);
            
            if(soli.Full_Box_Order__c)
                soliIdBoxQtyMap.put(soli.id,soli.BOX_QTY__c);
        }
        system.debug('soliIdBoxQtyMap : '+soliIdBoxQtyMap);
        system.debug('soliIdMOQMap>>'+soliIdMOQMap);
        
        Integer verCount = 0;   //to count revise requests
        Integer latestVer = 0;  //to store latest version number
        for(Revise_Order__c revO : [Select id, name, CreatedDate, Mainetti_SO__c, Mainetti_SOLI__c, Approved__c, Revised__c, Mainetti_Model__c, Order_to_Company__c, Revise_req_Version__c, Status__c, What_to_Revise__c, Resons_to_Reject__c,Cancel_Order_Date__c,Reason_to_Cancel__c,
                                    Old_Bill_to_Ship_to_Address__c, Old_Expected_Delivery_Date__c, Old_Factory_Internal_PO__c, Old_Forwarder_Transportation_Details__c, Old_Quantity__c, Old_Shipping_Mark__c, Old_Ship_to_Address1__c, Old_Ship_to_City__c, Old_Ship_to_Contact_Name__c, Old_Bill_to_Ship_to_Address__r.Contact__c, Old_Ship_to_Country__c, Old_Ship_to_Email__c, Old_Ship_to_Company__c, Old_Ship_to_Postcode__c, Old_Ship_to_State__c, Old_Ship_to_Tel__c, 
                                    New_Bill_to_Ship_to_Address__c, New_Expected_Delivery_Date__c, New_Factory_Internal_PO__c, New_Forwarder_Transportation_Details__c, New_Quantity__c, New_Shipping_Mark__c, New_Ship_to_Address1__c, New_Ship_to_City__c, New_Ship_to_Contact_Name__c, New_Bill_to_Ship_to_Address__r.Contact__c, New_Ship_to_Country__c, New_Ship_to_Email__c, New_Ship_to_Company__c, New_Ship_to_Postcode__c, New_Ship_to_State__c, New_Ship_to_Tel__c
                                    from Revise_Order__c where Mainetti_SO__c =:SoId order by Revise_req_Version__c desc])
        {
            system.debug('revO>>'+revO.Id+' ver>>'+revO.Revise_req_Version__c+' verCount>>'+verCount+' latestVer>>'+latestVer);
            if(verCount == 0)
                latestVer = Integer.valueOf(revO.Revise_req_Version__c);
            if(revReqVerReconcileMap.containskey(revO.Revise_req_Version__c))   //keeping sames revise versions together
            {   
                system.debug('<<already added version>>');
                ReviseReqVersionsWrap ReviseReqVersion = new ReviseReqVersionsWrap();
                ReviseReqVersion = revReqVerReconcileMap.get(revO.Revise_req_Version__c);
                
                ReviseReqwrap ReviseReq = new ReviseReqwrap();
                ReviseReq.revOData = revO;
                ReviseReq.oldVal = revO;
                ReviseReq.newVal = revO;
                if(latestVer == revO.Revise_req_Version__c && revO.Status__c=='Approve Pending')
                    ReviseReq.iseditable = true;
                
                if(revO.What_to_Revise__c=='Quantity' && MgSo.Retailer_Code1__r.Full_Box_Order__c && soliIdBoxQtyMap.containsKey(revO.Mainetti_SOLI__c))
                    ReviseReq.boxQty=soliIdBoxQtyMap.get(revO.Mainetti_SOLI__c);
                if(revO.What_to_Revise__c=='Quantity' && soliIdMOQMap.containsKey(revO.Mainetti_SOLI__c))
                    ReviseReq.MOQ = soliIdMOQMap.get(revO.Mainetti_SOLI__c);
                
                
                ReviseReqVersion.ReviseReqWrapList.add(ReviseReq);
                revReqVerReconcileMap.put(ReviseReqVersion.revVersion,ReviseReqVersion);
                system.debug('revReqVerReconcileMap:::'+revReqVerReconcileMap);
            }
            else
            {
                system.debug('<<new version to add>>');
                ReviseReqVersionsWrap ReviseReqVersion = new ReviseReqVersionsWrap();
                
                ReviseReqwrap ReviseReq = new ReviseReqwrap();
                ReviseReq.revOData = revO;
                ReviseReq.oldVal = revO;
                ReviseReq.newVal = revO;
                if(latestVer == revO.Revise_req_Version__c && revO.Status__c=='Approve Pending')
                    ReviseReq.iseditable = true;
                
                if(revO.What_to_Revise__c=='Quantity' && MgSo.Retailer_Code1__r.Full_Box_Order__c && soliIdBoxQtyMap.containsKey(revO.Mainetti_SOLI__c))
                    ReviseReq.boxQty=soliIdBoxQtyMap.get(revO.Mainetti_SOLI__c);
                if(revO.What_to_Revise__c=='Quantity' && soliIdBoxQtyMap.containsKey(revO.Mainetti_SOLI__c))
                    ReviseReq.MOQ = soliIdMOQMap.get(revO.Mainetti_SOLI__c);
                
                ReviseReqVersion.revVersion = revO.Revise_req_Version__c;
                ReviseReqVersion.ReviseReqWrapList.add(ReviseReq);
                revReqVerReconcileMap.put(ReviseReqVersion.revVersion,ReviseReqVersion);
                
                verCount++;
            }
        }
        
        ReviseReqVrnList = revReqVerReconcileMap.values();
        system.debug('final ReviseReqVrnList>>'+ReviseReqVrnList);
        return ReviseReqVrnList;  
    }
    
    //code to save revise orders from view revise orders pop up
    @AuraEnabled
    public static String toSaveReviseOrderRequests(List<Revise_Order__c> RORqtToSave)
    {
        String retString = 'Success';
        Sales_Order__c SO = new Sales_Order__c();
        List<Sales_Order_Line_Items__c> SOLIList = new List<Sales_Order_Line_Items__c>();
        boolean abortflag = false;
        boolean Notabortflag = false;
        system.debug('RORqtToSave>>'+RORqtToSave);
        for(Revise_Order__c revobj : RORqtToSave)
        {
            system.debug('inside for'+ revobj.name );
            revobj.New_Quantity__c = String.valueOf(revobj.New_Quantity__c);
            if(revobj.What_to_Revise__c == 'Cancel Line Item' && revobj.Status__c == 'Rejected')
            {
                system.debug('inside if and cancelflage==>');
                Sales_Order_Line_Items__c SOLI = new Sales_Order_Line_Items__c();
                abortflag = true;
                SOLI.id=revobj.Mainetti_SOLI__c;
                SOLI.Production_Status__c ='Open';
                SOLI.Online_Detail_Status__c = 'Order Received';
                SOLIList.add(SOLI);
            }
            else{
                Notabortflag = true;
            }
            system.debug('abortflag>>'+abortflag);
        }
        if(SOLIList.size() != 0)
        {
            system.debug('SOLIList>>'+SOLIList);
            update SOLIList;
        }
        if(abortflag == true && Notabortflag == false)                  // code when only lineitem is canceled
        {
            system.debug('inside abortflag>>');
            SO.id =RORqtToSave[0].Mainetti_SO__c;
            SO.Status__c='Order submitted';
            SO.Enquiry_Status__c ='Order Received';
            SO.Link_To_ERP__c ='Resend';
            update SO;
        }
        system.debug('first RORqtToSave>>'+RORqtToSave);
        system.debug('first SO>>'+SO);
        system.debug('first SOLIList>>'+SOLIList);
        update RORqtToSave;
        system.debug('final RORqtToSave>>'+RORqtToSave);
        
        return retString;  
    }
    //UPDATE MSO-NO button functionality START --------------------
    //new code to manually update the status if JDE didn't not update
    
    @AuraEnabled
    public static Sales_Order__c fetchMSO(String recordId)
    {
        Sales_Order__c SOObject = [SELECT id,Generated_Reject_Xml__c,Generated_Confirm_Xml__c,Name,Status__c,Mainetti_SO_SC__c,Enquiry_Status__c,Link_To_ERP__c,ERP_Connected__c,Expected_Completion_Date__c,Expected_Delivery_Date__c,RecordTypeId,RecordType.Name FROM Sales_Order__c WHERE id =:recordId];
        return SOObject;
    }    
    @AuraEnabled
    public static String fetchMSO1(String recordId)
    {
         String responseMessage;
        Boolean orderRejected = false;
        
        try
        {
            List<Sales_Order__c> SOList = new List<Sales_Order__c>();
            List<Sales_Order_Line_Items__c> SOLIList = new List<Sales_Order_Line_Items__c>();
            
           // Sales_Order__c so = [SELECT id, Name,Status__c,Generated_Reject_Xml__c,Mainetti_SO_SC__c,Enquiry_Status__c,Link_To_ERP__c,ERP_Connected__c,Expected_Completion_Date__c,Expected_Delivery_Date__c,(select id,name,Production_Status__c,Online_Detail_Status__c,Expected_Completion_Date__c,Expected_Delivery_Date__c,Start_Num__c,Sheet_Number__c from Sales_Order_Line_Items__r where Start_Num__c = null) FROM Sales_Order__c WHERE id =:recordId ];
          //  System.debug('so:::+'+so);
           // System.debug('so.Sales_Order_Line_Items__r:::::'+so.Sales_Order_Line_Items__r);
            for(Sales_Order__c SOOBJ :[SELECT id,Reject_Reason__c, Name,Status__c,Generated_Reject_Xml__c,Mainetti_SO_SC__c,Enquiry_Status__c,Link_To_ERP__c,ERP_Connected__c,Expected_Completion_Date__c,Expected_Delivery_Date__c,(select id,name,Production_Status__c,Online_Detail_Status__c,Expected_Completion_Date__c,Expected_Delivery_Date__c,Start_Num__c,Sheet_Number__c from Sales_Order_Line_Items__r) FROM Sales_Order__c WHERE id =:recordId ])
            {
                String serialNum = '';
                String sheetNum = '';
                Boolean serialNumberNull = false;
                
                
                for(Sales_Order_Line_Items__c SOLIOBJ: SOOBJ.Sales_Order_Line_Items__r)
                {
                    System.debug('SOLIOBJ.Start_Num__c:::'+SOLIOBJ.Start_Num__c);
                    SOLIOBJ.Production_Status__c ='Open';
                    SOLIOBJ.Online_Detail_Status__c = 'Order Received';
                    serialNum = SOLIOBJ.Start_Num__c;
                    if(serialNum == null){
                        System.debug('serialNum::Null:::'+serialNum);
                        serialNumberNull = true;
                    }else{
                        System.debug('serialNum:::::'+serialNum);
                    }
                    
                    sheetNum = SOLIOBJ.Sheet_Number__c;
                    SOLIList.add(SOLIOBJ);
                }
              //  System.debug('serialNum:::'+serialNum);
                System.debug('serialNumberNull:::'+serialNumberNull);
                if(serialNumberNull == true && String.IsBlank(sheetNum)){
                    System.debug('Inside Else Part');
                    SOOBJ.Enquiry_Status__c = 'Order rejected';
                    SOOBJ.Status__c = 'Order rejected';
                    SOList.add(SOOBJ);
                   orderRejected = true;
                    
                }else{
                     System.debug('Inside Serial val');
                    SOOBJ.Enquiry_Status__c = 'Order Received';
                    SOOBJ.Link_To_ERP__c = 'Resend';
                    SOList.add(SOOBJ);
                }   
                
                responseMessage = 'SUCCESS';  
            } 
            System.debug('SOList::::'+SOList);
            System.debug('SOLIList:::'+SOLIList);
            update SOList;
            update SOLIList;
            system.debug('responseMessage>>'+responseMessage);
           // return responseMessage;
        }
        catch (Exception e)
        {
            System.debug('EmailException:' + e);
           // return 'Error';
        }
        if(orderRejected == true){
            System.debug('rejected true');
            return 'Order Rejected Because Serial Number Empty';
        }else{
            return 'Order Confirmed';
        }
           
    }
    
 @AuraEnabled
    public static string updateMSONum(String recordId, string MSONumber, string complitiondate)
    {
        String responseMessage;
        try
        {
            List<Sales_Order__c> SOList = new List<Sales_Order__c>();
            List<Sales_Order_Line_Items__c> SOLIList = new List<Sales_Order_Line_Items__c>();
            
            for(Sales_Order__c SOOBJ :[SELECT id, Name,Status__c,Mainetti_SO_SC__c,Enquiry_Status__c,Link_To_ERP__c,ERP_Connected__c,Expected_Completion_Date__c,Expected_Delivery_Date__c,(select id,name,Production_Status__c,Online_Detail_Status__c,Expected_Completion_Date__c,Expected_Delivery_Date__c from Sales_Order_Line_Items__r) FROM Sales_Order__c WHERE id =:recordId ])
            {
                SOOBJ.Mainetti_SO_SC__c = MSONumber;
                SOOBJ.Enquiry_Status__c = 'Order Received';
                SOOBJ.Link_To_ERP__c = 'Resend';
                SOOBJ.Expected_Completion_Date__c = Date.valueOf(complitiondate);
                for(Sales_Order_Line_Items__c SOLIOBJ: SOOBJ.Sales_Order_Line_Items__r)
                {
                    SOLIOBJ.Production_Status__c ='Open';
                    SOLIOBJ.Online_Detail_Status__c = 'Order Received';
                    SOLIOBJ.Expected_Completion_Date__c = Date.valueOf(complitiondate);
                    SOLIList.add(SOLIOBJ);
                }
                SOList.add(SOOBJ);
                responseMessage = 'SUCCESS'; 
            } 
            upsert SOList;
            upsert SOLIList;
            system.debug('responseMessage>>'+responseMessage);
            return responseMessage;
        }
        catch (Exception e)
        {
            System.debug('EmailException:' + e);
            return 'Error';
        }
    }
    //UPDATE MSO-NO button functionality STOP --------------------
    
    //SO clone feature starts   //added on Feb 04 2020 by Vidit
    @AuraEnabled
    public static boolean cartVerification(String customerid)
    {
        boolean retVal = true;
        
        Sales_Order__c cartSO=UtilityClass.getSORecordAsCart(customerid);
        system.debug('cartSO'+cartSO);
        if(cartSO.Id != null)
        {
            retVal = true;            
        }
        else
            retVal = false;
        
        return retVal;
    }
    
    //method to clone sales orders from order history tab
    @AuraEnabled
    public static String SOClone(String recordId)
    {
        String retString = 'SUCCESS';
        String soFields=UtilityClass.getAllFields('Sales_Order__c');
        System.debug(soFields);
        String soliFields=UtilityClass.getAllFields('Sales_Order_Line_Items__c');
        contact contactid=UtilityClass.getCurrentUserContact();
        system.debug('Customer Info ID for Product>>>>'+contactid.Customer_Information__c); 
        List<Customer_Information__c> CustProdID=[select MagNET_Price_Code__c from Customer_Information__c where Id=: contactid.Customer_Information__c ];
        system.debug('Customer Info Product code>>>>'+CustProdID);
        String soQueryString='select '+soFields+'   ,(select Id,'+soliFields+',Price_Product_by_Currency__r.Price_100_pcs__c, Price_Specification_Book_Product__r.USD_Rebate_pc__c, Price_Specification_Book_Product__r.Active__c, Price_Specification_Book_Product__r.EUR_Rebate_pc__c, Price_Specification_Book_Product__r.USD_Reuse_Rebate_pc__c, Price_Specification_Book_Product__r.EUR_Reuse_Rebate_pc__c, Price_Specification_Book_Product__r.Sizer_Print__c,Price_Specification_Book_Product__r.Local_SKU__c,Price_Specification_Book_Product__r.BOX_QTY__c,Price_Product_by_Currency__r.MagNET_Price_Code__c,Price_Specification_Book_Product__r.Id from Sales_Order_Line_Items__r) from Sales_Order__c where Id=:recordId';
        System.debug(soQueryString);
        Sales_Order__c parentSO = Database.query(soQueryString);    //qureying Sales order , sales order line items and price book related fields
        System.debug('existing SO Querry'+ parentSO);
        system.debug('soQueryString'+soQueryString);
        system.debug('soFields>>'+soFields);        
        Map<Id,Price_Product_by_Currency__c> pbIdSpecialDiscountPriceMap = new Map<Id,Price_Product_by_Currency__c>();  //Key=> Product ID and Value => Special Product Price for Customer 
        set<string> psbpId = new set<string>();
        for(Sales_Order_Line_Items__c soli : parentSO.Sales_Order_Line_Items__r){
            psbpId.add(soli.Price_Specification_Book_Product__c);
        }
        
        for(Price_Product_by_Currency__c procurr : [select id,name, CurrencyIsoCode, Local_ERP_customer_code__c, Price_100_pcs__c, Price_1000_pcs__c,UOM_Price__c,Price_Book_Product__c,Price_Book_Product__r.Order_to_Company__c,Mainetti_Model_Code__c,MagNET_Price_Code__c from Price_Product_by_Currency__c where Price_Book_Product__c IN:psbpId])
        {
            if(parentSO.CurrencyIsoCode.contains(procurr.CurrencyIsoCode) && procurr.MagNET_Price_Code__c !=null && procurr.MagNET_Price_Code__c == CustProdID[0].MagNET_Price_Code__c){
                System.debug('Inside Special Price');
                pbIdSpecialDiscountPriceMap.put(procurr.Price_Book_Product__c,procurr);
                System.debug('Inside::'+pbIdSpecialDiscountPriceMap);
            }
        }
        
        Set<Id> pSoliId = new Set<Id>();
        Sales_Order__c clonedSO = parentSO.clone(false, true, false, false);
        clonedSO.Parent_Order__c = recordId;
        clonedSO.OrderSource__c = 'Cloned';
        clonedSO.Factory_Internal_PO__c = '';
        clonedSO.RecordtypeId = CartRecordType;
        clonedSO.Status__c = 'New Order';
        clonedSO.Enquiry_Status__c ='';
        clonedSO.Link_To_ERP__c ='';
        clonedSO.Expected_Delivery_Date__c = null;
        clonedSO.Expected_Completion_Date__c = null;
        clonedSO.Mainetti_SO_SC__c = '';
        clonedSO.Shared_With_Retailer__c = false;

        System.debug('Brand Lable for clone object==');
        
        
        Boolean isPricebookActive = false;  //true, if any of the pricebook is active
        Boolean isAnyPricebookActive = true;    //false, if any of the pricebook is inactive
        for(Sales_Order_Line_Items__c soli:parentSO.Sales_Order_Line_Items__r)
        {
            system.debug('pricebook active::'+soli.Price_Specification_Book_Product__r.Active__c);
            if(soli.Price_Specification_Book_Product__r.Active__c)
            {
                isPricebookActive = true;
            }
            else
            {
                isAnyPricebookActive = false;
            }
        }
        if(isPricebookActive)   //order lines will be clones only if the their pricebooks are active
        {
            system.debug(' billto:::'+parentSO.Bill_to_Address__c+ ' shipto::'+parentSO.Ship_to_Address__c);
            
            Ship_Bill_Address__c BillAddress = [select id,name,recordtype.name,Is_Default__c,Company_Name__c,Address_1__c,City__c,State__c,Country__c,Postcode__c,Factory_Name__c,Contact__c,Tel_No__c,Email_Address__c, Fax_No__c from Ship_Bill_Address__c where Id =: parentSO.Bill_to_Address__c ];
            
            Ship_Bill_Address__c shipAddress = [select id,name,recordtype.name,Is_Default__c,Company_Name__c,Address_1__c,City__c,State__c,Country__c,Postcode__c,Factory_Name__c,Contact__c,Tel_No__c,Email_Address__c, Fax_No__c from Ship_Bill_Address__c where Id =: parentSO.Ship_to_Address__c ];
            
            clonedSO = UtilityClass.assignBillToAdd(clonedSO,BillAddress);
            clonedSO = UtilityClass.assignShipToAdd(clonedSO,shipAddress);
            
            
            insert clonedSO;
            system.debug('clonedSO:::'+clonedSO);
            Sales_Order__c tempSO1 = [Select id,name,Status__c,Enquiry_Status__c,Link_To_ERP__c from Sales_Order__c where Id =: clonedSO.Id];
            system.debug('tempSO1:::'+tempSO1);
            List<Sales_Order_Line_Items__c> soliList = new List<Sales_Order_Line_Items__c>();
            for(Sales_Order_Line_Items__c soli:parentSO.Sales_Order_Line_Items__r)
            {
                system.debug('soli'+soli);
                if(soli.Price_Specification_Book_Product__r.Active__c)
                {
                    pSoliId.add(soli.Id);
                    Sales_Order_Line_Items__c clonedSOLI = soli.clone(false, true, false, false);
                    clonedSOLI.Sales_Order__c = clonedSO.Id;
                    clonedSOLI.Status__c = 'Order Submitted';
                    clonedSOLI.Production_Status__c='';
                    clonedSOLI.Online_Detail_Status__c ='';
                    clonedSOLI.Shared_With_Production_User__c = false;
                    clonedSOLI.Parent_Mainetti_Order_Line_Item__c = soli.Id;
                    clonedSOLI.Is_Downloaded__c = false;
                    clonedSOLI.Ship_qty__c = null;
                    clonedSOLI.Total_Ship_Qty__c = null;
                    clonedSOLI.Remaining_Qty__c = soli.Ordered_Quantity__c;
                    if(pbIdSpecialDiscountPriceMap.containskey(soli.Price_Specification_Book_Product__c)){
                        system.debug('with magnet price'+soli.Price_Specification_Book_Product__c);
                        if(soli.Price_Product_by_Currency__r.Price_100_pcs__c!=null){  
                            clonedSOLI.Price_100_pcs__c = String.valueof(pbIdSpecialDiscountPriceMap.get(soli.Price_Specification_Book_Product__c).Price_100_pcs__c);
                            clonedSOLI.Price_1000_pcs__c = String.valueof((pbIdSpecialDiscountPriceMap.get(soli.Price_Specification_Book_Product__c).Price_100_pcs__c)*10);
                            clonedSOLI.Price_Product_by_Currency__c = pbIdSpecialDiscountPriceMap.get(soli.Price_Specification_Book_Product__c).Id;
                            system.debug('clonedSOLI.Price_100_pcs__c'+clonedSOLI.Price_100_pcs__c);
                        }
                    }
                    else{
                        system.debug('without magnet price'+soli.Price_Specification_Book_Product__c);
                        if(soli.Price_Product_by_Currency__r.Price_100_pcs__c!=null){
                            clonedSOLI.Price_100_pcs__c = String.valueof(soli.Price_Product_by_Currency__r.Price_100_pcs__c);
                            clonedSOLI.Price_1000_pcs__c = String.valueof((soli.Price_Product_by_Currency__r.Price_100_pcs__c)*10);
                        }
                    }
                    clonedSOLI.USD_Rebate_pc__c = soli.Price_Specification_Book_Product__r.USD_Rebate_pc__c;
                    clonedSOLI.EUR_Rebate_pc__c = soli.Price_Specification_Book_Product__r.EUR_Rebate_pc__c;
                    clonedSOLI.USD_Reuse_Rebate_pc__c = soli.Price_Specification_Book_Product__r.USD_Reuse_Rebate_pc__c;
                    clonedSOLI.EUR_Reuse_Rebate_pc__c = soli.Price_Specification_Book_Product__r.EUR_Reuse_Rebate_pc__c;
                    clonedSOLI.Print__c = soli.Price_Specification_Book_Product__r.Sizer_Print__c;
                    clonedSOLI.Expected_Delivery_Date__c = null;
                    clonedSOLI.Expected_Completion_Date__c = null;
                    clonedSOLI.Local_SKU__c = soli.Price_Specification_Book_Product__r.Local_SKU__c;
                    clonedSOLI.BOX_QTY__c = soli.Price_Specification_Book_Product__r.BOX_QTY__c;
                    clonedSOLI.Total_Ship_Qty__c = 0;
                    clonedSOLI.Ship_qty__c = 0;
                    clonedSOLI.Supply_Quantity_num__c = 0;
                    clonedSOLI.Shipped_Date__c = null;
                    clonedSOLI.Remarks__c = null;
                    clonedSOLI.iSCloned__c=true;
                    soliList.add(clonedSOLI);
                }
            }
            system.debug('soliList size:::'+soliList.size());
            
            insert soliList;
            system.debug('pSoliId:::'+pSoliId);
            
            //cloning care label order lines
            List<Care_Label_Order_Line__c> clolList = [Select Id, name, RecordtypeId, Care_Instruction_Detail__c, Care_Instruction_Group__c, careInstructions__c, Component__c, Ex_Care_Instructions__c, Item_Number__c, Labelling_Code__c, Language1__c, Language2__c, Language3__c, Language4__c, Language5__c, Lot_Number__c, SalesOrderLineItems__c, Material__c, Packaging_Code__c, Position__c, RN_Number__c, Season__c, Season_Month__c, Season_Year__c, Style_Number__c, Supplier_Number__c, Value__c from Care_Label_Order_Line__c where SalesOrderLineItems__c IN: pSoliId];
            if(clolList.size()>0)
            {
                Map<Id,Id> pSOLInClonedSOLIMap = new Map<Id,Id>();
                for(Sales_Order_Line_Items__c cSOLI:soliList)
                {
                    pSOLInClonedSOLIMap.put(cSOLI.Parent_Mainetti_Order_Line_Item__c,cSOLI.Id);
                }
                
                List<Care_Label_Order_Line__c> newClolList = new List<Care_Label_Order_Line__c>();
                for(Care_Label_Order_Line__c pclol:clolList)
                {
                    system.debug('pclol:::'+pclol);
                    Care_Label_Order_Line__c clonedclol = pclol.clone(false, true, false, false);
                    //clonedSO.RecordtypeId = pclol.RecordtypeId;
                    clonedclol.SalesOrderLineItems__c = pSOLInClonedSOLIMap.get(pclol.SalesOrderLineItems__c);
                    newClolList.add(clonedclol);
                }
                insert newClolList;
                system.debug('newClolList:::'+newClolList);
            }
            
            Sales_Order__c tempSO = [Select id,name,Status__c,Enquiry_Status__c,Link_To_ERP__c from Sales_Order__c where Id =: clonedSO.Id];
            system.debug('tempSO:::'+tempSO);
            retString = clonedSO.Id;
        }
        system.debug('isPricebookActive:::'+isPricebookActive+' ::isAnyPricebookActive::'+isAnyPricebookActive);
        if(isPricebookActive == false && isAnyPricebookActive == false) //all the pricebooks are inactive
        {
            retString = 'All pricebook inactive';
        }
        if(isPricebookActive == true && isAnyPricebookActive == false)  //some the pricebooks are inactive
        {
            retString = 'Some pricebook inactive';
        }
        return retString;
    }
    //SO clone feature ends
    
    public class ReviseReqVersionsWrap
    {
        @AuraEnabled public Decimal revVersion ;
        @AuraEnabled public List<ReviseReqwrap> ReviseReqWrapList = new List<ReviseReqwrap>();
    }
    
    public class ReviseReqwrap
    {
        @AuraEnabled public boolean iseditable = false;
        @AuraEnabled public Revise_Order__c revOData;
        @AuraEnabled public Revise_Order__c oldVal;
        @AuraEnabled public Revise_Order__c newVal;
        @AuraEnabled public Decimal boxQty;
        @AuraEnabled public Decimal MOQ;
    }
    
    //Code to view Revise requests ends here
    
    //wrapper class to show sales orders in Order History tab
    public class ResponseWrapper
    {
        @AuraEnabled
        public Integer pageSize;
        @AuraEnabled
        public Integer page;
        @AuraEnabled
        public Integer totalRecords ;
        @AuraEnabled
        public List<String> ListOfStatus;       
        @AuraEnabled
        public List<SalesOrderWrap> SOList;
        
    }
    public class SalesOrderWrap
    {
        @AuraEnabled
        public Sales_Order__c SO;
        @AuraEnabled
        public List<Sales_Order_Line_Items__c> SOLI;
        @AuraEnabled
        public List<PurchaseOrder__c> PoToUpdate;
        //@AuraEnabled
        //public List<Purchase_Order_LineItem__c> PoliToUpdate;
        @AuraEnabled
        public Map<Id,Purchase_Order_LineItem__c> PoliMapToUpdate;
        
    }
    public class ReviseOrderRequestWrap
    {
        @AuraEnabled
        public Sales_Order__c revSO; 
        @AuraEnabled
        public List<Sales_Order_Line_Items__c> SOLI;
        @AuraEnabled
        public orderlineitem OrderLineList = new orderlineitem();
        @AuraEnabled 
        public List<String> pickListValuesList;
    }
    public class orderlineitem
    {
        @AuraEnabled
        public List<Revise_Order__c> reviseOrder = new List<Revise_Order__c>();
        
    }
    public class SOLIWrapperList     
    {
        @AuraEnabled
        public List<Sales_Order_Line_Items__c> SOLIWrapper ;
        @AuraEnabled
        public Decimal TotalPriceByCurrencyInCart {get;set;} 
    }
    
      @AuraEnabled
      public static Integer getLeadTime(string punchoutID)
       {
        Integer leadTime;
        Expected_ExFactory_Date__c leadDate=[SELECT LeadTime__c FROM Expected_ExFactory_Date__c	];
        
        return leadTime=(Integer)leadDate.LeadTime__c;
      }
    //wrapper for product Details
    public class SOLIWrapper{
        @AuraEnabled
        public String Id {get;set;}
        @AuraEnabled
        public String SOid {get;set;}
        @AuraEnabled
        public String Name {get;set;}
        @AuraEnabled
        public String producttype {get;set;}
        @AuraEnabled
        public String Productimage {get;set;}
        @AuraEnabled
        public String Color {get;set;}
        @AuraEnabled
        public String LocalSKU {get;set;}
        @AuraEnabled
        public String Size {get;set;}
        @AuraEnabled
        public String Quantity {get;set;}
        @AuraEnabled
        public String Description {get;set;}
        @AuraEnabled
        public String retailerName {get;set;}
        @AuraEnabled
        public Boolean fullboxQty;
        @AuraEnabled
        public Boolean ShowBoxQty; // Added 8 Jun 2023 Ivy Lee
         @AuraEnabled
        public String DisplayModel {get;set;} // Added 8 Jun 2023 Ivy Lee
        @AuraEnabled
        public Decimal boxquantity;
        @AuraEnabled
        public String PSBP {get;set;}
       // @AuraEnabled
       //public String DisplayModel {get;set;} // Added 7 Jun 2023 Ivy Lee
        @AuraEnabled
        public String ProductId {get;set;}
        @AuraEnabled
        public Decimal MOQ {get;set;}
        @AuraEnabled
        public String NewVal {get;set;}
        @AuraEnabled
        public String Remarks {get;set;}
        @AuraEnabled
        public Boolean showremarks;
        @AuraEnabled
        public String orderUom{get;set;}
        @AuraEnabled
        public String variableDataProduct{get;set;}
        //Added By Bharath On 08/11/2021
        @AuraEnabled
        public Decimal TotalPriceByCurrency {get;set;} 
        @AuraEnabled
        public String CurrencyIsoCode {get;set;}
        @AuraEnabled
        public String BlankString {get;set;}
        @AuraEnabled
        public Boolean ShowPriceInOrder;
    }
    //wrapper for address
    public class addressWrapper
    { 
        @AuraEnabled
        public List<Ship_Bill_Address__c> billAddList;
        @AuraEnabled
        public List<Ship_Bill_Address__c> shipAddList;
        @AuraEnabled
        public List<Ship_Bill_Address__c> buyerAddList;
        @AuraEnabled
        public List<Ship_Bill_Address__c> invoiceAddList;
        @AuraEnabled
        public List<String> shipTermList;
        @AuraEnabled
        public boolean SuzhouFlag;
        @AuraEnabled
        public String defaultCompany;
        @AuraEnabled
        public String defaultCurrency;
        @AuraEnabled
        public List<String> seasonsList;
        @AuraEnabled
        public List<String> seasonsYearList;
        @AuraEnabled
        public List<String> divisionList;
        @AuraEnabled
        public List<String> brandLabelList;
        @AuraEnabled
        public Sales_Order__c protoSO; 
        //==== for UnMask Supplier Code and Manufacture Code in Customer Sales Order==//
        @AuraEnabled
        public boolean SOUnMask;
        @AuraEnabled
        public boolean MOUnMask;
        @AuraEnabled
        public list<String> ManuSuppList;
        @AuraEnabled
        public list<String> ManuCompleteList;
        @AuraEnabled
        public list<Retailer_Code__c> MandatoryCheckFields;
        @AuraEnabled
        public Integer leadTime;
        
    } 
    
    public class POtoSOWrap     //#2.1 ENH
    {
        @AuraEnabled
        public List<Sales_Order__c> SOList = new List<Sales_Order__c>();
        @AuraEnabled
        public List<Sales_Order_Line_Items__c> SOLIList = new List<Sales_Order_Line_Items__c>();
        @AuraEnabled
        public List<PurchaseOrder__c> PoList = new List<PurchaseOrder__c>();
        @AuraEnabled
        public Map<Id,Purchase_Order_LineItem__c> PoliPOIdMap = new Map<Id,Purchase_Order_LineItem__c>();
    }
    public class ResponseWrapperInternal
    {
        @AuraEnabled
        public Integer pageSize;
        @AuraEnabled
        public Integer page;
        @AuraEnabled
        public Integer totalRecords ;
        @AuraEnabled
        public List<String> ListOfStatus;       
        @AuraEnabled
        public List<SalesOrderWrap> SOList;
        
    }
    
    //=========== code for display POLI details in Revise order ViewPOLI Popup for Single SO Conversion=====//
    @AuraEnabled
    public static List<Purchase_Order_LineItem__c> getrevisePOLI(List<string> poliIds){
        List<Purchase_Order_LineItem__c> reversePOLIList =[SELECT Id,Name,Purchase_Order__c,Purchase_Order__r.Order_Number__c,Original_Quantity__c  FROM Purchase_Order_LineItem__c WHERE Id IN : poliIds];
        return reversePOLIList;
    }
    //Code to uncheck all the selected PO
    @AuraEnabled
    public static void uncheckPoCheckbox(List<String> SelectedId){
        List<PurchaseOrder__c> checkBoxStore;
        checkBoxStore =[Select Id ,UserId__c, PO_Selected__c from PurchaseOrder__c where Id=:SelectedId];   
        for(PurchaseOrder__c cb : checkBoxStore ){
            for(string selId : SelectedId){
                if(cb.Id==selId){
                    cb.PO_Selected__c=false;
                    cb.UserId__c='';
                }
            }
            System.debug('loop values of cb>>>'+ cb);
        }
        update checkBoxStore;
    }
    @AuraEnabled
    public static ResponseWrapperInternal FetchSalesOrdersforInternal(String recordID)
    {
        ResponseWrapperInternal response = new ResponseWrapperInternal();
        System.debug('RecordID>>>'+recordID);
        try
        {
            String SOquery;
            String SOCount;
            
            SOquery='Select Id, Name, Reference__c, Revise_Version__c,OrderSource__c,Purchase_Orders__c, Order_Number__c,CreatedDate, LastModifiedDate, Company__c, Shipment_Terms__c, Delivery_Instructions__c, Expected_Delivery_Date__c, Expected_Completion_Date__c,Status__c, Link_To_ERP__c, Enquiry_Status__c, Retailer__c, Retailer__r.Name, Retailer_Contact__c, Retailer_Contact__r.Name, Supplier__c, Supplier__r.Name, Retailer_Code1__c, Retailer_Code1__r.Name,Retailer_Code1__r.Market_Segment__c, Retailer_Code1__r.Remarks__c, Priority__c, Mainetti_Email__c, Mainetti_SO_SC__c, Ship_to_Company__c,Ship_to_Address__c,Ship_to_Address__r.Name,Ship_to_Address__r.Contact__c,Ship_to_Country__c,Ship_to_Tel__c,Ship_to_Email__c,Ship_to_Factory__c,Ship_to_Address1__c,Ship_to_State__c,Ship_to_Postcode__c,Ship_to_City__c,Factory_Internal_PO__c,Shipping_Mark__c,Transportation_Details__c';
            SOquery+=' from Sales_Order__c where Id =: recordID';
            SOCount='SELECT count(id) totalCount FROM Sales_Order__c where Id =: recordID';
            
            List<Sales_Order__c> soList = Database.query(SOquery);
            system.debug('soList>>>>>'+soList);
            Set<Id> soIdSet = new Set<Id>();
            Integer searchCounter =0;
            
            for(Sales_Order__c order :soList)
            {
                soIdSet.add(order.Id);
            }
            response.totalRecords = Integer.valueOf(Database.query(SOCount)[0].get('totalCount')); 
            
            Map<Id,List<Sales_Order_Line_Items__c>> SOnSOLIListMap = new Map<Id,List<Sales_Order_Line_Items__c>>();
            for(Sales_Order_Line_Items__c soli :[Select Id, Name, Sales_Order__c, CreatedDate, LastModifiedDate, Quantity__c, Expected_Delivery_Date__c, Supply_Quantity__c,Customer_Ref_Model__c, Mainetti_Model_Code__c,Full_Box_Order__c,BOX_QTY__c, Ordered_Quantity__c, Products__c, Products__r.Name, Price_Specification_Book_Product__r.Name, APN__c, DEPT_DESC__c, Style_No__c, Colour__c, Size__c, Status__c, Online_Detail_Status__c, Production_Status__c, Due_Date_TXT__c, LOCN_TXT__c, Printshop_Pick__c,Test_date_and_time__c,Expected_Completion_Date__c,Purchase_Order_LineItem__c,POLI_Text_Ids__c,POLI_Text_Name__c,variable_data_product__c,print__c, Price_Specification_Book_Product__r.MOQ__c,Remarks__c from Sales_Order_Line_Items__c where Sales_Order__c IN:soIdSet ])
            {
                if(SOnSOLIListMap.containsKey(soli.Sales_Order__c))
                {
                    SOnSOLIListMap.get(soli.Sales_Order__c).add(soli);
                }
                else
                {
                    List<Sales_Order_Line_Items__c> soliList = new List<Sales_Order_Line_Items__c>();
                    soliList.add(soli);
                    SOnSOLIListMap.put(soli.Sales_Order__c,soliList);
                }
            }
            
            List<SalesOrderWrap> SOWrapList = new List<SalesOrderWrap>();
            for(Sales_Order__c order :soList)
            {
                if(soIdSet.contains(order.Id)){
                    SalesOrderWrap SOWrap = new SalesOrderWrap();
                    SOWrap.SO = order;
                    if(SOnSOLIListMap.containsKey(order.Id))
                        SOWrap.SOLI = SOnSOLIListMap.get(order.Id);
                    SOWrapList.add(SOWrap);
                }
                
            }
            response.SOList = SOWrapList;
            return response;
        }
        catch (Exception e)
        {
            System.debug('e:::'+e);
            return null;
        }
    }
    @AuraEnabled
    public static addressWrapper FetchCustAddForCatalogOrder(String custInfoid,String retailer, String retailercodeId, String orderSource)
    {
        system.debug('orderSource>>>>'+orderSource);
        Map<String, List<String>> CompanyAndItsShippingTerms = new Map<String, List<String>>();
        Online_Enquiry__c oe = new Online_Enquiry__c();
        CompanyAndItsShippingTerms = RegistrationService.getDependentMap(oe,'Order_Country__c','Delivery_Instruction__c');
        Contact con = UtilityClass.getCurrentUserContact();
        String CompName;
        String currencyName;
        boolean iscloned = false;
        Sales_Order__c cartSO = new Sales_Order__c();
        
        for(Retailer_Related_Data__c rrd:[Select Id,Order_to_Company__c,Preferred_Currency__c from Retailer_Related_Data__c where ContactID__c =:con.Id AND Status__c = 'Active' AND Retailer_Code__c =:retailercodeId ])
        {
            system.debug('rrd getcostomerinfo'+rrd);
            //contactid.Order_to_Company1__c=companyNameandAPI.get(contactid.Order_to_Company1__c);
            con.Order_to_Company__c=rrd.Order_to_Company__c;
            con.Preferred_Currency__c=rrd.Preferred_Currency__c;
            
        }
        
        system.debug('comapny>>>>'+con.Order_to_Company__c+'currency>>>>'+con.Preferred_Currency__c);
        system.debug('CompanyAndItsShippingTerms>>>>'+CompanyAndItsShippingTerms);
        if(orderSource == 'PO')
        {
            Map<String,String> companyAPIandName = UtilityClass.getOrderToCompanyPicklist(true);
            if(companyAPIandName.containskey(con.Order_to_Company__c))
            {
                CompName=companyAPIandName.get(con.Order_to_Company__c);
            }
            else if(con.Order_to_Company__c != null)
            {
                CompName = con.Order_to_Company__c;
            }
            
            String CurrCode;
            if(con.Preferred_Currency__c.contains('-'))
            {
                String [] currencySplit = con.Preferred_Currency__c.split('-');
                
                if(currencySplit.size()>1)
                {
                    String ResCurr = currencySplit[0].trim();
                    CurrCode = ResCurr;
                }
            }
            else
            {
                CurrCode = con.Preferred_Currency__c;
            }
            
            Map<String,String> currencyAPIandName = UtilityClass.getPreferredCurrencyPicklist(true);
            system.debug('CurrCode>>>>'+CurrCode);
            if(currencyAPIandName.containskey(CurrCode))
            {
                currencyName=currencyAPIandName.get(CurrCode);
            }
        }
        else
        {
            cartSO = UtilityClass.getSORecordAsCart(custInfoid);
            system.debug('cartSO>>>>'+cartSO);
            
            Schema.DescribeFieldResult companyResult = Online_Enquiry__c.Order_Country__c.getDescribe();
            List<Schema.PicklistEntry> values = companyResult.getPicklistValues();
            
            for( Schema.PicklistEntry v : values) 
            {
                if(v.getLabel() == cartSO.Company__c)
                {
                    System.debug('PicklistEntry name'+v.getLabel()+' API name '+v.getValue());
                    CompName = v.getLabel();
                    break;
                }
            }
            
            String [] currencySplit = cartSO.CurrencyIsoCode.split('-');
            String CurrCode;
            if(currencySplit.size()>1)
            {
                String ResCurr = currencySplit[0].trim();
                CurrCode = ResCurr;
            }
            else
            {
                CurrCode = cartSO.CurrencyIsoCode;
            }
            
            Map<String,String> currencyAPIandName = UtilityClass.getPreferredCurrencyPicklist(true);
            system.debug('CurrCode>>>>'+CurrCode);
            if(currencyAPIandName.containskey(CurrCode))
            {
                currencyName=currencyAPIandName.get(CurrCode);
            }
            system.debug('OrderSource>>>>'+cartSO.OrderSource__c);
            if(cartSO.OrderSource__c == 'Cloned')
            {
                iscloned = true;
            }
        }
        system.debug('CompName>>>>'+CompName);
        system.debug('currencyName>>>>'+currencyName);
        addressWrapper addWrap = new addressWrapper();
        List<Ship_Bill_Address__c> billAddress = new List<Ship_Bill_Address__c>();
        List<Ship_Bill_Address__c> shipAddress = new List<Ship_Bill_Address__c>();
        List<Ship_Bill_Address__c> buyerAddress = new List<Ship_Bill_Address__c>();
        List<Ship_Bill_Address__c> invoiceAddress = new List<Ship_Bill_Address__c>();
        
        //fetching address realted to customer and grouping them by their record types
        List<Ship_Bill_Address__c> custAddress= [select id,name,recordtype.name,Is_Default__c,Company_Name__c,Address_1__c,City__c,State__c,Country__c,Postcode__c,Factory_Name__c,Contact__c,Tel_No__c,Email_Address__c, Fax_No__c from Ship_Bill_Address__c where Customer_Information__c =: custInfoid AND Bill_Ship_Status__c=:'Active'];
        for(Ship_Bill_Address__c addss:custAddress)
        {
            if(addss.recordtype.name == 'Bill To' || addss.recordtype.name == 'Bill To Locked')
            {
                billAddress.add(addss);
            }
            else if(addss.recordtype.name == 'Ship To')
            {
                shipAddress.add(addss);
            }
            else if(addss.recordtype.name == 'Buyer')
            {
                buyerAddress.add(addss);
            }
            else if(addss.recordtype.name == 'Invoice To')
            {
                invoiceAddress.add(addss);
            }
        }
        addWrap.billAddList = billAddress;
        addWrap.shipAddList = shipAddress;
        addWrap.buyerAddList = buyerAddress;
        addWrap.invoiceAddList = invoiceAddress;
        addWrap.defaultCompany = CompName;
        addWrap.defaultCurrency = currencyName;
        
        
        
        if(CompanyAndItsShippingTerms.containskey(CompName))
        {
            addWrap.shipTermList = CompanyAndItsShippingTerms.get(CompName);
        }
        //addWrap.SuzhouFlag = con.Order_to_Company__c.contains('Suzhou');
        
        addWrap.SuzhouFlag = CompName.contains('Suzhou');
        
        //changes for retailer information section
        //to get division list values
        List<string> listValuesOfDivision = new List<string>();
        listValuesOfDivision = DependentPicklist(retailer,'Retailer_Code_Hidden__c','Division__c');
        System.debug(' listValuesOfDivision:: '+listValuesOfDivision);

         //to get Brand_Label list values
         List<string> listValuesOfBrandLabel = new List<string>();
         listValuesOfBrandLabel = DependentPicklist(retailer,'Retailer_Code_Hidden__c','Brand_Label__c');
         System.debug(' listValuesOfBrandLabel:: '+listValuesOfBrandLabel);
        
        //to get season list values
        List<string> listValuesOfSeason = new List<string>();
        listValuesOfSeason = DependentPicklist(retailer,'Retailer_Code_Hidden__c','Season__c');
        System.debug(' listValuesOfSeason:: '+listValuesOfSeason);
        
        //to get season year list values
        Schema.DescribeFieldResult seasonYearResult = Online_Enquiry__c.Season_Year__c.getDescribe();
        List<Schema.PicklistEntry> seasonYearvalues = seasonYearResult.getPicklistValues();
        List<string> listValuesOfSeasonYear = new List<string>();
        for( Schema.PicklistEntry v : seasonYearvalues) 
        {
            System.debug('PicklistEntry name'+v.getLabel()+' API name '+v.getValue());
            listValuesOfSeasonYear.add(v.getLabel());
        }
        System.debug(' listValuesOfSeasonYear:: '+listValuesOfSeasonYear);
        listValuesOfSeasonYear.sort();  //to sort years in ascending order
        
        addWrap.seasonsList = listValuesOfSeason;
        addWrap.seasonsYearList = listValuesOfSeasonYear;
        addWrap.divisionList = listValuesOfDivision;
        addWrap.brandLabelList = listValuesOfBrandLabel;
        
        //to get suppiel code and manufacturing code
        List<Retailer_Related_Data__c> ContRetailer = new List<Retailer_Related_Data__c>();
        //added by tony 20230201
        ContRetailer = [select id,Name,Supplier_Code__c,Retailer_Code__r.Supplier_Code_UnMask__c,Retailer_Code__r.Manufacturer_Code_UnMask__c,Customer_Information__c,Retailer_Code__c,Manufacturer_Factory_Code__c from Retailer_Related_Data__c where Customer_Information__c =: custInfoid AND Retailer_Code__c =: retailercodeId AND Order_to_Company__c =:CompName];
        System.debug('ContRetailer>>>>>>'+ContRetailer);
        if(ContRetailer.size()==0)
        {
        ContRetailer = [select id,Name,Supplier_Code__c,Retailer_Code__r.Supplier_Code_UnMask__c,Retailer_Code__r.Manufacturer_Code_UnMask__c,Customer_Information__c,Retailer_Code__c,Manufacturer_Factory_Code__c from Retailer_Related_Data__c where Customer_Information__c =: custInfoid AND Retailer_Code__c =: retailercodeId];
        System.debug('ContRetailer>>>>>>'+ContRetailer);
        }
        //added end
        if(ContRetailer[0].Retailer_Code__c != null){
            addWrap.SOUnMask = ContRetailer[0].Retailer_Code__r.Supplier_Code_UnMask__c;
            addWrap.MOUnMask = ContRetailer[0].Retailer_Code__r.Manufacturer_Code_UnMask__c;
        }
        else{
            addWrap.SOUnMask = false;
            addWrap.MOUnMask = false;
        }
        //Fetching Checkbox values for mandatory feilds according to retailer code
        List<Retailer_Code__c> MandatoryCheck = new List<Retailer_Code__c>();
        MandatoryCheck = [Select Season_Mandatory__c , Season_Year_Mandatory__c ,Retailer_PO_Mandatory__c,Division_Mandatory__c,Brand_Label_Mandatory__c,MG_Remarks_Mandatory__c from Retailer_Code__c where Id =: retailercodeId ];
        addWrap.MandatoryCheckFields=MandatoryCheck;
        
        system.debug('iscloned::'+iscloned);
        Sales_Order__c prototypeSO = new Sales_Order__c();
        if(iscloned)
        {
            prototypeSO = [Select Id, Name, Expected_Delivery_Date__c, Delivery_Instructions__c, Division__c, Season__c, Season_Year__c,Brand_Label__c,Remarks__c, OrderSource__c, Transportation_Details__c, Shipping_Mark__c, Bill_to_Address__c, Buyer_Address__c, Invoice_To_Address__c, Ship_to_Address__c from Sales_Order__c where Id =: cartSO.Id];
            //prototypeSO.Expected_Delivery_Date__c = Date.today();
            system.debug('today\'s date::'+System.today());
            system.debug(' date todate ::'+Date.today());
        }
        system.debug('prototypeSO::'+prototypeSO);
        prototypeSO.Supplier_Code__c=ContRetailer[0].Supplier_Code__c;
        prototypeSO.Manufacturer_Code__c=ContRetailer[0].Manufacturer_Factory_Code__c;
        prototypeSO.Id = cartSO.Id;
        addWrap.protoSO = prototypeSO;
        
        
        
        return addWrap;
    }
    @AuraEnabled
    public static string SaveRevOrderInternal(string revOrder, string ordertocompany,string RetailerCode,Date CancelDate)
    {
        if(revOrder == null)
            return 'failure';
        
        List<Revise_Order__c> desobj = (List<Revise_Order__c>)JSON.deserialize(revOrder, List<Revise_Order__c>.class);
        system.debug('desobj:::'+desobj);
        Sales_Order__c Salesorder = [select id, Name,Revise_Version__c,Status__c,Enquiry_Status__c,Link_To_ERP__c from Sales_Order__c where id =: desobj[0].Mainetti_SO__c];
        system.debug('Salesorder:::'+Salesorder);
        
        List<Revise_Order__c> roList = new List<Revise_Order__c>(); 
        Sales_Order__c so = new Sales_Order__c();
        List<Sales_Order_Line_Items__c> soli = new List<Sales_Order_Line_Items__c>();
        
        try{
            //Logic-->once the printshop downloads and customer revise the order
            //once print shop downloads only date and address needs to revise
            if(Salesorder.Status__c == 'Order Under Processing' && Salesorder.Enquiry_Status__c == 'Under Manufacturing')
            {
                system.debug('desobj:::'+desobj);
                for(Revise_Order__c Ro:desobj)
                {
                    Revise_Order__c roobj = new Revise_Order__c();
                    if(Ro.Revised__c == true)
                    {   
                        roobj.Revised_by_Admin__c = true;
                        so.id =Ro.Mainetti_SO__c;
                        so.Enquiry_Status__c ='Pending for change approval';
                        so.Link_To_ERP__c ='Resend';
                        
                        if(Ro.What_to_Revise__c == 'Ship Date' && Ro.New_Expected_Delivery_Date__c !=null)
                        {
                            roobj.id = Ro.id;
                            roobj.Mainetti_SO__c = Ro.Mainetti_SO__c;
                            roobj.Status__c ='Approve Pending' ;
                            roobj.What_to_Revise__c =Ro.What_to_Revise__c;
                            roobj.New_Expected_Delivery_Date__c = Ro.New_Expected_Delivery_Date__c!=null?Ro.New_Expected_Delivery_Date__c:null;
                            roobj.Old_Expected_Delivery_Date__c = Ro.Old_Expected_Delivery_Date__c!=null?Ro.Old_Expected_Delivery_Date__c:null;
                            roobj.Revise_req_Version__c = Salesorder.Revise_Version__c+1;
                            roList.add(roobj);
                        }
                        else if(Ro.What_to_Revise__c == 'Ship To' && Ro.Mainetti_SO__c !=null)
                        { 
                            roobj.Mainetti_SO__c = Ro.Mainetti_SO__c;
                            roobj.Status__c ='Approve Pending' ;
                            roobj.What_to_Revise__c =Ro.What_to_Revise__c;
                            roobj.New_Bill_to_Ship_to_Address__c = Ro.New_Bill_to_Ship_to_Address__c!=null?Ro.New_Bill_to_Ship_to_Address__c:'';
                            roobj.Old_Bill_to_Ship_to_Address__c = Ro.Old_Bill_to_Ship_to_Address__c!=null?Ro.Old_Bill_to_Ship_to_Address__c:'';
                            roobj.New_Ship_to_Company__c = Ro.New_Ship_to_Company__c!=null?Ro.New_Ship_to_Company__c:'';
                            roobj.Old_Ship_to_Company__c = Ro.Old_Ship_to_Company__c!=null?Ro.Old_Ship_to_Company__c:'';
                            roobj.New_Ship_to_Address1__c = Ro.New_Ship_to_Address1__c!=null?Ro.New_Ship_to_Address1__c:'';
                            roobj.Old_Ship_to_Address1__c = Ro.Old_Ship_to_Address1__c!=null?Ro.Old_Ship_to_Address1__c:'';
                            roobj.New_Ship_to_State__c = Ro.New_Ship_to_State__c!=null?Ro.New_Ship_to_State__c:'';
                            roobj.Old_Ship_to_State__c = Ro.Old_Ship_to_State__c!=null?Ro.Old_Ship_to_State__c:'';
                            roobj.New_Ship_to_City__c = Ro.New_Ship_to_City__c!=null?Ro.New_Ship_to_City__c:'';
                            roobj.Old_Ship_to_City__c = Ro.Old_Ship_to_City__c!=null?Ro.Old_Ship_to_City__c:'';
                            roobj.New_Ship_to_Country__c = Ro.New_Ship_to_Country__c!=null?Ro.New_Ship_to_Country__c:'';
                            roobj.Old_Ship_to_Country__c = Ro.Old_Ship_to_Country__c!=null?Ro.Old_Ship_to_Country__c:'';
                            roobj.New_Ship_to_Postcode__c = Ro.New_Ship_to_Postcode__c!=null?Ro.New_Ship_to_Postcode__c:'';
                            roobj.Old_Ship_to_Postcode__c = Ro.Old_Ship_to_Postcode__c!=null?Ro.Old_Ship_to_Postcode__c:'';
                            roobj.New_Ship_to_Tel__c = Ro.New_Ship_to_Tel__c!=null?Ro.New_Ship_to_Tel__c:'';
                            roobj.Old_Ship_to_Tel__c = Ro.Old_Ship_to_Tel__c!=null?Ro.Old_Ship_to_Tel__c:'';
                            roobj.Old_Ship_to_Email__c = Ro.Old_Ship_to_Email__c!=null?Ro.Old_Ship_to_Email__c:'';
                            roobj.New_Ship_to_Email__c = Ro.New_Ship_to_Email__c!=null?Ro.New_Ship_to_Email__c:'';
                            roobj.Old_Ship_to_Contact_Name__c = Ro.Old_Ship_to_Contact_Name__c!=null?Ro.Old_Ship_to_Contact_Name__c:'';
                            roobj.New_Ship_to_Contact_Name__c = Ro.New_Ship_to_Contact_Name__c!=null?Ro.New_Ship_to_Contact_Name__c:'';
                            roobj.Revise_req_Version__c = Salesorder.Revise_Version__c+1;
                            roList.add(roobj);
                            system.debug('Ro11>>>'+Ro);
                        }
                    }
                }   
            }
            else                                                                            //else loop for before print shop downloads the order  
            {
                for(Revise_Order__c Ro:desobj)
                {
                    system.debug('Ro>>'+Ro);
                    Revise_Order__c roobj = new Revise_Order__c();
                    if(Ro.Revised__c == true)
                    {   
                        roobj.Revised_by_Admin__c = true;
                        so.id =Ro.Mainetti_SO__c;
                        so.Status__c='Approve Pending';
                        so.Enquiry_Status__c ='Pending for change approval';
                        so.Link_To_ERP__c ='Resend';
                        
                        if(Ro.What_to_Revise__c == 'Ship Date' && Ro.New_Expected_Delivery_Date__c !=null)
                        {
                            roobj.id = Ro.id;
                            roobj.Mainetti_SO__c = Ro.Mainetti_SO__c;
                            roobj.Status__c ='Approve Pending' ;
                            roobj.What_to_Revise__c =Ro.What_to_Revise__c;
                            roobj.New_Expected_Delivery_Date__c = Ro.New_Expected_Delivery_Date__c!=null?Ro.New_Expected_Delivery_Date__c:null;
                            roobj.Old_Expected_Delivery_Date__c = Ro.Old_Expected_Delivery_Date__c!=null?Ro.Old_Expected_Delivery_Date__c:null;
                            roobj.Revise_req_Version__c = Salesorder.Revise_Version__c+1;
                            roList.add(roobj);
                        }
                        else if(Ro.What_to_Revise__c == 'Ship To' && Ro.Mainetti_SO__c !=null)
                        { 
                            roobj.Mainetti_SO__c = Ro.Mainetti_SO__c;
                            roobj.Status__c ='Approve Pending' ;
                            roobj.What_to_Revise__c =Ro.What_to_Revise__c;
                            roobj.New_Bill_to_Ship_to_Address__c = Ro.New_Bill_to_Ship_to_Address__c!=null?Ro.New_Bill_to_Ship_to_Address__c:'';
                            roobj.Old_Bill_to_Ship_to_Address__c = Ro.Old_Bill_to_Ship_to_Address__c!=null?Ro.Old_Bill_to_Ship_to_Address__c:'';
                            roobj.New_Ship_to_Company__c = Ro.New_Ship_to_Company__c!=null?Ro.New_Ship_to_Company__c:'';
                            roobj.Old_Ship_to_Company__c = Ro.Old_Ship_to_Company__c!=null?Ro.Old_Ship_to_Company__c:'';
                            roobj.New_Ship_to_Address1__c = Ro.New_Ship_to_Address1__c!=null?Ro.New_Ship_to_Address1__c:'';
                            roobj.Old_Ship_to_Address1__c = Ro.Old_Ship_to_Address1__c!=null?Ro.Old_Ship_to_Address1__c:'';
                            roobj.New_Ship_to_State__c = Ro.New_Ship_to_State__c!=null?Ro.New_Ship_to_State__c:'';
                            roobj.Old_Ship_to_State__c = Ro.Old_Ship_to_State__c!=null?Ro.Old_Ship_to_State__c:'';
                            roobj.New_Ship_to_City__c = Ro.New_Ship_to_City__c!=null?Ro.New_Ship_to_City__c:'';
                            roobj.Old_Ship_to_City__c = Ro.Old_Ship_to_City__c!=null?Ro.Old_Ship_to_City__c:'';
                            roobj.New_Ship_to_Country__c = Ro.New_Ship_to_Country__c!=null?Ro.New_Ship_to_Country__c:'';
                            roobj.Old_Ship_to_Country__c = Ro.Old_Ship_to_Country__c!=null?Ro.Old_Ship_to_Country__c:'';
                            roobj.New_Ship_to_Postcode__c = Ro.New_Ship_to_Postcode__c!=null?Ro.New_Ship_to_Postcode__c:'';
                            roobj.Old_Ship_to_Postcode__c = Ro.Old_Ship_to_Postcode__c!=null?Ro.Old_Ship_to_Postcode__c:'';
                            roobj.New_Ship_to_Tel__c = Ro.New_Ship_to_Tel__c!=null?Ro.New_Ship_to_Tel__c:'';
                            roobj.Old_Ship_to_Tel__c = Ro.Old_Ship_to_Tel__c!=null?Ro.Old_Ship_to_Tel__c:'';
                            roobj.Old_Ship_to_Email__c = Ro.Old_Ship_to_Email__c!=null?Ro.Old_Ship_to_Email__c:'';
                            roobj.New_Ship_to_Email__c = Ro.New_Ship_to_Email__c!=null?Ro.New_Ship_to_Email__c:'';
                            roobj.Old_Ship_to_Contact_Name__c = Ro.Old_Ship_to_Contact_Name__c!=null?Ro.Old_Ship_to_Contact_Name__c:'';
                            roobj.New_Ship_to_Contact_Name__c = Ro.New_Ship_to_Contact_Name__c!=null?Ro.New_Ship_to_Contact_Name__c:'';
                            roobj.Revise_req_Version__c = Salesorder.Revise_Version__c+1;
                            roList.add(roobj);
                            system.debug('Ro11>>>'+Ro);
                        }
                        else if(Ro.What_to_Revise__c == 'Factory Internal PO' && Ro.New_Factory_Internal_PO__c !=null)
                        {
                            roobj.id = Ro.id;
                            roobj.Mainetti_SO__c = Ro.Mainetti_SO__c;
                            roobj.Status__c ='Approve Pending' ;
                            roobj.What_to_Revise__c =Ro.What_to_Revise__c;
                            roobj.New_Factory_Internal_PO__c = Ro.New_Factory_Internal_PO__c!=null?Ro.New_Factory_Internal_PO__c:null;
                            roobj.Old_Factory_Internal_PO__c = Ro.Old_Factory_Internal_PO__c!=null?Ro.Old_Factory_Internal_PO__c:null;
                            roobj.Revise_req_Version__c = Salesorder.Revise_Version__c+1;
                            roList.add(roobj);
                        }
                        else if(Ro.What_to_Revise__c == 'Shipping Mark/Special Instruction' && Ro.New_Shipping_Mark__c !=null)
                        {
                            roobj.id = Ro.id;
                            roobj.Mainetti_SO__c = Ro.Mainetti_SO__c;
                            roobj.Status__c ='Approve Pending' ;
                            roobj.What_to_Revise__c =Ro.What_to_Revise__c;
                            if(Ro.New_Shipping_Mark__c !=null && Ro.New_Shipping_Mark__c.contains('_space'))
                                roobj.New_Shipping_Mark__c = Ro.New_Shipping_Mark__c.replace('_space', '\n');
                            else{
                                roobj.New_Shipping_Mark__c = Ro.New_Shipping_Mark__c!=null?Ro.New_Shipping_Mark__c:null;
                            }
                            if(Ro.Old_Shipping_Mark__c !=null && Ro.Old_Shipping_Mark__c.contains('_space'))
                                roobj.Old_Shipping_Mark__c = Ro.Old_Shipping_Mark__c.replace('_space', '\n');
                            else{
                                roobj.Old_Shipping_Mark__c = Ro.Old_Shipping_Mark__c!=null?Ro.Old_Shipping_Mark__c:null;
                            }
                            
                            roobj.Revise_req_Version__c = Salesorder.Revise_Version__c+1;
                            roList.add(roobj);
                        }
                        if(Ro.What_to_Revise__c == 'Forwarder/Transportation Details' && Ro.New_Forwarder_Transportation_Details__c !=null)
                        {
                            roobj.id = Ro.id;
                            roobj.Mainetti_SO__c = Ro.Mainetti_SO__c;
                            roobj.Status__c ='Approve Pending' ;
                            roobj.What_to_Revise__c =Ro.What_to_Revise__c;
                            
                            if(Ro.New_Forwarder_Transportation_Details__c !=null && Ro.New_Forwarder_Transportation_Details__c.contains('_space'))
                                roobj.New_Forwarder_Transportation_Details__c = Ro.New_Forwarder_Transportation_Details__c.replace('_space', '\n');
                            else
                                roobj.New_Forwarder_Transportation_Details__c = Ro.New_Forwarder_Transportation_Details__c!=null?Ro.New_Forwarder_Transportation_Details__c:null;
                            
                            if(Ro.Old_Forwarder_Transportation_Details__c !=null && Ro.Old_Forwarder_Transportation_Details__c.contains('_space'))
                                roobj.Old_Forwarder_Transportation_Details__c = Ro.Old_Forwarder_Transportation_Details__c.replace('_space', '\n');
                            else
                                roobj.Old_Forwarder_Transportation_Details__c = Ro.Old_Forwarder_Transportation_Details__c!=null?Ro.Old_Forwarder_Transportation_Details__c:null;
                            
                            roobj.Revise_req_Version__c = Salesorder.Revise_Version__c+1;
                            roList.add(roobj);
                        }
                        else if(Ro.Mainetti_SOLI__c !=null && Ro.What_to_Revise__c == 'Quantity')
                        {   
                            Sales_Order_Line_Items__c soliobj = new Sales_Order_Line_Items__c();
                            soliobj.id=Ro.Mainetti_SOLI__c;                                        // check for multiple SOLI
                            soliobj.Online_Detail_Status__c='Pending for change approval';
                            soliobj.Production_Status__c = 'Open';
                            
                            roobj.Mainetti_SOLI__c = Ro.Mainetti_SOLI__c;
                            roobj.Mainetti_SO__c = Ro.Mainetti_SO__c;
                            roobj.Customer_Refe_Model__c = Ro.Customer_Refe_Model__c;
                            roobj.Color__c = Ro.Color__c;
                            roobj.Status__c ='Approve Pending' ;
                            if(Ro.New_Quantity__c !=null)
                            {
                                roobj.What_to_Revise__c =Ro.What_to_Revise__c;
                                roobj.New_Quantity__c =Ro.New_Quantity__c;
                                roobj.Old_Quantity__c =Ro.Old_Quantity__c;
                            }
                            system.debug('roobj>>'+roobj);
                            roobj.Revise_req_Version__c = Salesorder.Revise_Version__c+1;
                            roList.add(roobj);
                            soli.add(soliobj);
                            
                        }
                        else if(Ro.What_to_Revise__c == 'Cancel Order')         //header level    
                        {
                            roobj.Mainetti_SO__c = Ro.Mainetti_SO__c;
                            roobj.Mainetti_SOLI__c = Ro.Mainetti_SOLI__c;       
                            roobj.Status__c='Approve Pending';
                            roobj.What_to_Revise__c = Ro.What_to_Revise__c;
                            roobj.Reason_to_Cancel__c = Ro.Reason_to_Cancel__c;
                            roobj.Cancel_Order_Date__c = CancelDate;
                            roobj.Revise_req_Version__c = Salesorder.Revise_Version__c+1;
                            roList.add(roobj);
                        }
                        else if(Ro.Mainetti_SOLI__c !=null && Ro.What_to_Revise__c == 'Cancel Line Item')       //line level
                        {
                            Sales_Order_Line_Items__c solicancelobj = new Sales_Order_Line_Items__c();
                            solicancelobj.id=Ro.Mainetti_SOLI__c;                                           
                            solicancelobj.Online_Detail_Status__c='Pending for change approval';
                            solicancelobj.Production_Status__c = 'Open';
                            
                            roobj.Mainetti_SO__c = Ro.Mainetti_SO__c;
                            roobj.Mainetti_SOLI__c = Ro.Mainetti_SOLI__c;
                            roobj.Status__c='Approve Pending';
                            roobj.What_to_Revise__c = Ro.What_to_Revise__c;
                            roobj.Color__c = Ro.Color__c;
                            roobj.Customer_Refe_Model__c = Ro.Customer_Refe_Model__c;
                            roobj.New_Quantity__c =Ro.New_Quantity__c;
                            roobj.Old_Quantity__c =Ro.Old_Quantity__c;
                            roobj.Revise_req_Version__c = Salesorder.Revise_Version__c+1;
                            roList.add(roobj);
                            soli.add(solicancelobj);
                        }
                    }
                } 
                upsert soli;
            }
            if(Salesorder.Revise_Version__c == 0 || Salesorder.Revise_Version__c == null )
            {
                so.Revise_Version__c = 1;
            }
            else{
                so.Revise_Version__c = Salesorder.Revise_Version__c+1;
            }
            upsert roList;
            so.Revise_Order_Created_Date__c = Date.parse(system.today().format());
            if(roList.size() != 0)
            {
                //System.debug('___I__N__S__I__D__E_____I_F________L__O__O__P_');
                upsert so;
                //System.debug('___A F T E R _________U P S E R T________');
                //System.debug('ordertocompany>>>'+ordertocompany);
                //System.debug('RetailerCode>>>'+RetailerCode);
                //System.debug('roList>>>'+roList);
                //sendEmail(ordertocompany,RetailerCode,roList);
                //sendEmailToCustomer(ordertocompany,RetailerCode,roList);
                return 'success';
            }
            return 'ERROR'; 
        }
        catch (Exception e)
        {
            System.debug('e:::'+e);
            System.debug(LoggingLevel.ERROR, e.getMessage());
            return 'ERROR';
        }
    }
    @AuraEnabled
    public static void UpdateRevOrderAfterTrigger(String SoID, Boolean isCancelled)
    {
        List<Revise_Order__c> RevList = [Select id,Name,Revised_by_Admin__c from Revise_Order__c where Revised_by_Admin__c=true];
        for(Revise_Order__c eachRev:RevList){
            System.debug('___________________________________________________');
            System.debug('Each Rev>>>>'+eachRev);
            System.debug('___________________________________________________');
            if(eachRev.Revised_by_Admin__c==true){
                eachRev.Revised_by_Admin__c=false;
            }
        }
        if(isCancelled==false){
            List<Sales_Order__c> SO = [Select id, Name, Status__c, Enquiry_Status__c from Sales_Order__c where id=:SoID];
            for(Sales_Order__c eachSO:SO){
                if(eachSO.Status__c=='Approve Pending'){
                    eachSO.Status__c='Revised';
                }
                if(eachSO.Enquiry_Status__c=='Pending for change approval'){
                    eachSO.Enquiry_Status__c='Change Received';
                }
                update eachSO;
            }
        }else if(isCancelled==true){
            List<Sales_Order__c> SO = [Select id, Name, Status__c, Enquiry_Status__c from Sales_Order__c where id=:SoID];
            for(Sales_Order__c eachSO:SO){
                if(eachSO.Status__c=='Approve Pending'){
                    eachSO.Status__c='Cancelled';
                }
                if(eachSO.Enquiry_Status__c=='Pending for change approval'){
                    eachSO.Enquiry_Status__c='Cancelled';
                }
                update eachSO;
            }
        }
        update RevList;
    }
    
    @AuraEnabled
    public static CareLabelOrder.MainWrapper getWrapperData(String retailerCode, String productname,string customerid,boolean fullboxQty,String boxquantity)    
    {
        //MainWrapper wrpadatas = new MainWrapper();
        //system.debug(CareLabelOrder.getWrapperData(retailerCode,productname,customerid,fullboxQty,boxquantity));
        CareLabelOrder.MainWrapper wrpadatas;
        if(retailerCode !=null && productname !=null && customerid !=null){
            wrpadatas = CareLabelOrder.getWrapperDataForViewCart(retailerCode,productname,customerid,fullboxQty,boxquantity);
            system.debug('wrpadatas:::::::'+wrpadatas);
        }
        return wrpadatas;
    }
    
    @AuraEnabled
    public static void saveCareLabelData(String careLabelSelectedDataList, String productId,String retailerId,String completeWrap,string customeid,string addTo,string selectedCurrency,String searchedCurrency)    
    {
        system.debug('careLabelSelectedDataList'+careLabelSelectedDataList+' '+'productId'+' '+'retailerId'+retailerId+' '+'completeWrap'+completeWrap+' '+'customeid'+customeid+' '+'addTo'+addTo+' '+'selectedCurrency'+selectedCurrency+' '+'searchedCurrency'+searchedCurrency);
        CareLabelOrder.saveCareLabelData(careLabelSelectedDataList,productId,retailerId,completeWrap,customeid, addTo,selectedCurrency,searchedCurrency);
    }
    @AuraEnabled
    public static void saveAsCareLabelData(String careLabelSelectedDataList, String productId,String retailerId,String completeWrap,string customeid,string addTo,string selectedCurrency,String searchedCurrency)    
    {
        system.debug('careLabelSelectedDataList'+careLabelSelectedDataList+' '+'productId'+' '+'retailerId'+retailerId+' '+'completeWrap'+completeWrap+' '+'customeid'+customeid+' '+'addTo'+addTo+' '+'selectedCurrency'+selectedCurrency+' '+'searchedCurrency'+searchedCurrency);
        CareLabelOrder.saveAsCareLabelData(careLabelSelectedDataList,productId,retailerId,completeWrap,customeid, addTo,selectedCurrency,searchedCurrency);
    }
    @AuraEnabled
    public static List<CareLabelOrder.CareLabelSelectedData> fetchCareLabelData(String retailerId,string customeid)    
    {
        return CareLabelOrder.fetchCareLabelData(retailerId,customeid);
    }
    @AuraEnabled
    public static void deletedCLLI(List<String> deletedCLLIList)    
    {
        CareLabelOrder.deletedCLLI(deletedCLLIList);
    }
}