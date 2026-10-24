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

/// Any share card as it will be shared, with optional [controls] under it,
/// then Share. What's shared is exactly what's shown, drawn full size.
///
/// [poster] is laid out on the fixed card canvas (see `PosterCanvas`).
class SharePreview extends StatelessWidget {
  const SharePreview({
    required this.poster,
    this.controls = const [],
    super.key,
  });

  final Widget poster;
  final List<Widget> controls;

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
    create: (c) =>
        ShareViewModel(c.read<ShareSheet>(), c.read<SessionRepository>().now),
    child: _Preview(poster: poster, controls: controls),
  );
}

class _Preview extends StatefulWidget {
  const _Preview({required this.poster, required this.controls});

  final Widget poster;
  final List<Widget> controls;

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
                          child: widget.poster,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            ...widget.controls,
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

/// Whether this platform can share a card at all: an action that opens
/// one is only offered when it can.
bool canShare(BuildContext context) => context.read<ShareSheet>().available;

/// Opens [poster] in the share preview, with [controls] under it, if this
/// platform can share. It ends when the preview is closed.
Future<void> openSharePreview(
  BuildContext context,
  Widget poster, {
  List<Widget> controls = const [],
}) async {
  if (!canShare(context)) return;
  await Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => SharePreview(poster: poster, controls: controls),
    ),
  );
}

/// Opens the Finish poster to share, with the switch for the Note. Its
/// extras are watched only while the preview is open.
Future<void> openFinishPreview(
  BuildContext context, {
  required Finish finish,
  required int floors,
  required int floor,
}) async {
  final vm = FinishShareViewModel(
    context.read<SessionRepository>(),
    workId: finish.work.id,
  );
  try {
    await openSharePreview(
      context,
      FinishShareCard(vm: vm, finish: finish, floors: floors, floor: floor),
      controls: [FinishNoteSwitch(vm: vm)],
    );
  } finally {
    vm.dispose();
  }
}

/// The Finish poster with what [vm] has found to go on it.
class FinishShareCard extends StatelessWidget {
  const FinishShareCard({
    required this.vm,
    required this.finish,
    required this.floors,
    required this.floor,
    super.key,
  });

  final FinishShareViewModel vm;
  final Finish finish;

  /// How many floors the Building has, and which one, from the top, is
  /// this Finish.
  final int floors;
  final int floor;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: vm,
    builder: (context, _) => FinishPoster(
      finish: finish,
      floors: floors,
      floor: floor,
      urgesLetPass: vm.extras.urgesLetPass,
      note: vm.note,
    ),
  );
}

/// The switch for whether the Finish poster carries the user's last Note;
/// shown only when there is one.
class FinishNoteSwitch extends StatelessWidget {
  const FinishNoteSwitch({required this.vm, super.key});

  final FinishShareViewModel vm;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: vm,
      builder: (context, _) => vm.extras.lastNote == null
          ? const SizedBox.shrink()
          : SwitchListTile(
              key: const Key('showNote'),
              contentPadding: const EdgeInsets.symmetric(horizontal: 24),
              title: Text(l10n.shareShowNote),
              subtitle: Text(l10n.shareShowNoteHint),
              value: vm.showNote,
              onChanged: (on) => vm.showNote = on,
            ),
    );
  }
}
