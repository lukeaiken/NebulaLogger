/*************************************************************************************************
 * This file is part of the Nebula Logger project, released under the MIT License.                *
 * See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    *
 *************************************************************************************************/
@isTest
private class LogEntryEventBuilder_Tests {
    private static final String ENTRY_TYPE_DIAGNOSTIC = 'Diagnostic';
    private static final String ENTRY_TYPE_EXCEPTION = 'Exception';
    @TestSetup
    static void setup() {
        // Most tests will involve settings being enabled, so enable by default
        // Any tests that need a specific logging level, or logging disabled, should handle updating the settings
        insert new LoggerSettings__c(IsEnabled__c = true, LoggingLevel__c = 'DEBUG', Name = 'Test Settings');
    }

    @isTest
    static void it_should_short_circuit_when_logging_is_not_enabled() {
        LoggerSettings__c settings = [SELECT Id, IsEnabled__c FROM LoggerSettings__c];
        settings.IsEnabled__c = false;
        update settings;

        Test.startTest();
        LogEntryEventBuilder builder = new LogEntryEventBuilder(LoggingLevel.DEBUG);
        Test.stopTest();

        System.assertEquals(null, builder.getLogEntryEvent());
        System.assertEquals(null, builder.setMessage('test').getLogEntryEvent());
        System.assertEquals(null, builder.setExceptionDetails(new IllegalArgumentException('test')).getLogEntryEvent());
        System.assertEquals(null, builder.setRecordId(new Account()).getLogEntryEvent());
        System.assertEquals(null, builder.setRecordId('005000000000001').getLogEntryEvent());
        System.assertEquals(null, builder.setTopics(new List<String>{ '', ' ' }).getLogEntryEvent());
    }

    @isTest
    static void it_should_short_circuit_when_enabled_logging_level_above_called_level() {
        LoggerSettings__c settings = [SELECT Id, IsEnabled__c FROM LoggerSettings__c];
        settings.IsEnabled__c = false;
        update settings;

        LogEntryEventBuilder builder = new LogEntryEventBuilder(LoggingLevel.FINE);

        System.assertEquals(null, builder.getLogEntryEvent());
    }

    @isTest
    static void it_should_not_short_circuit_when_enabled_logging_level_meets_called_level() {
        LoggerSettings__c settings = [SELECT Id, IsEnabled__c FROM LoggerSettings__c];
        settings.IsEnabled__c = true;
        settings.LoggingLevel__c = 'FINE';
        update settings;

        LogEntryEventBuilder builder = new LogEntryEventBuilder(LoggingLevel.FINE);

        System.assertNotEquals(null, builder.getLogEntryEvent());
    }

    // TODO - figure out the best way to handle DeleteResult & MergeResult
    // ...that works in all orgs so the unmanaged project can be deployed as-is
    // @isTest
    // static void it_should_set_dml_result_fields_for_delete_result_with_errors() {
    //     System.assert(Logger.isEnabled());

    //     Database.DeleteResult deleteResult = Database.delete(new Account(Id = '0011234567890ABCDEF'), false);
    //     System.assertEquals(false, deleteResult.isSuccess());

    //     LogEntryEventBuilder builder = new LogEntryEventBuilder(LoggingLevel.INFO);

    //     Test.startTest();
    //     builder.setDmlResult(deleteResult);
    //     Test.stopTest();

    //     LogEntryEvent__e logEntryEvent = builder.getLogEntryEvent();

    //     System.assertEquals(Json.serialize(deleteResult.getErrors()), logEntryEvent.DmlOperationErrors__c);
    //     System.assertEquals(ENTRY_TYPE_EXCEPTION, logEntryEvent.Type__c);
    //     System.assertEquals(Database.DeleteResult.class.getName(), logEntryEvent.DmlOperationType__c);
    // }

    // @isTest
    // static void it_should_set_dml_result_fields_for_merge_result_with_errors() {
    //     System.assert(Logger.isEnabled());

    //     Database.MergeResult mergeResult = Database.merge(new Account(), new Account(), false);
    //     System.assertEquals(false, mergeResult.isSuccess());

    //     LogEntryEventBuilder builder = new LogEntryEventBuilder(LoggingLevel.INFO);

    //     Test.startTest();
    //     builder.setDmlResult(mergeResult);
    //     Test.stopTest();

    //     LogEntryEvent__e logEntryEvent = builder.getLogEntryEvent();

    //     System.assertEquals(Json.serialize(mergeResult.getErrors()), logEntryEvent.DmlOperationErrors__c);
    //     System.assertEquals(ENTRY_TYPE_EXCEPTION, logEntryEvent.Type__c);
    //     System.assertEquals(Database.MergeResult.class.getName(), logEntryEvent.DmlOperationType__c);
    // }

    @isTest
    static void it_should_set_dml_result_fields_for_save_result_with_errors() {
        System.assert(Logger.isEnabled());

        Database.SaveResult saveResult = Database.insert(new Account(), false);
        System.assertEquals(false, saveResult.isSuccess());

        LogEntryEventBuilder builder = new LogEntryEventBuilder(LoggingLevel.INFO);

        Test.startTest();
        builder.setDmlResult(saveResult);
        Test.stopTest();

        LogEntryEvent__e logEntryEvent = builder.getLogEntryEvent();

        System.assertEquals(Json.serialize(saveResult.getErrors()), logEntryEvent.DmlOperationErrors__c);
        System.assertEquals(ENTRY_TYPE_EXCEPTION, logEntryEvent.Type__c);
        System.assertEquals(Database.SaveResult.class.getName(), logEntryEvent.DmlOperationType__c);
    }

    @isTest
    static void it_should_set_dml_result_fields_for_upsert_result_with_errors() {
        System.assert(Logger.isEnabled());

        Database.UpsertResult upsertResult = Database.upsert(new Account(), false);
        System.assertEquals(false, upsertResult.isSuccess());

        LogEntryEventBuilder builder = new LogEntryEventBuilder(LoggingLevel.INFO);

        Test.startTest();
        builder.setDmlResult(upsertResult);
        Test.stopTest();

        LogEntryEvent__e logEntryEvent = builder.getLogEntryEvent();

        System.assertEquals(Json.serialize(upsertResult.getErrors()), logEntryEvent.DmlOperationErrors__c);
        System.assertEquals(ENTRY_TYPE_EXCEPTION, logEntryEvent.Type__c);
        System.assertEquals(Database.UpsertResult.class.getName() + '.Insert', logEntryEvent.DmlOperationType__c);
    }

    @isTest
    static void it_should_set_stack_trace_and_origin_location_for_stack_trace_string() {
        LoggerSettings__c settings = [SELECT Id, IsEnabled__c FROM LoggerSettings__c];
        settings.IsEnabled__c = true;
        settings.LoggingLevel__c = 'FINE';
        update settings;

        DmlException stackTraceHandler = new DmlException();

        LogEntryEventBuilder builder = new LogEntryEventBuilder(LoggingLevel.FINE);
        builder.getLogEntryEvent().OriginLocation__c = null;
        builder.getLogEntryEvent().StackTrace__c = null;

        Test.startTest();
        builder.parseStackTrace(stackTraceHandler.getStackTraceString());
        Test.stopTest();

        String expectedOriginLocation = stackTraceHandler.getStackTraceString()
            .split('\n')
            .get(0)
            .substringBefore(':')
            .substringAfter('Class.');
        String expectedStackTrace = stackTraceHandler.getStackTraceString();

        System.assertNotEquals(null, builder.getLogEntryEvent().OriginLocation__c);
        System.assertEquals(expectedOriginLocation, builder.getLogEntryEvent().OriginLocation__c);
        System.assertNotEquals(null, builder.getLogEntryEvent().StackTrace__c);
        System.assertEquals(expectedStackTrace, builder.getLogEntryEvent().StackTrace__c);
    }
}
