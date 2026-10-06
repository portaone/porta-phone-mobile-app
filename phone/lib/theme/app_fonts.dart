import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import 'package:google_fonts/google_fonts.dart';
import 'package:logging/logging.dart';

final _logger = Logger('AppFonts');

/// The app's typeface: where it comes from and how the text theme names it.
///
/// Everything the app knows about fonts is here, and nothing else in it talks
/// to google_fonts.
///
/// A brand's typeface arrives as one file per weight in `assets/fonts/`, each
/// named `<Family>-<Weight>`. [load] registers all the files of a family
/// as ONE family under the name the theme uses, so a text style only names the
/// typeface and the engine picks the face for the weight asked - for a style
/// of the theme, for a `copyWith(fontWeight: ...)` on one, and for a style a
/// theme document spells out itself.
///
/// The registration is the engine's and lasts as long as the process, which is
/// why what was registered is kept here rather than handed down the tree.
abstract final class AppFonts {
  static const _directory = 'assets/fonts/';
  static const _extensions = ['.ttf', '.otf'];

  static final Set<String> _families = {};

  /// Whether [family] is ready to be drawn with: [load] found and registered it.
  static bool has(String family) => _families.contains(family);

  /// Readies the typefaces the theme names, before the first frame.
  ///
  /// Where a typeface comes from is this class's own business. Today it is
  /// the app's bundle: webtrit_phone_tools fetches the typeface during the
  /// white-label build, and fetching at runtime is turned off, because it
  /// would bring network work back into startup and hide a build that failed
  /// to bundle it. Only [families] are read - the faces are held in memory
  /// from here on.
  ///
  /// Nothing here stops the start. A typeface that cannot be had costs the
  /// brand its typeface, and the text is drawn in the platform one.
  static Future<void> load(Set<String> families, {AssetBundle? bundle}) async {
    bundle ??= rootBundle;
    GoogleFonts.config.allowRuntimeFetching = false;
    if (families.isEmpty) return;

    final Map<String, List<String>> bundled;
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(bundle);
      bundled = facesByFamily(manifest.listAssets());
    } catch (error, stackTrace) {
      _logger.warning('The bundle could not be searched for typefaces', error, stackTrace);
      return;
    }

    for (final family in families) {
      final faces = bundled[family];
      if (faces == null) continue;
      // Every face is read before any is handed over, because the loader
      // takes them one at a time and a read that fails while it waits on an
      // earlier one would fail unobserved, outside this handler.
      try {
        final loaded = await Future.wait(faces.map(bundle.load));
        final loader = FontLoader(family);
        for (final face in loaded) {
          loader.addFont(Future.value(face));
        }
        await loader.load();
        _families.add(family);
      } catch (error, stackTrace) {
        _logger.warning('Bundled typeface $family was not registered', error, stackTrace);
      }
    }
  }

  /// [base] in the typeface [family], or [base] itself where the theme names
  /// none or the app cannot have the one it names.
  static TextTheme textTheme(
    String? family,
    TextTheme base, {
    @visibleForTesting bool Function(String family) isLoaded = has,
    @visibleForTesting bool Function() mayFetch = _fetchingAllowed,
  }) {
    if (family == null) return base;

    // A bundled typeface is one family holding every weight, so the styles
    // name it and the weight of each is matched when the text is drawn. The
    // family repeats as a fallback for a style that names another typeface
    // the build does not carry.
    if (isLoaded(family)) {
      return base.apply(fontFamily: family, fontFamilyFallback: [family]);
    }

    // The app itself does not fetch, so a typeface its build lacks cannot be
    // had at all. Asking google_fonts for it anyway fails once for every
    // style, after this has returned: releases on google_fonts 8.1 reported
    // each of those as a fatal error, later ones swallow it. Either way the
    // text ends up in the platform typeface, so that is what is returned.
    if (!mayFetch()) {
      _logger.info('Typeface $family is not bundled; the platform one is used');
      return base;
    }

    // A host that draws the app without its bundle - the configurator's
    // preview - has the typeface fetched instead. That route binds a style to
    // a single face, chosen here, where the styles carry no weight yet: every
    // style gets the regular one whatever weight it is later drawn with.
    try {
      return GoogleFonts.getTextTheme(family, base);
    } catch (e) {
      return base;
    }
  }

  static bool _fetchingAllowed() => GoogleFonts.config.allowRuntimeFetching;

  /// The font files among [assets], grouped by the family each belongs to.
  ///
  /// The family is the file name up to its last hyphen: a family name may
  /// carry hyphens and spaces of its own, a weight name carries neither.
  @visibleForTesting
  static Map<String, List<String>> facesByFamily(Iterable<String> assets) {
    final families = <String, List<String>>{};

    for (final asset in assets) {
      if (!asset.startsWith(_directory)) continue;
      final file = asset.substring(_directory.length);
      if (file.contains('/')) continue;
      final dot = file.lastIndexOf('.');
      if (dot <= 0 || !_extensions.contains(file.substring(dot).toLowerCase())) continue;
      final name = file.substring(0, dot);
      final hyphen = name.lastIndexOf('-');
      final family = hyphen > 0 ? name.substring(0, hyphen) : name;
      families.putIfAbsent(family, () => []).add(asset);
    }

    return families;
  }
}
