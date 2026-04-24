# FULL Daffodil Test Package

## Functional Test
daffodil parse -s schemas/csv_schema.xsd input/valid.csv -o output/result.xml
diff expected/valid.xml output/result.xml

## Complex Test
daffodil parse -s schemas/complex_schema.xsd input/nested.txt -o output/nested.xml
diff expected/nested.xml output/nested.xml

## Negative Test
daffodil parse -s schemas/csv_schema.xsd input/invalid.csv

## Performance Test
time daffodil parse -s schemas/csv_schema.xsd input/large.csv

## Unparse Test
daffodil unparse -s schemas/csv_schema.xsd output/result.xml -o output/back.csv

## Smoke Testing
# ./run_smoke.sh
# or: ./run_tests.sh --smoke-only

## Compatibility (WSL vs Windows)
# See COMPATIBILITY.md — same parse commands, then compare tools/canonicalize_*.py outputs
