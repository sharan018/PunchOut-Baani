public class PunchOutRequestController {
    
    public Static Id CartRecordType = Schema.SObjectType.Base_Order__c.getRecordTypeInfosByName().get('Cart').getRecordTypeId();
    public Static Id OrderRecordType = Schema.SObjectType.Base_Order__c.getRecordTypeInfosByName().get('Order').getRecordTypeId();
    
     @AuraEnabled
    public static Base_Order__c checkRetailerInSO(String customerid)
    {
        Id punchoutId = PunchOutRequestController.getPunchoutRequestId();
        Base_Order__c cartSO=PunchOutRequestController.getSORecordAsCart(punchoutId);
        system.debug('cartSO'+cartSO);
        if(cartSO.Id != null)
        {
            return cartSO;
            
        }
        else
            return null;
    }
    
      @AuraEnabled
    public static Base_Order__c getSORecordAsCart(Id punchoutId)
    {
        List<Base_Order__c> cartSo = [select id,name, CurrencyIsoCode, OrderSource__c, Retailer_Code1__c,Retailer_Code1__r.Name,Retailer_Code1__r.Market_Segment__c, Vertical__c, Company__c,Supplier__r.Name,Supplier_Contact__c,Supplier_Contact__r.Name,Supplier_Contact__r.Email from Base_Order__c where PunchOut_Request__c  =: punchoutId AND recordtype.name='Cart' limit 1];
        if(cartSo.size()==1)
        {
            return cartSo[0];
        }
        else
        {
            Base_Order__c emptySO = new Base_Order__c();
            return emptySO;
        }
    }
    
      @AuraEnabled
    public static Id putPunchoutRequestId(Id rqtId){
        String partitionInput = 'PunchOut';
        Cache.SessionPartition  sessionPartition = Cache.Session.getPartition(partitionInput);
        
        sessionPartition.put('PunchOutId', rqtId);
        Id punchOutRefId= (Id)sessionPartition.get('PunchOutId');
        System.debug('punchOutRefId><>'+punchOutRefId); 
         //String currentUrl = Url.getCurrentRequestUrl().toExternalForm();
       String sessionId = UserInfo.getSessionId();
        

        return punchOutRefId;
    }
    @AuraEnabled
    public static Id getPunchoutRequestId(){
        String partitionInput = 'PunchOut';
        Cache.SessionPartition  sessionPartition = Cache.Session.getPartition(partitionInput);
        Id punchOutRefId= (Id)sessionPartition.get('PunchOutId');
        System.debug('punchOutRefId><>'+punchOutRefId); 
        return punchOutRefId;
    }
    
    
   @AuraEnabled
    public static contact FetchCustData()
    {
        contact contactid=UtilityClass.getCurrentUserContact();
        system.debug('contactid'+contactid);
        return contactid;  
    }
    
       @AuraEnabled
       public static Integer getLeadTime(string punchoutID)
    {
        Integer leadTime;
        Expected_ExFactory_Date__c leadDate=[SELECT LeadTime__c FROM Expected_ExFactory_Date__c	];
        System.debug('leadTime --> '+(Integer)leadDate.LeadTime__c);
        
        return leadTime=(Integer)leadDate.LeadTime__c;
    }
    
 //save the cart value by creating MG and MGLI with "CART" record type
    @AuraEnabled
    public static string saveCart(id customerData,id retailercode, string quantity,id priceBookProId,id priceByCurr,string custRefModel,string selectedCurrency,String searchedCurrency)
    {
        Id panoutId = PunchOutRequestController.getPunchoutRequestId();
        system.debug('customerData==='+customerData);
        system.debug('retailerData==='+retailercode);
        system.debug('priceBookProId==='+priceBookProId);
        system.debug('quantity==='+quantity);
        system.debug('priceByCurr==='+priceByCurr);
        system.debug('custRefModel==='+custRefModel);
        system.debug('selectedCurrency==='+selectedCurrency);
        system.debug('searchedCurrency==='+searchedCurrency);
       // List<Base_Order__c> BaseList=[Select Id,PunchOut_Request__c From Base_Order__c Where PunchOut_Request__c=:panoutId ];
        
        List<Retailer_Related_Data__c> ContRetailer = new List<Retailer_Related_Data__c>();
        ContRetailer = [select id,Name,Supplier_Code__c,Customer_Information__c,Retailer_Code__c, Manufacturer_Factory_Code__c from Retailer_Related_Data__c where Customer_Information__c =: customerData AND Retailer_Code__c =: retailercode AND Status__c='Active'];
        system.debug('ContRetailer::'+ContRetailer);
        
        Price_Specification_Book_Product__c prodData =new Price_Specification_Book_Product__c();
        Price_Product_by_Currency__c priceproductbycurrency;
        
        prodData =[select id,Product_Unique_ID__c,Product_Unique_ID__r.name,CurrencyIsoCode,Product_Unique_ID__r.Business_Vertical__c, Local_SKU__c,Color__c,Retailer_Code__c,Retailer_Code__r.Full_Box_Order__c,BOX_QTY__c,Description__c,Price_100pcs__c,Price_1000pcs__c,Product_image_url__c,Product_Size__c,Order_to_Company__c,Print_Shop__c,Product_Family__c,Customer_Ref_Model__c ,EUR_Rebate_pc__c,EUR_Reuse_Rebate_pc__c,USD_Rebate_pc__c,USD_Reuse_Rebate_pc__c,Sizer_Print__c,Variable_Data_Product__c from Price_Specification_Book_Product__c where id =:priceBookProId];
        system.debug('prodData>>>>'+prodData);
        if(priceByCurr!=null)
        {  
            priceproductbycurrency = [select id,Name,CurrencyIsoCode,Price_Book_Product__c,Local_ERP_customer_code__c,Price_100_pcs__c from Price_Product_by_Currency__c where id =:priceByCurr];
            system.debug('priceproductbycurrency>>>>'+priceproductbycurrency);
        }
        
        //Ma List<Sales_Order__c> SOList=new List<Sales_Order__c>();
        //Ma List<Sales_Order_Line_Items__c> SoliList=new List<Sales_Order_Line_Items__c>();
        List<Base_Order__c> SOList=new List<Base_Order__c>();
        List<Base_Order_Detail__c> SoliList=new List<Base_Order_Detail__c>();
        //Ma SOList =[select id, name, Retailer_Code1__c,Retailer__c,Product__r.Business_Vertical__c,Status__c,CurrencyIsoCode,Supplier_Code__c,Enquiry_Status__c,Link_To_ERP__c from Sales_Order__c where Supplier__c =:customerData AND recordtypeId =:CartRecordType ];
        
            SOList =[select id, name, Retailer_Code1__c,Product__r.Business_Vertical__c,CurrencyIsoCode,Supplier_Code__c,PunchOut_Request__c from Base_Order__c where Supplier__c =:customerData AND recordtypeId =:CartRecordType AND PunchOut_Request__c=:panoutId  ];

        system.debug('SOList>>'+SOList);
        system.debug('SOList.size>>'+SOList.size());
        
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
        system.debug('prodData.CurrencyIsoCode>>>'+prodData.CurrencyIsoCode); 
        /* if(searchedCurrency!=selectedCurrency)
{
prodData.CurrencyIsoCode=searchedCurrency.split('-')[0];
}else if(selectedCurrency!=null && priceByCurr==null)
{
prodData.CurrencyIsoCode=selectedCurrency.split('-')[0];
}
else{
prodData.CurrencyIsoCode=con.Preferred_Currency__c.split('-')[0];
}*/
        system.debug('prodData.CurrencyIsoCode>>>'+prodData.CurrencyIsoCode);
        if(SOList.size()==0)                                    // if no data on the respective customer then insert the new SO and SOLI
        {
            system.debug('insideIf');
            Base_Order__c So=new Base_Order__c();
            So.Supplier__c = customerData;
            So.Supplier_Contact__c = loggedInContact.Id;
            So.PunchOut_Request__c=panoutId;
             So.RecordtypeId = CartRecordType;
            So.Retailer_Code1__c = retailercode;
            So.PunchOut_Status__c = 'Product Added';
            So.Processing_Status__c = 'Failed';
            //Ma  So.OrderSource__c = 'Catalog Order';
            So.SupplierParty_CNUF__c = 'SupplierParty';
            So.CustomerParty_Name__c = 'CustomerParty';
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
           // So.OwnerId =config.SalesOrder_OwnerId__c; 
            system.debug('Solist>>>>'+So);
            insert So;
            
            
            system.debug('So>>>>'+So);
            Base_Order_Detail__c soli=new Base_Order_Detail__c();
            soli.Base_Order__c=So.id;
            soli.Products__c = prodData.Product_Unique_ID__c;
            soli.Product_Description__c = prodData.Description__c;
            soli.Size__c = prodData.Product_Size__c;
            soli.print__c = prodData.Sizer_Print__c;
            soli.Colour__c = prodData.Color__c;
            soli.Local_SKU__c = prodData.Local_SKU__c;
            soli.variable_data_product__c=prodData.Variable_Data_Product__c;
            soli.Quantity__c = Integer.valueOf(quantity);
            soli.Ordered_Quantity__c = Integer.valueOf(quantity);
            soli.Supply_Quantity__c = quantity;
            soli.Supply_Quantity_num__c = Integer.valueOf(quantity);
            soli.Remaining_Qty__c = Integer.valueOf(quantity);
            soli.Full_Box_Order__c =prodData.Retailer_Code__r.Full_Box_Order__c;
            soli.BOX_QTY__c =prodData.BOX_QTY__c;
            soli.Product_image_url__c=prodData.Product_image_url__c;
            soli.Price_Specification_Book_Product__c = prodData.Id;
            soli.Model_Id__c = prodData.Product_Unique_ID__r.name;
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
            /* Soli.EUR_Rebate_pc__c = prodData.EUR_Rebate_pc__c;
Soli.EUR_Reuse_Rebate_pc__c = prodData.EUR_Reuse_Rebate_pc__c;
Soli.USD_Rebate_pc__c = prodData.USD_Rebate_pc__c;
Soli.USD_Reuse_Rebate_pc__c = prodData.USD_Reuse_Rebate_pc__c;*/
Soli.Status__c = 'Order Submitted';
Soli.Production_Status__c='';
Soli.Online_Detail_Status__c ='';
soli.Customer_Ref_Model__c = prodData.Customer_Ref_Model__c;            
            soli.CurrencyIsoCode = So.CurrencyIsoCode;
            insert soli;
            system.debug('soli>>>>'+soli);
            
        }
        else                                                    // insert only SOLI
        {
            //SoliList =[select id, name,Sales_Order__c,Products__c,Local_SKU__c,Colour__c,Quantity__c,Product_image_url__c,Full_Box_Order__c,BOX_QTY__c,Price_Product_by_Currency__c,Customer_Ref_Model__c,Ordered_Quantity__c,Supply_Quantity__c,Supply_Quantity_num__c from Sales_Order_Line_Items__c where Sales_Order__c=:SOList[0].id AND Colour__c=:prodData.Color__c AND Products__c=:prodData.Product_Unique_ID__c];
            //Mahadevaprasad  SoliList =[select id, name,Sales_Order__c,Products__c,Local_SKU__c,Colour__c,Quantity__c,Product_image_url__c,Full_Box_Order__c,BOX_QTY__c,Price_Product_by_Currency__c,Customer_Ref_Model__c,Ordered_Quantity__c,Supply_Quantity__c,Supply_Quantity_num__c,Production_Status__c,Online_Detail_Status__c from Sales_Order_Line_Items__c where Sales_Order__c=:SOList[0].id AND Colour__c=:prodData.Color__c AND Price_Specification_Book_Product__c=:prodData.Id];
            SoliList =[select id, name,Base_Order__c,Products__c,Local_SKU__c,Colour__c,Quantity__c,Product_image_url__c,Full_Box_Order__c,BOX_QTY__c,Price_Product_by_Currency__c,Customer_Ref_Model__c,Ordered_Quantity__c,Supply_Quantity__c,Supply_Quantity_num__c,Production_Status__c,Online_Detail_Status__c from Base_Order_Detail__c where Base_Order__c=:SOList[0].id AND Colour__c=:prodData.Color__c AND Price_Specification_Book_Product__c=:prodData.Id];
            
            // system.debug('SoliList>>>>'+SoliList);
            //system.debug('SoliList.size>>'+SoliList.size());
            if(SoliList.size()==0)                                  // if no data on the respective SKU and color then insert the SO and SOLI
            {
                system.debug('SoliList in if>>'+SoliList);
                //Mahadevaprasad Sales_Order_Line_Items__c soli=new Sales_Order_Line_Items__c();
                Base_Order_Detail__c soli=new Base_Order_Detail__c();
                soli.Base_Order__c=SOList[0].id;
                soli.Products__c = prodData.Product_Unique_ID__c;
                soli.Product_Description__c = prodData.Description__c;
                soli.Size__c = prodData.Product_Size__c;
                soli.print__c = prodData.Sizer_Print__c;
                soli.Colour__c = prodData.Color__c;
                soli.Local_SKU__c = prodData.Local_SKU__c;
                soli.variable_data_product__c=prodData.Variable_Data_Product__c;
                soli.Quantity__c = Integer.valueOf(quantity);                           
                soli.Ordered_Quantity__c = Integer.valueOf(quantity);
                soli.Supply_Quantity__c = quantity;
                soli.Supply_Quantity_num__c = Integer.valueOf(quantity);
                soli.Remaining_Qty__c = Integer.valueOf(quantity);
                soli.Full_Box_Order__c =prodData.Retailer_Code__r.Full_Box_Order__c;
                soli.BOX_QTY__c =prodData.BOX_QTY__c;
                soli.Product_image_url__c=prodData.Product_image_url__c;
                soli.Price_Specification_Book_Product__c = prodData.Id;
                soli.Model_Id__c = prodData.Product_Unique_ID__r.name;
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
                
                
                Base_Order__c So=new Base_Order__c();
                So.Id = SOList[0].id;
                So.PunchOut_Status__c = 'Product Added';
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
                    SoliList[0].Quantity__c = Integer.valueOf(convertedqty + (Integer.valueOf(quantity))); 
                    
                    integer convertedqty1 = integer.ValueOf(SoliList[0].Ordered_Quantity__c);
                    SoliList[0].Ordered_Quantity__c = convertedqty1 +(integer.ValueOf(quantity)); 
                    
                    integer convertedqty2 = integer.ValueOf(SoliList[0].Supply_Quantity__c);
                    SoliList[0].Supply_Quantity__c = String.valueOf(convertedqty2 + (integer.ValueOf(quantity))); 
                    
                    integer convertedqty3 = integer.ValueOf(SoliList[0].Supply_Quantity_num__c);
                    SoliList[0].Supply_Quantity_num__c = convertedqty3 + (integer.ValueOf(quantity)); // need to add price,url,retailer code 
                }
                else{
                    system.debug('inside else');
                    SoliList[0].Quantity__c = Integer.valueOf(quantity);
                    SoliList[0].Ordered_Quantity__c = Integer.valueOf(quantity);
                    SoliList[0].Supply_Quantity__c = quantity;
                    SoliList[0].Supply_Quantity_num__c = Integer.valueOf(quantity);
                }
                SoliList[0].Remaining_Qty__c = SoliList[0].Supply_Quantity_num__c;
                system.debug('SoliList[0]>>'+SoliList[0]);
                upsert SoliList[0];
            }
            
        }
        
        return 'AddedTO cart';
    }
    
    
      @AuraEnabled
    public static List<SOLIWrapper>  getAllCartDetails(id punchoutID)
    {
        
         punchoutID = PunchOutRequestController.getPunchoutRequestId();
        System.debug('punchoutID --> '+punchoutID);
        // String partitionInput = 'PunchOut';
        
       // Cache.SessionPartition  sessionPartition = Cache.Session.getPartition(partitionInput);
        
       // Id punchOutRefId= (Id)sessionPartition.get('PunchOutId');
       // System.debug('punchOutRefId><>'+punchOutRefId);
        //Mahadevaprasad List<Sales_Order__c> SOList=new List<Sales_Order__c>();
        //Mahadevaprasad List<Sales_Order_Line_Items__c> SOliList=new List<Sales_Order_Line_Items__c>();
        List<Base_Order__c> SOList=new List<Base_Order__c>();
        List<Base_Order_Detail__c> SOliList=new List<Base_Order_Detail__c>();
        List<SOLIWrapper> prodwrapList = new List<SOLIWrapper>();
        
        system.debug('customerid>>'+punchoutID);
        system.debug('CartRecordType>>'+CartRecordType);
        
        //Mahadevaprasad SOList =[select id, name, Retailer_Code1__c,Retailer_Code1__r.name,Retailer_Code1__r.Show_Price_in_Order__c,Retailer__c,Product__r.Business_Vertical__c from Sales_Order__c where Supplier__c =: customerid AND RecordTypeId =: CartRecordType];
        SOList =[select id, name, Retailer_Code1__c,Retailer_Code1__r.name,Retailer_Code1__r.Show_Price_in_Order__c,Product__r.Business_Vertical__c from Base_Order__c where PunchOut_Request__r.Id=:punchoutID ];
        Decimal TotalCartprice = 0.0;
        System.debug('SOList.size()>>'+SOList.size());
        
        set<id> baseIds=new set<id>();
        for(Base_Order__c b:SOList){
            baseIds.add(b.Id);
        }
        if(SOList.size()>0)  
        {
            //Mahadevaprasad SOliList =[select id,Supply_Quantity__c,Price_100_pcs__c,name,Sales_Order__c,Products__c,Print__c,Products__r.Name,Sales_Order__r.RecordType.Name,Quantity__c,Size__c,Colour__c,Local_SKU__c,Product_Description__c,Product_image_url__c,Sales_Order__r.Retailer_Code1__r.name,Sales_Order__r.Retailer_Code1__r.Show_Price_in_Order__c,Sales_Order__r.Retailer_Code1__r.Remarks__c,Full_Box_Order__c,BOX_QTY__c,Price_Specification_Book_Product__c,Price_Specification_Book_Product__r.Name,Price_Specification_Book_Product__r.Id, Price_Specification_Book_Product__r.MOQ__c,Products__r.Id,Price_Specification_Book_Product__r.UOM_Price__c, Products__r.Sub_category__c,Remarks__c,CurrencyIsoCode,Price_Product_by_Currency__r.MagNET_Price_Code__c,Price_Product_by_Currency__r.UOM_Price__c,Order_UOM__c,variable_data_product__c from Sales_Order_Line_Items__c where Sales_Order__r.RecordTypeID =: CartRecordType AND Sales_Order__c =:SOList[0].id  AND Added_As_a_Label__c=false];//  AND Added_As_a_Label__c=false Added by seema .
            SOliList =[select id,Base_Order__r.PunchOut_Status__c,Price_Product_by_Currency__r.Price_100_pcs__c,Price_Specification_Book_Product__r.Product_Unique_ID__r.Status__c,Supply_Quantity__c,Price_100_pcs__c,name,Base_Order__c,Products__c,Print__c,Products__r.Name,Base_Order__r.RecordType.Name,Quantity__c,Size__c,Colour__c,Local_SKU__c,Product_Description__c,Product_image_url__c,Base_Order__r.Retailer_Code1__r.name,Base_Order__r.Retailer_Code1__r.Show_Price_in_Order__c,Base_Order__r.Retailer_Code1__r.Remarks__c,Full_Box_Order__c,BOX_QTY__c,Price_Specification_Book_Product__c,Price_Specification_Book_Product__r.Name,Price_Specification_Book_Product__r.Id, Price_Specification_Book_Product__r.MOQ__c,Products__r.Id,Price_Specification_Book_Product__r.UOM_Price__c, Products__r.Sub_category__c,Remarks__c,CurrencyIsoCode,Price_Product_by_Currency__r.MagNET_Price_Code__c,Price_Product_by_Currency__r.UOM_Price__c,Order_UOM__c,variable_data_product__c from Base_Order_Detail__c where Base_Order__c IN:baseIds  AND Added_As_a_Label__c=false];//  AND Added_As_a_Label__c=false Added by seema .
            system.debug(' SOliList>>'+ SOliList);
            for(Base_Order_Detail__c SOLI:SOliList)
            {
                SOLIWrapper productobj = new SOLIWrapper();
                productobj.id = SOLI.id;
                productobj.SOid = SOLI.Base_Order__c;
                productobj.Name=SOLI.Products__r.Name;
                productobj.Quantity=String.valueOf(SOLI.Quantity__c);
                productobj.Color=SOLI.Colour__c;
                productobj.LocalSKU=SOLI.Local_SKU__c;
                productobj.fullboxQty=SOLI.Full_Box_Order__c;
                productobj.boxquantity=SOLI.BOX_QTY__c;
                productobj.Description=SOLI.Product_Description__c;
                productobj.Productimage=SOLI.Product_image_url__c;
                productobj.Remarks=SOLI.Remarks__c;
                productobj.retailerName = SOLI.Base_Order__r.Retailer_Code1__r.name;
                productobj.showremarks = SOLI.Base_Order__r.Retailer_Code1__r.Remarks__c;
                productobj.PSBP = SOLI.Price_Specification_Book_Product__r.Name;
                productobj.ProductId = SOLI.Products__r.Id;
                productobj.MOQ = SOLI.Price_Specification_Book_Product__r.MOQ__c; 
                productobj.orderUom = SOLI.Order_UOM__c;
                productobj.ShowPriceInOrder = SOLI.Base_Order__r.Retailer_Code1__r.Show_Price_in_Order__c;
                productobj.variableDataProduct = SOLI.variable_data_product__c;
                productobj.Status =  SOLI.Price_Specification_Book_Product__r.Product_Unique_ID__r.Status__c;
                if(SOLI.Base_Order__r.PunchOut_Status__c=='Product Added'){
                productobj.punchOutStatus=true;
                }else{
                     productobj.punchOutStatus=false;

                }
                if(String.ValueOf(SOLI.Price_Product_by_Currency__r.Price_100_pcs__c)!=SOLI.Price_100_pcs__c){
               productobj.priceChanged=true;
}
                //Price_Specification_Book_Product__r.Product_Unique_ID__r.Status__c
                // Decimal.ValueOf(str)
                //  system.debug(' SOLI.Price_Specification_Book_Product__r.UOM_Price__c :::'+ SOLI.Price_Specification_Book_Product__r.UOM_Price__c);
                // system.debug(' SOLI.Quantity__c :::'+ SOLI.Quantity__c);
                //system.debug(' SOLI.Id :::'+ SOLI.Id);
                //system.debug(' SOLI.Id :::'+ SOLI.Products__r.Name);
                
                //If the user is perticular user then perticular price is set added By raghu starts
                system.debug(' SOLI.Price_Product_by_Currency__r.MagNET_Price_Code__c :::'+ SOLI.Price_Product_by_Currency__r.MagNET_Price_Code__c);
                if(SOLI.Price_Product_by_Currency__r.MagNET_Price_Code__c != null){
                    // system.debug(' SOLI.Supply_Quantity__c>>'+ SOLI.Supply_Quantity__c);
                    //system.debug(' SOLI.Price_100_pcs__c>>'+ SOLI.Price_100_pcs__c);
                    //system.debug('SOLI.COLOUR>>'+SOLI.Colour__c);
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
                //if(SOLI.Products__r.Sub_category__c == 'STICKER' || SOLI.Products__r.Sub_category__c == 'SIZER')			// added by chandana on 03/26/2020
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
            system.debug(' prodwrapList123 :::'+ prodwrapList);
            return prodwrapList;
            
        }
        else 
        {
            return null;
        }
    }

    
         public static void GetPriceValue(string punchOutRqt) {
    Boolean priceValue=false;
        
   List<Base_Order_Detail__c>  BaseLine =[select id,Base_Order__c,Base_Order__r.PunchOut_Request__c,Price_Product_by_Currency__r.Price_100_pcs__c,Price_100_pcs__c from Base_Order_Detail__c where Base_Order__r.PunchOut_Request__c=:punchOutRqt  AND Added_As_a_Label__c=false];
       set<id> baseIds=new set<id>();
       set<id> samePriceIds=new set<id>();
         for(Base_Order_Detail__c b:BaseLine){
            System.debug(String.ValueOf(b.Price_Product_by_Currency__r.Price_100_pcs__c)+'   '+b.Price_100_pcs__c);
            if(String.ValueOf(b.Price_Product_by_Currency__r.Price_100_pcs__c)!=b.Price_100_pcs__c){
               baseIds.add(b.Id);
            }else if(String.ValueOf(b.Price_Product_by_Currency__r.Price_100_pcs__c) == b.Price_100_pcs__c){
                samePriceIds.add(b.Id);
            }
        }
         
         
          list<Base_Order__c>   baseList =[select id from Base_Order__c Where Id In:baseIds];
          List<Base_Order_Detail__c>  BaseLinelist =[select id,Base_Order__r.PunchOut_Request__c,Price_Specification_Book_Product__r.Product_Unique_ID__r.Status__c from Base_Order_Detail__c where Id IN:baseIds  AND Added_As_a_Label__c=false ];
          delete BaseLinelist;
             
          List<Base_Order_Detail__c>  BaseLineSamePricelist =[select id,Base_Order__r.PunchOut_Request__c,Price_Specification_Book_Product__r.Product_Unique_ID__r.Status__c from Base_Order_Detail__c where Id IN:baseIds  AND Added_As_a_Label__c=false ];
          if(BaseLineSamePricelist.Size() == 0){
              delete baseList;
          }
         
  
    }
    //delete the inactive product from list
     @AuraEnabled
       public static void  deleteInactiveModel(Id punchoutID)
    {
        punchoutID = PunchOutRequestController.getPunchoutRequestId();
        PunchOutRequestController.GetPriceValue(punchoutID);
        set<id> baseLineIds=new set<id>();
        
         List<Base_Order_Detail__c>  BaseLine =[select id,Base_Order__r.PunchOut_Request__c,Price_Specification_Book_Product__r.Product_Unique_ID__r.Status__c from Base_Order_Detail__c where Base_Order__r.PunchOut_Request__c=:punchoutID  AND Added_As_a_Label__c=false AND Price_Specification_Book_Product__r.Product_Unique_ID__r.Status__c='Inactive'];
        for(Base_Order_Detail__c b:BaseLine){
            
            baseLineIds.add(b.Base_Order__c);
        }
         List<Base_Order_Detail__c>  BaseActiveLine =[select id,Base_Order__r.PunchOut_Request__c,Price_Specification_Book_Product__r.Product_Unique_ID__r.Status__c from Base_Order_Detail__c where Base_Order__r.PunchOut_Request__c=:punchoutID  AND Added_As_a_Label__c=false AND Price_Specification_Book_Product__r.Product_Unique_ID__r.Status__c='Active'];
        if(BaseActiveLine.Size() == 0){
         list<Base_Order__c>   baseList =[select id from Base_Order__c Where Id In:baseLineIds];
            delete baseList;
        }
        delete BaseLine;
         
    }
    
    
      @AuraEnabled
    public static string SaveBaseOrder(list<PunchOut_Request__c> punchoutShipTO)
    {
        string operation=punchoutShipTO[0].Operation__c;
        string punchOutRqt=punchoutShipTO[0].Id;
        System.debug('punchOutRqt><>>'+punchOutRqt);
//string cxmlValue=PunchOutCXMLgenerate.generateCXML(punchOutRqt);        
        list<Base_Order__c> basePunchOutList=[select Id,PunchOut_Request__c,CustomerParty_ShipTo_Address1__c,CustomerParty_ShipTo_CityName__c,CustomerParty_ShipTo_Postal_Code__c,CustomerParty_ShipTo_Country__c,CustomerParty_ShipTo_Address2__c,CustomerParty_ShipTo_State__c from Base_Order__c where PunchOut_Request__c=:punchOutRqt ];
          
            if(basePunchOutList.size()>0){
                for(Base_Order__c b:basePunchOutList){
                    b.CustomerParty_ShipTo_Address1__c=punchoutShipTO[0].Address_Name__c;
                    b.CustomerParty_ShipTo_Address2__c=punchoutShipTO[0].Street__c; 
                    b.CustomerParty_ShipTo_CityName__c=punchoutShipTO[0].City__c;
                    b.CustomerParty_ShipTo_State__c=punchoutShipTO[0].State__c;
                    b.CustomerParty_ShipTo_Country__c=punchoutShipTO[0].Country__c;
                     b.CustomerParty_ShipTo_Postal_Code__c=punchoutShipTO[0].PostalCode__c;
                    b.PunchOut_Status__c='Punched Out';
                }  
                update basePunchOutList;
            }
        return 'cxmlValue';
    }
    
    
     @AuraEnabled
    public static addressWrapper FetchCustAddForCatalogOrder(String custInfoid,String retailer, String retailercodeId, String orderSource)
    {
        Id  punchoutID = PunchOutRequestController.getPunchoutRequestId();
        system.debug('punchoutID>>>>'+punchoutID);
        Map<String, List<String>> CompanyAndItsShippingTerms = new Map<String, List<String>>();
        Online_Enquiry__c oe = new Online_Enquiry__c();
        CompanyAndItsShippingTerms = RegistrationService.getDependentMap(oe,'Order_Country__c','Delivery_Instruction__c');
        Contact con = UtilityClass.getCurrentUserContact();
        String CompName;
        String currencyName;
        boolean iscloned = false;
       //Ma Sales_Order__c cartSO = new Sales_Order__c();
        Base_order__c cartSO = new Base_order__c();
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
             cartSO = PunchOutRequestController.getSORecordAsBaseCart(custInfoid);
            //cartSO = UtilityClass.getSORecordAsCart(custInfoid);
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
        List<PunchOut_Request__c> billRqt = new List<PunchOut_Request__c>();
        //fetching address realted to customer and grouping them by their record types
        List<Ship_Bill_Address__c> custAddress= [select id,name,recordtype.name,Is_Default__c,Company_Name__c,Address_1__c,City__c,State__c,Country__c,Postcode__c,Factory_Name__c,Contact__c,Tel_No__c,Email_Address__c, Fax_No__c from Ship_Bill_Address__c where Customer_Information__c =: custInfoid AND Bill_Ship_Status__c=:'Active'];
         billRqt=[select Id,payloadID__c,Operation__c,Street__c,City__c,State__c,PostalCode__c,Country__c,Address_Name__c From PunchOut_Request__c Where Id=:punchoutID];
        system.debug('billRqt>>>>'+billRqt);
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
        addwrap.billAddListRqt=billRqt;
        
        
        if(CompanyAndItsShippingTerms.containskey(CompName))
        {
            addWrap.shipTermList = CompanyAndItsShippingTerms.get(CompName);
        }
        //addWrap.SuzhouFlag = con.Order_to_Company__c.contains('Suzhou');
        
        addWrap.SuzhouFlag = CompName.contains('Suzhou');
        
        //changes for retailer information section
        //to get division list values
        List<string> listValuesOfDivision = new List<string>();
        listValuesOfDivision = SOController.DependentPicklist(retailer,'Retailer_Code_Hidden__c','Division__c');
        System.debug(' listValuesOfDivision:: '+listValuesOfDivision);
        
         //to get Brand_Label list values
        List<string> listValuesOfBrandLabel = new List<string>();
        listValuesOfBrandLabel = SOController.DependentPicklist(retailer,'Retailer_Code_Hidden__c','Brand_Label__c');
        System.debug(' listValuesOfBrandLabel:: '+listValuesOfBrandLabel);
        
        //to get season list values
        List<string> listValuesOfSeason = new List<string>();
        listValuesOfSeason = SOController.DependentPicklist(retailer,'Retailer_Code_Hidden__c','Season__c');
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
        ContRetailer = [select id,Name,Supplier_Code__c,Retailer_Code__r.Supplier_Code_UnMask__c,Retailer_Code__r.Manufacturer_Code_UnMask__c,Customer_Information__c,Retailer_Code__c,Manufacturer_Factory_Code__c from Retailer_Related_Data__c where Customer_Information__c =: custInfoid AND Retailer_Code__c =: retailercodeId];
        System.debug('ContRetailer>>>>>>'+ContRetailer);
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
        Base_Order__c prototypeSO = new Base_Order__c(); 
        if(iscloned)
        {
            prototypeSO = [Select Id, Name, Expected_Delivery_Date__c, Delivery_Instructions__c, Division__c, Season__c, Season_Year__c, OrderSource__c, Transportation_Details__c, Shipping_Mark__c, Bill_to_Address__c, Buyer_Address__c, Invoice_To_Address__c, Ship_to_Address__c from Base_Order__c where Id =: cartSO.Id];
            prototypeSO.Expected_Delivery_Date__c = Date.today();
            system.debug('today\'s date::'+System.today());
            system.debug(' date todate ::'+Date.today());
        }
        system.debug('prototypeSO::'+prototypeSO);
        prototypeSO.Supplier_Code__c=ContRetailer[0].Supplier_Code__c;
        prototypeSO.Manufacturer_Code__c=ContRetailer[0].Manufacturer_Factory_Code__c;
        prototypeSO.Id = cartSO.Id;
        addWrap.protoSO = prototypeSO;
        
        system.debug('addWrap>>>>'+addWrap);
        
        return addWrap;
    }
    
        @AuraEnabled(cacheable=true)
        public static Integer getCartDataCount(Id customerid)
    {
        System.debug('customerid'+customerid);
        Integer count= PunchOutRequestController.getAllCartDetails(customerid).size();
        system.debug('count>>>'+count);
        return count;
    }
    
         @AuraEnabled
    public static Base_Order__c getSORecordAsBaseCart(Id customerInfo)
    {

        List<Base_Order__c> cartSo = [select id,name, CurrencyIsoCode, OrderSource__c, Retailer_Code1__c,Retailer_Code1__r.Name,Retailer_Code1__r.Market_Segment__c, Vertical__c, Company__c,Supplier__r.Name,Supplier_Contact__c,Supplier_Contact__r.Name,Supplier_Contact__r.Email from Base_Order__c where Supplier__c  =: customerInfo AND recordtype.name='Cart' limit 1];
        //ma List<Sales_Order__c> cartSo = [select id,name, CurrencyIsoCode, OrderSource__c, Retailer__r.name, Retailer_Code1__c,Retailer_Code1__r.Name,Retailer_Code1__r.Market_Segment__c, Vertical__c, Company__c,Supplier__r.Name,Supplier_Contact__c,Supplier_Contact__r.Name,Supplier_Contact__r.Email,Sales_Order_Number_For_Report__c,Retailer_Code2__c,Supplier1__c from Sales_Order__c where Supplier__c  =: customerInfo AND recordtype.name='Cart' limit 1];
        if(cartSo.size()==1)
        {
            return cartSo[0];
        }
        else
        {
            //ma Sales_Order__c emptySO = new Sales_Order__c();
            Base_Order__c emptySO = new Base_Order__c();
            
            return emptySO;
        }
    }
    
    
      // Delete product from the cart
    @AuraEnabled
    public static list<SOLIWrapper>  deleteProductFromCart(string soliId, string soId)
    {
        system.debug('soliId>>'+ soliId);
        system.debug('soId>>'+ soId);
        //Ma Sales_Order_Line_Items__c soliObject = new Sales_Order_Line_Items__c();
        Base_Order_Detail__c soliObject = new Base_Order_Detail__c();
        soliObject.Id = soliId;
        
        delete soliObject;        
        
        //Ma list<Sales_Order_Line_Items__c> remainingrec = [select id,name,Products__c,Products__r.Name,BOX_QTY__c,Size__c,Sales_Order__r.RecordType.Name,Sales_Order__c,Sales_Order__r.Retailer_Code1__c,Quantity__c,Colour__c,Local_SKU__c,Product_Description__c,Product_image_url__c,Price_Specification_Book_Product__r.Name,Full_Box_Order__c,Added_As_a_Label__c,Price_Product_by_Currency__r.MagNET_Price_Code__c,Price_Product_by_Currency__r.UOM_Price__c, Price_Specification_Book_Product__r.MOQ__c,Price_Specification_Book_Product__r.UOM_Price__c,CurrencyIsoCode  from Sales_Order_Line_Items__c where Sales_Order__r.RecordType.Name ='Cart' AND Sales_Order__c=:soId];
        //system.debug('remainingrec>>'+ remainingrec);
        list<Base_Order_Detail__c> remainingrec = [select id,name,Products__c,Products__r.Name,BOX_QTY__c,Size__c,Base_Order__r.RecordType.Name,Base_Order__c,Base_Order__r.Retailer_Code1__c,Quantity__c,Colour__c,Local_SKU__c,Product_Description__c,Product_image_url__c,Price_Specification_Book_Product__r.Name,Full_Box_Order__c,Added_As_a_Label__c,Price_Product_by_Currency__r.MagNET_Price_Code__c,Price_Product_by_Currency__r.UOM_Price__c, Price_Specification_Book_Product__r.MOQ__c,Price_Specification_Book_Product__r.UOM_Price__c,CurrencyIsoCode  from Base_Order_Detail__c where  Base_Order__c=:soId];
        list<SOLIWrapper> prodwrapList = new list<SOLIWrapper>();
        
        if(remainingrec.size()==0)
        {
            //Ma Sales_Order__c SOToDelete = new Sales_Order__c();
            Base_Order__c SOToDelete = new Base_Order__c();
            SOToDelete.id= soId;
            delete SOToDelete;
        }
        //Ma for(Sales_Order_Line_Items__c SOLI:remainingrec)
        for(Base_Order_Detail__c SOLI:remainingrec)
        {
            if(SOLI.Added_As_a_Label__c==false)
            {
                SOLIWrapper productobj = new SOLIWrapper();
                productobj.id = SOLI.id;
                productobj.SOid = SOLI.Base_Order__c;
                productobj.Name=SOLI.Products__r.Name;
                productobj.Quantity=String.valueOf(SOLI.Quantity__c);
                productobj.Color=SOLI.Colour__c;
                productobj.LocalSKU=SOLI.Local_SKU__c;
                productobj.Size=SOLI.Size__c;
                productobj.Description=SOLI.Product_Description__c;
                productobj.Productimage=SOLI.Product_image_url__c;
                productobj.PSBP=SOLI.Price_Specification_Book_Product__r.Name;
                productobj.boxquantity=SOLI.BOX_QTY__c;
                productobj.fullboxQty=SOLI.Full_Box_Order__c; 								//added by chandana for After delete in the cart to check boxqty 
                productobj.MOQ = SOLI.Price_Specification_Book_Product__r.MOQ__c;
                //If the user is perticular user then perticular price is set added By raghu on 15/11/2021 starts
                if(SOLI.Price_Product_by_Currency__r.MagNET_Price_Code__c != null){
                    productobj.TotalPriceByCurrency = (SOLI.Price_Product_by_Currency__r.UOM_Price__c) *  (SOLI.Quantity__c) ;
                }
                else {
                    productobj.TotalPriceByCurrency = (SOLI.Price_Specification_Book_Product__r.UOM_Price__c) * (SOLI.Quantity__c) ; 
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
    public static void ClearCartDetails(string punchoutID)//parameter => string customerId removed by Vidit
    {
        
        punchoutID = PunchOutRequestController.getPunchoutRequestId();
        System.debug('punchoutID><>>'+punchoutID);
        List<Base_Order__c> SOobject=new List<Base_Order__c>();
        Contact CustomerContact = UtilityClass.getCurrentUserContact();	
        
        Id conId = CustomerContact.Id;
        if(punchoutID != null){
        SOobject =[select id, name, Retailer_Code1__c,Product__r.Business_Vertical__c,PunchOut_Request__r.Id from Base_Order__c where  PunchOut_Request__r.Id=:punchoutID];
        System.debug('SOobject><>>'+SOobject);
        if(SOobject != null)
            delete SOobject;
        }
        
    }
    
    
    @AuraEnabled
    public static List<Base_Order_Detail__c> getSizerList(String  retailercode,String customerid, String prodName)
    {
        Id panchoutId = PunchOutRequestController.getPunchoutRequestId();
        String punchout = String.valueOf(panchoutId);
        system.debug('retailercode>>>'+retailercode);
        system.debug('panchoutId>>>'+punchout);
        return [select id,name,Colour__c,Quantity__c,Size__c,Print__c,Base_Order__r.PunchOut_Request__c,Base_Order__c,Price_Specification_Book_Product__r.id,Customer_Ref_Model__c,Mainetti_Model_Code__c,Added_As_a_Label__c,BOX_QTY__c,Full_Box_Order__c,Business_Vertical__c from Base_Order_Detail__c where Base_Order__r.Retailer_Code1__c=:retailerCode AND Base_Order__r.Supplier__c=:customerid and Added_As_a_Label__c=true AND Base_Order__r.PunchOut_Request__c =: punchout];//And Products__r.Mainetti_Model__c=:prodName
    }
    
     @AuraEnabled
    public static string addSizerToCart(String retailercode,String customerid)
    {
        String prodName = '';
        List<Base_Order_Detail__c> sizrList=PunchOutRequestController.getSizerList(retailercode,customerid,prodName);
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
    public static addressWrapper  getAllOldShipTO()
    {
        Id punchoutID = PunchOutRequestController.getPunchoutRequestId();
        System.debug('punchoutID>>>>'+punchoutID);
        boolean shipToChanged=false;
        addressWrapper addWrap = new addressWrapper();
        List<PunchOut_Request__c> billRqt = new List<PunchOut_Request__c>();
        
        billRqt=[select Id,payloadID__c,Operation__c,Street__c,City__c,State__c,PostalCode__c,Country__c,Address_Name__c From PunchOut_Request__c Where Id=:punchoutID];
        list<Base_Order__c> basePunchOutList=[select Id,PunchOut_Request__c,CustomerParty_ShipTo_Address1__c,CustomerParty_ShipTo_CityName__c,CustomerParty_ShipTo_Postal_Code__c,CustomerParty_ShipTo_Country__c,CustomerParty_ShipTo_Address2__c,CustomerParty_ShipTo_State__c from Base_Order__c where PunchOut_Request__c=:punchoutID And PunchOut_Status__c='Punched Out'];
         System.debug('basePunchOutList>>>>'+basePunchOutList);
        System.debug('billRqt>>>>'+billRqt);
        if(basePunchOutList.size()>0){
        if((basePunchOutList[0].CustomerParty_ShipTo_Address1__c)!=(billRqt[0].Address_Name__c)){
            shipToChanged=true;
        }else if((basePunchOutList[0].CustomerParty_ShipTo_Address2__c)!=(billRqt[0].Street__c)){
            shipToChanged=true ; 
            
        }else if((basePunchOutList[0].CustomerParty_ShipTo_CityName__c)!=(billRqt[0].City__c)){
            shipToChanged=true;  
        }
        else if((basePunchOutList[0].CustomerParty_ShipTo_State__c)!=(billRqt[0].State__c)){
            shipToChanged=true ; 
        }
        else if((basePunchOutList[0].CustomerParty_ShipTo_Postal_Code__c)!=(billRqt[0].PostalCode__c)){
            shipToChanged=true;  
        }
        else if((basePunchOutList[0].CustomerParty_ShipTo_Country__c)!=(billRqt[0].Country__c)){
            shipToChanged=true;  
        }
        }else{
            
        }
        System.debug('shipToChanged>>>>'+shipToChanged);
        
        if(shipToChanged){
            
            List<PunchOut_Request__c> billRqtOld=new   List<PunchOut_Request__c>(); 
            PunchOut_Request__c bill=new PunchOut_Request__c();
            
            bill.Address_Name__c=  basePunchOutList[0].CustomerParty_ShipTo_Address1__c;
            bill.Street__c=basePunchOutList[0].CustomerParty_ShipTo_Address2__c;
            bill.City__c=basePunchOutList[0].CustomerParty_ShipTo_CityName__c;
            bill.State__c=basePunchOutList[0].CustomerParty_ShipTo_State__c;
            bill.Country__c=basePunchOutList[0].CustomerParty_ShipTo_Country__c;
            bill.PostalCode__c=basePunchOutList[0].CustomerParty_ShipTo_Postal_Code__c;
           billRqtOld.add(bill);
            addwrap.billAddListRqt=billRqtOld;
          System.debug('addwrap>>>>'+addwrap);  
            
        }else{
            addWrap=new addressWrapper();
        }
        return addWrap;
    }
    
    
      @AuraEnabled
       public static List<SOLIWrapper>  getAllActiveCartDetails()
    {
        Id punchoutID = PunchOutRequestController.getPunchoutRequestId();
        system.debug('customerid123>>'+punchoutID);
        List<Base_Order__c> SOList=new List<Base_Order__c>();
        List<Base_Order_Detail__c> SOliList=new List<Base_Order_Detail__c>();
        List<SOLIWrapper> prodwrapList = new List<SOLIWrapper>();
        
        //system.debug('customerid123>>'+punchoutID);
        system.debug('CartRecordType>>'+CartRecordType);
        
       
        SOList =[select id, name, Retailer_Code1__c,Retailer_Code1__r.name,Retailer_Code1__r.Show_Price_in_Order__c,Product__r.Business_Vertical__c from Base_Order__c where PunchOut_Request__r.Id=:punchoutID ];
        Decimal TotalCartprice = 0.0;
        System.debug('SOList.size()>>'+SOList.size());
        
        set<id> baseIds=new set<id>();
        for(Base_Order__c b:SOList){
            baseIds.add(b.Id);
        }
        
       
        
        
        
        
        if(SOList.size()>0)  
        {
            //Mahadevaprasad SOliList =[select id,Supply_Quantity__c,Price_100_pcs__c,name,Sales_Order__c,Products__c,Print__c,Products__r.Name,Sales_Order__r.RecordType.Name,Quantity__c,Size__c,Colour__c,Local_SKU__c,Product_Description__c,Product_image_url__c,Sales_Order__r.Retailer_Code1__r.name,Sales_Order__r.Retailer_Code1__r.Show_Price_in_Order__c,Sales_Order__r.Retailer_Code1__r.Remarks__c,Full_Box_Order__c,BOX_QTY__c,Price_Specification_Book_Product__c,Price_Specification_Book_Product__r.Name,Price_Specification_Book_Product__r.Id, Price_Specification_Book_Product__r.MOQ__c,Products__r.Id,Price_Specification_Book_Product__r.UOM_Price__c, Products__r.Sub_category__c,Remarks__c,CurrencyIsoCode,Price_Product_by_Currency__r.MagNET_Price_Code__c,Price_Product_by_Currency__r.UOM_Price__c,Order_UOM__c,variable_data_product__c from Sales_Order_Line_Items__c where Sales_Order__r.RecordTypeID =: CartRecordType AND Sales_Order__c =:SOList[0].id  AND Added_As_a_Label__c=false];//  AND Added_As_a_Label__c=false Added by seema .
            SOliList =[select id,Price_Product_by_Currency__r.Price_100_pcs__c,Price_Specification_Book_Product__r.Product_Unique_ID__r.Status__c,Supply_Quantity__c,Price_100_pcs__c,name,Base_Order__c,Products__c,Print__c,Products__r.Name,Base_Order__r.RecordType.Name,Quantity__c,Size__c,Colour__c,Local_SKU__c,Product_Description__c,Product_image_url__c,Base_Order__r.Retailer_Code1__r.name,Base_Order__r.Retailer_Code1__r.Show_Price_in_Order__c,Base_Order__r.Retailer_Code1__r.Remarks__c,Full_Box_Order__c,BOX_QTY__c,Price_Specification_Book_Product__c,Price_Specification_Book_Product__r.Name,Price_Specification_Book_Product__r.Id, Price_Specification_Book_Product__r.MOQ__c,Products__r.Id,Price_Specification_Book_Product__r.UOM_Price__c, Products__r.Sub_category__c,Remarks__c,CurrencyIsoCode,Price_Product_by_Currency__r.MagNET_Price_Code__c,Price_Product_by_Currency__r.UOM_Price__c,Order_UOM__c,variable_data_product__c from Base_Order_Detail__c where Base_Order__c IN:baseIds  AND Added_As_a_Label__c=false AND Price_Specification_Book_Product__r.Product_Unique_ID__r.Status__c='Active'];//  AND Added_As_a_Label__c=false Added by seema .
            system.debug(' SOliList>>'+ SOliList);
            for(Base_Order_Detail__c SOLI:SOliList)
            {
                if(String.ValueOf(SOLI.Price_Product_by_Currency__r.Price_100_pcs__c)==SOLI.Price_100_pcs__c){
                SOLIWrapper productobj = new SOLIWrapper();
                productobj.id = SOLI.id;
                productobj.SOid = SOLI.Base_Order__c;
                productobj.Name=SOLI.Products__r.Name;
                productobj.Quantity=String.valueOf(SOLI.Quantity__c);
                productobj.Color=SOLI.Colour__c;
                productobj.LocalSKU=SOLI.Local_SKU__c;
                productobj.fullboxQty=SOLI.Full_Box_Order__c;
                productobj.boxquantity=SOLI.BOX_QTY__c;
                productobj.Description=SOLI.Product_Description__c;
                productobj.Productimage=SOLI.Product_image_url__c;
                productobj.Remarks=SOLI.Remarks__c;
                productobj.retailerName = SOLI.Base_Order__r.Retailer_Code1__r.name;
                productobj.showremarks = SOLI.Base_Order__r.Retailer_Code1__r.Remarks__c;
                productobj.PSBP = SOLI.Price_Specification_Book_Product__r.Name;
                productobj.ProductId = SOLI.Products__r.Id;
                productobj.MOQ = SOLI.Price_Specification_Book_Product__r.MOQ__c; 
                productobj.orderUom = SOLI.Order_UOM__c;
                productobj.ShowPriceInOrder = SOLI.Base_Order__r.Retailer_Code1__r.Show_Price_in_Order__c;
                productobj.variableDataProduct = SOLI.variable_data_product__c;
                productobj.Status =  SOLI.Price_Specification_Book_Product__r.Product_Unique_ID__r.Status__c;
                //Price_Specification_Book_Product__r.Product_Unique_ID__r.Status__c
                // Decimal.ValueOf(str)
                //  system.debug(' SOLI.Price_Specification_Book_Product__r.UOM_Price__c :::'+ SOLI.Price_Specification_Book_Product__r.UOM_Price__c);
                // system.debug(' SOLI.Quantity__c :::'+ SOLI.Quantity__c);
                //system.debug(' SOLI.Id :::'+ SOLI.Id);
                //system.debug(' SOLI.Id :::'+ SOLI.Products__r.Name);
                
                //If the user is perticular user then perticular price is set added By raghu starts
                system.debug(' SOLI.Price_Product_by_Currency__r.MagNET_Price_Code__c :::'+ SOLI.Price_Product_by_Currency__r.MagNET_Price_Code__c);
                if(SOLI.Price_Product_by_Currency__r.MagNET_Price_Code__c != null){
                    // system.debug(' SOLI.Supply_Quantity__c>>'+ SOLI.Supply_Quantity__c);
                    //system.debug(' SOLI.Price_100_pcs__c>>'+ SOLI.Price_100_pcs__c);
                    //system.debug('SOLI.COLOUR>>'+SOLI.Colour__c);
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
                //if(SOLI.Products__r.Sub_category__c == 'STICKER' || SOLI.Products__r.Sub_category__c == 'SIZER')			// added by chandana on 03/26/2020
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
            }
            system.debug(' prodwrapList4567 :::'+ prodwrapList);
            return prodwrapList;
            
        }
        else 
        {
            return null;
        }
        
    }

    
     // Update product to the cart
    @AuraEnabled 
    public static string updateCartValue(String solilistjson)
    {
        try{
            list<SOLIWrapper> prodwrapList = new list<SOLIWrapper>();
            list<Base_Order_Detail__c> Solilist = new list<Base_Order_Detail__c>();
            list<SOLIWrapper> solideserlist = (list<SOLIWrapper>)JSON.deserialize(solilistjson , list<SOLIWrapper>.class);
            
            for(SOLIWrapper SOLIwrap:solideserlist)
            {
                Base_Order_Detail__c Soliobj = new Base_Order_Detail__c();
                Soliobj.id = SOLIwrap.id;
                Soliobj.Ordered_Quantity__c=Integer.valueOf(SOLIwrap.Quantity);
                Soliobj.Supply_Quantity__c=SOLIwrap.Quantity;
                Soliobj.Remaining_Qty__c=Integer.valueOf(SOLIwrap.Quantity);
                Soliobj.Quantity__c=Decimal.valueOf(SOLIwrap.Quantity);
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
    
    
      /*Add Products for bulk add to cart: --START--*/
    @AuraEnabled
    public static string addBulkProduct(String custid,String retailerCodeId,String bulkCartDataToSave,string selectedCurrency,String searchedCurrency)
    {
        system.debug('custid>>'+custid);
        system.debug('retailerCodeId>>'+retailerCodeId);
        system.debug('bulkCartDataToSave>>'+bulkCartDataToSave);
        system.debug('selectedCurrency>>'+selectedCurrency);
        system.debug('searchedCurrency>>'+searchedCurrency);

        List<BulkAddToCartWrap> bulkCartDataToSaveDes = (List<BulkAddToCartWrap>)JSON.deserialize(bulkCartDataToSave , List<BulkAddToCartWrap>.class);
        system.debug('bulkCartDataToSaveDes>>'+bulkCartDataToSaveDes);
        String res = PunchOutRequestController.saveBulkCart(custid,retailerCodeId,bulkCartDataToSaveDes,selectedCurrency,searchedCurrency);
        system.debug('res>>'+res);
        return res;
    }
    
    
       /*Added by seema for bulk add to cart: --START--*/
    @AuraEnabled
    public static string saveBulkCart(String custid,String retailerCodeId,List<BulkAddToCartWrap> bulkCartDataToSaveDes,string selectedCurrency,String searchedCurrency)
    {
        //List<Retailer_Related_Data__c> ContRetailer = new List<Retailer_Related_Data__c>();
        //ContRetailer = [select id,Name,Supplier_Code__c,Customer_Information__c,Retailer_Code__c, Manufacturer_Factory_Code__c from Retailer_Related_Data__c where Customer_Information__c =: custid AND Retailer_Code__c =: retailerCodeId AND Status__c='Active'];
        //system.debug('ContRetailer::'+ContRetailer);
        Id panoutId = PunchOutRequestController.getPunchoutRequestId();
        system.debug('panoutId>>>>'+panoutId);
        List<Id> pricebookSpecIdList=new List<Id>();
        List<String> colorList=new List<String>();
        List<String> priceByCurr=new List<String>();
        Map<Id,Price_Product_by_Currency__c> priceproductbycurrencyMap;
        for(BulkAddToCartWrap singleCartData:bulkCartDataToSaveDes)
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
        List<Base_Order_Detail__c> SoliList=new List<Base_Order_Detail__c>();
        List<Base_Order__c> SOList=new List<Base_Order__c>();
        //SOList =[select id, name, Retailer_Code1__c,Retailer__c,Product__r.Business_Vertical__c,Status__c,CurrencyIsoCode,Supplier_Code__c,Enquiry_Status__c,Link_To_ERP__c from Base_Order__c where Supplier__c =:custid AND recordtypeId =:CartRecordType ];
        SOList =[select id, name, Retailer_Code1__c,Product__r.Business_Vertical__c,Status__c,CurrencyIsoCode,Supplier_Code__c,Enquiry_Status__c,Link_To_ERP__c from Base_Order__c where Supplier__c =:custid AND recordtypeId =:CartRecordType ];
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
            
            Base_Order__c So=new Base_Order__c();
            //So.Retailer__c = Retailercon.Customer_Information__c;
            So.Supplier__c = custid;
            So.Supplier_Contact__c = loggedInContact.Id;
            So.RecordtypeId = CartRecordType;
            So.Retailer_Code1__c = retailerCodeId;
            So.PunchOut_Request__c = panoutId;
            So.PunchOut_Status__c = 'Product Added';
            So.Processing_Status__c = 'Failed';
            So.Status__c = 'New Order';
            So.OrderSource__c = 'Catalog Order';
            So.Vertical__c = prodDataMap.values()[0].Product_Unique_ID__r.Business_Vertical__c;
            So.Company__c = prodDataMap.values()[0].Order_to_Company__c;
            for(BulkAddToCartWrap singleCartData:bulkCartDataToSaveDes)
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
            Id currentuserId = UserInfo.getUserId();
            So.OwnerId =currentuserId;
            //So.OwnerId =config.SalesOrder_OwnerId__c; 
            system.debug('So>>>>'+So);
            insert So;                                                          
            // need to add Billing and shipping address 
            List<Base_Order_Detail__c> soliListToInsert=new List<Base_Order_Detail__c>();
            for(BulkAddToCartWrap singleCartData:bulkCartDataToSaveDes)
            {
                Base_Order_Detail__c soli=new Base_Order_Detail__c();
                soli.Base_Order__c=So.id;
                soli.Products__c = prodDataMap.get(singleCartData.pricebookId).Product_Unique_ID__c;
                soli.Product_Description__c = prodDataMap.get(singleCartData.pricebookId).Description__c;
                soli.Size__c = prodDataMap.get(singleCartData.pricebookId).Product_Size__c;
                soli.print__c = prodDataMap.get(singleCartData.pricebookId).Sizer_Print__c;
                soli.Colour__c = prodDataMap.get(singleCartData.pricebookId).Color__c;
                soli.Local_SKU__c = prodDataMap.get(singleCartData.pricebookId).Local_SKU__c;
                soli.Quantity__c = Decimal.valueOf(singleCartData.quantity+'');
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
            List<Base_Order_Detail__c> soliListToInsert=new List<Base_Order_Detail__c>();
            for(BulkAddToCartWrap singleCartData:bulkCartDataToSaveDes)
            {
                system.debug('SoliList in if>>'+SoliList);
                Base_Order_Detail__c soli=new Base_Order_Detail__c();
                soli.Base_Order__c=SOList[0].id;
                soli.Products__c = prodDataMap.get(singleCartData.pricebookId).Product_Unique_ID__c;
                soli.Product_Description__c = prodDataMap.get(singleCartData.pricebookId).Description__c;
                soli.Size__c = prodDataMap.get(singleCartData.pricebookId).Product_Size__c;
                soli.print__c = prodDataMap.get(singleCartData.pricebookId).Sizer_Print__c;
                soli.Colour__c = prodDataMap.get(singleCartData.pricebookId).Color__c;
                soli.Local_SKU__c = prodDataMap.get(singleCartData.pricebookId).Local_SKU__c;
                soli.variable_data_product__c=prodDataMap.get(singleCartData.pricebookId).Variable_Data_Product__c;
                soli.Quantity__c = Decimal.valueOf(singleCartData.quantity+'');                            // need to add size,price,img url
                soli.Ordered_Quantity__c = Integer.valueOf(singleCartData.quantity);
                soli.Supply_Quantity__c = String.valueOf(singleCartData.quantity+'');
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
        return 'Bulk Cart Added';
    }
    /*Bulk add to cart: --END--*/
    
     //This code handle the three operation search keyword,tabset,pagination.
    @AuraEnabled
    public static completeProductWrapper searchProducts(String SearchKeyword,String selectedTab,Integer offsetValue,String retailerCode,String selectedFamily, String orderToCompany, String preCurrency,Decimal pageNumber)
    {
        system.debug('retailerCode:'+retailerCode+' SearchKeyword: '+SearchKeyword+' selectedTab: '+selectedTab+' selectedFamily: '+selectedFamily+' orderToCompany: '+orderToCompany+' preCurrency: '+preCurrency);
        completeProductWrapper compProdWrap=new completeProductWrapper();
        //to get company label from its API name
        Map<String,String> companyAPIandName = UtilityClass.getOrderToCompanyPicklist(true);    
        //to get company API Name from its label
        Map<String,String> companyNameandAPI = UtilityClass.getOrderToCompanyPicklist(false);
        
        //to get currency API Name from its label
        Map<String,String> currencyAPIandName = UtilityClass.getPreferredCurrencyPicklist(true);
        system.debug('currencyAPIandName>>>>>>'+currencyAPIandName);
        
        //to get currency API Name from its label
        Map<String,String> currencyNameandAPI = UtilityClass.getPreferredCurrencyPicklist(false);
        system.debug('currencyNameandAPI>>>>>>'+currencyNameandAPI);
        
        //getting current user customer information Id
         contact contactid=UtilityClass.getCurrentUserContact();
         system.debug('Customer Info ID for Product>>>>'+contactid.Customer_Information__c); 
        List<Customer_Information__c> CustProdID=[select MagNET_Price_Code__c from Customer_Information__c where Id=: contactid.Customer_Information__c ];
        system.debug('Customer Info Product code>>>>'+CustProdID);
        
        //getting customer's contact data to get preferred currency and order to company
        Contact con = CatalogOrderController.getcostomerinfo(retailerCode);
        system.debug('con from getcostomerinfo>>>>>>'+con);
        if(preCurrency!=null && preCurrency!='NULL' && preCurrency!='')
        {
            //override preferred currency in contact(not updating) if user selectes currency in catalog
            con.Preferred_Currency__c = preCurrency;
            
        }
        else
        {
            preCurrency = con.Preferred_Currency__c;    //if currency is not selected in catalog, taking preferred currency
        }
        if(currencyNameandAPI.containskey(preCurrency))
        {
            preCurrency=currencyNameandAPI.get(preCurrency);
        }
        
        //Query starts
        String qryPbProNames='select Name from Price_Specification_Book_Product__c';    //to get unique set of product name within the given limit
        //1 Jun 2023 Ivy Lee added DisplayModel__c & Retailer_Code__r.Show_Box_Qty__c 
        String qryPbProDetails='select Id, Name,DisplayModel__c,Product_Family__c,Price_100pcs__c,UOM_Price__c,Show_Price_UOM__c, BOX_QTY__c, Order_to_Company__c, CurrencyIsoCode, Product_image_url__c,Additional_Images__c, Description__c,Description2__c,Description_3__c,color__c,Product_Unique_ID__c,Product_Unique_ID__r.Name,Product_Unique_ID__r.Business_Vertical__c,Product_Unique_ID__r.Product_Family__c,Retailer_Code__r.name, Retailer_Code__r.Full_Box_Order__c,Retailer_Code__r.Show_Price_in_Order__c,Retailer_Code__r.Show_Box_Qty__c,Retailer_Code__c,Customer_Ref_Model__c,Order_UOM__c,Variable_Data_Product__c,Sizer_Print__c, MOQ__c from Price_Specification_Book_Product__c'; //to get the details of price specification book based on the name provided by qryPbProNames
        String qryPbProWhereClause = ' where Active__c = true AND Product_Unique_ID__r.Status__c = \'Active\' AND Hidden_Catalogue__c=false';
        
        String qryCount=' select COUNT_DISTINCT(Name) totalCount from Price_Specification_Book_Product__c where Active__c = true AND Product_Unique_ID__r.Status__c = \'Active\' AND Hidden_Catalogue__c=false ';
        if(orderToCompany!=null && orderToCompany!='NULL' && orderToCompany!='' && companyNameandAPI.containskey(orderToCompany))
        {
            system.debug('orderToCompany ::'+orderToCompany);
            orderToCompany=companyNameandAPI.get(orderToCompany);
            qryPbProWhereClause+=' AND Order_to_Company__c =\''+orderToCompany+'\'';
            qryCount+=' AND Order_to_Company__c =\''+orderToCompany+'\'';
        }
        else
        {
            orderToCompany = con.Order_to_Company__c;
            system.debug('orderToCompany ::'+orderToCompany);
            qryPbProWhereClause+=' AND Order_to_Company__c =\''+orderToCompany+'\'';    //if company is not selected in catalog, taking prferred order to company
            qryCount+=' AND Order_to_Company__c =\''+orderToCompany+'\'';
        }
        if(selectedTab!=null)
        {
            qryPbProWhereClause+=' AND Product_Unique_ID__r.Business_Vertical__c =\''+selectedTab+'\'';
            qryCount+=' AND Product_Unique_ID__r.Business_Vertical__c =\''+selectedTab+'\'';
        }
       
        if(selectedFamily!=null && selectedFamily!='NULL')
        {
            system.debug('selectedFamily>>>'+selectedFamily);
            qryPbProWhereClause+=' AND Product_Family__c =\''+selectedFamily+'\'';
            qryCount+=' AND Product_Family__c =\''+selectedFamily+'\'';
            /*if(selectedFamily.contains('SIZER'))
                {
                qryPbProWhereClause+=' AND Variable_Data_Product__c=\'Yes\'';
                qryCount+=' AND Variable_Data_Product__c=\'Yes\'';
                }*/
        }
         if(retailerCode!=null)
        {
            qryPbProWhereClause+=' AND Retailer_Code__c=\''+retailerCode+'\'';
            qryCount+=' AND Retailer_Code__c=\''+retailerCode+'\'';
        }
        /*if(preCurrency!=null && preCurrency!='NULL')
        {
            qryPbProWhereClause+=' AND id IN(select Price_Book_Product__c from Price_Product_by_Currency__c  where CurrencyIsoCode=\''+preCurrency+'\')';
            qryCount +=' AND id IN(select Price_Book_Product__c from Price_Product_by_Currency__c  where CurrencyIsoCode=\''+preCurrency+'\')';
        }*/
        if(selectedFamily!=null && selectedFamily!='NULL')
        {
    /*Original 7 Jun 2023 Ivy Lee        qryCount+=' AND Product_Unique_ID__c IN (select Id from Product__c  where Status__c = \'Active\' AND Product_Family__c =\''+selectedFamily+'\' AND Business_Vertical__c =\''+selectedTab+'\')'; */
            qryCount+=' AND Product_Family__c =\''+selectedFamily+'\'';
            
        }
        else
        {
            //qryPbProWhereClause+=' AND Product_Unique_ID__c IN \''+SearchKeyword+'\'';
            qryCount+=' AND Product_Unique_ID__c IN (select Id from Product__c  where Status__c = \'Active\' AND Business_Vertical__c =\''+selectedTab+'\')';
        }
        //this part should always be at last to prevent offset and limit attribute during search by product names
        if(SearchKeyword!=null && SearchKeyword!='')
        {
            system.debug('inside keyword>>'+SearchKeyword); 
            SearchKeyword ='%'+searchKeyWord +'%';
            qryPbProWhereClause+=' AND Keywords__c Like \''+SearchKeyword+'\'';
            qryCount+=' AND Keywords__c Like \''+SearchKeyword+'\'';
        }
        
        qryPbProNames=qryPbProNames + qryPbProWhereClause;
        
        
        Integer pageRecSize = 36;
        //code added for Pagination
        System.debug('pageNumber:'+pageNumber);
        Integer offset = ((Integer)pageNumber - 1) * pageRecSize;
        System.debug('qryCount>>>>>>'+qryCount);
        compProdWrap.totalRecords = Integer.valueOf(Database.query(qryCount)[0].get('totalCount'));
        compProdWrap.pageSize = pageRecSize;
        compProdWrap.pageNumber = (Integer) pageNumber;
        
        if(SearchKeyword!=null && SearchKeyword!='')  //if searching product name don't include limit and offset
        {
            pageNumber = 1;pageRecSize = 200;  //changes specific to search by name feature
            // 1 Jun Ivy Leeoriginal >> qryPbProNames=qryPbProNames + ' group by Name order by name ';
            qryPbProNames=qryPbProNames + ' group by Name order by Name';
        }
        else
        {
            if(!test.isRunningTest())
            {
                //	1 Jun Ivy Leeoriginal >> qryPbProNames=qryPbProNames + ' group by Name order by name Limit 36 OFFSET:offset';
                qryPbProNames=qryPbProNames + ' group by Name order by Name Limit 36 OFFSET:offset';
            }
            else
            {
               // 1 Jun Ivy Leeoriginal >> qryPbProNames=qryPbProNames + ' group by Name order by name Limit 36';
                qryPbProNames=qryPbProNames + ' group by Name order by Name Limit 36';
            }
        }
        system.debug('qryPbProNames>>>>>>'+qryPbProNames);
        //executing Query to get price specification book names
        List<AggregateResult> listofprodNames = (Database.query(qryPbProNames));    //to get unique names of products with given limit in query
        
        Set<String> pruductNameSet = new Set<String>();
        for(AggregateResult priceBookPro : listofprodNames)
        {
            system.debug('priceBookPro>>'+String.valueOf(priceBookPro.get('Name')));
            pruductNameSet.add( String.valueOf( priceBookPro.get('Name') ) );
        }
        system.debug(' pruductNameSet>> '+pruductNameSet.size()+' '+pruductNameSet);
        
        //executing Query to get price specification book details
        // 1 Jun Ivy Lee original qryPbProDetails=qryPbProDetails + qryPbProWhereClause+ ' AND Name IN:pruductNameSet order by name';
        qryPbProDetails=qryPbProDetails + qryPbProWhereClause+ ' AND Name IN:pruductNameSet order by Name';
        system.debug('qryPbProDetails>>>>>>'+qryPbProDetails);
        List<Price_Specification_Book_Product__c> listofprod = (Database.query(qryPbProDetails));   //to get unique names of products with given limit in query
        system.debug('listofprod>>>>>>'+listofprod.size());
        
        //Special Price Starts | currency of customer and ERP customer code should match in product price by currency object
        Id billToRecordType = Schema.SObjectType.Ship_Bill_Address__c.getRecordTypeInfosByName().get('Bill To').getRecordTypeId();  //bill to records id of billtoShip to address object
        Id billToLockedRecordType = Schema.SObjectType.Ship_Bill_Address__c.getRecordTypeInfosByName().get('Bill to Locked').getRecordTypeId();  //bill to records id of billtoShip to address object
        system.debug('billToRecordType>>'+billToRecordType);
        system.debug('billToLockedRecordType>>'+billToLockedRecordType);
        //to store customer code from Bill to ERP link object
        Set<String> ERPCustomerCode = new Set<String>();    
        //to store pricebook id from listofprod list
        Set<Id> pbIdSet = new Set<Id>();    
        for(Bill_to_ERP_Link__c ERPLink:[select id, name, Local_ERP_customer_code__c, Local_ERP_Payment_Code__c, Locked_Bill_To__c, Mainetti_Company__c, Mainetti_Company__r.name from Bill_to_ERP_Link__c where Parent_Bill_To__r.Customer_Information__c =:con.Customer_Information__c and Parent_Bill_To__r.Is_Default__c =: true AND (Parent_Bill_To__r.RecordTypeId =: billToRecordType OR Parent_Bill_To__r.RecordTypeId =: billToLockedRecordType)])
        {
            system.debug('ERPLink>>'+ERPLink);
            ERPCustomerCode.add(ERPLink.Local_ERP_customer_code__c);
        }
        //Special Price ends
        
        //Normal Price starts
        for(Price_Specification_Book_Product__c psbp : listofprod)
        {
            system.debug('psbp>>'+psbp);
            pbIdSet.add(psbp.Id);
        }
        system.debug('pbIdSet>>>>>>'+pbIdSet);
        system.debug('pbIdSet size>>>>>>'+pbIdSet.size());
        
        Map<Id,List<Price_Product_by_Currency__c>> pbIdPriceCurrMap = new Map<Id,List<Price_Product_by_Currency__c>>(); //key=> pbsp id and value => product price by currency
        //Map<String,List<String>> mapOfcompAndCurrency = new Map<String,List<String>>(); //#advanced key=> pbsp company name => currency name
        //Map<Id,Price_Product_by_Currency__c> pbIdSpecialPriceMap = new Map<Id,Price_Product_by_Currency__c>();  //key=> pbsp id and value => special product price for customer
        //changes made on 8 nov 2021
        Map<Id,Price_Product_by_Currency__c> pbIdSpecialDiscountPriceMap = new Map<Id,Price_Product_by_Currency__c>();  //Key=> Product ID and Value => Special Product Price for Customer
        
        for(Price_Product_by_Currency__c procurr : [select id,name, CurrencyIsoCode, Local_ERP_customer_code__c, Price_100_pcs__c, Price_1000_pcs__c,UOM_Price__c,Price_Book_Product__c,Price_Book_Product__r.Order_to_Company__c,Mainetti_Model_Code__c,MagNET_Price_Code__c from Price_Product_by_Currency__c where Price_Book_Product__c IN:pbIdSet])
        {
            /*
String [] currencySplit = con.Preferred_Currency__c.split('-');
String ResCurr = currencySplit[0].trim();
String CurrCode;
if(ResCurr.size()>1)
{
CurrCode = ResCurr[0];
}
*/
            system.debug('procurr>>'+procurr);
            system.debug('con.Preferred_Currency__c '+con.Preferred_Currency__c+' procurr.CurrencyIsoCode '+procurr.CurrencyIsoCode);
            /*if(con.Preferred_Currency__c.contains(procurr.CurrencyIsoCode) && ERPCustomerCode.contains(procurr.Local_ERP_customer_code__c) )    //if special price is defined for current customer
            {
                pbIdSpecialPriceMap.put(procurr.Price_Book_Product__c,procurr);
                system.debug('pbIdSpecialPriceMap>>'+pbIdSpecialPriceMap);
            }
            
            //Added by Raghu on 8 nov 2021 starts
            else*/ if(con.Preferred_Currency__c.contains(procurr.CurrencyIsoCode) && procurr.MagNET_Price_Code__c == CustProdID[0].MagNET_Price_Code__c){
                System.debug('Inside Special Price');
                pbIdSpecialDiscountPriceMap.put(procurr.Price_Book_Product__c,procurr);
                 System.debug('Inside::'+pbIdSpecialDiscountPriceMap);
            }
            //Added by Raghu on 8 nov 2021 ends
            else if(con.Preferred_Currency__c.contains(procurr.CurrencyIsoCode))    //to get normal price in case special price is not there
            {
                if(pbIdPriceCurrMap.containskey(procurr.Price_Book_Product__c))
                {
                    pbIdPriceCurrMap.get(procurr.Price_Book_Product__c).add(procurr);
                }
                else
                {
                    List<Price_Product_by_Currency__c> currList = new List<Price_Product_by_Currency__c>();
                    currList.add(procurr);
                    pbIdPriceCurrMap.put(procurr.Price_Book_Product__c,currList);
                }
            }
            else    //pricebook don't have any record for preferred currency
            {
                system.debug(' currency not found ');
            }
        }
        //Normal Price ends
        //Addedto cart disable functionality
        Map<Id,String> addToCartData=new Map<Id,String>();
        Map<Id,String> addedaslabelData=new Map<Id,String>();
        Map<Id,Decimal> addToCartQuantity=new Map<Id,Decimal>();
        Map<Id,String> prodIdaddedColorListMap=new Map<Id,String>();
        try
        {
            //contact contactid=UtilityClass.getCurrentUserContact();
            for(Base_Order_Detail__c soli:[select id,name,Colour__c,Quantity__c,Added_As_a_Label__c,Products__c,Price_Specification_Book_Product__r.id from Base_Order_Detail__c where Base_Order__r.Retailer_Code1__c=:retailerCode AND Base_Order__r.RecordType.Name='Cart' AND Base_Order__r.Supplier__c=:contactid.Customer_Information__c])
            {
                if(soli.Added_As_a_Label__c)
                    addedaslabelData.put(soli.Price_Specification_Book_Product__r.id,soli.Colour__c);
                addToCartData.put(soli.Price_Specification_Book_Product__r.id,soli.Colour__c);
                //addToCartData.put(soli.Price_Specification_Book_Product__r.id,new List<String> {soli.Colour__c,soli.Quantity__c});
                addToCartQuantity.put(soli.Price_Specification_Book_Product__r.id,soli.Quantity__c);
                
                if(prodIdaddedColorListMap.containsKey(soli.Products__c))
                {
                    //prodIdaddedColorListMap.get(soli.Products__c).add(soli.Colour__c);
                    if(soli.Added_As_a_Label__c)
                    {
                        prodIdaddedColorListMap.put(soli.Products__c,'Pending');
                    }
                }
                else
                {
                    if(soli.Added_As_a_Label__c)
                    {
                        prodIdaddedColorListMap.put(soli.Products__c,'Pending');
                    }
                    else
                    {
                        prodIdaddedColorListMap.put(soli.Products__c,'Added');
                    }
                }
            }
            system.debug('addToCartData>>>>'+addToCartData);
        }
        catch(Exception e)
        {
            
        }
        //system.debug();
        List<ProductWrapper> productList = new List<ProductWrapper>(); 
        //to store product family form pricebook product
        Set<String> proFamily= new Set<String>();
        //Set<Id> prodIdSet = new Set<Id>();    //to store product id for counting purpose
        
        //looping through products in the query results
        Map<String,ProductWrapper> productMap = new Map<String,ProductWrapper>();
        if(selectedTab.contains('Hanger') || selectedTab.contains('MCare'))
        {
            System.debug('listofprod >>'+listofprod);
            for(Price_Specification_Book_Product__c psbp : listofprod)  
            {
                system.debug('psbp>>'+psbp);
                system.debug('psbp.id>>'+psbp.id);
                if(productMap.containskey(psbp.Name))
                {
                    system.debug('psbp name>>'+psbp.Name);
                    ProductWrapper prod = productMap.get(psbp.Name);
                    
                    ProductSecificationWrapper pbdata = new ProductSecificationWrapper();
                    pbdata.proddescription = psbp.Description__c;
                    pbdata.proddescription2 = psbp.Description2__c;
                    pbdata.proddescription3 = psbp.Description_3__c;//added for Mcare Description (23-3-21)
                    pbdata.prodid=psbp.Product_Unique_ID__c;
                    pbdata.proImgURL =psbp.Product_image_url__c;
                    pbdata.proAdditionalImgURL = CatalogOrderController.SpilitByCommaSeparator(psbp.Additional_Images__c);
                    pbdata.retailerCodeId =psbp.Retailer_Code__c; 
                    pbdata.retailerCodeName =psbp.Retailer_Code__r.name;
                    pbdata.fullboxQty=psbp.Retailer_Code__r.Full_Box_Order__c;
                    pbdata.ShowBoxQty=psbp.Retailer_Code__r.Show_Box_Qty__c;	//1 Jun 2023 Ivy Lee
                    pbdata.DisplayModel=psbp.DisplayModel__c;	//2 Jun 2023 Ivy Lee
                    pbdata.PBPFamily=psbp.Product_Family__c;	//8 Jun 2023 Ivy Lee
                    pbdata.boxquantity=psbp.BOX_QTY__c;
                    pbdata.MOQ=psbp.MOQ__c;
                    pbdata.showPicklistPrice = psbp.Show_Price_UOM__c;
                    system.debug('psbp.id>>'+psbp.id);
                    if(addToCartQuantity.containsKey(psbp.id) && addToCartQuantity.get(psbp.id)!=null)
                    {
                          system.debug('psbp id>>'+psbp.id);
                        pbdata.quantity=addToCartQuantity.get(psbp.id);
                    }
                    if(addToCartData.containsKey(psbp.id) && addToCartData.get(psbp.id).contains(psbp.color__c)){
                        pbdata.addedToCart=true;
                    }else
                        pbdata.addedToCart=false;
                    if(addedaslabelData.containsKey(psbp.id) && addedaslabelData.get(psbp.id).contains(psbp.color__c)){
                        pbdata.addedAsLabel=true;
                    }else
                        pbdata.addedAsLabel=false;
                    if(prodIdaddedColorListMap.containsKey(psbp.Product_Unique_ID__c) && (psbp.Product_Family__c.contains('SIZER') || psbp.Product_Family__c.contains('STICKER') || psbp.Product_Family__c.contains('GLOVE')))
                    {
                        if(prodIdaddedColorListMap.get(psbp.Product_Unique_ID__c)=='Pending')
                        {
                            pbdata.addedAsLabel=true;
                            
                        }
                        else
                        {
                            pbdata.addedAsLabel=false;
                        }
                        pbdata.addedToCart=true;
                    }
                    pbdata.color=psbp.color__c;
                    pbdata.MainettiModelCode=psbp.Name;
                    pbdata.custRefModel=psbp.Customer_Ref_Model__c;
                    pbdata.priceBookId = psbp.id;
                    pbdata.showPrice=psbp.Retailer_Code__r.Show_Price_in_Order__c;
                    pbdata.ShowBoxQty=psbp.Retailer_Code__r.Show_Box_Qty__c; 	//1 Jun 2023 IvyLee
                    pbdata.DisplayModel=psbp.DisplayModel__c;	//2 Jun 2023 Ivy Lee
                    pbdata.PBPFamily=psbp.Product_Family__c;	//8 Jun 2023 Ivy Lee
                    pbdata.UomOrder=psbp.Order_UOM__c;
                    pbdata.vardataproduct=psbp.Variable_Data_Product__c;
                    pbdata.prodFamily=psbp.Sizer_Print__c;
                    //pbdataList.add(pbdata);
                    //if there is a special price in the pricebook for current customer
                    /*if(pbIdSpecialPriceMap.containskey(psbp.id))    
                    {
                          system.debug('psbp id>>'+psbp.id);
                        pbdata.proPrice=pbIdSpecialPriceMap.get(psbp.id).Price_100_pcs__c;
                        pbdata.uomPrice=pbIdSpecialPriceMap.get(psbp.id).UOM_Price__c;
                        pbdata.proPriceBy1000=pbIdSpecialPriceMap.get(psbp.id).Price_1000_pcs__c;
                        system.debug('proPriceBy1000 ::'+pbdata.proPriceBy1000);
                        pbdata.currencyType=pbIdSpecialPriceMap.get(psbp.id).CurrencyIsoCode;
                        pbdata.priceByCurr=pbIdSpecialPriceMap.get(psbp.id).Id;
                        
                        proFamily.add(psbp.Product_Family__c);
                    }
                    //Added by Raghu on 8 nov 2021 starts
                    else*/ if(pbIdSpecialDiscountPriceMap.containskey(psbp.id)){
                        pbdata.proPrice=pbIdSpecialDiscountPriceMap.get(psbp.id).Price_100_pcs__c;
                        pbdata.uomPrice=pbIdSpecialDiscountPriceMap.get(psbp.id).UOM_Price__c;
                        pbdata.proPriceBy1000=pbIdSpecialDiscountPriceMap.get(psbp.id).Price_1000_pcs__c;
                        pbdata.currencyType=pbIdSpecialDiscountPriceMap.get(psbp.id).CurrencyIsoCode;
                        pbdata.priceByCurr=pbIdSpecialDiscountPriceMap.get(psbp.id).Id;
                        System.debug('Product Price'+pbdata.proPrice);
                        System.debug('Product ISO'+pbdata.currencyType);
                        proFamily.add(psbp.Product_Family__c);
                    }
                    //Added by Raghu on 8 nov 2021 ends
                    //if special price is not present for th customer take normal price in preferred currency
                    else if(pbIdPriceCurrMap.containskey(psbp.id))
                    {
                        List<Price_Product_by_Currency__c> currList = pbIdPriceCurrMap.get(psbp.id);
                        pbdata.proPrice=currList[0].Price_100_pcs__c;
                        pbdata.uomPrice=currList[0].UOM_Price__c;
                        pbdata.proPriceBy1000=currList[0].Price_1000_pcs__c;
                        system.debug('proPriceBy1000 ::'+pbdata.proPriceBy1000);
                        pbdata.currencyType=currList[0].CurrencyIsoCode;
                        pbdata.priceByCurr=currList[0].Id;
                        
                        proFamily.add(psbp.Product_Family__c);
                    }
                    prod.ProductDataMap.put( psbp.color__c , pbdata );
                    productMap.put( psbp.Name , prod );
                    system.debug('productMap>>>>>>'+productMap);
                }
                else
                {
                    system.debug('inside else######');
                    ProductWrapper pro = new ProductWrapper();
                    pro.Id =psbp.Product_Unique_ID__c; 
                    //pro.Name =psbp.Product_Unique_ID__r.Name; 
                    pro.Name = psbp.Name;
                    pro.producttype = psbp.Product_Unique_ID__r.Business_Vertical__c;
                    selectedTab = psbp.Product_Unique_ID__r.Business_Vertical__c;
                    pro.productfamily=psbp.Product_Unique_ID__r.Product_Family__c;
                    pro.selectedColor=psbp.color__c;
                    
                    ProductSecificationWrapper pbdata = new ProductSecificationWrapper();
                    pbdata.MainettiModelCode=psbp.Name;
                    pbdata.prodid=psbp.Product_Unique_ID__c;
                    pbdata.custRefModel=psbp.Customer_Ref_Model__c;
                    pbdata.proddescription = psbp.Description__c;
                    pbdata.proddescription2 = psbp.Description2__c;/*Added for phase 2.1 requirement*/
                    pbdata.proddescription3 = psbp.Description_3__c;//added for Mcare Description (23-3-21)
                    pbdata.proImgURL =psbp.Product_image_url__c;
                    pbdata.proAdditionalImgURL = CatalogOrderController.SpilitByCommaSeparator(psbp.Additional_Images__c);
                    pbdata.retailerCodeId =psbp.Retailer_Code__c; 
                    pbdata.retailerCodeName =psbp.Retailer_Code__r.name;
                    pbdata.fullboxQty=psbp.Retailer_Code__r.Full_Box_Order__c;
                    pbdata.ShowBoxQty=psbp.Retailer_Code__r.Show_Box_Qty__c; // 1 Jun 2023 Ivy Lee
                    pbdata.DisplayModel=psbp.DisplayModel__c; // 1 Jun 2023 Ivy Lee
                    pbdata.PBPFamily=psbp.Product_Family__c;	//8 Jun 2023 Ivy Lee
                    pbdata.boxquantity=psbp.BOX_QTY__c;
                    pbdata.MOQ=psbp.MOQ__c;
                    pbdata.showPicklistPrice = psbp.Show_Price_UOM__c;
                    if(addToCartQuantity.containsKey(psbp.id) && addToCartQuantity.get(psbp.id)!=null)
                    {
                        pbdata.quantity=addToCartQuantity.get(psbp.id);
                    }
                    if(addToCartData.containsKey(psbp.id) && addToCartData.get(psbp.id).contains(psbp.color__c)){
                        pbdata.addedToCart=true;
                    }else
                        pbdata.addedToCart=false;
                    if(addedaslabelData.containsKey(psbp.id) && addedaslabelData.get(psbp.id).contains(psbp.color__c)){
                        pbdata.addedAsLabel=true;
                    }else
                        pbdata.addedAsLabel=false;
                    if(prodIdaddedColorListMap.containsKey(psbp.Product_Unique_ID__c) && (psbp.Product_Family__c.contains('SIZER') || psbp.Product_Family__c.contains('STICKER') || psbp.Product_Family__c.contains('GLOVE')))
                    {
                        if(prodIdaddedColorListMap.get(psbp.Product_Unique_ID__c)=='Pending')
                        {
                            pbdata.addedAsLabel=true;
                        }
                        else
                        {
                            pbdata.addedAsLabel=false;
                        }
                        pbdata.addedToCart=true;
                    }
                    pbdata.color=psbp.color__c;
                    pbdata.priceBookId = psbp.id;
                    pbdata.showPrice=psbp.Retailer_Code__r.Show_Price_in_Order__c;
                    pbdata.UomOrder=psbp.Order_UOM__c;
                    pbdata.ShowBoxQty=psbp.Retailer_Code__r.Show_Box_Qty__c; // 1 Jun 2023 Ivy Lee
                    pbdata.DisplayModel=psbp.DisplayModel__c; // 1 Jun 2023 Ivy Lee
                    pbdata.PBPFamily=psbp.Product_Family__c;	//8 Jun 2023 Ivy Lee
                    pbdata.vardataproduct=psbp.Variable_Data_Product__c;
                    pbdata.prodFamily=psbp.Sizer_Print__c;
                    //pbdataList.add(pbdata);
                    
                    //if there is a special price in the pricebook for current customer
                    //system.debug('pbIdSpecialPriceMap>>'+pbIdSpecialPriceMap);
                    /*if(pbIdSpecialPriceMap.containskey(psbp.id))    
                    {
                        system.debug('pbIdSpecialPriceMap>>'+pbIdSpecialPriceMap);
                        pbdata.proPrice=pbIdSpecialPriceMap.get(psbp.id).Price_100_pcs__c;
                        system.debug('proPrice ::' +pbdata.proPrice);
                        pbdata.uomPrice=pbIdSpecialPriceMap.get(psbp.id).UOM_Price__c;
                        pbdata.proPriceBy1000=pbIdSpecialPriceMap.get(psbp.id).Price_1000_pcs__c;
                        system.debug('proPriceBy1000 ::'+pbdata.proPriceBy1000);
                        pbdata.currencyType=pbIdSpecialPriceMap.get(psbp.id).CurrencyIsoCode;
                        pbdata.priceByCurr=pbIdSpecialPriceMap.get(psbp.id).Id;
                        
                        proFamily.add(psbp.Product_Family__c);
                    }
                    //Added by Raghu on 8 nov 2021 starts
                    else*/ if(pbIdSpecialDiscountPriceMap.containskey(psbp.id)){
                        pbdata.proPrice=pbIdSpecialDiscountPriceMap.get(psbp.id).Price_100_pcs__c;
                        pbdata.uomPrice=pbIdSpecialDiscountPriceMap.get(psbp.id).UOM_Price__c;
                        system.debug('uomPrice ::'+pbdata.uomPrice);
                        pbdata.proPriceBy1000=pbIdSpecialDiscountPriceMap.get(psbp.id).Price_1000_pcs__c;
                        pbdata.currencyType=pbIdSpecialDiscountPriceMap.get(psbp.id).CurrencyIsoCode;
                        pbdata.priceByCurr=pbIdSpecialDiscountPriceMap.get(psbp.id).Id;
                        
                        proFamily.add(psbp.Product_Family__c);
                    }
                    //Added by Raghu on 8 nov 2021 ends
                    //if special price is not present for th customer take normal price in preferred currency
                    else if(pbIdPriceCurrMap.containskey(psbp.id))
                    {
                        List<Price_Product_by_Currency__c> currList = pbIdPriceCurrMap.get(psbp.id);
                        pbdata.proPrice=currList[0].Price_100_pcs__c;
                        pbdata.uomPrice=currList[0].UOM_Price__c;
                        pbdata.proPriceBy1000=currList[0].Price_1000_pcs__c;
                        system.debug('proPriceBy1000 ::'+pbdata.proPriceBy1000);
                        pbdata.currencyType=currList[0].CurrencyIsoCode;
                        pbdata.priceByCurr=currList[0].Id;
                        
                        proFamily.add(psbp.Product_Family__c);
                    }
                    pro.ProductDataMap.put( psbp.color__c , pbdata );
                    productMap.put( psbp.Name , pro );
                    system.debug('productMap>>>>>>'+productMap);
                }
            }
        }           //for Hanger vertical ENDS
        else{
            for(Price_Specification_Book_Product__c psbp : listofprod)  
            {
                if(productMap.containskey(psbp.Customer_Ref_Model__c))
                {
                    system.debug('psbp name>>'+psbp.Customer_Ref_Model__c);
                    ProductWrapper prod = productMap.get(psbp.Customer_Ref_Model__c);
                    
                    ProductSecificationWrapper pbdata = new ProductSecificationWrapper();
                    pbdata.proddescription = psbp.Description__c;
                    pbdata.proddescription2 = psbp.Description2__c;
                    pbdata.proddescription3 = psbp.Description_3__c;//added for Mcare Description (23-3-21)
                    pbdata.prodid=psbp.Product_Unique_ID__c;
                    pbdata.proImgURL =psbp.Product_image_url__c;
                    pbdata.proAdditionalImgURL =CatalogOrderController.SpilitByCommaSeparator(psbp.Additional_Images__c);
                    pbdata.retailerCodeId =psbp.Retailer_Code__c; 
                    pbdata.retailerCodeName =psbp.Retailer_Code__r.name;
                    pbdata.fullboxQty=psbp.Retailer_Code__r.Full_Box_Order__c;
                    pbdata.ShowBoxQty=psbp.Retailer_Code__r.Show_Box_Qty__c; // 1 Jun 2023 Ivy Lee
                    pbdata.DisplayModel=psbp.DisplayModel__c; // 1 Jun 2023 Ivy Lee
                    pbdata.PBPFamily=psbp.Product_Family__c;	//8 Jun 2023 Ivy Lee
                    pbdata.boxquantity=psbp.BOX_QTY__c;
                    pbdata.MOQ=psbp.MOQ__c;
                    pbdata.color=psbp.color__c;
                    pbdata.showPicklistPrice = psbp.Show_Price_UOM__c;
                    if(addToCartQuantity.containsKey(psbp.id) && addToCartQuantity.get(psbp.id)!=null)
                    {
                        pbdata.quantity=addToCartQuantity.get(psbp.id);
                    }
                    if(addToCartData.containsKey(psbp.id) && addToCartData.get(psbp.id).contains(psbp.color__c)){
                        pbdata.addedToCart=true;
                    }else
                        pbdata.addedToCart=false;
                    if(addedaslabelData.containsKey(psbp.id) && addedaslabelData.get(psbp.id).contains(psbp.color__c)){
                        pbdata.addedAsLabel=true;
                    }else
                        pbdata.addedAsLabel=false;
                    
                    pbdata.MainettiModelCode=psbp.Name;
                    pbdata.custRefModel=psbp.Customer_Ref_Model__c;
                    pbdata.priceBookId = psbp.id;
                    pbdata.showPrice=psbp.Retailer_Code__r.Show_Price_in_Order__c;
                    pbdata.UomOrder=psbp.Order_UOM__c;
                    pbdata.ShowBoxQty=psbp.Retailer_Code__r.Show_Box_Qty__c; // 1 Jun 2023 Ivy Lee
                    pbdata.DisplayModel=psbp.DisplayModel__c; // 1 Jun 2023 Ivy Lee
                    pbdata.PBPFamily=psbp.Product_Family__c;	//8 Jun 2023 Ivy Lee
                    pbdata.vardataproduct=psbp.Variable_Data_Product__c;
                    pbdata.prodFamily=psbp.Sizer_Print__c;
                    //pbdataList.add(pbdata);
                    
                    //if there is a special price in the pricebook for current customer
                    /*if(pbIdSpecialPriceMap.containskey(psbp.id))    
                    {
                        pbdata.proPrice=pbIdSpecialPriceMap.get(psbp.id).Price_100_pcs__c;
                        pbdata.uomPrice=pbIdSpecialPriceMap.get(psbp.id).UOM_Price__c;
                        pbdata.proPriceBy1000=pbIdSpecialPriceMap.get(psbp.id).Price_1000_pcs__c;
                        system.debug('proPriceBy1000 ::'+pbdata.proPriceBy1000);
                        pbdata.currencyType=pbIdSpecialPriceMap.get(psbp.id).CurrencyIsoCode;
                        pbdata.priceByCurr=pbIdSpecialPriceMap.get(psbp.id).Id;
                        
                        proFamily.add(psbp.Product_Family__c);
                    }
                    //Added by Raghu on 8 nov 2021 starts
                    else*/ if(pbIdSpecialDiscountPriceMap.containskey(psbp.id)){
                        pbdata.proPrice=pbIdSpecialDiscountPriceMap.get(psbp.id).Price_100_pcs__c;
                        pbdata.uomPrice=pbIdSpecialDiscountPriceMap.get(psbp.id).UOM_Price__c;
                        pbdata.proPriceBy1000=pbIdSpecialDiscountPriceMap.get(psbp.id).Price_1000_pcs__c;
                        pbdata.currencyType=pbIdSpecialDiscountPriceMap.get(psbp.id).CurrencyIsoCode;
                        pbdata.priceByCurr=pbIdSpecialDiscountPriceMap.get(psbp.id).Id;
                        
                        proFamily.add(psbp.Product_Family__c);
                    }
                    //Added by Raghu on 8 nov 2021 ends
                    //if special price is not present for th customer take normal price in preferred currency
                    else if(pbIdPriceCurrMap.containskey(psbp.id))
                    {
                        List<Price_Product_by_Currency__c> currList = pbIdPriceCurrMap.get(psbp.id);
                        pbdata.proPrice=currList[0].Price_100_pcs__c;
                        pbdata.uomPrice=currList[0].UOM_Price__c;
                         pbdata.proPriceBy1000=currList[0].Price_1000_pcs__c;
                        system.debug('proPriceBy1000 ::'+pbdata.proPriceBy1000);
                        pbdata.currencyType=currList[0].CurrencyIsoCode;
                        pbdata.priceByCurr=currList[0].Id;
                        
                        proFamily.add(psbp.Product_Family__c);
                    }
                    prod.ProductDataMap.put( psbp.color__c , pbdata );
                    productMap.put( psbp.Customer_Ref_Model__c , prod );
                    system.debug('productMap>>>>>>'+productMap);
                }
                else
                {
                    system.debug('inside else######');
                    ProductWrapper pro = new ProductWrapper();
                    pro.Id =psbp.Product_Unique_ID__c; 
                    //pro.Name =psbp.Product_Unique_ID__r.Name; 
                    pro.Name = psbp.Name;
                    pro.producttype = psbp.Product_Unique_ID__r.Business_Vertical__c;
                    selectedTab = psbp.Product_Unique_ID__r.Business_Vertical__c;
                    pro.productfamily=psbp.Product_Unique_ID__r.Product_Family__c;
                    pro.selectedColor=psbp.color__c;
                    pro.selectedSize=psbp.Sizer_Print__c;
                    
                    ProductSecificationWrapper pbdata = new ProductSecificationWrapper();
                    pbdata.custRefModel=psbp.Customer_Ref_Model__c;
                    pbdata.prodid=psbp.Product_Unique_ID__c;
                    pbdata.proddescription = psbp.Description__c;
                    pbdata.proddescription2 = psbp.Description2__c;
                    pbdata.proddescription3 = psbp.Description_3__c;//added for Mcare Description (23-3-21)
                    pbdata.proImgURL =psbp.Product_image_url__c;
                    pbdata.proAdditionalImgURL =CatalogOrderController.SpilitByCommaSeparator(psbp.Additional_Images__c);
                    pbdata.retailerCodeId =psbp.Retailer_Code__c; 
                    pbdata.retailerCodeName =psbp.Retailer_Code__r.name;
                    pbdata.fullboxQty=psbp.Retailer_Code__r.Full_Box_Order__c;
                    pbdata.ShowBoxQty=psbp.Retailer_Code__r.Show_Box_Qty__c; // 1 Jun 2023 Ivy Lee
                    pbdata.DisplayModel=psbp.DisplayModel__c; // 1 Jun 2023 Ivy Lee
                    pbdata.PBPFamily=psbp.Product_Family__c;	//8 Jun 2023 Ivy Lee
                    pbdata.boxquantity=psbp.BOX_QTY__c;
                    pbdata.MOQ=psbp.MOQ__c;
                    pbdata.color=psbp.color__c;
                    pbdata.showPicklistPrice = psbp.Show_Price_UOM__c;
                    if(addToCartQuantity.containsKey(psbp.id) && addToCartQuantity.get(psbp.id)!=null)
                    {
                        pbdata.quantity=addToCartQuantity.get(psbp.id);
                    }
                    if(addToCartData.containsKey(psbp.id) && addToCartData.get(psbp.id).contains(psbp.color__c)){
                        pbdata.addedToCart=true;
                    }else
                        pbdata.addedToCart=false;
                    if(addedaslabelData.containsKey(psbp.id) && addedaslabelData.get(psbp.id).contains(psbp.color__c)){
                        pbdata.addedAsLabel=true;
                    }else
                        pbdata.addedAsLabel=false;
                    
                    pbdata.MainettiModelCode=psbp.Name;
                    pbdata.priceBookId = psbp.id;
                    pbdata.showPrice=psbp.Retailer_Code__r.Show_Price_in_Order__c;
                    pbdata.UomOrder=psbp.Order_UOM__c;
                    pbdata.vardataproduct=psbp.Variable_Data_Product__c;
                    pbdata.prodFamily=psbp.Sizer_Print__c;
                    //pbdataList.add(pbdata);
                    
                    //if there is a special price in the pricebook for current customer
                    /*if(pbIdSpecialPriceMap.containskey(psbp.id))    
                    {
                        pbdata.proPrice=pbIdSpecialPriceMap.get(psbp.id).Price_100_pcs__c;
                        pbdata.uomPrice=pbIdSpecialPriceMap.get(psbp.id).UOM_Price__c;
                        pbdata.proPriceBy1000=pbIdSpecialPriceMap.get(psbp.id).Price_1000_pcs__c;
                        system.debug('proPriceBy1000 ::'+pbdata.proPriceBy1000);
                        pbdata.currencyType=pbIdSpecialPriceMap.get(psbp.id).CurrencyIsoCode;
                        pbdata.priceByCurr=pbIdSpecialPriceMap.get(psbp.id).Id;
                        
                        proFamily.add(psbp.Product_Family__c);
                    }
                    //Added by Raghu on 8 nov 2021 starts
                    else*/ if(pbIdSpecialDiscountPriceMap.containskey(psbp.id)){
                        pbdata.proPrice=pbIdSpecialDiscountPriceMap.get(psbp.id).Price_100_pcs__c;
                        pbdata.uomPrice=pbIdSpecialDiscountPriceMap.get(psbp.id).UOM_Price__c;
                        pbdata.proPriceBy1000=pbIdSpecialDiscountPriceMap.get(psbp.id).Price_1000_pcs__c;
                        pbdata.currencyType=pbIdSpecialDiscountPriceMap.get(psbp.id).CurrencyIsoCode;
                        pbdata.priceByCurr=pbIdSpecialDiscountPriceMap.get(psbp.id).Id;
                        
                        proFamily.add(psbp.Product_Family__c);
                    }
                    //Added by Raghu on 8 nov 2021 ends
                    //if special price is not present for th customer take normal price in preferred currency
                    else if(pbIdPriceCurrMap.containskey(psbp.id))
                    {
                        List<Price_Product_by_Currency__c> currList = pbIdPriceCurrMap.get(psbp.id);
                        pbdata.proPrice=currList[0].Price_100_pcs__c;
                        pbdata.uomPrice=currList[0].UOM_Price__c;
                         pbdata.proPriceBy1000=currList[0].Price_1000_pcs__c;
                        system.debug('proPriceBy1000 ::'+pbdata.proPriceBy1000);
                        pbdata.currencyType=currList[0].CurrencyIsoCode;
                        pbdata.priceByCurr=currList[0].Id;
                        
                        proFamily.add(psbp.Product_Family__c);
                    }
                    pro.ProductDataMap.put( psbp.color__c , pbdata );
                    productMap.put( psbp.Customer_Ref_Model__c , pro );
                    system.debug('productMap>>>>>>'+productMap);
                }
            }
        }
        
        List<String> ListOfProductFamily = new List<String>();
        //ListOfProductFamily.addAll(proFamily);  //current page family
        ListOfProductFamily = CatalogOrderController.getPicklistValues(qryPbProWhereClause);  //product family from all the eligible pricebooks
        ListOfProductFamily.sort();
        
        if(companyAPIandName.containskey(orderToCompany))
        {
              system.debug('orderToCompany ::'+orderToCompany);
              system.debug('companyAPIandName ::'+companyAPIandName);
            compProdWrap.Ocomp=companyAPIandName.get(orderToCompany);
        }
        else
        {
            system.debug('orderToCompany ::'+orderToCompany);
            compProdWrap.Ocomp=orderToCompany;
        }
        if(currencyAPIandName.containskey(preCurrency))
        {
            compProdWrap.Pcurr=currencyAPIandName.get(preCurrency);
        }
        else
        {
            compProdWrap.Pcurr=preCurrency;
        }
        compProdWrap.PcurrList = CatalogOrderController.getDependentPicklistValues(compProdWrap.Ocomp,'Order_Country__c','Preferred_Currency__c');
        compProdWrap.productList=productMap.values();
        //to used in product search to filter by product family
        compProdWrap.productFamilyList = ListOfProductFamily;
        //compProdWrap.tabOverride = selectedTab;   //commented since not to be used
        system.debug('compProdWrap>>>'+compProdWrap);
        return compProdWrap; 
    }
   
   
@AuraEnabled
    public static List<Base_Order_Detail__c> checkLengthAddAndCloneDataToDelete(string customerid)    
    {
        system.debug('customerid >>>>.'+customerid);
        Id punchoutId = PunchOutRequestController.getPunchoutRequestId();
        List<Base_Order_Detail__c> soli=[select id,Added_As_a_Label__c,Base_Order__r.Supplier__c from Base_Order_Detail__c where Added_As_a_Label__c = true AND Base_Order__r.Supplier__c=:customerid AND Base_Order__r.PunchOut_Request__c=: punchoutId];
        system.debug('soli>>>>.'+soli);
        return soli;
    }   
    @AuraEnabled
    public static void checkAddAndCloneDataToDelete(string customerid)    
    {
        List<Base_Order_Detail__c> soli=[select id,Added_As_a_Label__c,Base_Order__r.Supplier__c from Base_Order_Detail__c where Added_As_a_Label__c = true AND Base_Order__r.Supplier__c=:customerid];
        system.debug('soli>>>>.'+soli);
        delete soli;
    }
    
    //Kinda resets the order if cancelled from confirmation page
    @AuraEnabled
    public static void toCancelOrder(Base_Order__c dOrder)
    {
        dOrder = [Select Id, name, OrderSource__c, Supplier__c, Parent_Order__c, Parent_Order__r.Bill_to_Address__c, Parent_Order__r.Ship_to_Address__c, Parent_Order__r.Buyer_Address__c, Parent_Order__r.Invoice_To_Address__c from Base_Order__c where Id =: dOrder.Id];
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
    
    
    
    
     /*****************************************************************************************************************************************************/
    //to convert PO to BO
    @AuraEnabled
    public static String convertPOstoSo(Base_Order__c SO, String slctRec,Ship_Bill_Address__c BillAddress,Ship_Bill_Address__c shipAddress,Ship_Bill_Address__c invoiceAddress,Ship_Bill_Address__c buyerAddress,boolean suzhouFlag,boolean onlyvalidate)
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
        List<Base_Order__c> SOListToInsert = new List<Base_Order__c>();
        List<Base_Order_Detail__c>  SOLItoInsert = new List<Base_Order_Detail__c>();
        List<PurchaseOrder__c>  POIDList = new List<PurchaseOrder__c>();
        POtoSOWrap SOWrapData = new POtoSOWrap();           //#2.1 ENH
        SOWrapData = POtoSOConversion(slctRec);       //#2.1 ENH
        system.debug('SOWrapData>>: '+SOWrapData);
        
        if(SOWrapData==null)
        {
            returnVal = 'An error occured while converting Purchase Order to Base Order. Please contact your adminstrator';
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
        
        for(Base_Order__c newSO : SOListToInsert)      //#2.1 ENH
        {
            newSO.OwnerId =config.SalesOrder_OwnerId__c;
            newSO.Expected_Delivery_Date__c = SO.Expected_Delivery_Date__c;
            //newSO.Expected_Completion_Date__c = SO.Expected_Delivery_Date__c;
            
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
                
                for(Base_Order_Detail__c Soli:SOLItoInsert)
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
            for(Base_Order_Detail__c Soli:SOLItoInsert)
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
        for(Base_Order_Detail__c Soli:SOLItoInsert)
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
        Map<Id,Base_Order__c> SalesOrderMap = new Map<Id,Base_Order__c>();    //key => bo id, Value => bo rec
        Map<Id,Id> PoIdnSoIdMap = new Map<Id,Id>(); //key => po id, Value => so id
        String soIdForEmail = '';
        for(Base_Order__c newSO : SOListToInsert)
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
        for(Base_Order_Detail__c Soli:SOLItoInsert)
        {
            system.debug('poli id: '+Soli.POLI_Text_Ids__c);
            system.debug('containskey poli id: '+SOWrapData.PoliPOIdMap.containsKey((Id)Soli.POLI_Text_Ids__c));
            system.debug('contains po id: '+PoIdnSoIdMap.get(SOWrapData.PoliPOIdMap.get((Id)Soli.POLI_Text_Ids__c).Purchase_Order__c));
            Soli.Base_Order__c = PoIdnSoIdMap.get(SOWrapData.PoliPOIdMap.get((Id)Soli.POLI_Text_Ids__c).Purchase_Order__c);
            Soli.CurrencyIsoCode = SalesOrderMap.get(Soli.Base_Order__c).CurrencyIsoCode;  //#2.1 ENH
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
                            Soli.Quantity__c = Decimal.valueof(MoqNFullBoxqty);    //text
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
      
            if(pbIdSpecialDiscountPriceMap.containskey(Soli.Price_Specification_Book_Product__c)){
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
            
            Soli.Expected_Delivery_Date__c = SalesOrderMap.get(Soli.Base_Order__c).Expected_Delivery_Date__c;  //added on 16 Dec 2019
            Soli.Expected_Completion_Date__c = SalesOrderMap.get(Soli.Base_Order__c).Expected_Delivery_Date__c;    //added on 16 Dec 2019
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
        for(Base_Order__c newSO : SOListToInsert)
        {
            SoIdsforName.add(newSO.id);
            
        } 
        system.debug('SoIdsforName: '+SoIdsforName);
        /* code for RFID generation by Alvin*/
        if(!onlyvalidate){
            Set<Id> Ids_1 = (new Map<Id,Base_Order_Detail__c>(SOLItoInsert)).keySet();
            List<Base_Order_Detail__c> SoliList_1 = [select id, Name, Base_Order__c, Base_Order__r.Retailer_Code1__c, Supply_Quantity__c, Quantity__c, Expected_Delivery_Date__c, Status__c, Price_Product_by_Currency__c,Online_Detail_Status__c, Price_Product_by_Currency__r.Price_100_pcs__c, Price_Specification_Book_Product__r.USD_Rebate_pc__c, Price_Specification_Book_Product__r.EUR_Rebate_pc__c, Price_Specification_Book_Product__r.USD_Reuse_Rebate_pc__c, Price_Specification_Book_Product__r.EUR_Reuse_Rebate_pc__c,Price_Specification_Book_Product__r.RFIDSerial__c  from Base_Order_Detail__c where Id IN :Ids_1];
            //SoliList_2 =[select Id,Price_Specification_Book_Product__r.RFIDSerial__c , Start_Num__c from Sales_Order_Line_Items__c where Id IN resultIds];
            Boolean IsRevised1 = false;
            Map<Base_Order_Detail__c,boolean> ReviseMap1;
            string retailcode1 = SO.Retailer_Code1__c;
            System.enqueueJob(new PunchoutRFIDNumGeneartion(SoliList_1, IsRevised1,ReviseMap1,retailcode1));
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
    
    
        //method to send emails to retailers after po is converted to SO
    
    public static void adminEmailAfterPOtoSOconversion(Map<Id,Base_Order__c> SalesOrderMap)
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
            for(Base_Order__c newSOList : [Select id,name,Company__c,Retailer_Code1__c,Retailer_Code1__r.Name,Retailer_Code1__r.Market_Segment__c,Supplier__r.Name,Supplier__c,Supplier_Contact__r.Name,Supplier_Contact__r.Email,Expected_Delivery_Date__c,
                                            Bill_to_Factory__c, CustomerParty_BillTo_Address1__c, CustomerParty_BillTo_CityName__c, Bill_to_State__c, CustomerParty_BillTo_Postal_Code__c, Bill_to_Country__c, CustomerParty_BillTo_Telephone__c, Bill_To_Contact__c,
                                            Ship_to_Factory__c, CustomerParty_ShipTo_Address1__c, CustomerParty_ShipTo_CityName__c, CustomerParty_ShipTo_State__c, CustomerParty_ShipTo_Postal_Code__c, CustomerParty_ShipTo_Country__c, CustomerParty_ShipTo_Telephone__c, Ship_To_Contact__c
                                            from Base_Order__c where Id IN: SalesOrderMap.keyset()])
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
            
            
            for(Base_Order__c newSO : [Select id,name,Company__c,Retailer_Code1__c,Retailer_Code1__r.Name,Retailer_Code1__r.Market_Segment__c,Supplier__r.Name,Supplier__c,Supplier_Contact__r.Name,Supplier_Contact__r.Email,Expected_Delivery_Date__c,
                                        Bill_to_Factory__c, CustomerParty_BillTo_Address1__c, CustomerParty_BillTo_CityName__c, Bill_to_State__c, CustomerParty_BillTo_Postal_Code__c, Bill_to_Country__c, CustomerParty_BillTo_Telephone__c, Bill_To_Contact__c,
                                        Ship_to_Factory__c, CustomerParty_ShipTo_Address1__c, CustomerParty_ShipTo_CityName__c, CustomerParty_ShipTo_State__c, CustomerParty_ShipTo_Postal_Code__c, CustomerParty_ShipTo_Country__c, CustomerParty_ShipTo_Telephone__c, Ship_To_Contact__c
                                        from Base_Order__c where Id IN: SalesOrderMap.keyset()])
            {
                
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                date EXFactory = newSO.Expected_Delivery_Date__c;
                string orderToCompanytoconv = companyNameandAPI.get(newSO.Company__c); 
                
                //RegistrationService.ToEmailandCCEmailWrapper Regwrap = RegistrationService.getMailAddresses(orderToCompanytoconv, newSO.Retailer_Code1__r.Market_Segment__c ,config);
                system.debug('Regwrap>>'+Regwrap);
                
                String RecordsLink='';
                
                string subject = 'Sales Order has been Created for '+newSO.Name+'(Retailer code: '+ newSO.Retailer_Code1__r.Name +')';
                RecordsLink += '<a href= '+config.My_Domain__c+'/'+newSO.Id+'>'+newSO.Name+'</a>'+'<br/><br />';
                
                string BillToPostCode = newSO.CustomerParty_BillTo_Postal_Code__c!=null?newSO.CustomerParty_BillTo_Postal_Code__c:'';
                string ShipToPostCode = newSO.CustomerParty_ShipTo_Postal_Code__c!=null?newSO.CustomerParty_ShipTo_Postal_Code__c:'';
                
                
                string  emailBody = 'Dear all, <br /><br />'+newSO.Supplier_Contact__r.Name+' has Submitted below MagNET Order, please reference to the link below for the order details.' + '<br /><br />' +
                    +RecordsLink+
                    '<br />'+'Customer Contact: '+newSO.Supplier_Contact__r.Name+' / '+newSO.Supplier_Contact__r.Email+
                    '<br /><br />'+'Retailer code: '+ newSO.Retailer_Code1__r.Name +
                    '<br /><br />'+'MagNET Order: '+newSO.Name+
                    '<br /><br />'+'Expected Ex-Factory Date: '+EXFactory.format()+
                    '<br /><br />'+'Order to Company: '+newSO.Company__c+
                    '<br /><br />'+'Bill To: '+
                    '<br />'+newSO.Bill_to_Factory__c+
                    '<br />'+newSO.CustomerParty_BillTo_Address1__c+
                    '<br />'+newSO.CustomerParty_BillTo_CityName__c+
                    '<br />'+newSO.Bill_to_State__c+
                    '<br />'+BillToPostCode+
                    '<br />'+newSO.Bill_to_Country__c+
                    '<br />'+newSO.Bill_To_Contact__c+
                    '<br />'+newSO.CustomerParty_BillTo_Telephone__c+
                    
                    '<br /><br />'+'Ship To: '+
                    '<br />'+newSO.Ship_to_Factory__c+
                    '<br />'+newSO.CustomerParty_ShipTo_Address1__c+
                    '<br />'+newSO.CustomerParty_ShipTo_CityName__c+
                    '<br />'+newSO.CustomerParty_ShipTo_State__c+
                    '<br />'+ShipToPostCode+
                    '<br />'+newSO.CustomerParty_ShipTo_Country__c+
                    '<br />'+newSO.Ship_To_Contact__c+
                    '<br />'+newSO.CustomerParty_ShipTo_Telephone__c+
                    
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
    
     
    //newly created to have convert multiple PO into one SO
    public static PunchOutRequestController.POtoSOWrap POtoSOConversion(String slctRec)		//#2.1 ENH
    {  
        System.debug('slctRec>>>>>>>>>'+slctRec);
        //SOController.SalesOrderWrap SOWrap = new SOController.SalesOrderWrap();
        PunchOutRequestController.POtoSOWrap POListWrap = new PunchOutRequestController.POtoSOWrap();	//#2.1 ENH
        try{
            List<POLIwrapper> POlist = ( List<POLIwrapper>)JSON.deserialize(slctRec, List<POLIwrapper>.class);
            
            Id OrderRecordType = Schema.SObjectType.Base_Order__c.getRecordTypeInfosByName().get('Order').getRecordTypeId();
            System.debug('POlist>>>>>>>>>'+POlist);
            System.debug('POlist size()>>>>>>>>>'+POlist.size());
            List<Purchase_Order_LineItem__c> POliupdate = new List<Purchase_Order_LineItem__c>();
            Map<Id,Purchase_Order_LineItem__c> PoliPOId = new Map<Id,Purchase_Order_LineItem__c>();
            List<Base_Order_Detail__c>  newSOLIList = new List<Base_Order_Detail__c>();
            
            Contact loggedInContact = SOController.FetchCustData();
            
            
            for(POLIwrapper poInd : POlist)
            {
                Base_Order__c SOins = new Base_Order__c();
                System.debug('poInd>>>>>>>>>'+poInd);
                System.debug('poInd.POwrap>>>>>>>>>>>>'+poInd.POwrap);
                PurchaseOrder__c POId = new PurchaseOrder__c();
                POId.Id=poInd.POwrap.id;
                //POId.Name=poInd.POwrap.Name;
                POId.Status__c = 'Confirmed';
                POListWrap.PoList.add(POId);	//#2.1 ENH
                
                SOins.RecordtypeId = OrderRecordType;
                SOins.Purchase_Order__c = poInd.POwrap.Id;	//#2.1 ENH
                SOins.Retailer__c = poInd.POwrap.Retailer_Code_Cus__c;
                //SOins.Retailer_Code__c = poInd.POwrap.Retailer_Code__c;
                SOins.Retailer_Code1__c = poInd.POwrap.Retailer_Code1__c;
                SOins.Retailer_Contact__c = poInd.POwrap.Retailer_Contact__c;
                SOins.Status__c = 'Order Submitted';
                SOins.Enquiry_Status__c = 'Order submitted'; 
                SOins.OrderSource__c = 'Stage PO';
                SOins.Supplier_Street__c = poInd.POwrap.Supplier_Street__c;
                SOins.Supplier_Town__c = poInd.POwrap.Supplier_Town_c__c;
                SOins.Supplier_Country__c = poInd.POwrap.Supplier_Country_c__c;
                SOins.Supplier_State__c = poInd.POwrap.Supplier_State__c; 
                SOins.Priority__c = poInd.POwrap.Priority__c;
                //SOins.Supplier_Billing_Address__c = poInd.POwrap.Supplier_Billing_Address__c;
                SOins.Supplier__c = poInd.POwrap.Supplier_from_Cus_Inf__c;
                SOins.Supplier_Contact__c = loggedInContact.Id;
                SOins.Supplier_Factory__c = poInd.POwrap.Supplier_Factory__c;
                SOins.Tag_Type__c = poInd.POwrap.Tag_Type__c;
                SOins.Purchase_Orders__c = poInd.POwrap.Name;
                SOins.Order_Number__c = poInd.POwrap.Order_Number__c;	//#2.1 ENH
                SOins.Vertical__c = poInd.POwrap.Vertical__c;
                SOins.Supplier_Code__c =poInd.POwrap.Supplier_Code__c;
                System.debug('SOins>>>>>>>>>>>>'+SOins);
                
                POListWrap.SOList.add(SOins);	//#2.1 ENH
            }
            for(POLIwrapper POLIdata : POlist)
            {
                for(Purchase_Order_LineItem__c POLIRef : POLIdata.POLIwrap)
                {
                    String SupQty = POLIRef.Supply_Quantity__c;
                    if(Integer.ValueOf(SupQty) > 0)
                    {
                        Base_Order_Detail__c SOLIINS = new Base_Order_Detail__c();
                        //SOLIINS.Sales_Order__c     = SOins.Id;
                        SOLIINS.Status__c ='Order Submitted';
                        SOLIINS.Online_Detail_Status__c ='Order submitted';
                        //SOLIINS.Purchase_Order_LineItem__c = POLIRef.Id;
                        SOLIINS.POLI_Text_Ids__c = POLIRef.Id;
                        SOLIINS.POLI_Text_Name__c = POLIRef.Name;
                        SOLIINS.CurrencyIsoCode = POLIRef.CurrencyIsoCode;
                        SOLIINS.APN__c = POLIRef.APN__c;
                        SOLIINS.Charge_Type__c = POLIRef.Charge_Type__c;
                        SOLIINS.Class__c = POLIRef.Class__c;
                        SOLIINS.Colour__c = POLIRef.Colour__c;
                        SOLIINS.Dept__c = POLIRef.Dept__c;
                        SOLIINS.DEPT_DESC__c = POLIRef.DEPT_DESC__c; 
                        //SOLIINS.Due_Date__c = POLIRef.Due_Date__c;
                        //SOLIINS.Family__c = POLIRef.Family__c;
                        SOLIINS.KD__c = POLIRef.KD__c;
                        SOLIINS.Expected_Delivery_Date__c = POLIRef.Expected_Delivery_Date__c;
                        SOLIINS.LOCN_TXT__c = POLIRef.LOCN_TXT__c;
                        SOLIINS.MINOR_DEPT__c = POLIRef.MINOR_DEPT__c;
                        SOLIINS.MINOR_DEPT_DESC__c = POLIRef.MINOR_DEPT_DESC__c;
                        //SOLIINS.Name__c = POLIRef.Name__c;
                        SOLIINS.Order_Number__c = POLIRef.Order_Number__c;
                        SOLIINS.Pieces__c = POLIRef.Pieces__c;
                        SOLIINS.Products__c = POLIRef.Product__c;
                        SOLIINS.Product_name__c = POLIRef.Product_name__c;
                        SOLIINS.PLU__c = POLIRef.PLU__c;
                        SOLIINS.Priority__c = POLIRef.Priority__c;
                        SOLIINS.PRIV_LBL_DESC__c = POLIRef.PRIV_LBL_DESC__c;
                        System.debug('OrderQtyPO>>>'+POLIRef.Quantity__c);
                        SOLIINS.Quantity__c = Decimal.valueOf(POLIRef.Quantity__c);

                        SOLIINS.Ordered_Quantity__c = Integer.ValueOf(POLIRef.Quantity__c);
                        SOLIINS.Supply_Quantity_num__c = Integer.ValueOf(POLIRef.Supply_Quantity__c);
                        SOLIINS.Remaining_Qty__c = Integer.ValueOf(POLIRef.Supply_Quantity__c);
                        SOLIINS.Supply_Quantity__c = POLIRef.Supply_Quantity__c;
                        SOLIINS.Season__c = POLIRef.Season__c;
                        SOLIINS.Priority__c = POLIRef.Priority__c;
                        SOLIINS.Selling_Price__c = POLIRef.Selling_Price__c;
                        SOLIINS.Size__c = POLIRef.Size__c;
                        SOLIINS.Style_No__c = POLIRef.Style_No__c;
                        SOLIINS.SUP_LOCN_IND__c = POLIRef.SUP_LOCN_IND__c;
                        SOLIINS.Tag_Job__c = POLIRef.Tag_Job__c;
                        SOLIINS.Tag_Size_Color__c = POLIRef.Tag_Size_Color__c; 
                        SOLIINS.Price_Specification_Book_Product__c = POLIRef.Price_Specification_Book_Product__c;
                        SOLIINS.Price_Product_by_Currency__c = POLIRef.Price_Product_by_Currency__c;
                        SOLIINS.Print_Shop__c = POLIRef.Print_Shop__c;
                        // SOLIINS.Printshop_Pick__c = POLIRef.Printshop_Pick__c;
                        SOLIINS.Due_Date_TXT__c = POLIRef.Due_Date_TXT__c;
                        SOLIINS.SUP_PC__c = POLIRef.SUP_PC__c;
                        SOLIINS.SUP_PH__c = POLIRef.SUP_PH__c;
                        SOLIINS.Sup_PH_Area__c = POLIRef.Sup_PH_Area__c;
                        SOLIINS.SUP_ABN__c = POLIRef.SUP_ABN__c;
                        SOLIINS.PEC_TXT_1__c = POLIRef.PEC_TXT_1__c;
                        SOLIINS.PEC_TXT_2__c = POLIRef.PEC_TXT_2__c;
                        SOLIINS.Item_name__c = POLIRef.Item_Name__c;
                        SOLIINS.Size_Chart__c = POLIRef.Size_Chart__c;
                        SOLIINS.Country_Of_Origin__c = POLIRef.Country_Of_Origin_Text__c;
                        SOLIINS.Customer_Ref_Model__c = POLIRef.Customer_Ref_Model__c;
                        SOLIINS.STYLE_DESC__c = POLIRef.STYLE_DESC__c;
                        newSOLIList.add(SOLIINS);	//#2.1 ENH
                         POLIRef.Status__c = 'Confirmed';
                    }
                    else{
                        POLIRef.Status__c = 'Open';
                    }
                  //  POLIRef.Status__c = 'Confirmed';
                    PoliPOId.put(POLIRef.Id,POLIRef);	//#2.1 ENH
                }
            }
            System.debug('Before update POliupdate'+POliupdate.size()+POliupdate);
			
            //#2.1 ENH
            POListWrap.SOLIList = newSOLIList;
            POListWrap.PoliPOIdMap = PoliPOId;
            System.debug('POListWrap>>>>>>>>>>>>>'+POListWrap);
            
            return POListWrap;
        }
        catch (Exception e)
        { 
            System.debug('e:::'+e);
            System.debug('isnide Exception occured:::'+e.getMessage() +'and getLineNumber>>'+e.getLineNumber() +' and getCause is '+e.getCause());
            createErrorLog.insertError('Save Sales Order and its line Items',e.getMessage(),'Method - updatestatus',null,'',e.getStackTraceString(),UserInfo.getUserId());
            return null;
        }
        
    }
    
        public class POLIwrapper{
        
        @AuraEnabled
        public   PurchaseOrder__c POwrap;
        @AuraEnabled
        public   boolean IsSelected;
        @AuraEnabled
        public   boolean isAllqtyZero;
        @AuraEnabled
        public List<Purchase_Order_LineItem__c> POLIwrap;
        
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
        public Boolean punchOutStatus {get;set;}
        @AuraEnabled
        public Boolean priceChanged {get;set;}
        @AuraEnabled
        public String Status {get;set;}
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
        public Decimal boxquantity;
        @AuraEnabled
        public String PSBP {get;set;}
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
        public List<PunchOut_Request__c> billAddListRqt;
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
        public Base_Order__c protoSO; 
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
        
    } 
    
    
    
     //Wrapper Class For Product Count and details  
    public class completeProductWrapper {
        @AuraEnabled
        public Integer pageSize;
        @AuraEnabled
        public Integer pageNumber;
        @AuraEnabled
        public Integer totalRecords; 
        @AuraEnabled
        public Integer recordStart;
        @AuraEnabled
        public Integer recordEnd;
        @AuraEnabled
        public String tabOverride;
        @AuraEnabled
        public List<ProductWrapper> productList;
        @AuraEnabled
        public List<String> productFamilyList;
        @AuraEnabled
        public String Ocomp;
        @AuraEnabled
        public String Pcurr;
        @AuraEnabled
        public List<String> PcurrList;
    }
    
    //wrapper for product Details
    public class ProductWrapper{
        @AuraEnabled
        public String Id;
        @AuraEnabled
        public String Name;
        @AuraEnabled
        public String producttype;
        @AuraEnabled
        public String selectedColor;
        @AuraEnabled
        public String selectedSize;
        @AuraEnabled
        public String productfamily;
        @AuraEnabled
        public Map<string, ProductSecificationWrapper> ProductDataMap=new Map<string, ProductSecificationWrapper>();
    }
    
    //Wrapper for Product specification book product details.
    public class ProductSecificationWrapper{
        @AuraEnabled
        public String proddescription;
        @AuraEnabled
        public String proddescription2;
        @AuraEnabled
        public String proddescription3;
        @AuraEnabled
        public String color;
        @AuraEnabled
        public String MainettiModelCode; 
        @AuraEnabled
        public String priceByCurr;  
        @AuraEnabled
        public Decimal proPrice;  
        @AuraEnabled
        public Decimal uomPrice;
        @AuraEnabled
        public String showPicklistPrice;
        //Added By Bharath on 04/11/2021 
         @AuraEnabled
        public Decimal proPriceBy1000;
        @AuraEnabled
        public String proImgURL; 
        @AuraEnabled
        public List<String> proAdditionalImgURL;
        @AuraEnabled
        public String retailercodeId; 
        @AuraEnabled
        public String retailerCodeName;
        @AuraEnabled
        public String priceBookId;   
        @AuraEnabled
        public Decimal quantity; 
        @AuraEnabled
        public Boolean showPrice; 
        @AuraEnabled
        public String currencyType;
        @AuraEnabled
        public Boolean fullboxQty;
		//1 Jun2023 Ivy Lee
        @AuraEnabled
        public Boolean ShowBoxQty;
        //2 Jun2023 Ivy Lee
        @AuraEnabled
        public String DisplayModel;
        //8 Jun2023 Ivy Lee
        @AuraEnabled
        public String PBPFamily;
        @AuraEnabled
        public Decimal boxquantity;  
        @AuraEnabled
        public Decimal MOQ; 
        @AuraEnabled
        public String custRefModel;
        @AuraEnabled
        public String prodid;
        @AuraEnabled
        public String UomOrder;
        @AuraEnabled
        public string vardataproduct;
        @AuraEnabled
        public Boolean addedToCart;
        @AuraEnabled
        public Boolean addedAsLabel;
        @AuraEnabled
        public string prodFamily;
    }
    public class BulkAddToCartWrap{
        @AuraEnabled
        public string retailerCodeId;
        @AuraEnabled
        public string pricebookId;
        @AuraEnabled
        public Integer quantity;
        @AuraEnabled
        public string cur;
        @AuraEnabled
        public string custRefModel;
        @AuraEnabled
        public string color;
    } 
    
       public class POtoSOWrap     //#2.1 ENH
    {
        @AuraEnabled
        public List<Base_Order__c> SOList = new List<Base_Order__c>();
        @AuraEnabled
        public List<Base_Order_Detail__c> SOLIList = new List<Base_Order_Detail__c>();
        @AuraEnabled
        public List<PurchaseOrder__c> PoList = new List<PurchaseOrder__c>();
        @AuraEnabled
        public Map<Id,Purchase_Order_LineItem__c> PoliPOIdMap = new Map<Id,Purchase_Order_LineItem__c>();
    }
  
}