import 'package:doomread/data/repositories/work_repository.dart';
import 'package:doomread/l10n/app_localizations.dart';
import 'package:doomread/ui/books/view_models/books_view_model.dart';
import 'package:doomread/ui/core/theme.dart';
import 'package:doomread/ui/core/work_text.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class BooksScreen extends StatelessWidget {
  const BooksScreen({super.key});

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
    create: (c) => BooksViewModel(c.read<WorkRepository>()),
    child: const _Books(),
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
                  ListTile(
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
                      onPressed: () => context.push('/work/edit', extra: work),
                    ),
                  ),
              ],
            ),
    );
  }
}
