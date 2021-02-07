public with sharing class LogEntryEventMapper {
    private static Map<String, List<LogEntryEventMapping__mdt>> cachedMappings = new Map<String, List<LogEntryEventMapping__mdt>>();

    public static void mapFields(LogEntryEvent__e logEntryEvent, SObject mappedRecord) {
        List<LogEntryEventMapping__mdt> mappedRecordMappings = getMappings(mappedRecord.getSObjectType());

        for (LogEntryEventMapping__mdt mapping : mappedRecordMappings) {
            String logEntryEventField = mapping.LogEntryEventField__r.QualifiedApiName;
            Object logEntryEventValue = logEntryEvent.get(logEntryEventField);
            String mappedRecordField = mapping.MappedField__r.QualifiedApiName;

            if (logEntryEvent.getPopulatedFieldsAsMap().containsKey(logEntryEventField)) {
                mappedRecord.put(mappedRecordField, logEntryEventValue);
            }
        }
    }

    private static List<LogEntryEventMapping__mdt> getMappings(Schema.SObjectType mappedSObjectType) {
        String mappedSObjectApiName = String.valueOf(mappedSObjectType);

        if (!cachedMappings.containsKey(mappedSObjectApiName)) {
            List<LogEntryEventMapping__mdt> mappings = [
                SELECT
                    LogEntryEventSObject__r.QualifiedApiName,
                    LogEntryEventField__r.QualifiedApiName,
                    MappedSObject__r.QualifiedApiName,
                    MappedField__r.QualifiedApiName
                FROM logEntryEventMapping__mdt
                WHERE MappedSObject__r.QualifiedApiName = :mappedSObjectApiName
            ];
            cachedMappings.put(mappedSObjectApiName, mappings);
        }

        return cachedMappings.get(mappedSObjectApiName);
    }
}
