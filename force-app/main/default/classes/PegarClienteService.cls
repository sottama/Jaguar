@RestResource(urlMapping='/consultaNovasContas/*')
global  class PegarClienteService {

    @HttpGet
    global static Retorno consultar(){
        String contas = RestContext.request.params.get('contas');
        String arquivos = RestContext.request.params.get('arquivos');
        if(contas != null){
            List<Id> lstIdAcc = contas.split(';');
            List<Id> lstIdFiles = arquivos.split(';');
            
            List<Account> lstAccount = [SELECT Id, EnviadoERP__c FROM Account WHERE Id in :lstIdAcc];
            
            for(Account acc: lstAccount){
                acc.EnviadoERP__c = True;
            }
            
            Database.update(lstAccount, false);
            
            Database.delete(lstIdFiles, false);
            
            // Result r = new Result();
            // r.status = 'Sucesso';
            // return r;
            Retorno r = new Retorno();
            r.status = 'Sucesso';
            return r;
        }else{
           return consultarNovasContas();
        }
    
    }

    global static Retorno consultarNovasContas(){
        List<Account> lstAcc = [SELECT Id, Name, Cnpj__c FROM Account WHERE EnviadoERP__c = False];
		List<Id> lstAccountId = new List<Id>();
        Map<Id, Account> mapAcc = new Map<Id,Account>();
        Map<Id, Account> mapDocAcc = new Map<Id,Account>();
        
        for(Account acc : lstAcc){
            lstAccountId.add(acc.Id);
            mapAcc.put(acc.Id, acc);
        }
        
    	Set<Id> setDocId = new Set<Id>();
		for (ContentDocumentLink doc : [SELECT ContentDocumentId,LinkedEntityId, ContentDocument.Title, ContentDocument.LatestPublishedVersionId
                                        FROM ContentDocumentLink
                                        WHERE LinkedEntityId IN: lstAccountId]) {
            setDocId.add(doc.ContentDocument.LatestPublishedVersionId);
            mapDocAcc.put(doc.ContentDocument.LatestPublishedVersionId, mapAcc.get(doc.LinkedEntityId));
        }

        List<ContentVersion> lstContentVersion = [SELECT Id, ContentDocumentId, ContentDocument.LatestPublishedVersionId, ContentDocument.FileType,Title
                                                  FROM ContentVersion
                                                  WHERE Id IN: setDocId];
        

        Map<Id, Cliente> NovasAccs = new Map<Id, Cliente>();
        Map<Id, AccountAndFiles> mapNewAccs = new Map<Id, AccountAndFiles>();
        
        
        Cliente b;
        AccountAndFiles a;
        
        for (ContentVersion c: lstContentVersion) {
            if(mapNewAccs.containsKey(mapDocAcc.get(c.ContentDocument.LatestPublishedVersionId).Id)){
                a = mapNewAccs.get(mapDocAcc.get(c.ContentDocument.LatestPublishedVersionId).Id);
                File f = new File();
                f.type = c.ContentDocument.FileType;
                f.name = c.Title;
                f.id = c.Id;
                a.lstFiles.add(f);
                
                b = NovasAccs.get(mapDocAcc.get(c.ContentDocument.LatestPublishedVersionId).Id);
                ArquivoCadastro ar = new ArquivoCadastro();
                ar.id_arquivo = c.Id;
                ar.nome_arquivo = c.Title;
                ar.tipo_arquivo = c.ContentDocument.FileType;
                b.arquivo_cadastro.add(ar);
            }else{
                a = new AccountAndFiles();
                a.acc = (Account)mapDocAcc.get(c.ContentDocument.LatestPublishedVersionId);
                File f = new File();
                f.type = c.ContentDocument.FileType;
                f.name = c.Title;
                f.id = c.Id;
                a.lstFiles.add(f);

                b = new Cliente();
                ArquivoCadastro ar = new ArquivoCadastro();
                ar.id_arquivo = c.Id;
                ar.nome_arquivo = c.Title;
                ar.tipo_arquivo = c.ContentDocument.FileType;
                b.arquivo_cadastro.add(ar);
            }
        	// mapNewAccs.put(c.Id, a);
        	NovasAccs.put(c.Id, b);
        }

        Retorno retorno = new Retorno();
        retorno.status = 'Sucesso';
    
        Result lstNewAccList = new Result();
        
        for (ContentVersion c: lstContentVersion) {
            lstNewAccList.lstResult.add(mapNewAccs.get(c.Id));
            retorno.cliente.add(NovasAccs.get(c.Id));
        }
        // return lstNewAccList;
        return retorno;
    }



    global class Result{
        String status;
        public List<AccountAndFiles> lstResult = new List<AccountAndFiles>();
    }

    public class AccountAndFiles {
        public List<File> lstFiles = new List<File>();
        Account acc;
    }
	
    public Class File{
        String type;
        String name;
        String id;
    }
   
    //////////////////////////////////

    global class Retorno {
        public String status;
        public List<Cliente> cliente;
    }
    
    public class Cliente {
        public Account cliente;
        public String cnpj_cliente;
        public List<ArquivoCadastro> arquivo_cadastro = new List<ArquivoCadastro>();
    }
    
    public class ArquivoCadastro {
        public String tipo_arquivo;
        public String nome_arquivo;
        public String id_arquivo;
    }
}