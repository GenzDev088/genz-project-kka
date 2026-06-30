import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:otax/tabunganku/main.dart' as tabunganku;
import 'package:otax/tabunganku/core/routing/app_router.dart'
    as tabunganku_router;

class TabunganKuModule extends StatefulWidget {
  const TabunganKuModule({super.key});

  @override
  State<TabunganKuModule> createState() => _TabunganKuModuleState();
}

class _SmartClockWidgetsState {}

class _TabunganKuModuleState extends State<TabunganKuModule> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await initializeDateFormatting('id_ID', null);
      if (mounted) {
        setState(() {
          _initialized = true;
        });
      }
    } catch (e) {
      debugPrint('Error initializing TabunganKu module: $e');
      if (mounted) {
        setState(() {
          _initialized = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return ProviderScope(
      child: tabunganku.TabunganKuApp(
        onExit: () {
          debugPrint('TabunganKuModule: onExit called');
          if (mounted) {
            Navigator.pop(context);
          }
        },
      ),
    );
  }
}
