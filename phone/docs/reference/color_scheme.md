# Color Scheme Description

The app's Material 3 color scheme is generated from a single `seedColor`, and any role can be
overridden with a fixed value under `colorSchemeOverride`. Both live in two files:

- `assets/themes/original.color_scheme.light.config.json` - light mode
- `assets/themes/original.color_scheme.dark.config.json` - dark mode

A color set in a widget's configuration (see [widgets_configuration.md](widgets_configuration.md),
e.g. `"backgroundColor": "#75B943"`) takes precedence over the base theme color.

Reference: [Material 3 Color Roles](https://m3.material.io/styles/color/roles/color-roles)
