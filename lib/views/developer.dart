import 'package:jichanglianmeng/common/common.dart';
import 'package:jichanglianmeng/controller.dart';
import 'package:jichanglianmeng/core/controller.dart';
import 'package:jichanglianmeng/enum/enum.dart';
import 'package:jichanglianmeng/models/common.dart';
import 'package:jichanglianmeng/providers/config.dart';
import 'package:jichanglianmeng/state.dart';
import 'package:jichanglianmeng/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DeveloperView extends ConsumerWidget {
  const DeveloperView({super.key});

  Widget _getDeveloperList(BuildContext context, WidgetRef ref) {
    return generateSectionV2(
      title: appLocalizations.options,
      items: [
        ListItem(
          title: Text(appLocalizations.messageTest),
          minVerticalPadding: 12,
          onTap: () {
            context.showNotifier(appLocalizations.messageTestTip);
          },
        ),
        ListItem(
          title: Text(appLocalizations.logsTest),
          minVerticalPadding: 12,
          onTap: () {
            for (int i = 0; i < 1000; i++) {
              appController.addLog(
                Log.app(
                  '[$i]${utils.generateRandomString(maxLength: 200, minLength: 20)}',
                ),
              );
            }
          },
        ),
        if (globalState.isPre)
          ListItem(
            title: Text(appLocalizations.crashTest),
            minVerticalPadding: 12,
            onTap: () async {
              final res = await globalState.showMessage(
                message: TextSpan(text: appLocalizations.confirmForceCrashCore),
              );
              if (res != true) {
                return;
              }
              coreController.crash();
            },
          ),
        ListItem(
          title: Text(appLocalizations.clearData),
          minVerticalPadding: 12,
          onTap: () async {
            final res = await globalState.showMessage(
              message: TextSpan(text: appLocalizations.confirmClearAllData),
            );
            if (res != true) {
              return;
            }
            await appController.handleClear();
          },
        ),
        // ListItem(
        //   title: Text(appLocalizations.loadTest),
        //   minVerticalPadding: 12,
        //   onTap: () {
        //     ref.read(loadingProvider.notifier).value = !ref.read(
        //       loadingProvider,
        //     );
        //   },
        // ),
        ListItem(
          title: Text(appLocalizations.pruneCache),
          minVerticalPadding: 12,
          onTap: () {
            appController.shakingStore();
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context, ref) {
    final enable = ref.watch(
      appSettingProvider.select((state) => state.developerMode),
    );
    return BaseScaffold(
      title: appLocalizations.developerMode,
      body: SingleChildScrollView(
        padding: baseInfoEdgeInsets,
        child: Column(
          children: [
            CommonCard(
              type: CommonCardType.filled,
              radius: 18,
              child: ListItem.switchItem(
                padding: const EdgeInsets.only(left: 16, right: 16),
                title: Text(appLocalizations.developerMode),
                delegate: SwitchDelegate(
                  value: enable,
                  onChanged: (value) {
                    ref
                        .read(appSettingProvider.notifier)
                        .update(
                          (state) => state.copyWith(developerMode: value),
                        );
                  },
                ),
              ),
            ),
            SizedBox(height: 16),
            _getDeveloperList(context, ref),
          ],
        ),
      ),
    );
  }
}
