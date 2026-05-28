import 'dart:async';

import 'package:jichanglianmeng/common/common.dart';
import 'package:jichanglianmeng/controller.dart';
import 'package:jichanglianmeng/providers/config.dart';
import 'package:jichanglianmeng/state.dart';
import 'package:jichanglianmeng/widgets/list.dart';
import 'package:jichanglianmeng/widgets/scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

@immutable
class Contributor {
  final String avatar;
  final String name;
  final String link;

  const Contributor({
    required this.avatar,
    required this.name,
    required this.link,
  });
}

class AboutView extends StatelessWidget {
  const AboutView({super.key});

  static const _originalCoreUrl =
      'https://github.com/chen08209/Clash.Meta/tree/$originalCoreBranch';

  static const _originalContributors = [
    Contributor(
      avatar: 'assets/images/avatar/june2.jpg',
      name: 'June2',
      link: 'https://t.me/Jibadong',
    ),
    Contributor(
      avatar: 'assets/images/avatar/arue.jpg',
      name: 'Arue',
      link: 'https://t.me/xrcm6868',
    ),
  ];

  Future<void> _checkUpdate(BuildContext context) async {
    final data = await appController.safeRun<Map<String, dynamic>?>(
      request.checkForUpdate,
      title: appLocalizations.checkUpdate,
    );
    appController.checkUpdateResultHandle(data: data, isUser: true);
  }

  List<Widget> _buildMoreSection(BuildContext context) {
    return generateSection(
      separated: false,
      title: appLocalizations.more,
      items: [
        ListItem(
          title: Text(appLocalizations.checkUpdate),
          onTap: () {
            _checkUpdate(context);
          },
        ),
      ],
    );
  }

  List<Widget> _buildThanksSection(BuildContext context) {
    return generateSection(
      separated: false,
      title: appLocalizations.thanksOriginalProject,
      items: [
        ListItem(
          title: Text(
            appLocalizations.thanksOriginalProjectDesc,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        ListItem(
          title: Text(appLocalizations.forkProject),
          onTap: () {
            globalState.openUrl('https://github.com/$forkRepository');
          },
          trailing: const Icon(Icons.launch),
        ),
        ListItem(
          title: Text(appLocalizations.forkCommunity),
          onTap: () {
            globalState.openUrl(forkTelegramUrl);
          },
          trailing: const Icon(Icons.launch),
        ),
        ListItem(
          title: Text(appLocalizations.originalProject),
          onTap: () {
            globalState.openUrl('https://github.com/$originalRepository');
          },
          trailing: const Icon(Icons.launch),
        ),
        ListItem(
          title: Text(appLocalizations.originalCommunity),
          onTap: () {
            globalState.openUrl(originalTelegramUrl);
          },
          trailing: const Icon(Icons.launch),
        ),
        ListItem(
          title: Text(appLocalizations.core),
          onTap: () {
            globalState.openUrl(_originalCoreUrl);
          },
          trailing: const Icon(Icons.launch),
        ),
        ListItem(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                appLocalizations.otherContributors,
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Wrap(
                  spacing: 24,
                  children: [
                    for (final contributor in _originalContributors)
                      Avatar(contributor: contributor),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = [
      ListTile(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Consumer(
              builder: (_, ref, _) {
                return _DeveloperModeDetector(
                  child: Wrap(
                    spacing: 16,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Image.asset(
                          'assets/images/icon.png',
                          width: 64,
                          height: 64,
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            globalState.packageInfo.appName,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          Text(
                            globalState.packageInfo.version,
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                        ],
                      ),
                    ],
                  ),
                  onEnterDeveloperMode: () {
                    ref
                        .read(appSettingProvider.notifier)
                        .update((state) => state.copyWith(developerMode: true));
                    context.showNotifier(
                      appLocalizations.developerModeEnableTip,
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 24),
            Text(
              appLocalizations.desc,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      ..._buildThanksSection(context),
      ..._buildMoreSection(context),
    ];
    return BaseScaffold(
      title: appLocalizations.about,
      body: Padding(
        padding: kMaterialListPadding.copyWith(top: 16, bottom: 16),
        child: generateListView(items),
      ),
    );
  }
}

class Avatar extends StatelessWidget {
  final Contributor contributor;

  const Avatar({super.key, required this.contributor});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: Column(
        children: [
          SizedBox(
            width: 36,
            height: 36,
            child: CircleAvatar(
              foregroundImage: AssetImage(contributor.avatar),
            ),
          ),
          const SizedBox(height: 4),
          Text(contributor.name, style: context.textTheme.bodySmall),
        ],
      ),
      onTap: () {
        globalState.openUrl(contributor.link);
      },
    );
  }
}

class _DeveloperModeDetector extends StatefulWidget {
  final Widget child;
  final VoidCallback onEnterDeveloperMode;

  const _DeveloperModeDetector({
    required this.child,
    required this.onEnterDeveloperMode,
  });

  @override
  State<_DeveloperModeDetector> createState() => _DeveloperModeDetectorState();
}

class _DeveloperModeDetectorState extends State<_DeveloperModeDetector> {
  int _counter = 0;
  Timer? _timer;

  void _handleTap() {
    _counter++;
    if (_counter >= 5) {
      widget.onEnterDeveloperMode();
      _resetCounter();
    } else {
      _timer?.cancel();
      _timer = Timer(Duration(seconds: 1), _resetCounter);
    }
  }

  void _resetCounter() {
    _counter = 0;
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(onTap: _handleTap, child: widget.child);
  }
}
