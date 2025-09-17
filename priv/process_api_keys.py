import re

def to_snake_case(name):
    s1 = re.sub('(.)([A-Z][a-z]+)', r'\1_\2', name)
    return re.sub('([a-z0-9])([A-Z])', r'\1_\2', s1).lower()

with open('priv/kafka.bnf', 'r') as f_in:
    with open('priv/api-keys.eterm', 'w') as f_out:
        for line in f_in:
            if line.startswith('#ApiKey:'):
                match = re.search(r'#ApiKey: ([a-zA-Z_]+), ([0-9]+)', line)
                if match:
                    name = match.group(1)
                    key = match.group(2)
                    f_out.write(f'{{{to_snake_case(name)}, {key}}}.\n')
