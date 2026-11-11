import 'package:flutter/cupertino.dart';
import 'package:maltto/src/features/about/presentation/open_source_licenses_view.dart';
import 'package:maltto/src/features/reading/presentation/reading_setup_view.dart';
import 'package:maltto/src/features/reading/presentation/reading_view.dart';
import 'package:maltto/src/features/reading/presentation/reading_view_model.dart';
import 'package:maltto/src/features/scripts/model/script.dart';
import 'package:maltto/src/features/scripts/presentation/script_create_view.dart';
import 'package:maltto/src/features/scripts/presentation/script_create_view_model.dart';
import 'package:maltto/src/features/scripts/presentation/script_list_components.dart';
import 'package:maltto/src/features/scripts/presentation/script_list_view_model.dart';
import 'package:maltto/src/features/scripts/presentation/script_navigation_actions.dart';
import 'package:maltto/src/shared/design/app_tokens.dart';
import 'package:maltto/src/infrastructure/stt/stt_models.dart';

final class ScriptListView extends StatefulWidget {
  const ScriptListView({
    required this.viewModel,
    required this.createScriptViewModel,
    required this.readingSetupBuilder,
    this.prepareReading,
    this.openAppSettings,
    super.key,
  });

  final ScriptListViewModel viewModel;
  final ScriptCreateViewModel Function() createScriptViewModel;
  final Widget Function(Script script) readingSetupBuilder;
  final Future<SttPreparation> Function()? prepareReading;
  final Future<bool> Function()? openAppSettings;

  @override
  State<ScriptListView> createState() => _ScriptListViewState();
}

final class _ScriptListViewState extends State<ScriptListView> {
  bool _isOpeningReadingFlow = false;

  @override
  void initState() {
    super.initState();
    widget.viewModel.load();
  }

  Future<void> _openCreateView() async {
    await Navigator.of(context).push<void>(
      CupertinoPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) =>
            ScriptCreateView(viewModel: widget.createScriptViewModel()),
      ),
    );
  }

  Future<void> _openLicenses() => Navigator.of(context).push<void>(
    CupertinoPageRoute<void>(builder: (_) => const OpenSourceLicensesView()),
  );

  Future<void> _openReadingSetup(Script script) async {
    if (_isOpeningReadingFlow) return;
    _isOpeningReadingFlow = true;
    try {
      SttPreparation preparation;
      try {
        preparation =
            await (widget.prepareReading?.call() ??
                Future.value(
                  const SttPreparation(status: SttPreparationStatus.ready),
                ));
      } on Object {
        if (!mounted) return;
        await _showPreparationIssue(
          const SttPreparation(
            status: SttPreparationStatus.modelDownloading,
            failureCode: SttFailureCode.unknown,
          ),
        );
        return;
      }
      if (!mounted) return;
      if (preparation.status == SttPreparationStatus.permissionDenied) {
        await _showPermissionDenied();
        return;
      }
      if (preparation.status != SttPreparationStatus.ready) {
        await _showPreparationIssue(preparation);
        return;
      }
      final result = await showCupertinoModalPopup<ReadingSetupResult>(
        context: context,
        barrierColor: AppColors.sheetOverlay,
        builder: (sheetContext) => Align(
          alignment: Alignment.bottomCenter,
          child: SizedBox(
            width: double.infinity,
            height: MediaQuery.sizeOf(sheetContext).height.clamp(0, 520),
            child: ClipRRect(
              borderRadius: AppRadii.sheet,
              child: widget.readingSetupBuilder(script),
            ),
          ),
        ),
      );
      if (!mounted || result == null) return;
      await Navigator.of(context).push<void>(
        CupertinoPageRoute<void>(
          builder: (_) => ReadingView(
            viewModel: ReadingViewModel(
              repository: result.repository,
              initialState: result.initialState,
            ),
          ),
        ),
      );
    } finally {
      _isOpeningReadingFlow = false;
    }
  }

  Future<void> _showPermissionDenied() => showCupertinoDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => CupertinoAlertDialog(
      title: const Text('마이크 접근이 필요해요'),
      content: const Text('설정에서 마이크 접근을 허용한 뒤 다시 시도해 주세요.'),
      actions: [
        CupertinoDialogAction(
          key: const Key('permission-close-button'),
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('닫기'),
        ),
        CupertinoDialogAction(
          key: const Key('permission-settings-button'),
          isDefaultAction: true,
          onPressed: () async {
            Navigator.of(dialogContext).pop();
            await widget.openAppSettings?.call();
          },
          child: const Text('설정 가기'),
        ),
      ],
    ),
  );

  Future<void> _showPreparationIssue(SttPreparation preparation) =>
      showCupertinoDialog<void>(
        context: context,
        builder: (dialogContext) => CupertinoAlertDialog(
          title: const Text('낭독을 준비할 수 없습니다'),
          content: Text(switch (preparation) {
            SttPreparation(status: SttPreparationStatus.unsupported) =>
              '이 기기에서 온디바이스 한국어 음성 인식을 사용할 수 없습니다.',
            SttPreparation(failureCode: SttFailureCode.unknown) =>
              '음성 인식을 준비하지 못했습니다. 잠시 후 다시 시도해 주세요.',
            _ => '음성 인식을 준비 중입니다. 잠시 후 다시 시도해 주세요.',
          }),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('확인'),
            ),
          ],
        ),
      );

  Future<void> _confirmDelete(Script script) async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: const Text('대본을 삭제할까요?'),
        content: Text('“${script.title}” 대본을 기기에서 삭제합니다.'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('취소'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final deleted = await widget.viewModel.deleteScript(script.id);
    if (!deleted && mounted) {
      await showCupertinoDialog<void>(
        context: context,
        builder: (dialogContext) => CupertinoAlertDialog(
          title: const Text('삭제하지 못했습니다'),
          content: const Text('대본은 그대로 유지됩니다. 다시 시도해 주세요.'),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('확인'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final infoButton = ScriptNavigationButton(
      key: const Key('script-list-info-button'),
      semanticLabel: '앱 정보 및 오픈소스 라이선스',
      onPressed: _openLicenses,
      child: const Icon(CupertinoIcons.info),
    );
    final addButton = ScriptNavigationButton(
      key: const Key('script-list-add-button'),
      semanticLabel: '새 대본 추가',
      onPressed: _openCreateView,
      contentOffset: const Offset(
        0,
        -(AppTargets.preferred - kMinInteractiveDimensionCupertino) / 2,
      ),
      child: const Text('추가'),
    );

    return CupertinoPageScaffold(
      backgroundColor: AppColors.canvas,
      child: Stack(
        children: [
          AnimatedBuilder(
            animation: widget.viewModel,
            builder: (context, child) {
              return CustomScrollView(
                slivers: [
                  const CupertinoSliverNavigationBar(largeTitle: Text('대본')),
                  if (widget.viewModel.isLoading)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(child: CupertinoActivityIndicator()),
                    )
                  else if (widget.viewModel.hasLoadError)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: ScriptLoadError(onRetry: widget.viewModel.retry),
                    )
                  else if (widget.viewModel.scripts.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: ScriptEmptyState(onAdd: _openCreateView),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.large,
                      ),
                      sliver: SliverList.builder(
                        itemCount: widget.viewModel.scripts.length,
                        itemBuilder: (context, index) {
                          final script = widget.viewModel.scripts[index];
                          return ScriptListTile(
                            script: script,
                            onSelected: () => _openReadingSetup(script),
                            onDelete: () => _confirmDelete(script),
                          );
                        },
                      ),
                    ),
                ],
              );
            },
          ),
          Positioned.fill(
            child: ScriptNavigationActionOverlay(
              leading: infoButton,
              trailing: addButton,
            ),
          ),
        ],
      ),
    );
  }
}
