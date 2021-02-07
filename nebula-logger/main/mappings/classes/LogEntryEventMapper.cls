public with sharing class LogEntryEventMapper {
    public static void mapFields(LogEntryEvent__e logEntryEvent, SObject mappedRecord) {
        List<LogEntryEventMapping__mdt> mappedRecordMappings = getMappings(mappedRecord.getSObjectType());

        for (LogEntryEventMapping__mdt mapping : mappedRecordMappings) {
            String logEntryEventField = mapping.LogEntryEventField__r.QualifiedApiName;
            String mappedRecordField = mapping.MappedField__r.QualifiedApiName;
            Object logEntryEventValue = logEntryEvent.get(logEntryEventField);

            mappedRecord.put(mappedRecordField, logEntryEventValue);
        }
    }

    private static List<LogEntryEventMapping__mdt> getMappings(Schema.SObjectType mappedSObjectType) {
        return [
            SELECT
                LogEntryEventSObject__r.QualifiedApiName,
                LogEntryEventField__r.QualifiedApiName,
                MappedSObject__r.QualifiedApiName,
                MappedField__r.QualifiedApiName
            FROM logEntryEventMapping__mdt
            WHERE MappedSObject__r.QualifiedApiName = :mappedSObjectType
        ];
    }
}
