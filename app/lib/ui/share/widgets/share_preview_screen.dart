import 'dart:async';

import 'package:doomread/data/repositories/session_repository.dart';
import 'package:doomread/data/services/share_sheet.dart';
import 'package:doomread/l10n/app_localizations.dart';
import 'package:doomread/ui/core/theme.dart';
import 'package:doomread/ui/share/poster_image.dart';
import 'package:doomread/ui/share/view_models/share_view_model.dart';
import 'package:doomread/ui/share/widgets/finish_poster.dart';
import 'package:doomread/utils/result.dart';
import 'package:doomread_core/doomread_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';

/// The Finish poster as it will be shared, with the switch for the Note,
/// then Share. What's shared is exactly what's shown, drawn full size.
class SharePreviewScreen extends StatelessWidget {
  const SharePreviewScreen({
    required this.finish,
    required this.floors,
    required this.floor,
    this.sheet,
    super.key,
  });

  final Finish finish;

  /// How many floors the Building has, and which one, from the top, is
  /// this Finish.
  final int floors;
  final int floor;

  /// Where the image goes; tests pass a fake.
  final ShareSheet? sheet;

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
    create: (c) => ShareViewModel(
      c.read<SessionRepository>(),
      sheet ?? ShareSheet(),
      workId: finish.work.id,
    ),
    child: _Preview(finish: finish, floors: floors, floor: floor),
  );
}

class _Preview extends StatefulWidget {
  const _Preview({
    required this.finish,
    required this.floors,
    required this.floor,
  });

  final Finish finish;
  final int floors;
  final int floor;

  @override
  State<_Preview> createState() => _PreviewState();
}

class _PreviewState extends State<_Preview> {
  final GlobalKey _poster = GlobalKey();
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
        _poster.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final png = await posterPng(boundary);
    await _vm.share.execute((png: png, title: title));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final vm = context.watch<ShareViewModel>();
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
                          key: _poster,
                          child: FinishPoster(
                            finish: widget.finish,
                            floors: widget.floors,
                            floor: widget.floor,
                            urgesLetPass: vm.extras.urgesLetPass,
                            note: vm.note,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (vm.extras.lastNote != null)
              SwitchListTile(
                key: const Key('showNote'),
                contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                title: Text(l10n.shareShowNote),
                subtitle: Text(l10n.shareShowNoteHint),
                value: vm.showNote,
                onChanged: (on) => vm.showNote = on,
              ),
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(24, 8, 24, 16),
              child: ListenableBuilder(
                listenable: vm.share,
                builder: (context, _) => FilledButton(
                  onPressed: vm.share.running
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
