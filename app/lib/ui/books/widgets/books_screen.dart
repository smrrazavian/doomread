import 'dart:async';

import 'package:doomread/data/repositories/work_repository.dart';
import 'package:doomread/domain/use_cases/stop_deleted_sessions_use_case.dart';
import 'package:doomread/l10n/app_localizations.dart';
import 'package:doomread/ui/books/view_models/books_view_model.dart';
import 'package:doomread/ui/core/theme.dart';
import 'package:doomread/ui/core/work_text.dart';
import 'package:doomread_core/doomread_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class BooksScreen extends StatelessWidget {
  const BooksScreen({super.key});

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
    create: (c) => BooksViewModel(
      c.read<WorkRepository>(),
      c.read<StopDeletedSessionsUseCase>(),
    ),
    // Its own messenger, so the Undo snackbar lifts the Library's button
    // instead of covering it from the shell's Scaffold.
    child: const ScaffoldMessenger(child: _Books()),
  );
}

class _Books extends StatelessWidget {
  const _Books();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final vm = context.watch<BooksViewModel>();
    return Scaffold(
      appBar: AppBar(title: Text(l10n.navBooks)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/work/new'),
        icon: const Icon(Icons.add),
        label: Text(l10n.tonightAddBook),
      ),
      body: vm.works.isEmpty
          ? Center(child: Text(l10n.booksEmpty))
          : ListView(
              padding: const EdgeInsets.only(bottom: 96),
              children: [
                for (final work in vm.works)
                  Dismissible(
                    key: ValueKey(work.id),
                    background: const _DeleteBackground(
                      AlignmentDirectional.centerStart,
                    ),
                    secondaryBackground: const _DeleteBackground(
                      AlignmentDirectional.centerEnd,
                    ),
                    onDismissed: (_) => _delete(context, vm, work),
                    child: ListTile(
                      title: Text(work.title),
                      subtitle: Text(
                        work.id == vm.currentId
                            ? l10n.workNow(work.kind.name)
                            : work.author,
                      ),
                      leading: Icon(
                        work.id == vm.currentId
                            ? Icons.nightlight
                            : kindIcon(work.kind),
                        color: work.id == vm.currentId
                            ? Palette.lamp
                            : Palette.mute,
                      ),
                      onTap: () => vm.makeCurrent(work.id),
                      trailing: IconButton(
                        tooltip: l10n.editBook,
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () async {
                          final delete = await context.push<bool>(
                            '/work/edit',
                            extra: work,
                          );
                          if (delete == true && context.mounted) {
                            _delete(context, vm, work);
                          }
                        },
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

/// Deletes [work] and offers to undo it.
void _delete(BuildContext context, BooksViewModel vm, Work work) {
  final l10n = AppLocalizations.of(context);
  final current = work.id == vm.currentId;
  unawaited(vm.delete(work));
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(l10n.workDeleted(work.title)),
        // With an action, Flutter keeps it up for good unless told not to.
        persist: false,
        action: SnackBarAction(
          label: l10n.undo,
          onPressed: () => unawaited(vm.restore(work, current: current)),
        ),
      ),
    );
}

class _DeleteBackground extends StatelessWidget {
  const _DeleteBackground(this.alignment);

  final AlignmentDirectional alignment;

  @override
  Widget build(BuildContext context) => Container(
    color: Theme.of(context).colorScheme.errorContainer,
    alignment: alignment,
    padding: const EdgeInsets.symmetric(horizontal: 24),
    child: Icon(
      Icons.delete_outline,
      color: Theme.of(context).colorScheme.onErrorContainer,
    ),
  );
}
