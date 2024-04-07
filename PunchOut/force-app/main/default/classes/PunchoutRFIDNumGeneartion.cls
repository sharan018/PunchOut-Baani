public class PunchoutRFIDNumGeneartion implements Queueable
{
    List<Base_Order_Detail__c> LineList;
    Boolean ReviseOrderflow;
    Map<Base_Order_Detail__c,boolean> mapOfSOLI;
    string RetailerCode;
    public PunchoutRFIDNumGeneartion(List<Base_Order_Detail__c> SoliList, Boolean IsRevised,Map<Base_Order_Detail__c,boolean> ReviseMap, string retailcode){ 
        LineList=new List<Base_Order_Detail__c>();
        LineList = SoliList;
        ReviseOrderflow = IsRevised;
        mapOfSOLI=new Map<Base_Order_Detail__c,boolean>();
        mapOfSOLI = ReviseMap;
        RetailerCode = retailcode;
        system.debug('ReviseOrderflow>>'+ReviseOrderflow);
        system.debug('LineList>>'+LineList);
    }
    
    public void execute(QueueableContext context) 
    {
        //fetch the latest next num from Sys_Capex object
        system.debug('LineList>>'+LineList);
        Sys_Capex_Auto_Num__c[] Nextnum = [select id,name,Code__c,Next_Num__c,Year__c,Sys_Serial_Number__c,Retailer_Code__c from Sys_Capex_Auto_Num__c where Retailer_Code__c =:RetailerCode limit 1];
        	system.debug('Nextnum List>>'+Nextnum);
        
        //byforgeting the confermed SO and Reviseorder SO
        if(ReviseOrderflow != true)
        {
            
            if(Nextnum.size()>0)
            {
                decimal recentnum = Nextnum[0].Sys_Serial_Number__c;
                integer totalQuantity = 0;
                
                //updating the respective SOLI with next num 
                List<Base_Order_Detail__c> soliListupdate = new List<Base_Order_Detail__c>();
                for( Base_Order_Detail__c soli : LineList) 
                {
                    system.debug('soli'+soli);
                    system.debug('soli_PB'+soli.Price_Specification_Book_Product__c);
                    system.debug('soli_PB_RFID'+soli.Price_Specification_Book_Product__r.RFIDSerial__c);
                    if(soli.Price_Specification_Book_Product__r.RFIDSerial__c == true)
                    {
                        Base_Order_Detail__c soliobj = new Base_Order_Detail__c();
                        soliobj.id= soli.id;
                        soliobj.Start_Num__c =  Nextnum[0].Code__c+string.valueOf(totalQuantity+recentnum);
                        system.debug('soli_start num>>'+soliobj.Start_Num__c);
                        totalQuantity = totalQuantity+integer.valueOf(soli.Supply_Quantity__c);	//add by alvin 13/8/2021
                        //totalQuantity = totalQuantity+integer.valueOf(soli.Quantity__c);					//to take all the lineitem quantity 
                        system.debug('totalQuantity>>'+totalQuantity);
                        soliListupdate.add(soliobj);
                    }
                    system.debug('soliListupdate'+soliListupdate);
                    
                }
                update soliListupdate;
                
                //update the next serial number 
                Sys_Capex_Auto_Num__c sys = new Sys_Capex_Auto_Num__c();
                sys.id= Nextnum[0].id;
                //sys.Next_Num__c = string.valueOf(totalQuantity+recentnum));
                sys.Sys_Serial_Number__c = totalQuantity+recentnum;
                update sys;
            } 
        }
        else
        {
            //where Retailer_Code__c =:LineList[0].Mainetti_SOLI__r.Mainetti_SO__r.Retailer_Code1__c
            //Sys_Capex_Auto_Num__c[] Nextnum = [select id,name,Code__c,Next_Num__c,Year__c,Sys_Serial_Number__c,Retailer_Code__c from Sys_Capex_Auto_Num__c  limit 1];
        	system.debug('Nextnum List>>'+Nextnum);
        
            if(Nextnum.size()>0)
            {
                List<Base_Order_Detail__c> soliListupdate = new List<Base_Order_Detail__c>();
                decimal recentnum = Nextnum[0].Sys_Serial_Number__c;
                system.debug('recentnum'+recentnum);
                integer totalQuantity = 0;
                if(mapOfSOLI.size()>0)
                {
                    for (Base_Order_Detail__c key : mapOfSOLI.keySet()) 
                    {
                        system.debug('key'+key);
                        system.debug('key'+mapOfSOLI.get(key));
                        
                        if(mapOfSOLI.get(key) == true){											// logic to increase RFID number 
                            system.debug('inside increase logic ');
                            Base_Order_Detail__c soliobj = new Base_Order_Detail__c();
                            soliobj.id= key.id;
                            soliobj.Start_Num__c = Nextnum[0].Code__c+string.valueOf(totalQuantity+recentnum);
                            system.debug('soli_start num>>'+soliobj.Start_Num__c);
                            totalQuantity = totalQuantity+integer.valueOf(key.Supply_Quantity__c);////add by alvin 13/8/2021
                            //totalQuantity = totalQuantity+integer.valueOf(key.Quantity__c);					//to take all the lineitem quantity 
                            system.debug('totalQuantity>>'+totalQuantity);
                            soliListupdate.add(soliobj);
                            system.debug('soliListupdate'+soliListupdate);
                        }
                        else {																	// logic to Decrease RFID number
                            system.debug('inside decrease logic');
                            
                        }
                    }
                    upsert soliListupdate;
                }
                //update the next serial number 
                Sys_Capex_Auto_Num__c sys = new Sys_Capex_Auto_Num__c();
                sys.id= Nextnum[0].id;
                //sys.Next_Num__c = string.valueOf(totalQuantity+recentnum));
                sys.Sys_Serial_Number__c = totalQuantity+recentnum;
                update sys;
            }
        }
    }
}