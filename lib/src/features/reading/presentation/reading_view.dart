import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';
import 'package:maltto/src/features/reading/domain/reading_session.dart';
import 'package:maltto/src/features/reading/presentation/reading_view_model.dart';
import 'package:maltto/src/shared/design/app_tokens.dart';
import 'package:maltto/src/shared/design/app_components.dart';

part 'reading_view_components.dart';
part 'reading_script.dart';
part 'reading_terminal_states.dart';

final class ReadingView extends StatefulWidget {
  const ReadingView({required this.viewModel, super.key});

  final ReadingViewModel viewModel;

  @override
  State<ReadingView> createState() => _ReadingViewState();
}

final class _ReadingViewState extends State<ReadingView>
    with WidgetsBindingObserver {
  bool _isLeaving = false;
  bool _repetitionDialogVisible = false;
  bool _terminalDialogVisible = false;
  late bool _platformReduceMotion;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _platformReduceMotion = _readPlatformReduceMotion();
    widget.viewModel.addListener(_handleViewModelChange);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _handleViewModelChange();
    });
  }

  @override
  void didChangeAccessibilityFeatures() {
    final reduceMotion = _readPlatformReduceMotion();
    if (reduceMotion == _platformReduceMotion || !mounted) return;
    setState(() => _platformReduceMotion = reduceMotion);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      unawaited(widget.viewModel.leave());
    }
  }

  bool _readPlatformReduceMotion() => WidgetsBinding
      .instance
      .platformDispatcher
      .accessibilityFeatures
      .reduceMotion;

  void _handleViewModelChange() {
    if (!mounted) return;
    final state = widget.viewModel.state;
    if (state.status == ReadingSessionStatus.awaitingNextRepetition &&
        !_repetitionDialogVisible) {
      _repetitionDialogVisible = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_showNextRepetitionDialog());
      });
    }
    final showsTerminalDialog =
        state.status == ReadingSessionStatus.completed ||
        state.status == ReadingSessionStatus.exited;
    if (showsTerminalDialog && !_terminalDialogVisible) {
      _terminalDialogVisible = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_showTerminalDialog());
      });
    }
  }

  Future<void> _showTerminalDialog() async {
    final state = widget.viewModel.state;
    final failure = state.failure;
    final completed = state.status == ReadingSessionStatus.completed;
    await showCupertinoDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope<void>(
        canPop: false,
        child: CupertinoAlertDialog(
          title: Text(
            completed
                ? '낭독 완료'
                : failure == null
                ? '낭독 종료'
                : '음성 인식을 계속할 수 없습니다',
          ),
          content: completed
              ? Text(
                  '모든 반복 낭독을 완료했습니다.\n'
                  '낭독 시간 · ${_formatElapsed(state.elapsed)}',
                )
              : failure == null
              ? null
              : Text(_failureMessage(failure)),
          actions: [
            CupertinoDialogAction(
              key: Key(
                completed
                    ? 'reading-completed-return-button'
                    : 'reading-exited-return-button',
              ),
              isDefaultAction: true,
              onPressed: () {
                Navigator.of(context).pop();
                _returnToList();
              },
              child: const Text('목록으로'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showNextRepetitionDialog() async {
    final state = widget.viewModel.state;
    if (state.status != ReadingSessionStatus.awaitingNextRepetition) {
      _repetitionDialogVisible = false;
      return;
    }
    final shouldContinue = await showCupertinoDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope<void>(
        canPop: false,
        child: CupertinoAlertDialog(
          title: Text('${state.currentRepetition - 1}회 낭독 완료'),
          content: Text(
            '${state.currentRepetition}/${state.totalRepetitions}회를 이어서 낭독할까요?',
          ),
          actions: [
            CupertinoDialogAction(
              key: const Key('reading-repetition-stop-button'),
              isDestructiveAction: true,
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('그만하기'),
            ),
            CupertinoDialogAction(
              key: const Key('reading-repetition-continue-button'),
              isDefaultAction: true,
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('이어하기'),
            ),
          ],
        ),
      ),
    );
    _repetitionDialogVisible = false;
    if (!mounted ||
        widget.viewModel.state.status !=
            ReadingSessionStatus.awaitingNextRepetition) {
      return;
    }
    if (shouldContinue == true) {
      await widget.viewModel.continueNextRepetition();
      return;
    }
    _isLeaving = true;
    await widget.viewModel.leave();
    if (mounted) _returnToList();
  }

  Future<void> _requestLeave() async {
    if (_isLeaving) return;
    final state = widget.viewModel.state;
    if (state.status == ReadingSessionStatus.completed ||
        state.status == ReadingSessionStatus.exited) {
      _returnToList();
      return;
    }
    if (state.status == ReadingSessionStatus.awaitingNextRepetition) {
      _isLeaving = true;
      await widget.viewModel.leave();
      if (mounted) _returnToList();
      return;
    }

    if (!await _confirmLeave()) return;
    if (!mounted) return;

    _isLeaving = true;
    await widget.viewModel.leave();
    if (mounted) _returnToList();
  }

  Future<bool> _confirmLeave() async {
    final result = await showCupertinoDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('낭독을 종료할까요?'),
        content: const Text('현재 진행 상황은 저장되지 않습니다.'),
        actions: [
          CupertinoDialogAction(
            key: const Key('reading-leave-cancel-button'),
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('계속 읽기'),
          ),
          CupertinoDialogAction(
            key: const Key('reading-leave-confirm-button'),
            isDestructiveAction: true,
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('나가기'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _returnToList() {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.viewModel.removeListener(_handleViewModelChange);
    widget.viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.disableAnimationsOf(context) || _platformReduceMotion;
    return PopScope<void>(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_requestLeave());
      },
      child: CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          automaticallyImplyLeading: false,
          leading: Semantics(
            button: true,
            label: '낭독 나가기',
            hint: '낭독 종료 확인창을 엽니다',
            onTap: () => unawaited(_requestLeave()),
            excludeSemantics: true,
            child: CupertinoButton(
              key: const Key('reading-leave-button'),
              padding: EdgeInsets.zero,
              minimumSize: const Size.square(AppTargets.preferred),
              onPressed: _requestLeave,
              child: const Icon(CupertinoIcons.back),
            ),
          ),
          middle: Text(widget.viewModel.state.scriptTitle),
        ),
        child: SafeArea(
          child: AnimatedBuilder(
            animation: widget.viewModel,
            builder: (context, _) {
              final state = widget.viewModel.state;
              return _RunningSession(
                state: state,
                reduceMotion: reduceMotion,
                onMoveBack: widget.viewModel.moveBackOneWord,
              );
            },
          ),
        ),
      ),
    );
  }
}
