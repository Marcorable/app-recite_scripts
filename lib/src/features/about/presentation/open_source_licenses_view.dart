import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:maltto/src/shared/design/app_tokens.dart';

final class OpenSourceLicensesView extends StatefulWidget {
  const OpenSourceLicensesView({super.key});

  @override
  State<OpenSourceLicensesView> createState() => _OpenSourceLicensesViewState();
}

final class _OpenSourceLicensesViewState extends State<OpenSourceLicensesView> {
  late final Future<List<_PackageLicense>> _licenses = _loadLicenses();

  Future<List<_PackageLicense>> _loadLicenses() async {
    final licensesByPackage = <String, List<String>>{};
    await for (final entry in LicenseRegistry.licenses) {
      final text = entry.paragraphs
          .map((paragraph) => paragraph.text)
          .join('\n\n');
      for (final package in entry.packages) {
        licensesByPackage.putIfAbsent(package, () => []).add(text);
      }
    }

    return licensesByPackage.entries
        .map(
          (entry) => _PackageLicense(
            package: entry.key,
            text: entry.value.join('\n\n---\n\n'),
          ),
        )
        .toList()
      ..sort((left, right) => left.package.compareTo(right.package));
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.canvas,
      navigationBar: const CupertinoNavigationBar(middle: Text('오픈소스 라이선스')),
      child: SafeArea(
        child: FutureBuilder<List<_PackageLicense>>(
          future: _licenses,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CupertinoActivityIndicator());
            }
            final licenses = snapshot.requireData;
            return ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.large),
              itemCount: licenses.length + 1,
              separatorBuilder: (_, _) => const SizedBox(height: 1),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return const Padding(
                    padding: EdgeInsets.all(AppSpacing.large),
                    child: Text(
                      '말또는 공개 포트폴리오이며 프로젝트 고유 저작물의 '
                      '사용 권한을 부여하지 않습니다. 아래 구성 요소에는 각 '
                      '오픈소스 라이선스가 적용됩니다.',
                    ),
                  );
                }
                final license = licenses[index - 1];
                return CupertinoListTile(
                  title: Text(license.package),
                  trailing: const CupertinoListTileChevron(),
                  onTap: () => Navigator.of(context).push<void>(
                    CupertinoPageRoute<void>(
                      builder: (_) => _LicenseDetailView(license: license),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

final class _LicenseDetailView extends StatelessWidget {
  const _LicenseDetailView({required this.license});

  final _PackageLicense license;

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.canvas,
      navigationBar: CupertinoNavigationBar(middle: Text(license.package)),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.large),
          child: Text(license.text),
        ),
      ),
    );
  }
}

final class _PackageLicense {
  const _PackageLicense({required this.package, required this.text});

  final String package;
  final String text;
}
