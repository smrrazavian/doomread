import 'dart:math' as math;

import 'package:doomread/l10n/app_localizations.dart';
import 'package:doomread/ui/core/number_format.dart';
import 'package:doomread/ui/core/theme.dart';
import 'package:doomread/ui/core/yalda.dart';
import 'package:doomread/ui/reading/widgets/house_view.dart';
import 'package:doomread_core/doomread_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show NumberFormat;

/// Shab-e Yalda as a story-sized poster: the House in Yalda light under the
/// longest night's sky, what the user read, and for how long tonight.
///
/// Like the Finish poster, it's laid out on a fixed [size] canvas and drawn
/// at three times that for a 1080×1920 image, and Persian gets its own
/// layout: right to left, Persian digits, Naskh for the title.
class YaldaPoster extends StatelessWidget {
  const YaldaPoster({
    required this.work,
    required this.minutes,
    required this.house,
    required this.evening,
    super.key,
  });

  /// The canvas, in logical pixels; the image is three times this.
  static const size = Size(360, 640);

  /// What was read tonight; the last of it, if there was more than one.
  final Work work;

  /// Tonight's reading, in whole minutes.
  final int minutes;

  /// The House's Windows, from the journal.
  final List<HouseWindow> house;

  /// Tonight, for the year on the date line.
  final DateTime evening;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final fa = locale.languageCode == 'fa';
    final type = _Type(fa: fa);
    final heading = l10n.yaldaPosterHeading(work.kind.name);
    // Persian counts years from the Hijra, as Yalda itself does.
    final year = NumberFormat(
      '0',
      locale.languageCode,
    ).format(fa ? toSolarHijri(evening).year : evening.year);

    return MediaQuery(
      // The same poster on every phone, and the House already lit.
      data: const MediaQueryData(
        size: size,
        textScaler: TextScaler.noScaling,
        disableAnimations: true,
      ),
      child: SizedBox.fromSize(
        size: size,
        child: Material(
          type: MaterialType.transparency,
          child: ClipRect(
            child: Stack(
              children: [
                const Positioned.fill(child: CustomPaint(painter: _Sky())),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsetsDirectional.fromSTEB(
                        24,
                        28,
                        24,
                        0,
                      ),
                      child: _Wordmark(l10n.appTitle, type),
                    ),
                    Expanded(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Stack(
                          clipBehavior: Clip.none,
                          alignment: Alignment.bottomCenter,
                          children: [
                            const Positioned(
                              left: -40,
                              right: -40,
                              bottom: -60,
                              height: 300,
                              child: CustomPaint(painter: _Glow()),
                            ),
                            HouseView(
                              windows: house,
                              kind: work.kind,
                              yalda: true,
                              caption: false,
                            ),
                          ],
                        ),
                      ),
                    ),
                    DecoratedBox(
                      decoration: const BoxDecoration(
                        color: Palette.deep,
                        border: Border(
                          top: BorderSide(color: Palette.line, width: 1.5),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsetsDirectional.fromSTEB(
                          24,
                          24,
                          24,
                          28,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: '$heading\n',
                                    style: type.heading,
                                  ),
                                  TextSpan(
                                    // Isolated, so a Latin title in Persian
                                    // can't pull the guillemets around.
                                    text: l10n.sharePosterTitle(
                                      '\u2068${work.title}\u2069',
                                    ),
                                  ),
                                ],
                              ),
                              style: type.title,
                              maxLines: 4,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (work.author.trim().isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Text(
                                work.author,
                                style: type.author,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                            const SizedBox(height: 20),
                            Text(
                              formatNumber(minutes, locale),
                              style: type.number,
                            ),
                            Text(
                              l10n.yaldaPosterMinutes(minutes),
                              style: type.label,
                            ),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                const Pomegranate(size: 22, half: true),
                                const SizedBox(width: 10),
                                Text(
                                  l10n.yaldaPosterNight(year),
                                  style: type.label,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The poster's type, apart from the app theme so it can't drift with it.
class _Type {
  _Type({required bool fa})
    : heading = TextStyle(
        fontSize: fa ? 20 : 21,
        height: fa ? 1.7 : 1.35,
        fontWeight: FontWeight.w400,
        fontVariations: const [FontVariation.weight(400)],
        color: Palette.soft,
      ),
      title = TextStyle(
        fontFamily: fa ? 'NotoNaskhArabic' : 'Literata',
        fontFamilyFallback: [if (fa) 'Literata' else 'NotoNaskhArabic'],
        fontSize: fa ? 30 : 32,
        height: fa ? 1.55 : 1.15,
        fontWeight: FontWeight.w600,
        fontVariations: const [FontVariation.weight(600)],
        letterSpacing: 0,
        color: Palette.paper,
      ),
      author = _ui(fa, 14, Palette.mute),
      number = TextStyle(
        fontFamily: fa ? 'VazirmatnUI' : 'Literata',
        fontFamilyFallback: [if (fa) 'BricolageGrotesque' else 'VazirmatnUI'],
        fontSize: fa ? 30 : 34,
        height: 1.2,
        fontWeight: fa ? FontWeight.w700 : FontWeight.w500,
        fontVariations: fa ? null : const [FontVariation.weight(500)],
        letterSpacing: 0,
        color: YaldaPalette.me,
      ),
      label = _ui(fa, 13, Palette.mute),
      mark = _ui(fa, 14, Palette.paper, FontWeight.w500);

  final TextStyle heading;
  final TextStyle title;
  final TextStyle author;
  final TextStyle number;
  final TextStyle label;
  final TextStyle mark;

  static TextStyle _ui(
    bool fa,
    double size,
    Color color, [
    FontWeight w = FontWeight.w400,
  ]) => TextStyle(
    fontFamily: fa ? 'VazirmatnUI' : 'BricolageGrotesque',
    fontFamilyFallback: [if (fa) 'BricolageGrotesque' else 'VazirmatnUI'],
    fontSize: size,
    height: fa ? 1.7 : 1.4,
    fontWeight: w,
    fontVariations: [FontVariation.weight(w.value.toDouble())],
    letterSpacing: 0,
    color: color,
  );
}

/// A small window in Yalda light and the app's name.
class _Wordmark extends StatelessWidget {
  const _Wordmark(this.name, this.type);

  final String name;
  final _Type type;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 10,
        height: 12,
        decoration: BoxDecoration(
          color: YaldaPalette.lamp,
          borderRadius: BorderRadius.circular(1.5),
          boxShadow: [
            BoxShadow(
              color: YaldaPalette.lamp.withValues(alpha: 0.5),
              blurRadius: 8,
            ),
          ],
        ),
      ),
      const SizedBox(width: 8),
      Text(name, style: type.mark),
    ],
  );
}

/// The House's warm light on the night around it.
class _Glow extends CustomPainter {
  const _Glow();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          colors: [
            YaldaPalette.lamp.withValues(alpha: 0.16),
            YaldaPalette.rind.withValues(alpha: 0.05),
            YaldaPalette.rind.withValues(alpha: 0),
          ],
          stops: const [0, 0.5, 1],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_Glow oldDelegate) => false;
}

/// The longest night: deep at the top, a little lighter toward the street,
/// and more stars than usual. They're placed by a fixed seed, so every
/// Yalda poster has the same sky.
class _Sky extends CustomPainter {
  const _Sky();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Palette.zenith, Palette.deep, Palette.night],
          stops: [0, 0.4, 0.62],
        ).createShader(rect),
    );
    final random = math.Random(1405);
    final star = Paint();
    for (var i = 0; i < 70; i++) {
      final at = Offset(
        random.nextDouble() * size.width,
        24 + random.nextDouble() * size.height * 0.4,
      );
      final r = 0.5 + random.nextDouble() * 0.9;
      star.color = Palette.paper.withValues(
        alpha: 0.2 + random.nextDouble() * 0.5,
      );
      canvas.drawCircle(at, r, star);
    }
  }

  @override
  bool shouldRepaint(_Sky oldDelegate) => false;
}
