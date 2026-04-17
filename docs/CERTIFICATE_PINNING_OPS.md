# Certificate pinning operations (LingAfriq mobile)

This app supports **TLS leaf certificate pinning** (SHA-256 of the leaf certificate DER), enabled at **release** builds when pins are provided via `--dart-define`.

## What gets pinned

The runtime pin is:

`sha256/<base64(sha256(leafCertificateDER)))>`

This matches:

- `lib/utils/certificate_pinning.dart`
- `tool/print_ssl_pin.dart`

## Enable pinning in CI

The GitHub Actions workflow passes:

`--dart-define=CERTIFICATE_PIN_HASHES="${{ secrets.CERTIFICATE_PIN_HASHES }}"`

Set repository secret `CERTIFICATE_PIN_HASHES` to a comma-separated list of pins, e.g.:

`sha256/AAAA...,sha256/BBBB...`

## Generate pins (recommended workflow)

1. Generate the current production pin:

```bash
dart run tool/print_ssl_pin.dart admin.lingafriq.com 443
```

2. Before a certificate rotation, generate the **upcoming** pin too (from staging / new cert host if applicable).

3. Update `CERTIFICATE_PIN_HASHES` to include **both** pins (comma-separated) **before** the server switches.

4. After traffic is fully on the new cert and stable, remove the old pin from the secret.

## Safety / failure modes

- If pins are wrong or stale, HTTPS calls will fail TLS validation (this is intended).
- Pinning is automatically disabled for:
  - `kDebugMode`
  - `BACKEND_URL` starting with `http://`

## Related release guardrail

`EnvConfig.backendBaseUrl` throws in `kReleaseMode` if `BACKEND_URL` is `http://…` to prevent accidental insecure production builds.
