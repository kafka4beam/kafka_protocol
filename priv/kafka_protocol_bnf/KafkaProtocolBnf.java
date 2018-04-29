import org.apache.kafka.common.protocol.types.ArrayOf;
import org.apache.kafka.common.protocol.types.BoundField;
import org.apache.kafka.common.protocol.types.Schema;
import org.apache.kafka.common.protocol.types.Type;
import org.apache.kafka.common.protocol.Protocol;
import org.apache.kafka.common.protocol.ApiKeys;

import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.Map;
import java.util.Set;
import java.util.StringTokenizer;

import java.io.BufferedWriter;
import java.io.FileWriter;
import java.io.IOException;

public class KafkaProtocolBnf {
    private static String indentString(int size) {
        StringBuilder b = new StringBuilder(size);
        for (int i = 0; i < size; i++)
            b.append(" ");
        return b.toString();
    }

    private static void populateSchemaFields(Schema schema, Set<BoundField> fields) {
        for (BoundField field: schema.fields()) {
            fields.add(field);
            if (field.def.type instanceof ArrayOf) {
                Type innerType = ((ArrayOf) field.def.type).type();
                if (innerType instanceof Schema)
                    populateSchemaFields((Schema) innerType, fields);
            } else if (field.def.type instanceof Schema)
                populateSchemaFields((Schema) field.def.type, fields);
        }
    }

    private static void schemaToBnf(Schema schema, StringBuilder b, int indentSize) {
        final String indentStr = indentString(indentSize);
        final Map<String, Type> subTypes = new LinkedHashMap<>();

        // Top level fields
        int index = 0;
        int length = schema.fields().length;
        for (BoundField field: schema.fields()) {
            String fieldName = field.def.name;
            if (field.def.type instanceof ArrayOf) {
                b.append("[");
                b.append(fieldName);
                b.append("]");
                Type innerType = ((ArrayOf) field.def.type).type();
                if (!subTypes.containsKey(fieldName))
                    subTypes.put(fieldName, innerType);
            } else if (field.def.type instanceof Schema) {
                b.append(fieldName);
                if (!subTypes.containsKey(fieldName))
                    subTypes.put(fieldName, field.def.type);
            } else {
                b.append(fieldName);
                if (!subTypes.containsKey(fieldName))
                    subTypes.put(fieldName, field.def.type);
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
        Set<BoundField> fields = new LinkedHashSet<>();
        populateSchemaFields(schema, fields);

        for (BoundField field : fields) {
            if (field.def.docString != null) {
              b.append("# ");
              b.append(field.def.name);
              b.append(": ");
              b.append(field.def.docString);
              b.append("\n");
            }
        }
    }

    public static String toText() {
        final StringBuilder b = new StringBuilder();
        b.append("# generated code, do not edit!\n\n");
        for (ApiKeys key : ApiKeys.values()) {
            // Requests
            if (key.clusterAction) {
              continue;
            }
            b.append("#ApiKey: ");
            b.append(key.name);
            b.append(", ");
            b.append(new Integer(key.id).toString());
            b.append("\n");
            Schema[] requests = key.requestSchemas;
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
                    b.append("\n\n");
                }
            }

            // Responses
            Schema[] responses = key.responseSchemas;
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
        String filename = "";
        try {
            filename = args[0];
        } catch (ArrayIndexOutOfBoundsException e) {
            System.err.println("Expecting output filename as a single argument.");
            System.exit(1);
        }
        try (BufferedWriter bw = new BufferedWriter(new FileWriter(filename))) {
            bw.write(toText());
        } catch (IOException e) {
            e.printStackTrace();
        }
    }
}
