import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum NetworkStatus { online, offline }

final networkStatusProvider = StreamProvider<NetworkStatus>((ref) async* {

  final Connectivity connectivity = Connectivity();


  final List<ConnectivityResult> initialResults = await connectivity
      .checkConnectivity();

  bool isOnline(List<ConnectivityResult> results) {
    return results.any((r) => r != ConnectivityResult.none);
  }

  yield isOnline(initialResults) ? NetworkStatus.online : NetworkStatus.offline;


  await for (final results in connectivity.onConnectivityChanged) {
    yield isOnline(results) ? NetworkStatus.online : NetworkStatus.offline;
  }
});
