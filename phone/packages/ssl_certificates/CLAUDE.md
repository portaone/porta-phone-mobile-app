@AGENTS.md

## Gotcha

`securety_context.dart` — intentional misspelling ("securety" not "security"). Do not rename it.
Renaming breaks the barrel export `lib/ssl_certificates.dart`, the only file that references it; dependents import the barrel.
