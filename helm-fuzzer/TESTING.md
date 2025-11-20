# Testing Helm Fuzz Against Open Source Charts

## Test Plan

This document outlines how to test helm-fuzz against popular open source Helm charts.

## Prerequisites

```bash
# Build the fuzzer
cd helm-fuzzer
go mod download
go build -o helm-fuzz main.go
```

## Test Charts

### 1. Bitnami Redis
**Why**: Simple, widely-used chart with basic templates

```bash
# Download chart
helm repo add bitnami https://charts.bitnami.com/bitnami
helm pull bitnami/redis --untar

# Run fuzzer (quick test)
./helm-fuzz fuzz redis --iterations 500 --timeout 2m

# Run fuzzer (thorough test)
./helm-fuzz fuzz redis --iterations 5000 --timeout 10m
```

**Expected findings**:
- Missing nil checks on optional fields
- Unhandled empty arrays
- Edge cases in resource limit calculations

### 2. Bitnami PostgreSQL
**Why**: Database chart with more complex configuration and dependencies

```bash
# Download chart
helm pull bitnami/postgresql --untar

# Run fuzzer
./helm-fuzz fuzz postgresql --iterations 1000 --timeout 5m
```

**Expected findings**:
- Complex nested value access without safety checks
- Statefulset-specific edge cases
- PVC template rendering issues

### 3. Ingress-NGINX
**Why**: Networking chart with different template patterns

```bash
# Download chart
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm pull ingress-nginx/ingress-nginx --untar

# Run fuzzer
./helm-fuzz fuzz ingress-nginx --iterations 1000 --timeout 5m
```

**Expected findings**:
- Service configuration edge cases
- Annotation templating issues
- ConfigMap generation bugs

## Common Issues to Look For

1. **Nil Pointer Dereference**
   ```yaml
   # Crash when optional.subfield is nil
   {{ .Values.optional.subfield }}
   ```

2. **Missing Default Values**
   ```yaml
   # Crash when value doesn't exist
   {{ .Values.resources.limits.cpu }}
   ```

3. **Type Mismatches**
   ```yaml
   # Crash when expecting string but got number
   {{ .Values.port | quote }}
   ```

4. **Array Access Without Length Check**
   ```yaml
   # Crash when array is empty
   {{ index .Values.items 0 }}
   ```

## Analyzing Results

When crashes are found:

1. **Review the reproduction file**:
   ```bash
   cat fuzzer-repro-*.yaml
   ```

2. **Manually verify the crash**:
   ```bash
   helm install --dry-run test-release <chart> -f fuzzer-repro-*.yaml
   ```

3. **Identify the root cause**:
   - Check the error message for template location
   - Review the chart's templates at that location
   - Determine if it's a real bug or expected validation

4. **Configure fuzzer if needed**:
   ```yaml
   # .helmfuzz.yaml
   ignoreErrors:
     - "validation failed"  # If expected validation errors

   uninterestingPatterns:
     - "required value"  # If required fields are intentionally required
   ```

## Test with Local Chart

Test with the included buggy chart:

```bash
./helm-fuzz fuzz testdata/buggy-chart --iterations 100
```

This chart has intentional bugs to verify the fuzzer works correctly.

## CI/CD Integration

```bash
# In CI pipeline
./helm-fuzz fuzz <chart> --ci --timeout 5m --iterations 10000
if [ $? -ne 0 ]; then
  echo "Fuzzing found crashes!"
  cat fuzzer-repro-*.yaml
  exit 1
fi
```

## Expected Success Metrics

- **Redis**: Should find 2-5 crashes in 1000 iterations
- **PostgreSQL**: Should find 5-10 crashes in 1000 iterations
- **Ingress-NGINX**: Should find 3-7 crashes in 1000 iterations

## Performance Expectations

- **Speed**: 20-50 iterations/second depending on chart complexity
- **Memory**: ~100-200MB RAM usage
- **Time**: 5-10 minutes for 1000 iterations

## Known Limitations

1. **Complex regex patterns**: May not generate matching strings
2. **Custom validators**: Won't catch semantic errors, only template crashes
3. **Subcharts**: Currently tests the main chart only

## Future Testing

Once network access is available, this testing plan can be executed to:
- Validate the fuzzer against real-world charts
- Identify and fix any issues in the fuzzer itself
- Contribute bug reports upstream to chart maintainers
