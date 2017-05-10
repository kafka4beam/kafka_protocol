import org.apache.kafka.common.protocol.types.ArrayOf;
import org.apache.kafka.common.protocol.types.Field;
import org.apache.kafka.common.protocol.types.Schema;
import org.apache.kafka.common.protocol.types.Type;
import org.apache.kafka.common.protocol.Protocol;
import org.apache.kafka.common.protocol.ApiKeys;

import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.Map;
import java.util.Set;
import java.util.StringTokenizer;


public class KafkaProtocolBnf {
    private static String indentString(int size) {
        StringBuilder b = new StringBuilder(size);
        for (int i = 0; i < size; i++)
            b.append(" ");
        return b.toString();
    }

    private static void populateSchemaFields(Schema schema, Set<Field> fields) {
        for (Field field: schema.fields()) {
            fields.add(field);
            if (field.type instanceof ArrayOf) {
                Type innerType = ((ArrayOf) field.type).type();
                if (innerType instanceof Schema)
                    populateSchemaFields((Schema) innerType, fields);
            } else if (field.type instanceof Schema)
                populateSchemaFields((Schema) field.type, fields);
        }
    }

    private static void schemaToBnf(Schema schema, StringBuilder b, int indentSize) {
        final String indentStr = indentString(indentSize);
        final Map<String, Type> subTypes = new LinkedHashMap<>();

        // Top level fields
        int index = 0;
        int length = schema.fields().length;
        for (Field field: schema.fields()) {
            String fieldName = field.name;
            if (field.type instanceof ArrayOf) {
                b.append("[");
                b.append(fieldName);
                b.append("]");
                Type innerType = ((ArrayOf) field.type).type();
                if (!subTypes.containsKey(fieldName))
                    subTypes.put(fieldName, innerType);
            } else if (field.type instanceof Schema) {
                b.append(fieldName);
                if (!subTypes.containsKey(fieldName))
                    subTypes.put(fieldName, field.type);
            } else {
                b.append(fieldName);
                if (!subTypes.containsKey(fieldName))
                    subTypes.put(fieldName, field.type);
            }
            if (index < (length - 1))
                b.append(" ");
            index ++;
        }
        b.append("\n");

        // Sub Types/Schemas
        for (Map.Entry<String, Type> entry: subTypes.entrySet()) {
            if (entry.getValue() instanceof Schema) {
                // Complex Schema Type
                b.append(indentStr);
                b.append(entry.getKey());
                b.append(" => ");
                schemaToBnf((Schema) entry.getValue(), b, indentSize + 2);
            } else {
                // Standard Field Type
                b.append(indentStr);
                b.append(entry.getKey());
                b.append(" => ");
                b.append(entry.getValue().toString());
                b.append("\n");
            }
        }
    }

    private static void schemaToFieldTableText(Schema schema, StringBuilder b) {
        Set<Field> fields = new LinkedHashSet<>();
        populateSchemaFields(schema, fields);

        for (Field field : fields) {
            if (field.doc.isEmpty())
                continue;
            b.append("# ");
            b.append(field.name);
            b.append(": ");
            b.append(field.doc);
            b.append("\n");
        }
    }

    public static String toText() {
        final StringBuilder b = new StringBuilder();
        b.append("# generated code, do not edit!\n\n");

        b.append("Request => header message\n");
        b.append("  header => ");
        schemaToBnf(Protocol.REQUEST_HEADER, b, 4);
        b.append("  message => ");
        int apiKeysCnt = ApiKeys.values().length;
        int apiKeyIndex = 0;
        for (ApiKeys key : ApiKeys.values()) {
            Schema[] requests = Protocol.REQUESTS[key.id];
            for (int i = 0; i < requests.length; i++) {
                Schema schema = requests[i];
                // Schema
                if (schema != null) {
                    b.append(key.name);
                    b.append("RequestV");
                    b.append(i);
                    if (i < (requests.length - 1))
                        b.append(" | ");
                }
            }
            if (apiKeyIndex < (apiKeysCnt - 1))
                b.append(" | ");
            apiKeyIndex++;
        }
        b.append("\n\n");
        schemaToFieldTableText(Protocol.REQUEST_HEADER, b);
        b.append("\n\n");

        b.append("Response => header message\n");
        b.append("  header => ");
        schemaToBnf(Protocol.RESPONSE_HEADER, b, 4);
        b.append("  message => ");
        apiKeyIndex = 0;
        for (ApiKeys key : ApiKeys.values()) {
            Schema[] responses = Protocol.RESPONSES[key.id];
            for (int i = 0; i < responses.length; i++) {
                Schema schema = responses[i];
                // Schema
                if (schema != null) {
                    // Version header
                    b.append(key.name);
                    b.append("ResponseV");
                    b.append(i);
                    if (i < (responses.length - 1))
                        b.append(" | ");
                }
            }
            if (apiKeyIndex < (apiKeysCnt - 1))
                b.append(" | ");
            apiKeyIndex++;
        }
        b.append("\n\n");
        schemaToFieldTableText(Protocol.RESPONSE_HEADER, b);
        b.append("\n\n");

        for (ApiKeys key : ApiKeys.values()) {
            // Requests
            Schema[] requests = Protocol.REQUESTS[key.id];
            for (int i = 0; i < requests.length; i++) {
                Schema schema = requests[i];
                // Schema
                if (schema != null) {
                    // Version header
                    b.append(key.name);
                    b.append("RequestV");
                    b.append(i);
                    b.append(" => ");
                    schemaToBnf(requests[i], b, 2);
                    b.append("\n");
                    schemaToFieldTableText(requests[i], b);
                }
                b.append("\n\n");
            }

            // Responses
            Schema[] responses = Protocol.RESPONSES[key.id];
            for (int i = 0; i < responses.length; i++) {
                Schema schema = responses[i];
                // Schema
                if (schema != null) {
                    // Version header
                    b.append(key.name);
                    b.append("ResponseV");
                    b.append(i);
                    b.append(" => ");
                    schemaToBnf(responses[i], b, 2);
                    b.append("\n");
                    schemaToFieldTableText(responses[i], b);
                }
                b.append("\n\n");
            }
        }

        return b.toString();
    }

    public static void main(String[] args) {
        System.out.println(toText());
    }
}
