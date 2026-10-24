import 'dart:async';

import 'package:doomread/data/repositories/session_repository.dart';
import 'package:doomread/data/services/share_sheet.dart';
import 'package:doomread/l10n/app_localizations.dart';
import 'package:doomread/ui/core/theme.dart';
import 'package:doomread/ui/core/yalda.dart';
import 'package:doomread/ui/share/poster_image.dart';
import 'package:doomread/ui/share/view_models/share_view_model.dart';
import 'package:doomread/ui/share/widgets/yalda_poster.dart';
import 'package:doomread/ui/tonight/view_models/yalda_view_model.dart';
import 'package:doomread/utils/result.dart';
import 'package:doomread_core/doomread_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';

/// Tonight's line on Shab-e Yalda, by a painted pomegranate, and once
/// something's been read tonight, the way to the Yalda poster. Every other
/// night it's nothing at all.
class YaldaTonight extends StatelessWidget {
  const YaldaTonight({required this.kind, super.key});

  /// The current Work's kind, so the line says read, watch or listen.
  final WorkKind kind;

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
    create: (c) => YaldaViewModel(c.read<SessionRepository>()),
    child: _YaldaLine(kind: kind),
  );
}

class _YaldaLine extends StatelessWidget {
  const _YaldaLine({required this.kind});

  final WorkKind kind;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<YaldaViewModel>();
    if (!vm.yalda) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final work = vm.work;
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsetsDirectional.only(top: 2, end: 10),
                child: Pomegranate(),
              ),
              Expanded(
                child: Text(
                  l10n.yaldaTonight(kind.name),
                  style: text.bodyMedium!.copyWith(color: YaldaPalette.me),
                ),
              ),
            ],
          ),
          if (work != null && vm.minutes > 0)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => YaldaShareScreen(
                      poster: YaldaPoster(
                        work: work,
                        minutes: vm.minutes,
                        house: vm.house,
                        evening: vm.evening,
                      ),
                    ),
                  ),
                ),
                child: Text(l10n.yaldaShare),
              ),
            ),
        ],
      ),
    );
  }
}

/// The Yalda poster as it will be shared, then Share: the Finish poster's
/// preview and pipeline, with nothing to switch.
class YaldaShareScreen extends StatelessWidget {
  const YaldaShareScreen({required this.poster, super.key});

  final YaldaPoster poster;

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
    create: (c) => ShareViewModel(
      c.read<SessionRepository>(),
      c.read<ShareSheet>(),
      workId: poster.work.id,
    ),
    child: _Preview(poster: poster),
  );
}

class _Preview extends StatefulWidget {
  const _Preview({required this.poster});

  final YaldaPoster poster;

  @override
  State<_Preview> createState() => _PreviewState();
}

class _PreviewState extends State<_Preview> {
  final GlobalKey _boundary = GlobalKey();
  late final ShareViewModel _vm = context.read<ShareViewModel>();

  @override
  void initState() {
    super.initState();
    _vm.share.addListener(_shared);
  }

  @override
  void dispose() {
    _vm.share.removeListener(_shared);
    super.dispose();
  }

  /// Says where the poster went on Linux, or that sharing failed.
  void _shared() {
    final l10n = AppLocalizations.of(context);
    final message = switch (_vm.share.result) {
      Ok(value: final path?) => l10n.shareSavedTo(path),
      Error() => l10n.shareFailed,
      _ => null,
    };
    if (message == null) return;
    _vm.share.clearResult();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _share() async {
    final title = AppLocalizations.of(context).shareSendTo;
    final boundary =
        _boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final png = await posterPng(boundary);
    await _vm.share.execute((png: png, title: title));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.sharePreviewTitle)),
      body: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                child: Center(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Palette.line),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      // Scaled to the phone; drawn full size when shared.
                      child: FittedBox(
                        child: RepaintBoundary(
                          key: _boundary,
                          child: widget.poster,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(24, 8, 24, 16),
              child: ListenableBuilder(
                listenable: _vm.share,
                builder: (context, _) => FilledButton(
                  onPressed: _vm.share.running
                      ? null
                      : () => unawaited(_share()),
                  child: Text(l10n.shareSend),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
