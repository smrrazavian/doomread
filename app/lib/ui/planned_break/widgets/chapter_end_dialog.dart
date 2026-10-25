import 'package:doomread/l10n/app_localizations.dart';
import 'package:doomread/ui/core/number_format.dart';
import 'package:doomread/ui/core/theme.dart';
import 'package:flutter/material.dart';

/// "Chapter done" on an estimate: asks the page [chapter] really ended on,
/// starting from the [estimate]. It's somewhere after the Position [after]
/// and before the end [before]. Null when the user says not yet.
Future<int?> askChapterEnd(
  BuildContext context, {
  required int chapter,
  required int estimate,
  required int after,
  required int before,
}) => showDialog<int>(
  context: context,
  builder: (_) => _ChapterEndDialog(
    chapter: chapter,
    estimate: estimate.clamp(after + 1, before - 1),
    after: after,
    before: before,
  ),
);

class _ChapterEndDialog extends StatefulWidget {
  const _ChapterEndDialog({
    required this.chapter,
    required this.estimate,
    required this.after,
    required this.before,
  });

  final int chapter;
  final int estimate;
  final int after;
  final int before;

  @override
  State<_ChapterEndDialog> createState() => _ChapterEndDialogState();
}

class _ChapterEndDialogState extends State<_ChapterEndDialog> {
  final _page = TextEditingController();
  var _prefilled = false;
  var _problem = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // In the user's digits, once the locale is known.
    if (_prefilled) return;
    _prefilled = true;
    _page.text = formatNumber(widget.estimate, Localizations.localeOf(context));
  }

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  bool _fits(int page) => page > widget.after && page < widget.before;

  void _step(int by) {
    final page = (parseNumber(_page.text) ?? widget.estimate) + by;
    if (!_fits(page)) return;
    _page.text = formatNumber(page, Localizations.localeOf(context));
    setState(() => _problem = false);
  }

  void _save() {
    final page = parseNumber(_page.text);
    if (page == null || !_fits(page)) {
      setState(() => _problem = true);
      return;
    }
    Navigator.pop(context, page);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    return AlertDialog(
      backgroundColor: Palette.panel,
      title: Text(l10n.chapterEndedOn(widget.chapter)),
      content: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Level with the field, which grows downwards with a problem under
          // it.
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: IconButton.filledTonal(
              key: const Key('chapterEndDown'),
              onPressed: () => _step(-1),
              icon: const Icon(Icons.remove),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: SizedBox(
              width: 104,
              child: TextField(
                key: const Key('chapterEnd'),
                controller: _page,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                style: text.headlineSmall,
                onChanged: (_) => setState(() => _problem = false),
                onSubmitted: (_) => _save(),
                decoration: InputDecoration(
                  errorMaxLines: 3,
                  errorText: _problem
                      ? l10n.problemChapterEnd(widget.after, widget.before)
                      : null,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: IconButton.filledTonal(
              key: const Key('chapterEndUp'),
              onPressed: () => _step(1),
              icon: const Icon(Icons.add),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.chapterEndNotYet),
        ),
        FilledButton(
          key: const Key('chapterEndSave'),
          onPressed: _save,
          child: Text(l10n.save),
        ),
      ],
    );
  }
}
