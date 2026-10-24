import 'package:doomread/data/repositories/session_repository.dart';
import 'package:doomread/ui/settings/view_models/settings_view_model.dart';
import 'package:doomread/ui/share/view_models/receipt_view_model.dart';
import 'package:doomread/ui/share/widgets/receipt_poster.dart';
import 'package:doomread/ui/share/widgets/share_preview_screen.dart';
import 'package:doomread_core/doomread_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Tonight's receipt, ready to share. Opened only from End of the evening's
/// "share tonight", after the Session is saved, so the pages are known.
class ReceiptShareScreen extends StatelessWidget {
  const ReceiptShareScreen({required this.sessionId, super.key});

  final String sessionId;

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
    create: (c) => ReceiptViewModel(c.read<SessionRepository>(), sessionId),
    builder: (context, _) {
      final vm = context.watch<ReceiptViewModel>();
      final record = vm.record;
      if (record == null) return Scaffold(appBar: AppBar());
      return SharePreview(
        poster: ReceiptPoster(
          work: record.road.work,
          session: vm.session!,
          pages: record.pages,
          signOff: receiptSignOff(
            vm.session!,
            context.watch<SettingsViewModel>().tone,
            Localizations.localeOf(context).languageCode,
          ),
        ),
      );
    },
  );
}
