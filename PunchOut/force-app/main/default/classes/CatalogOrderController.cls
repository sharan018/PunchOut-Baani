/*=====================================================================================================
Author     : Seema S Yaladagi
Company    : CRMIT Solution Pvt Ltd.
Date       : 10th March 2019
Description: CatalogOrderController class helps to handle following 

* Handle the three operation search keyword,tabset,pagination,Retailer code,Selected Family,order to Company,
Preferred Currency.
* Fetch the ,Product,Product description from and Price_Specification_Book_Product__c Object.
* Save to the Sales_Order__c Order and Sales_Order_Line_Items__c of object with Cart as Record type.

=======================================================================================================*/
public without sharing class CatalogOrderController 
{    
    public Static Id CartRecordType = Schema.SObjectType.Sales_Order__c.getRecordTypeInfosByName().get('Cart').getRecordTypeId();
    
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
        Contact con = getcostomerinfo(retailerCode);
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
            for(Sales_Order_Line_Items__c soli:[select id,name,Colour__c,Quantity__c,Added_As_a_Label__c,Products__c,Price_Specification_Book_Product__r.id from Sales_Order_Line_Items__c where Sales_Order__r.Retailer_Code1__c=:retailerCode AND Sales_Order__r.RecordType.Name='Cart' AND Sales_Order__r.Supplier__c=:contactid.Customer_Information__c])
            {
                if(soli.Added_As_a_Label__c)
                    addedaslabelData.put(soli.Price_Specification_Book_Product__r.id,soli.Colour__c);
                addToCartData.put(soli.Price_Specification_Book_Product__r.id,soli.Colour__c);
                //addToCartData.put(soli.Price_Specification_Book_Product__r.id,new List<String> {soli.Colour__c,soli.Quantity__c});
                addToCartQuantity.put(soli.Price_Specification_Book_Product__r.id,decimal.valueOf(soli.Quantity__c));
                
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
                    pbdata.proAdditionalImgURL = SpilitByCommaSeparator(psbp.Additional_Images__c);
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
                    pbdata.proAdditionalImgURL = SpilitByCommaSeparator(psbp.Additional_Images__c);
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
                    pbdata.proAdditionalImgURL =SpilitByCommaSeparator(psbp.Additional_Images__c);
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
                    pbdata.proAdditionalImgURL =SpilitByCommaSeparator(psbp.Additional_Images__c);
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
        ListOfProductFamily = getPicklistValues(qryPbProWhereClause);  //product family from all the eligible pricebooks
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
        compProdWrap.PcurrList = getDependentPicklistValues(compProdWrap.Ocomp,'Order_Country__c','Preferred_Currency__c');
        compProdWrap.productList=productMap.values();
        //to used in product search to filter by product family
        compProdWrap.productFamilyList = ListOfProductFamily;
        //compProdWrap.tabOverride = selectedTab;   //commented since not to be used
        system.debug('compProdWrap>>>'+compProdWrap);
        return compProdWrap; 
    }
    //sizer selection 
    Public class SizerWrap{
        @AuraEnabled
        Public Map<String ,List<String>> colorSizeDependentList;
        @AuraEnabled
        Public List<Price_Specification_Book_Product__c> sizerList;
        @AuraEnabled
        Public Map<String ,List<String>> sizeColorDependentList;
        @AuraEnabled
        Public Boolean colorPriorityCheck;
        @AuraEnabled
        Public string customerInfoMagnetPrice;
    }
    
    @AuraEnabled
    public static sizerWrap productSizerDetails(String prodname,String retailerCode,String orderToCompany, String preCurrency,String selectedTab)
    {
        SizerWrap sizeWrap=new SizerWrap();
        system.debug('prodname>>>'+prodname);
        system.debug('orderToCompany>>>'+orderToCompany);
        system.debug('preCurrency>>>'+preCurrency);
        contact contactids=UtilityClass.getCurrentUserContact();
        Contact customerInfo=[Select Id,Customer_Information__r.MagNET_Price_Code__c from Contact where Id =:contactids.Id AND Status__c = 'Active'];
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
        
        //getting customer's contact data to get preferred currency and order to company
        Contact con = getcostomerinfo(retailerCode);
        //to get the perticular retailer to set either color dependent size or size dependent color by checking Color_Chart_Priority_Check__c field added by raghu on 17/11/2021 starts 
        Retailer_Code__c colorChartPriorityCheck = [select id,name,Color_Chart_Priority_Check__c from Retailer_Code__c where id=:retailerCode];
            if(colorChartPriorityCheck.Color_Chart_Priority_Check__c == true){
                sizeWrap.colorPriorityCheck = true;
            } else{
                sizeWrap.colorPriorityCheck = false;
            }
        //added by raghu on 17/11/2021 ends
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
        Map<String ,List<String>> productdataziserMap = new  Map<String ,List<String>>();
        Map<String ,List<String>> productdatacolorMap = new  Map<String ,List<String>>();
        String qrysizer;
        if(selectedTab == 'MCare')
        {
          
          qrysizer='select id,name,Color__c,Sizer_Print__c,Product_image_url__c,Additional_Images__c,Description__c,Description2__c,Retailer_Code__r.Full_Box_Order__c,BOX_QTY__c,Customer_Ref_Model__c,Order_to_Company__c,ProductCategory__c,Product_Sub_Category__c,variable_data_product__c,Retailer_Code__c,CurrencyIsoCode,MOQ__c,(select id,name,CurrencyIsoCode,MagNET_Price_Code__c from Price_Product_by_Currency__r) from Price_Specification_Book_Product__c where name=:prodname and Retailer_Code__c=:retailerCode AND variable_data_product__c=\'YES\' AND Active__c = true AND Product_Unique_ID__r.Status__c = \'Active\' AND Hidden_Catalogue__c=false';
        system.debug('qrysizer>>>>>>'+qrysizer);
        }
        else{
         qrysizer='select id,name,Color__c,Sizer_Print__c,Product_image_url__c,Additional_Images__c,Description__c,Description2__c,Retailer_Code__r.Full_Box_Order__c,BOX_QTY__c,Customer_Ref_Model__c,Order_to_Company__c,ProductCategory__c,Product_Sub_Category__c,variable_data_product__c,Retailer_Code__c,CurrencyIsoCode,MOQ__c,(select id,name,CurrencyIsoCode,MagNET_Price_Code__c from Price_Product_by_Currency__r) from Price_Specification_Book_Product__c where name=:prodname and Retailer_Code__c=:retailerCode AND variable_data_product__c=\'YES\' AND ProductCategory__c=\'ACCESSORIES\' AND (Product_Sub_Category__c=\'SIZER\' OR Product_Sub_Category__c=\'STICKER\') AND Active__c = true AND Product_Unique_ID__r.Status__c = \'Active\' AND Hidden_Catalogue__c=false';
  
        }

        if(orderToCompany!=null && orderToCompany!='NULL' && orderToCompany!='' && companyNameandAPI.containskey(orderToCompany))
        {
            orderToCompany=companyNameandAPI.get(orderToCompany);
            qrysizer+=' AND Order_to_Company__c =\''+orderToCompany+'\'';
            system.debug('qrysizer>>'+qrysizer);
        }
        else
        {
            orderToCompany = con.Order_to_Company1__c;
            qrysizer+=' AND Order_to_Company__c =\''+orderToCompany+'\'';       
        }
        /*if(preCurrency!=null && preCurrency!='NULL')
        {
            qrysizer+=' AND id IN(select Price_Book_Product__c from Price_Product_by_Currency__c  where CurrencyIsoCode=\''+preCurrency+'\')';
        }*/
        system.debug('qrysizer>>'+qrysizer);
        sizeWrap.sizerList=Database.query(qrysizer);
        system.debug('sizeWrap.sizerList>>'+sizeWrap.sizerList);
        for(Price_Specification_Book_Product__c psbpsizer : sizeWrap.sizerList)
        {
            System.debug('psbpsizer>>'+psbpsizer);
            if(productdataziserMap.containskey(psbpsizer.Color__c))
            {
                List<String> lstdata=productdataziserMap.get(psbpsizer.Color__c);
                lstdata.add(psbpsizer.Sizer_Print__c);
                system.debug('lstdata>>>'+lstdata);
                lstdata.sort();
                system.debug('lstdatasort>>>'+lstdata);
                productdataziserMap.put(psbpsizer.Color__c,lstdata);
            }
            else
            {
                productdataziserMap.put(psbpsizer.Color__c,new List<String>{psbpsizer.Sizer_Print__c});
            }
            //to get the size dependent color added by raghu on 17/11/2021 starts
            if(productdatacolorMap.containsKey(psbpsizer.Sizer_Print__c))
            {
                List<String> lstdata=productdatacolorMap.get(psbpsizer.Sizer_Print__c);
                lstdata.add(psbpsizer.Color__c);
                system.debug('lstdata>>>'+lstdata);
                lstdata.sort();
                system.debug('lstdatasort>>>'+lstdata);
                productdatacolorMap.put(psbpsizer.Sizer_Print__c,lstdata);

            } else {
                productdatacolorMap.put(psbpsizer.Sizer_Print__c,new List<String>{psbpsizer.Color__c});
            }
            //added by raghu on 17/11/2021 ends
        }
        
        system.debug('productdataziserMap>>>'+productdataziserMap);
        system.debug('productdatacolorMap>>>'+productdatacolorMap);
        sizeWrap.colorSizeDependentList=productdataziserMap;
        sizeWrap.sizeColorDependentList = productdatacolorMap;
        sizeWrap.customerInfoMagnetPrice = customerInfo.Customer_Information__r.MagNET_Price_Code__c;
        system.debug('sizeWrap.customerInfoMagnetPrice>>>'+sizeWrap.customerInfoMagnetPrice);
        return sizeWrap;
    }
    //Commented By Bharath Reddy On 26/11/2021 ,Because string type Parameter is not fectching the customerid value
   // public static Integer getCartDataCount(String customerid)
     @AuraEnabled(cacheable=true)
        public static Integer getCartDataCount(Id customerid)
    {
        System.debug('customerid'+customerid);
        Integer count= SOController.getAllCartDetails(customerid).size();
        system.debug('count>>>'+count);
        return count;
    }

    @AuraEnabled
    public static Retailer_Code__c getRetailerMsg(String retailerId){
        try {
            //Added by Akhilesh Nov 2022 order of the check box and msg to be maintained checkbox - msg
             List<Retailer_Code__c> retailerMsg =[SELECT Catalog_Msg_UI_Hangers_Accessories__c,Catalog_Msg_Hangers_Accessories__c, Catalog_Msg_UI_Labels_Tickets__c, Catalog_Msg_Labels_Tickets__c, Catalog_Msg_UI_Flexible_Packaging__c,  Catalog_Msg_Flexible_Packaging__c, Catalog_Msg_UI_Intelligent_Solutions__c, Catalog_Msg_Intelligent_Solutions__c, Catalog_Msg_UI_Structural_Packaging__c, Catalog_Msg_Structural_Packaging__c,  Catalog_Msg_UI_MCare__c, Catalog_Msg_MCare__c from Retailer_Code__c where id =:retailerId LIMIT 1];
            return retailerMsg[0];
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static List<Sales_Order_Line_Items__c> getSizerList(String  retailercode,String customerid, String prodName)
    {
        system.debug('retailercode>>>'+retailercode);
        system.debug('customerid>>>'+customerid);
        return [select id,name,Colour__c,Quantity__c,Size__c,Print__c,Sales_Order__c,Price_Specification_Book_Product__r.id,Customer_Ref_Model__c,Mainetti_Model_Code__c,Added_As_a_Label__c,BOX_QTY__c,Full_Box_Order__c,Business_Vertical__c from Sales_Order_Line_Items__c where Sales_Order__r.Retailer_Code1__c=:retailerCode AND Sales_Order__r.Supplier__c=:customerid and Added_As_a_Label__c=true];//And Products__r.Mainetti_Model__c=:prodName
    }
    @AuraEnabled
    public static string addSizerToCart(String retailercode,String customerid)
    {
        String prodName = '';
        List<Sales_Order_Line_Items__c> sizrList=getSizerList(retailercode,customerid,prodName);
        System.debug('sizrList.size()>>'+sizrList.size());
        if(sizrList.size()>0)
        {
            for(Sales_Order_Line_Items__c sizer:sizrList)
            {
                sizer.Added_As_a_Label__c=false;
            }
            update sizrList;
        }
        return 'SUCCESS';
    }
    //Get Contact Related Retailer List.
    @AuraEnabled
    public static List<Retailer_Code__c> retailerCodeDisplay()
    {
        List<Retailer_Code__c> crrlist=UtilityClass.getContactRelatedRetailer();
        
        return crrlist;
    } 
    //Delete function for soli
    @AuraEnabled
    public static void deletedSOLI(Id soliIdToDelete)    
    {
        if(soliIdToDelete!=null)
        {
            Sales_Order_Line_Items__c soli=new Sales_Order_Line_Items__c(id=soliIdToDelete);
            system.debug('soli>>>'+soli);
            delete soli;
            system.debug('soli>>>'+soli);
        }
    }
    
    //Get Current User Details.
    @AuraEnabled(cacheable=true)
    public static contact getcostomerinfo(String retailerCode)
    {
        system.debug('retailerCode getcostomerinfo:::'+retailerCode);
        contact contactid=UtilityClass.getCurrentUserContact();

      // contact contactid=[select Id,Name,Order_to_Company__c,Order_to_Company1__c,Status__c,AccountId,Account_Record_Type_Id__c,Preferred_Currency__c,Email,HasOptedOutOfEmail,Customer_Information__c,Customer_Related_Retailer__c From Contact where id='003O000001bGbw2IAC'];
        system.debug('contactid getcostomerinfo'+contactid);
        
        
        for(Retailer_Related_Data__c rrd:[Select Id,Order_to_Company__c,Preferred_Currency__c from Retailer_Related_Data__c where ContactID__c =:contactid.Id AND Status__c = 'Active' AND Retailer_Code__c =:retailerCode ])
        {
            system.debug('rrd getcostomerinfo'+rrd);
            //contactid.Order_to_Company1__c=companyNameandAPI.get(contactid.Order_to_Company1__c);
            contactid.Order_to_Company__c=rrd.Order_to_Company__c;
            contactid.Preferred_Currency__c=rrd.Preferred_Currency__c;
            
        }
        system.debug('contactid>> getcostomerinfo >>'+contactid);
        //to get API names
        Map<String,String> companyNameandAPI = UtilityClass.getOrderToCompanyPicklist(false);
        Map<String,String> currencyNameandAPI = UtilityClass.getPreferredCurrencyPicklist(false);
        
        for(String comp:companyNameandAPI.keyset())
        {
            system.debug('comp name>>>>>>'+comp);
            system.debug('contactid.Order_to_Company1__c >>'+contactid.Order_to_Company1__c);
             system.debug('contactid.Order_to_Company__c >>'+contactid.Order_to_Company__c);
        }
        
        if(companyNameandAPI.containskey(contactid.Order_to_Company__c))
        {
            contactid.Order_to_Company1__c=companyNameandAPI.get(contactid.Order_to_Company1__c);
              system.debug('contactid.Order_to_Company1__c >>'+contactid.Order_to_Company1__c);
            contactid.Order_to_Company__c=companyNameandAPI.get(contactid.Order_to_Company__c);
              system.debug('contactid.Order_to_Company__c >>'+contactid.Order_to_Company__c);
        }
        system.debug('contactid>>>>>>'+contactid);
        
        return contactid;
    }
    
     @AuraEnabled
    public static Retailer_Related_Data__c getcostomerRetailerData(String retailerCode)
    {
        system.debug('retailerCode getcostomerinfo:::'+retailerCode);
        contact contactid=UtilityClass.getCurrentUserContact();
        system.debug('contactid getcostomerinfo'+contactid);
        
        Retailer_Related_Data__c rrdval =[Select Id,Order_to_Company__c,Preferred_Currency__c from Retailer_Related_Data__c where ContactID__c =:contactid.Id AND Status__c = 'Active' AND Retailer_Code__c =:retailerCode order by CreatedDate desc limit 1];
          system.debug('rrdval getcostomerinfo'+rrdval);
     
        return rrdval;
    }
    
    //Store Sales Order Based on Retailer.
    @AuraEnabled
    public static Sales_Order__c checkRetailerInSO(String customerid)
    {
        Sales_Order__c cartSO=UtilityClass.getSORecordAsCart(customerid);
        system.debug('cartSO'+cartSO);
        if(cartSO.Id != null)
        {
            return cartSO;
            
        }
        else
            return null;
    }
    
    //Get Product Family List
    @AuraEnabled
    public static List<String> getPicklistValues(String queryWhereClause)
    { 
        system.debug('queryWhereClause>>>>>>'+queryWhereClause);
        Set<String> proFamily= new Set<String>();
        /*for(Price_Specification_Book_Product__c psbp: [select Name,Product_Unique_ID__c,Product_Family__c,Retailer_Code__c from Price_Specification_Book_Product__c where Active__c = true AND Retailer_Code__c=: retailerCode AND Product_Unique_ID__r.Business_Vertical__c =: vertical])
			{
				//proFamily.add(psbp.Product_Family__c);
		}*/
        if(queryWhereClause.contains('AND Product_Family__c ='))
        {
            integer firstIndex = queryWhereClause.indexOf('AND Product_Family__c');
            system.debug('firstIndex>>>>>'+firstIndex);
            String secString = queryWhereClause.substring(firstIndex+1);
            system.debug('secString>>>>>'+queryWhereClause.substring(firstIndex+1));
            integer lastIndex = secString.indexOf('\' AND');
            //system.debug('lastIndex>>>>>'+lastIndex);
            queryWhereClause = queryWhereClause.substring(0,firstIndex);
            //system.debug('queryWhereClause>>>>>'+queryWhereClause);
            //system.debug('secString.substringlastIndex>>>>>'+secString.substring(lastIndex));
            queryWhereClause = queryWhereClause + secString.substring(lastIndex+1);
            system.debug('queryWhereClause 2 nd last >>'+queryWhereClause);
        }
        String qryPbProFamily='select Name,Product_Family__c from Price_Specification_Book_Product__c'+queryWhereClause;
        system.debug('qryPbProFamily>>>>>>'+qryPbProFamily);
        List<Price_Specification_Book_Product__c> listofPriceBookProd = (Database.query(qryPbProFamily));   //to get unique names of products with given limit in query
        system.debug('listofprod>>>>>>'+listofPriceBookProd.size());
        for(Price_Specification_Book_Product__c psbp: listofPriceBookProd)
        {
            proFamily.add(psbp.Product_Family__c);
        }
        
        List<String> ListOfProductFamily = new List<String>();
        ListOfProductFamily.addAll(proFamily);
        return ListOfProductFamily;
    }
    
    @AuraEnabled
    public static List<string> getDependentPicklistValues(String controllingValue, String controllingFields, String dependentField)
    {
        List<string> listValues = new List<string>();
        
        listValues = SOController.DependentPicklist(controllingValue,controllingFields,dependentField);
        
        return listValues;
    }
    
    // code to save SO and SOLI(Cart record type) by chandana 
    @AuraEnabled
    public static string saveSO(id customerData,id retailercode, string quantity,id priceBookProId,id priceByCurr,string custRefModel,string selectedCurrency,String searchedCurrency)
    {
        system.debug('customerData==='+customerData);
        system.debug('retailerData==='+retailercode);
        system.debug('priceBookProId==='+priceBookProId);
        system.debug('quantity==='+quantity);
         system.debug('priceByCurr==='+priceByCurr);
        String res = SOController.saveCart(customerData,retailercode,quantity,priceBookProId,priceByCurr,custRefModel,selectedCurrency,searchedCurrency);
        return res;
    } 
    
      @AuraEnabled
    public static string saveSOMcare(id customerData,id retailercode, string quantity,id priceBookProId,id priceByCurr,string custRefModel,string selectedCurrency)
    {
        /*system.debug('customerData==='+customerData);
        system.debug('retailerData==='+retailercode);
        system.debug('priceBookProId==='+priceBookProId);
        system.debug('quantity==='+quantity);
         system.debug('priceByCurr==='+priceByCurr);*/
        String res = SOControllerMCare.saveCart(customerData,retailercode,quantity,priceBookProId,priceByCurr,custRefModel,selectedCurrency);
        return res;
    }
    
    
    /*Added by seema for bulk add to cart: --START--*/
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
        String res = SOController.saveBulkCart(custid,retailerCodeId,bulkCartDataToSaveDes,selectedCurrency,searchedCurrency);
        system.debug('res>>'+res);
        return res;
    }
    /*Bulk add to cart: --END--*/
    //Sizer add to cart/list
    @AuraEnabled
    public static string addSizerProduct(String obj,string addTo,string selectedCurrency,String searchedCurrency)
    {
        SizerAddToCartWrap sizerCartDataToSaveDes =(SizerAddToCartWrap)JSON.deserialize(obj , SizerAddToCartWrap.class);
        system.debug('sizerCartDataToSaveDes>>'+sizerCartDataToSaveDes);
        addTo='';
        String res = SOController.saveSizerCart(sizerCartDataToSaveDes,addTo,selectedCurrency,searchedCurrency);
        return res;
    }
    @AuraEnabled
    public static void deleteRow(String idTODalete)
    {
        system.debug('idTODalete>>'+idTODalete);
        Sales_Order_Line_Items__c soli=[select id,Sales_Order__c from Sales_Order_Line_Items__c where id=:idTODalete];
        String soId=soli.Sales_Order__c;
        delete soli;
        Sales_Order__c soData=new Sales_Order__c();
        soData=[select id,(select id from Sales_Order_Line_Items__r) from Sales_Order__c where id=:soId];
        if(soData.Sales_Order_Line_Items__r.size()==0)
        {
            delete soData;
        }
    }
    //Check cart length to show count
    @AuraEnabled
    public static List<SOController.SOLIWrapper> CheckCartDetailsForUpdate(id customerid)
    {
        List<SOController.SOLIWrapper> res = SOController.getAllCartDetails(customerid);
        return res;
    }
    // code to split additonal Images with comma separator by siva 
    public static List<String> SpilitByCommaSeparator(String value){        
        if(value !=null)
            return value.split(',');
        else
            return null;
    }
    
     //method for documents in quick view
    @AuraEnabled
    public static List<ContentDocumentLink> getDocCustomNotesAttachRetailer(String ProductName)
    {
        system.debug('ProductName>>>>'+ProductName);
        contact contactid=UtilityClass.getCurrentUserContact();
        //system.debug('contactidgetcostomerinfo>>'+contactid.Customer_Information__c);
        Set<Id> MDIdList = new Set<Id>();
        Set<Id> RRDIdList = new Set<Id>();
       // List<Retailer_Related_Data__c> RRDList = [SELECT Id,Retailer_Code__c,Customer_Information__c FROM Retailer_Related_Data__c WHERE Customer_Information__c =:contactid.Customer_Information__c];
       // for(Retailer_Related_Data__c RRDObj : RRDList){
            //RRDIdList.add(RRDObj.Retailer_Code__c);
       // }
        Price_Specification_Book_Product__c PSBP = [SELECT Product_Unique_ID__c from Price_Specification_Book_Product__c where id=:ProductName];
       // List<Mainetti_Document__c> attachments = [SELECT id,Name,Product__c FROM Mainetti_Document__c  where Active__c=true and Retailer_Code__c IN : RRDIdList and Product_do_not_use__c=:ProductName];
         List<Mainetti_Document__c> attachments = [SELECT id,Name,Product__c FROM Mainetti_Document__c  where Product_Unique_ID__c=:PSBP.Product_Unique_ID__c]; 
         system.debug('attachments>>>>'+attachments);
        for(Mainetti_Document__c attachmentsList : attachments){
            MDIdList.add(attachmentsList.Id);
        }
        //List<Attachment> attachments1 = [SELECT Id, Name, Body, ContentType FROM Attachment WHERE Parentid =:attachments.id]; 
        List<ContentDocumentLink> filelist=[SELECT Id, LinkedEntityId, ContentDocumentId, Visibility, IsDeleted, ShareType,
                                            ContentDocument.Title,ContentDocument.LatestPublishedVersionId, ContentDocument.createdDate, ContentDocument.FileType
                                            FROM ContentDocumentLink 
                                            WHERE LinkedEntityId IN : MDIdList ORDER BY ContentDocument.Title ASC];
        system.debug('filelist>>>>>'+filelist);
        
        return filelist;
    }
    
    //Method to return Retailer Id From the Sales Order Record Page
       @AuraEnabled
    public static Sales_Order__c getSORetailerCode(String SOID)
    {
      // Revise_Order__c reviseOrder =[select id , Mainetti_SO__c ,Mainetti_SO__r.Retailer_Code2__c ,Order_to_Company__c ,CurrencyIsoCode, Reason_to_Cancel__c from Revise_Order__c where Mainetti_SO__c =:SOID and Reason_to_Cancel__c IN ('Revise Currency','Revise Order To Company')];
           //System.debug('reviseOrder :::'+reviseOrder.Mainetti_SO__r.Retailer_Code2__c);
          Sales_Order__c salesOrder =[select id,Name,Company__c,Revise_Version__c,Retailer_Code2__c,CurrencyIsoCode from Sales_Order__c where id=:SOID];
      return salesOrder;
    }
    
    
    
     @AuraEnabled
    public static List<Revise_Order__c> getRODataTableValues()
    {
       List<Revise_Order__c> reviseOrder =[select id ,Name,Status__c,Mainetti_SO__c,Mainetti_SO__r.Name,Revise_Order_To_Company__c,Revise_Currency__c from Revise_Order__c where Status__c = 'Approve Pending' and Reason_to_Cancel__c IN ('Revise Currency','Revise Order To Company') AND (Revise_Order_To_Company__c <> null OR Revise_Currency__c <> null)];
       System.debug('reviseOrder :::'+reviseOrder);
      return reviseOrder;
    }
    
        
        
        //Method To Update the Sales order and Sales Order Line Item ,for Admin Revise Request
    @AuraEnabled
    public static Boolean updateRevisedSO(string roId,String SOID ,String SelectedPiklistCompany , String SelectedPiklistCurrency, string adminRemarks)
    {

        Boolean Status;
        List<Sales_Order_Line_Items__c> SOLIToUpdate = new List<Sales_Order_Line_Items__c>();
        Sales_Order__c SOToUpdate = new Sales_Order__c();
        List<Sales_Order_Line_Items__c> SOLI = new List<Sales_Order_Line_Items__c>();
        Set<String> SOLIIDSet = new Set<String>();
        Set<String> psbpIDSet = new Set<String>();
        Set<String> SOLICustModelRefSet = new Set<String>();
        Set<String> SOLIPriceModelRefSet = new Set<String>();
        List<Price_Specification_Book_Product__c> priceBookProList = new List<Price_Specification_Book_Product__c>();
        Map<String ,Price_Specification_Book_Product__c> pbspMap = new Map<String ,Price_Specification_Book_Product__c>();
        List<Price_Product_by_Currency__c> priceProCurrencyList = new List<Price_Product_by_Currency__c>();
        Map<String ,Price_Product_by_Currency__c> PPCMap = new Map<String ,Price_Product_by_Currency__c>();
        Map<String,Price_Product_by_Currency__c> pbIdSpecialDiscountPriceMap = new Map<String,Price_Product_by_Currency__c>();  //Key=> Product ID and Value => magnet Price code for Customer
        Map<String,String> customerRefModelAndColor = new Map<String,String>();
        System.debug('SOID :::'+SOID);
        System.debug('SelectedPiklistCompany :::'+SelectedPiklistCompany);
        System.debug('SelectedPiklistCurrency :::'+SelectedPiklistCurrency);
        System.debug('roId :::'+roId);
        Revise_Order__c ReviseObj = [SELECT Id,name,Status__c,Admin_Remarks__c from Revise_Order__c where id=:roId];

        Sales_Order__c salesOrder =[select id,Name,Retailer_Code1__c,CurrencyIsoCode from Sales_Order__c where id=:SOID];
        system.debug('salesOrder ::'+salesOrder);
        SOLI = [Select Id,Name ,Colour__c, Status__c,CurrencyIsoCode,Customer_Ref_Model__c, Sales_Order__c,Price_100_pcs__c,Price_1000_pcs__c,Price_Specification_Book_Product__c,CreatedById From Sales_Order_Line_Items__c where Sales_Order__c =: SOID];
        system.debug('SOLI ::'+SOLI);
        user createdUser = [select contactId from user where Id=:SOLI[0].CreatedById];
        system.debug('createdUser>>'+createdUser);
        list<contact> customerInfo = [select Id,Customer_Information__r.MagNET_Price_Code__c from contact where Id=:createdUser.contactId];
        system.debug('customerInfo>>'+customerInfo);
        String customerMagnetPriceCode = '';
        if(customerInfo.size() > 0){
            if(customerInfo[0].Customer_Information__r.MagNET_Price_Code__c !=null){
                customerMagnetPriceCode = customerInfo[0].Customer_Information__r.MagNET_Price_Code__c;
            }
            else{
                customerMagnetPriceCode = '';
            }
        }
        for(Sales_Order_Line_Items__c SOLIList :SOLI){
            SOLIIDSet.add(SOLIList.id);
            SOLICustModelRefSet.add(SOLIList.Customer_Ref_Model__c);
            SOLIPriceModelRefSet.add(SOLIList.Price_Specification_Book_Product__c);
            customerRefModelAndColor.put((SOLIList.Customer_Ref_Model__c).toUpperCase()+'#'+(SOLIList.Colour__c).toUpperCase(),(SOLIList.Customer_Ref_Model__c).toUpperCase()+'#'+(SOLIList.Colour__c).toUpperCase());
              }
        system.debug('SOLIIDSet ::'+SOLIIDSet);
        system.debug('SOLICustModelRefSet ::'+SOLICustModelRefSet);
        
        // To Update Order To company , Currency , Local_SKU__c ,Price_Product_by_Currency__c ,BOX_QTY__c , Price_100_pcs__c and Price_1000_pcs__c
        if(!string.isBlank(SelectedPiklistCompany)){ 
            
             salesOrder.Company__c =  SelectedPiklistCompany;
       
            priceBookProList = [select Id,Name, Product_Unique_ID__c, Order_to_Company__c, Retailer_Code__c, Retailer_Code__r.name, Local_SKU__c, BOX_QTY__c, Customer_Ref_Model__c,Color__c from Price_Specification_Book_Product__c where Active__c = true and  Product_Unique_ID__r.Status__c=:'Active' and Order_to_Company__c =:SelectedPiklistCompany AND Customer_Ref_Model__c IN: SOLICustModelRefSet and Retailer_Code__c =:salesOrder.Retailer_Code1__c];
            system.debug('priceBookProList ::'+priceBookProList);
            for(Price_Specification_Book_Product__c priceBookProListVal :priceBookProList){
                if(customerRefModelAndColor.containsKey((priceBookProListVal.Customer_Ref_Model__c).toUpperCase()+'#'+(priceBookProListVal.Color__c).toUpperCase())){
                    pbspMap.put(priceBookProListVal.Customer_Ref_Model__c,priceBookProListVal);//Map Containing Price specification Book Products Customer_Ref_Model__c and Price specification Book Products Records
                    psbpIDSet.add(priceBookProListVal.Id);
                }
            }
            system.debug('pbspMap ::'+pbspMap);
            system.debug('psbpIDSet ::'+psbpIDSet);
            
            priceProCurrencyList = [Select Id ,Name,Price_100_pcs__c,Price_1000_pcs__c,UOM_Price__c,Price_Book_Product__c,MagNET_Price_Code__c From Price_Product_by_Currency__c where CurrencyIsoCode =:SelectedPiklistCurrency.substring(0,3) and Price_Book_Product__c IN:psbpIDSet];
            system.debug('priceProCurrencyList ::'+priceProCurrencyList);
            for(Price_Product_by_Currency__c priceProCurrencyListVal :priceProCurrencyList){
                //if(customerInfo.size() > 0){
                    if(customerMagnetPriceCode != '' && priceProCurrencyListVal.MagNET_Price_Code__c == customerMagnetPriceCode){
                        pbIdSpecialDiscountPriceMap.put(priceProCurrencyListVal.Price_Book_Product__c,priceProCurrencyListVal);
                    }
                    else if(priceProCurrencyListVal.MagNET_Price_Code__c == null){
                        PPCMap.put(priceProCurrencyListVal.Price_Book_Product__c,priceProCurrencyListVal);//Map Containing Price specification Book Products Id and Price Product By currency record 
                    }
                //}
            }
            system.debug('PPCMap ::'+PPCMap);
            for(Sales_Order_Line_Items__c SOLIList :SOLI){
                SOLIList.CurrencyIsoCode = SelectedPiklistCurrency.substring(0,3); 
                SOLIList.Price_Specification_Book_Product__c = pbspMap.get(SOLIList.Customer_Ref_Model__c).Id;
                SOLIList.BOX_QTY__c = pbspMap.get(SOLIList.Customer_Ref_Model__c).BOX_QTY__c;
                SOLIList.Local_SKU__c = pbspMap.get(SOLIList.Customer_Ref_Model__c).Local_SKU__c; 
                system.debug('pbspMap.get(SOLIList.Customer_Ref_Model__c).Id ::::'+pbspMap.get(SOLIList.Customer_Ref_Model__c).Id);
                if(pbIdSpecialDiscountPriceMap.containsKey(pbspMap.get(SOLIList.Customer_Ref_Model__c).Id)){
                    SOLIList.Price_Product_by_Currency__c = pbIdSpecialDiscountPriceMap.get(pbspMap.get(SOLIList.Customer_Ref_Model__c).Id).Id;
                    SOLIList.Price_100_pcs__c = String.valueOf(pbIdSpecialDiscountPriceMap.get(pbspMap.get(SOLIList.Customer_Ref_Model__c).Id).Price_100_pcs__c);
                    SOLIList.Price_1000_pcs__c = String.valueOf(pbIdSpecialDiscountPriceMap.get(pbspMap.get(SOLIList.Customer_Ref_Model__c).Id).Price_1000_pcs__c);
                }
                else if(PPCMap.containsKey(pbspMap.get(SOLIList.Customer_Ref_Model__c).Id)){
                    SOLIList.Price_Product_by_Currency__c = PPCMap.get(pbspMap.get(SOLIList.Customer_Ref_Model__c).Id).Id;
                	SOLIList.Price_100_pcs__c = String.valueOf(PPCMap.get(pbspMap.get(SOLIList.Customer_Ref_Model__c).Id).Price_100_pcs__c);
                	SOLIList.Price_1000_pcs__c = String.valueOf(PPCMap.get(pbspMap.get(SOLIList.Customer_Ref_Model__c).Id).Price_1000_pcs__c);
                }
                else{
                    SOLIList.Price_Product_by_Currency__c = null;
                            SOLIList.Price_100_pcs__c = '0.00';
                            SOLIList.Price_1000_pcs__c = '0.00';
                }
                SOLIToUpdate.add(SOLIList);
            }
            
            system.debug('SOLIToUpdate ::'+SOLIToUpdate);
        }
        // To Update  Currency , Price_Product_by_Currency__c , Price_100_pcs__c and Price_1000_pcs__c
        else if(string.isBlank(SelectedPiklistCompany)){
            
            priceBookProList = [select Id,Name, Product_Unique_ID__c, Order_to_Company__c, Retailer_Code__c, Retailer_Code__r.name, Local_SKU__c, BOX_QTY__c, Customer_Ref_Model__c,Color__c from Price_Specification_Book_Product__c where Active__c = true and  Product_Unique_ID__r.Status__c=:'Active' AND Id IN: SOLIPriceModelRefSet and Retailer_Code__c =:salesOrder.Retailer_Code1__c ];
            system.debug('priceBookProList ::'+priceBookProList);
            for(Price_Specification_Book_Product__c priceBookProListVal :priceBookProList){
                //if(customerRefModelAndColor.containsKey((priceBookProListVal.Customer_Ref_Model__c).toUpperCase()+'#'+(priceBookProListVal.Color__c).toUpperCase())){
                    pbspMap.put(priceBookProListVal.Customer_Ref_Model__c,priceBookProListVal);//Map Containing Price specification Book Products Customer_Ref_Model__c and Price specification Book Products Records
                    psbpIDSet.add(priceBookProListVal.Id);
                //}
            }
            system.debug('pbspMap ::'+pbspMap);
            system.debug('psbpIDSet ::'+psbpIDSet);
            
            priceProCurrencyList = [Select Id ,Name,Price_100_pcs__c,Price_1000_pcs__c,UOM_Price__c,Price_Book_Product__c,MagNET_Price_Code__c From Price_Product_by_Currency__c where CurrencyIsoCode =:SelectedPiklistCurrency.substring(0,3) and Price_Book_Product__c IN:psbpIDSet];
            system.debug('priceProCurrencyList ::'+priceProCurrencyList);
            for(Price_Product_by_Currency__c priceProCurrencyListVal :priceProCurrencyList){
                //if(customerInfo.size() > 0){
                    if(customerMagnetPriceCode != '' && priceProCurrencyListVal.MagNET_Price_Code__c == customerMagnetPriceCode){
                        pbIdSpecialDiscountPriceMap.put(priceProCurrencyListVal.Price_Book_Product__c,priceProCurrencyListVal);
                    }
                    else if(priceProCurrencyListVal.MagNET_Price_Code__c == null){
                        PPCMap.put(priceProCurrencyListVal.Price_Book_Product__c,priceProCurrencyListVal);//Map Containing Price specification Book Products Id and Price Product By currency record
                    }
                //}
                
            }
            system.debug('PPCMap ::'+PPCMap);
            for(Sales_Order_Line_Items__c SOLIList :SOLI){
                SOLIList.CurrencyIsoCode = SelectedPiklistCurrency.substring(0,3);
                  if(pbIdSpecialDiscountPriceMap.containsKey(pbspMap.get(SOLIList.Customer_Ref_Model__c).Id)){
                    SOLIList.Price_Product_by_Currency__c = pbIdSpecialDiscountPriceMap.get(pbspMap.get(SOLIList.Customer_Ref_Model__c).Id).Id;
                    SOLIList.Price_100_pcs__c = String.valueOf(pbIdSpecialDiscountPriceMap.get(pbspMap.get(SOLIList.Customer_Ref_Model__c).Id).Price_100_pcs__c);
                    SOLIList.Price_1000_pcs__c = String.valueOf(pbIdSpecialDiscountPriceMap.get(pbspMap.get(SOLIList.Customer_Ref_Model__c).Id).Price_1000_pcs__c);
                }
               else if(PPCMap.containsKey(pbspMap.get(SOLIList.Customer_Ref_Model__c).Id)){
                    SOLIList.Price_Product_by_Currency__c = PPCMap.get(pbspMap.get(SOLIList.Customer_Ref_Model__c).Id).Id;
                	SOLIList.Price_100_pcs__c = String.valueOf(PPCMap.get(pbspMap.get(SOLIList.Customer_Ref_Model__c).Id).Price_100_pcs__c);
                	SOLIList.Price_1000_pcs__c = String.valueOf(PPCMap.get(pbspMap.get(SOLIList.Customer_Ref_Model__c).Id).Price_1000_pcs__c);
                }
                else{
                    SOLIList.Price_Product_by_Currency__c = null;
                            SOLIList.Price_100_pcs__c = '0.00';
                            SOLIList.Price_1000_pcs__c = '0.00';
                }
                SOLIToUpdate.add(SOLIList);
            }
            
            system.debug('SOLIToUpdate ::'+SOLIToUpdate);
            
        }  
         salesOrder.CurrencyIsoCode =  SelectedPiklistCurrency.substring(0,3);
        salesOrder.Status__c = 'Order Submitted';
        system.debug('salesOrder :::'+salesOrder);
        // update salesOrder;

        ReviseObj.Status__c = 'Approved';
        ReviseObj.Admin_Remarks__c = adminRemarks;
        update ReviseObj;
        
        //To Update Sales Order and Sales Order LineItem
       // Savepoint sp = Database.setSavepoint();
          update salesOrder;
          update SOLIToUpdate;
         //  Database.rollback(sp);
        return Status;
        
    }
    @AuraEnabled
    public static void ActivateData(String SOID ,String SelectedPiklistCompany ,string reviseVersionNum, String SelectedPiklistCurrency,string reviseReason, String reviseReasonText) 
    {
        if(SOID != null && SelectedPiklistCompany != null && SelectedPiklistCurrency!=null && reviseReason !=null){
            Revise_Order__c ReviseObj = new Revise_Order__c();  
            ReviseObj.Reason_to_Cancel__c = reviseReason;
            ReviseObj.Revise_Currency__c = SelectedPiklistCurrency;
            ReviseObj.Revise_Order_To_Company__c = SelectedPiklistCompany;
            ReviseObj.Mainetti_SO__c = SOID;
            ReviseObj.Status__c = 'Approve Pending';
            ReviseObj.Sales_Team_Remarks__c = reviseReasonText;
            ReviseObj.Revise_req_Version__c = Integer.valueOf(reviseVersionNum)+1;
            insert ReviseObj;
            //to update revise version of sales order with latest revise order version
            Sales_Order__c salesOrder =[select id,Retailer_Code2__c from Sales_Order__c where id=:SOID];
            salesOrder.Revise_Version__c = ReviseObj.Revise_req_Version__c;
            update salesOrder;
        }
    }
    @AuraEnabled
    public static adminReviseReq reviseOrderData(String roId) 
    {
         Set<String> SOLIIDSet = new Set<String>();
        Set<String> psbpIDSet = new Set<String>();
        Set<String> SOLICustModelRefSet = new Set<String>();
        Set<String> SOLIPriceModelRefSet = new Set<String>();
        List<Price_Specification_Book_Product__c> priceBookProList = new List<Price_Specification_Book_Product__c>();
        Map<String ,Price_Specification_Book_Product__c> pbspMap = new Map<String ,Price_Specification_Book_Product__c>();
        List<Price_Product_by_Currency__c> priceProCurrencyList = new List<Price_Product_by_Currency__c>();
        Map<String ,Price_Product_by_Currency__c> PPCMap = new Map<String ,Price_Product_by_Currency__c>();
		Map<String,Price_Product_by_Currency__c> pbIdSpecialDiscountPriceMap = new Map<String,Price_Product_by_Currency__c>();  //Key=> Product ID and Value => magnet Price code for Customer
        Revise_Order__c reviseOrderObj;
        Map<String,String> customerRefModelAndColor = new Map<String,String>();
        List<Sales_Order_Line_Items__c> soli= new List<Sales_Order_Line_Items__c>();
        List<Sales_Order_Line_Items__c> soliNew= new List<Sales_Order_Line_Items__c>();
        adminReviseReq reviseReqValues = new adminReviseReq();
        list<Sales_Order_Line_Items__c> newSolItem = new list<Sales_Order_Line_Items__c>();
        if(roId !=null){
            reviseOrderObj = [SELECT Id,Name,Order_to_Company__c,Mainetti_SO__c,Mainetti_SO__r.name,Mainetti_SO__r.OrderSource__c,Mainetti_SO__r.CurrencyIsoCode,CurrencyIsoCode,Revise_Order_To_Company__c,Revise_Currency__c from Revise_Order__c where Id=:roId];
            system.debug('reviseOrderObj>>'+reviseOrderObj);
            soli = [select Id,name,Customer_Ref_Model__c,Colour__c,Size__c,CurrencyIsoCode,Local_SKU__c,Price_Specification_Book_Product__c,Price_Specification_Book_Product__r.Name,Price_Product_by_Currency__r.Name,Price_100_pcs__c,Price_1000_pcs__c,Sales_Order__r.Retailer_Code1__c,CreatedById from Sales_Order_Line_Items__c where Sales_Order__c=:reviseOrderObj.Mainetti_SO__c];
            soliNew = soli.deepclone(false,false,true);
            reviseReqValues.oldSoli = soliNew;
            system.debug('reviseReqValues.oldSoli>>'+reviseReqValues.oldSoli);
            reviseReqValues.reviseOrderObj = reviseOrderObj;
            user createdUser = [select Name,contactId from user where Id=:SOLI[0].CreatedById];
            reviseReqValues.createduser = createdUser;
        	List<contact> customerInfo = [select Id,Name,Customer_Information__c,Customer_Information__r.Name,Customer_Information__r.MagNET_Price_Code__c from contact where Id=:createdUser.contactId];
            String customerMagnetPriceCode = '';
            system.debug(createdUser.contactId);
            system.debug(createdUser.contactId);
            system.debug(customerInfo);
            system.debug(customerInfo.size() > 0);
            if(customerInfo.size() > 0){
                reviseReqValues.contactName = customerInfo[0];
                if(customerInfo[0].Customer_Information__r.MagNET_Price_Code__c !=null){
                    customerMagnetPriceCode = customerInfo[0].Customer_Information__r.MagNET_Price_Code__c;
                }
                else{
                    customerMagnetPriceCode = '';
                }
                
            }
            for(Sales_Order_Line_Items__c SOLIList :soli){
            	SOLIIDSet.add(SOLIList.id);
            	SOLICustModelRefSet.add(SOLIList.Customer_Ref_Model__c);
            	SOLIPriceModelRefSet.add(SOLIList.Price_Specification_Book_Product__c);
                customerRefModelAndColor.put((SOLIList.Customer_Ref_Model__c).toUpperCase()+'#'+(SOLIList.Colour__c).toUpperCase(),(SOLIList.Customer_Ref_Model__c).toUpperCase()+'#'+(SOLIList.Colour__c).toUpperCase());
              }
            system.debug('customerRefModelAndColor>>'+customerRefModelAndColor);
            system.debug('SOLIIDSet>>'+SOLIIDSet);
            system.debug(customerMagnetPriceCode);
            system.debug('SOLICustModelRefSet>>'+SOLICustModelRefSet);
            system.debug('SOLIPriceModelRefSet>>'+SOLIPriceModelRefSet);
            if(!string.isBlank(reviseOrderObj.Revise_Order_To_Company__c)){ 
                
            priceBookProList = [select Id,Name, Product_Unique_ID__c, Order_to_Company__c, Retailer_Code__c, Retailer_Code__r.name, Local_SKU__c, BOX_QTY__c, Customer_Ref_Model__c,Color__c from Price_Specification_Book_Product__c where Active__c = true and  Product_Unique_ID__r.Status__c='Active' and Order_to_Company__c =:reviseOrderObj.Revise_Order_To_Company__c AND Customer_Ref_Model__c IN: SOLICustModelRefSet and Retailer_Code__c =:soli[0].Sales_Order__r.Retailer_Code1__c ];
            system.debug('priceBookProList ::'+priceBookProList);
            for(Price_Specification_Book_Product__c priceBookProListVal :priceBookProList){
                if(customerRefModelAndColor.containsKey((priceBookProListVal.Customer_Ref_Model__c).toUpperCase()+'#'+(priceBookProListVal.Color__c).toUpperCase())){
                   pbspMap.put(priceBookProListVal.Customer_Ref_Model__c,priceBookProListVal);//Map Containing Price specification Book Products Customer_Ref_Model__c and Price specification Book Products Records
                	psbpIDSet.add(priceBookProListVal.Id); 
                    system.debug('pbspMap>>'+pbspMap);
                }
            }
            system.debug('pbspMap ::'+pbspMap);
            system.debug('psbpIDSet ::'+psbpIDSet);
            system.debug(reviseOrderObj.Revise_Currency__c.substring(0,3));
            priceProCurrencyList = [Select Id ,Name,Price_100_pcs__c,Price_1000_pcs__c,UOM_Price__c,Price_Book_Product__c,MagNET_Price_Code__c From Price_Product_by_Currency__c where CurrencyIsoCode =:reviseOrderObj.Revise_Currency__c.substring(0,3) and Price_Book_Product__c IN:psbpIDSet];
            system.debug('priceProCurrencyList ::'+priceProCurrencyList);
            for(Price_Product_by_Currency__c priceProCurrencyListVal :priceProCurrencyList){
                system.debug(priceProCurrencyListVal.MagNET_Price_Code__c);
                //if(customerInfo.size() > 0){
                    if(customerMagnetPriceCode != '' && priceProCurrencyListVal.MagNET_Price_Code__c == customerMagnetPriceCode){
                        system.debug('priceProCurrencyListVal ::'+priceProCurrencyListVal);
                        pbIdSpecialDiscountPriceMap.put(priceProCurrencyListVal.Price_Book_Product__c,priceProCurrencyListVal);
                    }
                    else if(priceProCurrencyListVal.MagNET_Price_Code__c == null){
                        PPCMap.put(priceProCurrencyListVal.Price_Book_Product__c,priceProCurrencyListVal);//Map Containing Price specification Book Products Id and Price Product By currency record
                    }
               // }
               
            }
            system.debug('PPCMap ::'+PPCMap);
            for(Sales_Order_Line_Items__c SOLIList :SOLI){
                system.debug('SOLIList>>'+SOLIList);
                SOLIList.CurrencyIsoCode = reviseOrderObj.Revise_Currency__c.substring(0,3); 
                if(pbspMap.size() > 0){
                    system.debug('pbspMap>>'+pbspMap);
                    //system.debug('pbspMap.get(SOLIList.Customer_Ref_Model__c).Id out>>'+pbspMap.get(SOLIList.Customer_Ref_Model__c).Id);
                    if(pbspMap.containsKey(SOLIList.Customer_Ref_Model__c)){
                        system.debug('pbspMap.get(SOLIList.Customer_Ref_Model__c).Id>>'+pbspMap.get(SOLIList.Customer_Ref_Model__c).Id);
                        SOLIList.Price_Specification_Book_Product__r.Name = pbspMap.get(SOLIList.Customer_Ref_Model__c).Name;
                        SOLIList.Price_Specification_Book_Product__c = pbspMap.get(SOLIList.Customer_Ref_Model__c).Id;
                        SOLIList.BOX_QTY__c = pbspMap.get(SOLIList.Customer_Ref_Model__c).BOX_QTY__c;
                        SOLIList.Local_SKU__c = pbspMap.get(SOLIList.Customer_Ref_Model__c).Local_SKU__c;
                        if(pbIdSpecialDiscountPriceMap.containsKey(pbspMap.get(SOLIList.Customer_Ref_Model__c).Id)){
                            SOLIList.Price_Product_by_Currency__c = pbIdSpecialDiscountPriceMap.get(pbspMap.get(SOLIList.Customer_Ref_Model__c).Id).Id;
                            SOLIList.PEC_TXT_1__c = pbIdSpecialDiscountPriceMap.get(pbspMap.get(SOLIList.Customer_Ref_Model__c).Id).Name;
                            system.debug('SOLIList.Price_Product_by_Currency__c>>'+SOLIList.PEC_TXT_1__c);
                            SOLIList.Price_100_pcs__c = String.valueOf(pbIdSpecialDiscountPriceMap.get(pbspMap.get(SOLIList.Customer_Ref_Model__c).Id).Price_100_pcs__c);
                            SOLIList.Price_1000_pcs__c = String.valueOf(pbIdSpecialDiscountPriceMap.get(pbspMap.get(SOLIList.Customer_Ref_Model__c).Id).Price_1000_pcs__c);
                        }
                        else if(PPCMap.containsKey(pbspMap.get(SOLIList.Customer_Ref_Model__c).Id)){
                            
                            SOLIList.Price_Product_by_Currency__c = PPCMap.get(pbspMap.get(SOLIList.Customer_Ref_Model__c).Id).Id;
                            SOLIList.PEC_TXT_1__c = PPCMap.get(pbspMap.get(SOLIList.Customer_Ref_Model__c).Id).Name;
                            system.debug('SOLIList.Price_Product_by_Currency__c>>'+SOLIList.PEC_TXT_1__c);
                            SOLIList.Price_100_pcs__c = String.valueOf(PPCMap.get(pbspMap.get(SOLIList.Customer_Ref_Model__c).Id).Price_100_pcs__c);
                            SOLIList.Price_1000_pcs__c = String.valueOf(PPCMap.get(pbspMap.get(SOLIList.Customer_Ref_Model__c).Id).Price_1000_pcs__c);
                        } 
                        else{
                            reviseReqValues.pbspOrPpcNotPresent = true;
                            SOLIList.Price_Product_by_Currency__c = null;
                            SOLIList.Price_100_pcs__c = '0.00';
                            SOLIList.Price_1000_pcs__c = '0.00';
                        }
                           }
                           else{
                               system.debug('inside else');
                               reviseReqValues.pbspOrPpcNotPresent = true;
                               SOLIList.Price_Specification_Book_Product__c = null;
                               SOLIList.Price_Product_by_Currency__c = null;
                               SOLIList.Price_100_pcs__c = '0.00';
                               SOLIList.Price_1000_pcs__c = '0.00';
                               SOLIList.BOX_QTY__c = 0.00;
                               SOLIList.Local_SKU__c = '0';
                           }
                }
                else{
                    system.debug('if pbsp not found');
                    SOLIList.Price_Specification_Book_Product__c = null;
                    reviseReqValues.pbspOrPpcNotPresent = true;
                    SOLIList.Price_Product_by_Currency__c = null;
                    SOLIList.Price_100_pcs__c = '0.00';
                    SOLIList.Price_1000_pcs__c = '0.00';
                    SOLIList.BOX_QTY__c = 0.00;
                    SOLIList.Local_SKU__c = '0';
                }
                 newSolItem.add(SOLIList);
            }
            system.debug('newSolItem ::'+newSolItem);
        }
        // To Update  Currency , Price_Product_by_Currency__c , Price_100_pcs__c and Price_1000_pcs__c
        else if(string.isBlank(reviseOrderObj.Revise_Order_To_Company__c)){
            
            priceBookProList = [select Id,Name, Product_Unique_ID__c, Order_to_Company__c, Retailer_Code__c, Retailer_Code__r.name, Local_SKU__c, BOX_QTY__c, Customer_Ref_Model__c from Price_Specification_Book_Product__c where Active__c = true and  Product_Unique_ID__r.Status__c=:'Active' AND Id IN: SOLIPriceModelRefSet and Retailer_Code__c =:soli[0].Sales_Order__r.Retailer_Code1__c ];
            system.debug('priceBookProList ::'+priceBookProList);
            for(Price_Specification_Book_Product__c priceBookProListVal :priceBookProList){
                //if(customerRefModelAndColor.containsKey((priceBookProListVal.Customer_Ref_Model__c).toUpperCase()+'#'+(priceBookProListVal.Color__c).toUpperCase())){
                    pbspMap.put(priceBookProListVal.Customer_Ref_Model__c,priceBookProListVal);//Map Containing Price specification Book Products Customer_Ref_Model__c and Price specification Book Products Records
                    psbpIDSet.add(priceBookProListVal.Id);
                //}
            }
            system.debug('pbspMap ::'+pbspMap);
            system.debug('psbpIDSet ::'+psbpIDSet);
            
            priceProCurrencyList = [Select Id ,Name,Price_100_pcs__c,Price_1000_pcs__c,UOM_Price__c,Price_Book_Product__c,MagNET_Price_Code__c From Price_Product_by_Currency__c where CurrencyIsoCode =:reviseOrderObj.Revise_Currency__c.substring(0,3) and Price_Book_Product__c IN:psbpIDSet];
            system.debug('priceProCurrencyList ::'+priceProCurrencyList);
            for(Price_Product_by_Currency__c priceProCurrencyListVal :priceProCurrencyList){
                //if(customerInfo.size() > 0){
                    if(customerMagnetPriceCode != '' && priceProCurrencyListVal.MagNET_Price_Code__c == customerMagnetPriceCode){
                        system.debug('priceProCurrencyListVal ::'+priceProCurrencyListVal);
                        pbIdSpecialDiscountPriceMap.put(priceProCurrencyListVal.Price_Book_Product__c,priceProCurrencyListVal);
                    }
                    else if(priceProCurrencyListVal.MagNET_Price_Code__c == null){
                        PPCMap.put(priceProCurrencyListVal.Price_Book_Product__c,priceProCurrencyListVal);//Map Containing Price specification Book Products Id and Price Product By currency record
                    }
               // }
            }
            system.debug('PPCMap ::'+PPCMap);
            system.debug('pbIdSpecialDiscountPriceMap ::'+pbIdSpecialDiscountPriceMap);
            for(Sales_Order_Line_Items__c SOLIList :SOLI){
                SOLIList.CurrencyIsoCode = reviseOrderObj.Revise_Currency__c.substring(0,3); 
                if(PPCMap.size() > 0 || pbIdSpecialDiscountPriceMap.size() > 0){
                    if(pbIdSpecialDiscountPriceMap.containsKey(pbspMap.get(SOLIList.Customer_Ref_Model__c).Id)){
                        SOLIList.Price_Product_by_Currency__c = pbIdSpecialDiscountPriceMap.get(pbspMap.get(SOLIList.Customer_Ref_Model__c).Id).Id;
                        SOLIList.PEC_TXT_1__c = pbIdSpecialDiscountPriceMap.get(pbspMap.get(SOLIList.Customer_Ref_Model__c).Id).Name;
                        SOLIList.Price_100_pcs__c = String.valueOf(pbIdSpecialDiscountPriceMap.get(pbspMap.get(SOLIList.Customer_Ref_Model__c).Id).Price_100_pcs__c);
                        SOLIList.Price_1000_pcs__c = String.valueOf(pbIdSpecialDiscountPriceMap.get(pbspMap.get(SOLIList.Customer_Ref_Model__c).Id).Price_1000_pcs__c);
                    }
                   else if(PPCMap.containsKey(pbspMap.get(SOLIList.Customer_Ref_Model__c).Id)){
                        SOLIList.Price_Product_by_Currency__c = PPCMap.get(pbspMap.get(SOLIList.Customer_Ref_Model__c).Id).Id;
                        SOLIList.PEC_TXT_1__c = PPCMap.get(pbspMap.get(SOLIList.Customer_Ref_Model__c).Id).Name;
                        SOLIList.Price_100_pcs__c = String.valueOf(PPCMap.get(pbspMap.get(SOLIList.Customer_Ref_Model__c).Id).Price_100_pcs__c);
                        SOLIList.Price_1000_pcs__c = String.valueOf(PPCMap.get(pbspMap.get(SOLIList.Customer_Ref_Model__c).Id).Price_1000_pcs__c);
                    }
                    else{
                        reviseReqValues.pbspOrPpcNotPresent = true;
                        SOLIList.Price_Product_by_Currency__c = null;
                            SOLIList.Price_100_pcs__c = '0.00';
                            SOLIList.Price_1000_pcs__c = '0.00';
                    }
                }
                else{
                        reviseReqValues.pbspOrPpcNotPresent = true;
                        SOLIList.Price_Product_by_Currency__c = null;
                            SOLIList.Price_100_pcs__c = '0.00';
                            SOLIList.Price_1000_pcs__c = '0.00';
                    }
                newSolItem.add(SOLIList);
            }
        }
        }
        system.debug('reviseReqValues.oldSoli>>'+reviseReqValues.oldSoli);
        reviseReqValues.newSoli = newSolItem;
        system.debug('reviseReqValues>>'+reviseReqValues);
        return reviseReqValues;
    }
    
    @AuraEnabled
    public static void rejectReviseRequest(String roId,string adminRemarks) 
    {
        system.debug('roId>>'+roId+'<<adminRemarks>>'+adminRemarks);
        if(roId !=null && adminRemarks !=null){
            Revise_Order__c reviseOrderObj = [SELECT Id,Admin_Remarks__c,Name,Status__c from Revise_Order__c where Id=:roId];
            reviseOrderObj.Status__c = 'Rejected';
            reviseOrderObj.Admin_Remarks__c = adminRemarks;
            update reviseOrderObj;
        }
    }

    @AuraEnabled 
    public static List<Retailer_Code__c> getCataUIMessage(String retailerCode){

        List<Retailer_Code__c> cataUI =[SELECT Catalog_Msg_UI_Hangers_Accessories__c,Catalog_Msg_UI_Labels_Tickets__c,Catalog_Msg_UI_Flexible_Packaging__c,Catalog_Msg_UI_Intelligent_Solutions__c,Catalog_Msg_UI_Structural_Packaging__c,Catalog_Msg_UI_MCare__c ,Catalog_Msg_Hangers_Accessories__c,Catalog_Msg_Labels_Tickets__c,Catalog_Msg_Flexible_Packaging__c,Catalog_Msg_Structural_Packaging__c,Catalog_Msg_Intelligent_Solutions__c,Catalog_Msg_MCare__c from Retailer_Code__c where id =:retailerCode ];
        return cataUI;
    }
    
    //wrapper class for sales order line item and revise order
    public class adminReviseReq{
        @AuraEnabled
        public List<Sales_Order_Line_Items__c> oldSoli {get;set;}
        @AuraEnabled
    	public List<Sales_Order_Line_Items__c> newSoli {get;set;}
         @AuraEnabled
    	public Revise_Order__c reviseOrderObj {get;set;}
        @AuraEnabled
        public boolean pbspOrPpcNotPresent;
        @AuraEnabled
        public user createduser;
        @AuraEnabled
        public contact contactName;
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
    public class SizerAddToCartWrap{
        @AuraEnabled
        public string retailerCodeId;
        @AuraEnabled
        public string pricebookId;
        @AuraEnabled
        public Integer quantity;
        @AuraEnabled
        public string pricebycur;
        @AuraEnabled
        public string preCurrency;
        @AuraEnabled
        public string custRefModel;
        @AuraEnabled
        public string color;
        @AuraEnabled
        public string size;
        @AuraEnabled
        public string customeid;
    }
}