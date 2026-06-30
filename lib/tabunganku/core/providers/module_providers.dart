import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


final moduleExitProvider = StateProvider<VoidCallback?>((ref) => null);


final dashboardTabIndexProvider = StateProvider<int>((ref) => 0);
