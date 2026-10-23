import 'package:doomread/data/repositories/session_repository.dart';
import 'package:doomread/data/repositories/work_repository.dart';
import 'package:doomread/l10n/app_localizations.dart';
import 'package:doomread/ui/book/view_models/book_view_model.dart';
import 'package:doomread/ui/core/road_view.dart';
import 'package:doomread/ui/core/theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// The Book page: the Road, and the story so far in the user's own Notes.
class BookScreen extends StatelessWidget {
  const BookScreen({required this.workId, super.key});

  final String workId;

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
    create: (c) => BookViewModel(
      c.read<WorkRepository>(),
      c.read<SessionRepository>(),
      workId,
    ),
    child: const _Book(),
  );
}

class _Book extends StatelessWidget {
  const _Book();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final vm = context.watch<BookViewModel>();
    final road = vm.road;
    if (road == null) return Scaffold(appBar: AppBar());
    final work = road.work;
    final persian = Localizations.localeOf(context).languageCode == 'fa';
    final noteStyle = text.bodyMedium?.copyWith(
      fontFamily: bookFamily(context),
      color: Palette.paper,
      height: persian ? 1.85 : 1.5,
    );

    return Scaffold(
      appBar: AppBar(),
      body: ListView(
        padding: const EdgeInsetsDirectional.fromSTEB(24, 0, 24, 24),
        children: [
          Text(
            work.title,
            style: text.headlineSmall?.copyWith(
              fontFamily: bookFamily(context),
            ),
          ),
          if (work.author.isNotEmpty)
            Text(
              work.author,
              style: text.bodySmall?.copyWith(color: Palette.mute),
            ),
          const SizedBox(height: 16),
          RoadView(road: road),
          const SizedBox(height: 8),
          Text(
            road.finished
                ? l10n.bookFinished
                : l10n.pagesLeft(work.totalPages - road.position),
            style: text.bodyMedium,
          ),
          const SizedBox(height: 32),
          Text(l10n.storySoFar, style: text.titleMedium),
          const SizedBox(height: 4),
          if (vm.notes.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                l10n.storyEmpty,
                style: text.bodyMedium?.copyWith(color: Palette.mute),
              ),
            ),
          for (final note in vm.notes)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Palette.line)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.pageRange(note.from, note.to),
                    style: text.bodySmall?.copyWith(color: Palette.mute),
                  ),
                  const SizedBox(height: 2),
                  Text(note.text, style: noteStyle),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
