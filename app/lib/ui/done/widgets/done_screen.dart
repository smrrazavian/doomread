import 'dart:async';
import 'dart:math' as math;

import 'package:doomread/data/repositories/session_repository.dart';
import 'package:doomread/data/repositories/work_repository.dart';
import 'package:doomread/domain/use_cases/task_done_use_case.dart';
import 'package:doomread/l10n/app_localizations.dart';
import 'package:doomread/ui/core/number_format.dart';
import 'package:doomread/ui/core/theme.dart';
import 'package:doomread/ui/done/view_models/done_view_model.dart';
import 'package:doomread/ui/settings/view_models/settings_view_model.dart';
import 'package:doomread/utils/result.dart';
import 'package:doomread_core/doomread_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

/// Where a Task's Done moment is.
String donePath(String taskId) => '/done/$taskId';

/// A Task's Done moment, played once: a big window lights from dark to
/// lamplight, with a soft glow and faint rays, over what it took and the
/// way on. A firm buzz with it. With reduced motion, the window is lit at
/// once.
class DoneScreen extends StatelessWidget {
  const DoneScreen({required this.taskId, super.key});

  final String taskId;

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
    create: (c) => DoneViewModel(
      c.read<WorkRepository>(),
      c.read<SessionRepository>(),
      c.read<TaskDoneUseCase>(),
      taskId,
    ),
    child: const _Done(),
  );
}

class _Done extends StatefulWidget {
  const _Done();

  @override
  State<_Done> createState() => _DoneState();
}

class _DoneState extends State<_Done> with SingleTickerProviderStateMixin {
  late final _light = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void initState() {
    super.initState();
    unawaited(HapticFeedback.heavyImpact());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _light.value = 1;
    } else if (_light.isDismissed) {
      _light.forward();
    }
  }

  @override
  void dispose() {
    _light.dispose();
    super.dispose();
  }

  void _toToday() => context.go('/tonight');

  Future<void> _next(DoneViewModel vm) async {
    await vm.startNext.execute();
    if (!mounted) return;
    if (vm.startNext.result case Ok(:final value)) {
      unawaited(HapticFeedback.lightImpact());
      context.pushReplacement('/reading/$value');
    }
  }

  Future<void> _undo(DoneViewModel vm) async {
    await vm.undo.execute();
    if (mounted) _toToday();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final locale = Localizations.localeOf(context);
    final vm = context.watch<DoneViewModel>();
    final task = vm.task;
    if (!vm.loaded || task == null) return const Scaffold();
    final next = vm.next;
    final line = doneLine(
      vm.sessions,
      context.watch<SettingsViewModel>().tone,
      locale.languageCode,
      minutes: formatNumber(vm.minutes, locale),
    );
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Center(child: _BigWindow(light: _light)),
              ),
              Text(
                l10n.doneTitle(task.name),
                textAlign: TextAlign.center,
                style: text.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(line, textAlign: TextAlign.center, style: text.bodyMedium),
              const SizedBox(height: 28),
              Row(
                children: [
                  _Stat(vm.minutes, l10n.doneMinutes),
                  _Stat(vm.longest, l10n.doneLongest),
                  _Stat(vm.urgesLetPass, l10n.doneUrges),
                ],
              ),
              const SizedBox(height: 32),
              if (next != null) ...[
                FilledButton(
                  onPressed: vm.startNext.running ? null : () => _next(vm),
                  child: Text(l10n.doneNext(next.name)),
                ),
                const SizedBox(height: 8),
              ],
              OutlinedButton(
                onPressed: _toToday,
                child: Text(l10n.doneBreather),
              ),
              const SizedBox(height: 4),
              TextButton(
                onPressed: vm.undo.running ? null : () => _undo(vm),
                child: Text(l10n.undo),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.value, this.label);

  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Expanded(
      child: Column(
        children: [
          Text(
            formatNumber(value, Localizations.localeOf(context)),
            style: text.headlineSmall?.copyWith(color: Palette.me),
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            style: text.bodySmall?.copyWith(color: Palette.mute),
          ),
        ],
      ),
    );
  }
}

/// The big window, lighting up as [light] runs from 0 to 1.
class _BigWindow extends StatelessWidget {
  const _BigWindow({required this.light});

  final Animation<double> light;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox.square(
      dimension: 240,
      child: AnimatedBuilder(
        animation: light,
        builder: (context, _) => CustomPaint(
          painter: _WindowPainter(Curves.easeOut.transform(light.value)),
        ),
      ),
    ),
  );
}

class _WindowPainter extends CustomPainter {
  _WindowPainter(this.t);

  /// How lit it is, from 0 (dark) to 1 (lamplight).
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final pane = Rect.fromCenter(center: c, width: 96, height: 124);
    // Faint rays, then the glow, then the window and its cross bars.
    final ray = Paint()
      ..color = Palette.lamp.withValues(alpha: 0.35 * t)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 8; i++) {
      final a = i * math.pi / 4;
      final d = Offset(math.cos(a), math.sin(a));
      canvas.drawLine(c + d * 92, c + d * 116, ray);
    }
    canvas
      ..drawRRect(
        RRect.fromRectAndRadius(pane.inflate(18), const Radius.circular(24)),
        Paint()
          ..color = Palette.lamp.withValues(alpha: 0.4 * t)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 28),
      )
      ..drawRRect(
        RRect.fromRectAndRadius(pane, const Radius.circular(6)),
        Paint()..color = Color.lerp(Palette.unlit, Palette.lamp, t)!,
      )
      ..drawRRect(
        RRect.fromRectAndRadius(pane, const Radius.circular(6)),
        Paint()
          ..color = Color.lerp(Palette.line, Palette.me, t)!
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    final bar = Paint()
      ..color = Color.lerp(Palette.line, Palette.tickPassed, t)!
      ..strokeWidth = 3;
    canvas
      ..drawLine(pane.topCenter, pane.bottomCenter, bar)
      ..drawLine(pane.centerLeft, pane.centerRight, bar);
  }

  @override
  bool shouldRepaint(_WindowPainter old) => old.t != t;
}
