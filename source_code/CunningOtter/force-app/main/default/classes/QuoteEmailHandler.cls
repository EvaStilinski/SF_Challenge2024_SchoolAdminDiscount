public class QuoteEmailHandler {
    @InvocableMethod
    public static void sendQuotePDFToContact(List<Id> quoteIds) {
        List<Messaging.EmailFileAttachment> attachments = new List<Messaging.EmailFileAttachment>();
        
        for (Id quoteId : quoteIds) {
            // query the Quote object to get the Opportunity Id
            Quote quoteRecord = [SELECT Id, OpportunityId FROM Quote WHERE Id = :quoteId LIMIT 1];
            
            // find the ContentDocument ID linked to the Quote
            List<ContentDocumentLink> contentDocumentLinks = [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :quoteId LIMIT 1];
            
            if (contentDocumentLinks.isEmpty()) {
                continue; 
            }
            
            // use the ContentDocumentId to retrieve the latest ContentVersion (the actual PDF)
            List<ContentVersion> contentVersions = [SELECT Id, Title, VersionData FROM ContentVersion WHERE ContentDocumentId = :contentDocumentLinks[0].ContentDocumentId ORDER BY VersionNumber DESC LIMIT 1];
            
            // query the Opportunity to get the associated Contact's email
            Opportunity opp = [SELECT Id, Contact__r.Email FROM Opportunity WHERE Id = :quoteRecord.OpportunityId LIMIT 1];
            
            // ensure the associated Contact's email exists
            if (opp.Contact__r.Email != null && !contentVersions.isEmpty()) {
                // Get the first ContentVersion (PDF file)
                ContentVersion contentVersionRecord = contentVersions[0];
                
                // Create an email attachment
                Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
                attachment.setFileName(contentVersionRecord.Title + '.pdf'); //  the file name as the ContentVersion title
                attachment.setBody(contentVersionRecord.VersionData); 
                attachment.setContentType('application/pdf');
                attachments.add(attachment);
                
                // Create and send the email
                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                email.setToAddresses(new String[] {opp.Contact__r.Email});
                email.setSubject('Your Quote Document');
                email.setHtmlBody('This is your Quote document attached! Have a nice day!');
                email.setFileAttachments(attachments);
                
                Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});
            }
        }
    }
}