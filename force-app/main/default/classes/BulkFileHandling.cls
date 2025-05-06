public class BulkFileHandling {
     @AuraEnabled
    public static List<EntityDefinition> getObjectNamesClone(String searchKey) {
        List<EntityDefinition> defList = new List<EntityDefinition>();
        try{
             String searchTerm = String.escapeSingleQuotes(searchKey) + '%';
        	defList = [SELECT QualifiedApiName FROM EntityDefinition 
					   WHERE QualifiedApiName LIKE :searchTerm];
            return defList;
        }catch(Exception e){
            System.debug('Error Message ' + e.getMessage() + 'Error Line no ' + e.getLineNumber());
            return defList;
        }
 	}
    
     @AuraEnabled
    public static List<EntityDefinition> allObjectNames() {
        List<EntityDefinition> defList = new List<EntityDefinition>();
        try{
        	defList = [SELECT QualifiedApiName FROM EntityDefinition 
					   ORDER BY QualifiedApiName];
            return defList;
        }catch(Exception e){
            System.debug('Error Message ' + e.getMessage() + 'Error Line no ' + e.getLineNumber());
            return defList;
        }
	}
    
     @AuraEnabled(cacheable=false)
    public static String getRelatedFiles(String str){
        PaginationWrap pgCls = (PaginationWrap)JSON.deserialize(str, PaginationWrap.class);
        String returnData = 'No Object Found';
        try{
            String queryObj = '';
			List<sObject> filesRecord = new List<sObject>();
            if(pgCls.objName != ''){
                if(pgCls.firstRecId == '' && pgCls.lastRecId == ''){
                    queryobj = 'SELECT Id, ContentDocumentId  FROM ContentDocumentLink WHERE LinkedEntityId';
                    queryobj = queryobj + ' IN (SELECT Id FROM ' + pgCls.objName + ' ) ORDER BY ID ASC LIMIT ' + pgCls.recLimit;
                }
                else{
                    String actionType = pgCls.actiontype;
                    switch on actionType {
                        when 'Next' {		
                            queryobj = 'SELECT Id, ContentDocumentId  FROM ContentDocumentLink WHERE LinkedEntityId';
                            queryobj = queryobj + ' IN (SELECT Id FROM ' + pgCls.objName + ' ) ';
							queryObj = queryobj +  ' AND Id > \'' + pgCls.lastRecId + '\'' + ' ORDER BY ID ASC LIMIT ' + pgCls.recLimit;
                        }	
                        when 'Prev' {	
                            queryobj = 'SELECT Id, ContentDocumentId  FROM ContentDocumentLink WHERE LinkedEntityId';
                            queryobj = queryobj + ' IN (SELECT Id FROM ' + pgCls.objName + ' ) ';
							queryObj = queryobj + ' AND Id < \'' + pgCls.firstRecId + '\'' + ' ORDER BY ID DESC LIMIT ' + pgCls.recLimit;
                            system.debug(queryObj);
                        }
       
					} 
                }
                filesRecord = Database.Query(queryobj);
                System.debug(filesRecord);
                if(filesRecord.size() == 0){
                    return 'No Records Found';
                }
                // Store the contentdocumentIds in the set of string
                List<String> condocIds = new List<String>();
                For(sObject obj : filesRecord){
                    condocIds.add(String.valueOf(obj.get('ContentDocumentId')));
                }
                String queryCount = 'SELECT COUNT() FROM ContentDocumentLink WHERE LinkedEntityId IN (SELECT Id FROM ' + pgCls.objName + ' )';
				Integer countFiles = Database.countQuery(queryCount);
                List<ContentVersion> cvList = [SELECT Id,title,filetype,ContentSize,ContentDocumentId FROM ContentVersion WHERE ContentDocumentId IN :condocIds ];
                // Add the Details in the JSON Wrapper
                if(cvList.size() > 0){
                    fileResponseClass resObj = new fileResponseClass();
                    resobj.contVerList  = cvList;
                    resObj.firstRecId   = filesRecord[0].Id;
                    resObj.lastRecId    = filesRecord[filesRecord.size() - 1].Id;
                    resObj.totalRecords = countFiles;
                    returnData = JSON.serialize(resObj); 
                    return returnData;
                }  
            }
            return returnData;
        }catch(Exception e){
            System.debug('Error occured on line number : ' + e.getLineNumber() +' and the error is ' + e.getMessage());
           throw new AuraHandledException('Error occured on line number : ' + e.getLineNumber() +' and the error is ' + e.getMessage());
          
        }
    }
    
     public class PaginationWrap{
        @AuraEnabled
        public String firstRecId{get;set;}
        @AuraEnabled
        public String lastRecId {get;set;}
        @AuraEnabled
        public Integer recLimit {get;set;}
        @AuraEnabled
        public String actiontype{get;set;}    
        @AuraEnabled
        public String objName{get;set;} 
    }
    
    public class fileResponseClass{
        @AuraEnabled
        public String firstRecId{get;set;}
        @AuraEnabled
        public String lastRecId {get;set;}
        @AuraEnabled
        public List<ContentVersion> contVerList {get;set;}
        @AuraEnabled
        public Integer totalRecords {get;set;}
        
    }

}