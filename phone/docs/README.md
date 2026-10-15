# The map

Every page of `phone/docs/`, one line each, and the order they are usually read in. Each folder
has its own `README.md` saying what belongs there; this page lists everything at once.

- **[architecture/](architecture/README.md)** - why the app is shaped this way
- **[guides/](guides/README.md)** - how to do a thing
- **[reference/](reference/README.md)** - what exists, named exactly
- **[features/](features/features.md)** - one page per feature: what the user does and how it is built

---

## Reading paths

**Building and shipping**
[guides/build.md](guides/build.md) -> [guides/build_verification.md](guides/build_verification.md) -> [reference/make_file.md](reference/make_file.md)

**Patching a released version**
[guides/hotfix_builds.md](guides/hotfix_builds.md)

**Drawing or touching a screen**
[guides/accessibility.md](guides/accessibility.md) -> [architecture/adaptive_layout.md](architecture/adaptive_layout.md) -> [guides/localization.md](guides/localization.md)

**Working on calls**
[features/call_arch.md](features/call_arch.md) -> [architecture/incoming_call_scenarios.md](architecture/incoming_call_scenarios.md) -> [architecture/signaling_architecture_target.md](architecture/signaling_architecture_target.md)

**Data that refreshes**
[architecture/polling.md](architecture/polling.md) -> [architecture/polling_workers.md](architecture/polling_workers.md) -> [architecture/data_refresh.md](architecture/data_refresh.md)

**What a brand configures**
[reference/application_config.md](reference/application_config.md) -> [reference/page_configuration.md](reference/page_configuration.md) -> [reference/widgets_configuration.md](reference/widgets_configuration.md) -> [reference/environment.md](reference/environment.md)

**Integration tests**
[guides/integration_test_commands.md](guides/integration_test_commands.md) -> [reference/integration_test_coverage.md](reference/integration_test_coverage.md) -> [reference/integration_test_variables.md](reference/integration_test_variables.md)

---

## architecture/

| Page | What it holds |
| --- | --- |
| [adaptive_layout.md](architecture/adaptive_layout.md) | Giving a screen a second arrangement (landscape) |
| [data_refresh.md](architecture/data_refresh.md) | How a user asks a list to fetch again, screen by screen |
| [dependency_ownership.md](architecture/dependency_ownership.md) | Which objects the startup path creates, which the widget tree creates, and who releases them |
| [destination_picking.md](architecture/destination_picking.md) | How a feature sends the user to the lists to pick a person |
| [fonts.md](architecture/fonts.md) | How the app gets the typeface a theme names |
| [history_paging.md](architecture/history_paging.md) | Paging a history by date: reaching records an endpoint does not volunteer |
| [ice_servers.md](architecture/ice_servers.md) | Where the STUN/TURN servers come from, how they are cached and renewed |
| [incoming_call_scenarios.md](architecture/incoming_call_scenarios.md) | How an incoming call is delivered and handled per app state and mode |
| [polling.md](architecture/polling.md) | PollingService: periodic, lifecycle and manual refreshes without overlap |
| [polling_workers.md](architecture/polling_workers.md) | The polling worker pattern: one sync cycle apart from its scheduling |
| [signaling_architecture_target.md](architecture/signaling_architecture_target.md) | The three layers of the signaling stack |
| [startup.md](architecture/startup.md) | Where cold start time goes, measured |
| [startup_performance.md](architecture/startup_performance.md) | How the Dart startup path is recorded and read |

## guides/

| Page | What it holds |
| --- | --- |
| [accessibility.md](guides/accessibility.md) | Exposing controls to screen readers and UI automation - mandatory for UI |
| [browserstack_upload.md](guides/browserstack_upload.md) | Uploading builds to BrowserStack App Live |
| [build.md](guides/build.md) | Building, running, signing and shipping the app |
| [build_verification.md](guides/build_verification.md) | Which check to run for a change, what it costs, the flags a build needs |
| [certificates.md](guides/certificates.md) | Trusted SSL certificates bundled with a brand |
| [development.md](guides/development.md) | Git hooks and the development setup |
| [hotfix_builds.md](guides/hotfix_builds.md) | Patching a released version |
| [integration_test_commands.md](guides/integration_test_commands.md) | Running the host integration suites and the Patrol scenarios |
| [localization.md](guides/localization.md) | ARB files, keys, translations and the configurator catalog |
| [web.md](guides/web.md) | Flutter web support (experimental) |

## reference/

| Page | What it holds |
| --- | --- |
| [application_config.md](reference/application_config.md) | The main application configuration: features and behaviour |
| [application_embedded_config.md](reference/application_embedded_config.md) | Embedded web pages |
| [callkeep_dependency.md](reference/callkeep_dependency.md) | How webtrit_callkeep is declared: always a path, never a git ref |
| [color_scheme.md](reference/color_scheme.md) | The Material 3 color scheme and its theme files |
| [custom_login.md](reference/custom_login.md) | A custom login or sign-up page in a WebView |
| [environment.md](reference/environment.md) | Environment and Dart define variables |
| [integration_test_coverage.md](reference/integration_test_coverage.md) | What the Patrol scenarios cover |
| [integration_test_variables.md](reference/integration_test_variables.md) | Variables the integration tests read |
| [make_file.md](reference/make_file.md) | Melos scripts |
| [optional_features.md](reference/optional_features.md) | Features chosen at build time by permission or capability |
| [page_configuration.md](reference/page_configuration.md) | Page-level appearance configuration read from JSON |
| [qr_signin.md](reference/qr_signin.md) | QR code sign-in on the login screen |
| [widgets_configuration.md](reference/widgets_configuration.md) | UI component configuration |

## features/

Indexed by [features/features.md](features/features.md).
