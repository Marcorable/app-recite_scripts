part of 'reading_view.dart';

final class _RunningSession extends StatelessWidget {
  const _RunningSession({
    required this.state,
    required this.reduceMotion,
    required this.onMoveBack,
    required this.onLeave,
  });

  final ReadingSessionState state;
  final bool reduceMotion;
  final Future<void> Function() onMoveBack;
  final Future<void> Function() onLeave;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            _ReadingStatus(state: state),
            Expanded(
              child: _ReadingScript(state: state, reduceMotion: reduceMotion),
            ),
          ],
        ),
        Positioned(
          right: AppSpacing.large,
          bottom: AppSpacing.large,
          child: _MoveBackAction(
            canMoveBack: (state.currentWordIndex ?? 0) > 0,
            onMoveBack: onMoveBack,
          ),
        ),
      ],
    );
  }
}

final class _ReadingStatus extends StatelessWidget {
  const _ReadingStatus({required this.state});

  final ReadingSessionState state;

  @override
  Widget build(BuildContext context) {
    final statusStyle = CupertinoTheme.of(context).textTheme.textStyle
        .copyWith(fontWeight: FontWeight.w600);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.large,
        AppSpacing.medium,
        AppSpacing.large,
        AppSpacing.small,
      ),
      child: AppGlassSurface(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.large),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 52),
          child: Row(
            children: [
              if (state.showsRepetition)
                Semantics(
                  label:
                      '현재 ${state.currentRepetition}회차, 전체 ${state.totalRepetitions}회, ${state.totalRepetitions - state.currentRepetition}회 남음',
                  excludeSemantics: true,
                  child: Text(
                    '${state.currentRepetition}/${state.totalRepetitions}회',
                    key: const Key('reading-repetition-status'),
                    style: statusStyle,
                  ),
                ),
              const Spacer(),
              Semantics(
                label: _elapsedSemantics(state.elapsed),
                excludeSemantics: true,
                child: Text(
                  _formatElapsed(state.elapsed),
                  key: const Key('reading-elapsed-time'),
                  style: const TextStyle(color: CupertinoColors.secondaryLabel),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _MoveBackAction extends StatelessWidget {
  const _MoveBackAction({required this.canMoveBack, required this.onMoveBack});

  final bool canMoveBack;
  final Future<void> Function() onMoveBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 68,
      child: AppGlassSurface(
        padding: const EdgeInsets.all(AppSpacing.small),
        child: Semantics(
          button: true,
          enabled: canMoveBack,
          onTap: canMoveBack ? () => unawaited(onMoveBack()) : null,
          label: canMoveBack ? '한 어절 뒤로' : '한 어절 뒤로, 첫 어절에서는 더 이상 이동할 수 없음',
          excludeSemantics: true,
          child: ConstrainedBox(
            constraints: const BoxConstraints.tightFor(width: 52, height: 52),
            child: CupertinoButton(
              key: const Key('reading-move-back-button'),
              padding: EdgeInsets.zero,
              onPressed: canMoveBack ? onMoveBack : null,
              child: const Icon(CupertinoIcons.arrow_uturn_left),
            ),
          ),
        ),
      ),
    );
  }
}
