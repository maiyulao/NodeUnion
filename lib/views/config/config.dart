import 'package:jichanglianmeng/common/app_localizations.dart';
import 'package:jichanglianmeng/views/config/general.dart';
import 'package:jichanglianmeng/widgets/widgets.dart';
import 'package:flutter/material.dart';

class ConfigView extends StatelessWidget {
  const ConfigView({super.key});

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      title: appLocalizations.basicConfig,
      body: generateListView(generalItems),
    );
  }
}
