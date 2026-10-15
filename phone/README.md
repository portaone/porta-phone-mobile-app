# WebTrit Phone

WebTrit Phone is a feature-rich application designed for seamless communication.

## Flutter Project Environment Setup

Use the following setup to ensure compatibility with this branch:

- **Flutter**: 3.47.1 (stable channel)
- **Android SDK**: 35.0.1

Please align your local environment with these versions for consistent behavior across development and testing workflows.

## Documentation Overview

[docs/README.md](docs/README.md) is the map of every page and the order they are usually read in.

- **Environment**: See the [Environment](docs/reference/environment.md) documentation for details on environment properties.
- **SSL Certificates**: Refer to the [SSL Certificates](docs/guides/certificates.md) documentation for information on SSL
  certificate handling.
- **Build Process**: Learn more about build configurations in the [Build](docs/guides/build.md) documentation.
- **Scripts**: Icons, splash, package name and the configurator step are melos scripts - [Melos Commands](docs/reference/make_file.md).
- **Localization**: For information on localization settings, see [Localization](docs/guides/localization.md).

## Application Configuration

The application offers extensive customization options:

- **[Color Scheme](docs/reference/color_scheme.md)** – Customize the application's color palette.
- **[Widgets](docs/reference/widgets_configuration.md)** – Configure UI widgets according to your needs.
- **[Fonts](docs/architecture/fonts.md)** – How the theme's typeface is bundled, loaded and drawn.
- **[Pages](docs/reference/page_configuration.md)** – Customize pages and their layouts.
- **[Features](docs/reference/application_config.md)** – Enable or disable specific features.
  - [Custom Login](docs/reference/custom_login.md) – Implement a custom login page.
  - [Embedded pages](docs/reference/application_embedded_config.md) –  Implements embedded pages that extend the WebTrit app with custom web content.

## Development & Build
 - **Build and run**: See the [Build and Run](docs/guides/build.md) documentation for details on how to build and run the application.
 - **Optional features**: See [Optional Android Features](docs/reference/optional_features.md) for the features whose permissions and manifest components are included only when the build enables them.
 - **Melos Commands**: See the [Melos Commands](docs/reference/make_file.md) for all available build, run, and automation commands.
 - **Development Workflow and Git Hooks**: See the [Development Guide](docs/guides/development.md) for details on commit conventions, hook setup, and workflow tools.
 - **Accessibility**: See the [Accessibility Guide](docs/guides/accessibility.md) for what every interactive control must expose to screen readers and UI automation, and how to verify it.
 - **Startup time**: See [Where cold start time goes](docs/architecture/startup.md) for the measured breakdown of a cold start and the candidates worth optimising next.
 - **Background polling**: See [Background Polling](docs/architecture/polling.md) for scheduler behavior and [Polling Worker Pattern](docs/architecture/polling_workers.md) for feature worker boundaries, ownership, and migration rules.
 - **Contact lookup by number**: See [Finding the contact a phone number belongs to](packages/data/app_database/docs/contact_lookup_by_number.md) for the exact-then-ending lookup, the two invariants that keep it from naming the wrong person, and what it deliberately does not do.
 - **Contact search**: See [Searching the contacts list](packages/data/app_database/docs/contact_search.md) for which contacts a search keeps, how they are ranked, and why the condition is on a contact rather than a row of the query.

# Testing

### Unit and widget tests
* Run unit and widget tests:
  ```bash
  flutter test
  ```
### Integration tests
- **Framework**: We use Patrol framework for integration testing.
It helps us to automate native iOS and Android behaviors and simplifyes routine tasks during testing.
You can find more information about it here: https://patrol.dev/ 
Integration tests are located in the `patrol_test` folder.

- **Configuration**: The configuration file `dart_define.integration_test.json` defines all the environment variables (login credentials, contacts, user info, and call settings) for the integration tests. [Integration Test Variables](docs/reference/integration_test_variables.md).

- **Calls test**: For simulating SIP calls during tests, here is [pjsua Companion](packages/pjsua_companion/README.md) — an HTTP server that wraps the `pjsua` CLI to place and answer calls programmatically when app tests is running.

- **Commands**: See [Integration Test Commands](docs/guides/integration_test_commands.md) for all patrol build, run, Firebase Test Lab, and local companion commands.

- **Coverage**: See [Integration Test Coverage](docs/reference/integration_test_coverage.md) for a description of every test file and its steps.

### Manual testing on real devices

- **BrowserStack App Live**: See [BrowserStack App Live Upload](docs/guides/browserstack_upload.md) for uploading builds to BrowserStack and testing them manually on real devices.

## Contributing

We welcome contributions from the community! Please follow our contribution guidelines when submitting changes for review.

## License

This project is licensed under the [MIT License](LICENSE).

## Acknowledgments

This project is tested with [BrowserStack](https://www.browserstack.com/).