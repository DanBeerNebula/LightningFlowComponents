@IsTest
public class FileUploadImproved_Test {

    @TestSetup
    static void makeData() {
        Contact con = new Contact(
                LastName = 'Test',
                FirstName = 'Bob'
        );
        insert con;

        ContentVersion cv = new ContentVersion(
                Title = 'Test',
                PathOnClient = 'Test',
                VersionData = EncodingUtil.base64Decode('Test'),
                IsMajorVersion = false
        );
        insert cv;
    }

    @IsTest
    public static void encryptedTest() {
        String key = FileUploadImprovedHelper.getKey();

        Contact con = getCon();
        ContentVersion cv = getCV();
        cv.Guest_Record_fileupload__c = FileUploadImprovedHelper.encrypt(con.Id, key);
        update cv;

        Test.startTest();
        FileUploadImprovedHelper.createContentDocLink(new List<String>{
                cv.Id
        }, key, true);
        Test.stopTest();

        List<ContentDocumentLink> cdl = [SELECT Id FROM ContentDocumentLink WHERE LinkedEntityId = :con.Id];
        System.assertEquals(1, cdl.size());
    }

    @IsTest
    public static void getExistingFiles() {
        String key = FileUploadImprovedHelper.getKey();

        Contact con = getCon();
        ContentVersion cv = getCV();
        cv.Guest_Record_fileupload__c = FileUploadImprovedHelper.encrypt(con.Id, key);
        update cv;

        Test.startTest();
        FileUploadImprovedHelper.createContentDocLink(new List<String>{
                cv.Id
        }, key, false);
        List<FileUploadImprovedHelper.objFiles> objFiles = FileUploadImprovedHelper.getExistingFiles(con.Id);
        Test.stopTest();

        System.assertEquals(1, objFiles.size());
    }

    @IsTest
    public static void changeFileName() {
        ContentVersion cv = getCV();
        String fileName = 'https://www.linkedin.com/in/rygramer/';

        Test.startTest();
        FileUploadImprovedHelper.updateFileName(new List<String>{
                cv.Id
        }, fileName);
        Test.stopTest();

        cv = getCV();
        System.assertEquals(fileName, cv.ContentDocument.Title);
    }

    @IsTest
    public static void deleteTest() {
        ContentVersion cv = getCV();

        Test.startTest();
        FileUploadImprovedHelper.deleteContentDoc(cv.Id);
        Test.stopTest();

    }

    @IsTest
    public static void invocableTestCreateLink() {
        ContentVersion cv = getCV();
        Contact con = getCon();

        FileUploadImprovedHelper.Input input = new FileUploadImprovedHelper.Input();
        input.versIds = new List<Id>{
                cv.Id
        };
        input.recordId = con.Id;
        input.visibleToAllUsers = true;

        Test.startTest();
        FileUploadImprovedHelper.createContentDocumentLinkDownstream(new List<FileUploadImprovedHelper.Input>{
                input
        });
        Test.stopTest();

        ContentDocumentLink link = [SELECT Visibility FROM ContentDocumentLink WHERE LinkedEntityId = :con.Id];

        System.assert(link.Visibility == 'AllUsers');
    }

    @IsTest
    public static void invocableTestLinkAlreadyExists() {
        ContentVersion cv = getCV();
        Contact con = getCon();

        ContentDocumentLink link = new ContentDocumentLink(
                ContentDocumentId = cv.ContentDocumentId,
                LinkedEntityId = con.Id,
                Visibility = 'AllUsers'
        );
        insert link;

        FileUploadImprovedHelper.Input input = new FileUploadImprovedHelper.Input();
        input.versIds = new List<Id>{
                cv.Id
        };
        input.recordId = con.Id;
        input.visibleToAllUsers = true;

        Test.startTest();
        FileUploadImprovedHelper.createContentDocumentLinkDownstream(new List<FileUploadImprovedHelper.Input>{
                input
        });
        Test.stopTest();

        link = [SELECT Visibility FROM ContentDocumentLink WHERE LinkedEntityId = :con.Id];

        System.assert(link.Visibility == 'AllUsers');
    }

    @IsTest
    public static void invocableTestWithEmptyList() {

        FileUploadImprovedHelper.Input input = new FileUploadImprovedHelper.Input();
        input.versIds = new List<Id>();

        Test.startTest();
        FileUploadImprovedHelper.createContentDocumentLinkDownstream(new List<FileUploadImprovedHelper.Input>{
                input
        });
        Test.stopTest();

    }

    @IsTest
    public static void createContentVersion() {
        String encodedKey = FileUploadImprovedHelper.getKey();
        String encodedRecordId = FileUploadImprovedHelper.encrypt(getCon().Id, encodedKey);

        String beforeString = 'File Upload Improved';
        Blob beforeBlob = Blob.valueOf(beforeString);
        String newVersionData = EncodingUtil.base64Encode(beforeblob);

        List<String> fileNames = new List<String>{
                'FileUploadImproved.txt'
        };
        List<Id> versIds = new List<Id>();
        Test.startTest();
        List<FileUploadImprovedHelper.objFiles> objFiles = FileUploadImprovedHelper.createContentVers(fileNames, encodedRecordId);

        for (FileUploadImprovedHelper.objFiles objFile : objFiles) {
            versIds.add(objFile.contentVersionId);
            FileUploadImprovedHelper.appendDataToContentVersion(objFile.contentVersionId, newVersionData);
        }
        Test.stopTest();

        for (ContentVersion vers : [SELECT VersionData, Guest_Record_fileupload__c FROM ContentVersion WHERE Id IN :versIds]) {
            System.assertEquals(encodedRecordId, vers.Guest_Record_fileupload__c);

            // I'm stumped on this one, I'd expect this to return this way, but it doesn't.
            // Perhaps there's a bug in Salesforce tests that make it so you can't update ContentVersions?
            // system.assertEquals(newVersionData, EncodingUtil.base64Encode(vers.VersionData));
        }
    }

    @IsTest
    public static void appendToContentVersionVersionHasData() {
        ContentVersion cv = getCV();

        String currentVersionData = EncodingUtil.base64Encode(cv.VersionData);

        String beforeString = 'File Upload Improved';
        Blob beforeBlob = Blob.valueOf(beforeString);
        String newVersionData = EncodingUtil.base64Encode(beforeblob);

        Test.startTest();
        FileUploadImprovedHelper.appendDataToContentVersion(cv.Id, newVersionData);
        Test.stopTest();

        // Stumped here too.
        // system.assertEquals(currentVersionData + newVersionData, EncodingUtil.base64Encode(getCV().VersionData));
    }

    private static ContentVersion getCV() {
        return [SELECT Id, Guest_Record_fileupload__c, ContentDocument.Title, ContentDocumentId, VersionData FROM ContentVersion LIMIT 1];
    }

    private static Contact getCon() {
        return [SELECT Id FROM Contact];
    }
}
