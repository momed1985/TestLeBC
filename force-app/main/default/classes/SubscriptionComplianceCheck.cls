global class SubscriptionComplianceCheck implements Database.Batchable<sObject> {
    private static final String ELEMENTS_MANQUANTS = 'Éléments manquants';
    private static final String IMMO_NEUF = 'Conformité Immo neuf'; 
    
    
    global Database.QueryLocator start(Database.BatchableContext cnx) { 
        System.debug('level start 1');
        return Database.getQueryLocator([SELECT Id,  
                                                SBQQ__RequiredById__c, 
                                                Souscription_Conforme__c, 
                                                ComplianceProcess__c, Status__c 
                                           FROM SBQQ__Subscription__c 
                                          WHERE Status__c = 'Éléments manquants'  
                                            AND Souscription_Conforme__c = false]);
                                          
    }
    
    global void execute(Database.BatchableContext cnx, List<SBQQ__Subscription__c> scope) {
        system.debug('  step 001 ');
        

        try {
            List<SBQQ__Subscription__c> subs = new List<SBQQ__Subscription__c>();
            List<SBQQ__Subscription__c> Immosubs = new List<SBQQ__Subscription__c>();
            List<String> IdSubImReqById = new List<String>();

            

            for(SBQQ__Subscription__c sub : scope) {
               if (sub.ComplianceProcess__c == IMMO_NEUF ) {
                   
                    subs.add(sub);
  
                }
            }
            system.debug('subs.size() = '+subs.size());
            system.debug('  step 1 ');
            if(subs.size() > 0)
            Immosubs = setConformiteImmoNeuf(subs);
            for(SBQQ__Subscription__c  subIm : Immosubs){
                if(subIm != null){
                    if (subIm.SBQQ__RequiredById__c != null) {
                       IdSubImReqById.add(subIm.SBQQ__RequiredById__c);
                    }
                }
            }
            setParentConforme(IdSubImReqById);
        } catch(Exception e) {
          // Logs.error('SubscriptionComplianceCheck','Batch Compliance Check', e);
          System.debug('error');
        }
    }
    
    global void finish(Database.BatchableContext cnx) {
    }
    

    private List<SBQQ__Subscription__c> setConformiteImmoNeuf(List<SBQQ__Subscription__c> subImmoNeuf) {
        List<SBQQ__Subscription__c> subToUpdate = new List<SBQQ__Subscription__c>();
        system.debug('  step 2 ');
        for(SBQQ__Subscription__c  sub : subImmoNeuf){
            sub.Souscription_Conforme__c = true;
            subToUpdate.add(sub);
               
        }
        system.debug('subs.size() = '+subToUpdate.size());
        if(subToUpdate.size()> 0){
            update subToUpdate;
            return subToUpdate;
        }else{
            return null ;
        }
    }
    
    private void setParentConforme(List<String> parentId) {
        List<SBQQ__Subscription__c> parentSubToUpdate =  new List<SBQQ__Subscription__c>();
        List<SBQQ__Subscription__c> parentSub = [SELECT Id, Souscription_Conforme__c 
                                                   FROM SBQQ__Subscription__c 
                                                  WHERE Status__c = :ELEMENTS_MANQUANTS 
                                                  AND Souscription_Conforme__c = false 
                                                  AND Id IN :parentId
                                                ];
         system.debug('  step 3 ');
        for(SBQQ__Subscription__c sub : parentSub){
            sub.Souscription_Conforme__c = true;
            parentSubToUpdate.add(sub);      
        }

        if(parentSubToUpdate.size() > 0){
            UPDATE parentSubToUpdate ;
        }
    }
}