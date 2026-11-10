part of 'reading_view.dart';

const double _moveBackSurfaceSize = 68;

final class _RunningSession extends StatelessWidget {
  const _RunningSession({
    required this.state,
    required this.reduceMotion,
    required this.onMoveBack,
  });

  final ReadingSessionState state;
  final bool reduceMotion;
  final Future<void> Function() onMoveBack;

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
    final repetitionText =
        '${state.currentRepetition}/${state.totalRepetitions}회';
    final elapsedText = _formatElapsed(state.elapsed);
    final defaultStyle = DefaultTextStyle.of(context).style;
    final statusStyle = defaultStyle.merge(
      CupertinoTheme.of(context).textTheme.textStyle
          .copyWith(fontWeight: FontWeight.w600),
    );
    final elapsedStyle = defaultStyle.merge(
      CupertinoTheme.of(context).textTheme.textStyle
          .copyWith(color: CupertinoColors.secondaryLabel),
    );
    final repetitionStatus = Semantics(
      label:
          '현재 ${state.currentRepetition}회차, 전체 ${state.totalRepetitions}회, ${state.totalRepetitions - state.currentRepetition}회 남음',
      excludeSemantics: true,
      child: Text(
        repetitionText,
        key: const Key('reading-repetition-status'),
        style: statusStyle,
      ),
    );
    final elapsedStatus = Semantics(
      label: _elapsedSemantics(state.elapsed),
      excludeSemantics: true,
      child: Text(
        elapsedText,
        key: const Key('reading-elapsed-time'),
        style: elapsedStyle,
      ),
    );
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
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (!state.showsRepetition) {
                return Align(
                  alignment: Alignment.centerRight,
                  child: elapsedStatus,
                );
              }
              final textScaler = MediaQuery.textScalerOf(context);
              final direction = Directionality.of(context);
              double textWidth(String text, TextStyle style) {
                final painter = TextPainter(
                  text: TextSpan(text: text, style: style),
                  textDirection: direction,
                  textScaler: textScaler,
                  maxLines: 1,
                )..layout();
                final width = painter.width;
                painter.dispose();
                return width;
              }

              final requiredWidth =
                  textWidth(repetitionText, statusStyle) +
                  textWidth(elapsedText, elapsedStyle) +
                  AppSpacing.medium;
              if (requiredWidth > constraints.maxWidth) {
                return Column(
                  key: const Key('reading-status-stacked'),
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: repetitionStatus,
                    ),
                    const SizedBox(height: AppSpacing.small),
                    Align(
                      alignment: Alignment.centerRight,
                      child: elapsedStatus,
                    ),
                  ],
                );
              }
              return Row(
                children: [repetitionStatus, const Spacer(), elapsedStatus],
              );
            },
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
      dimension: _moveBackSurfaceSize,
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
