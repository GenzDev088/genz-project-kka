import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:otax/tabunganku/providers/connectivity_provider.dart';

class ConnectivityGuard extends ConsumerStatefulWidget {
  final Widget child;
  const ConnectivityGuard({super.key, required this.child});

  @override
  ConsumerState<ConnectivityGuard> createState() => _ConnectivityGuardState();
}

class _ConnectivityGuardState extends ConsumerState<ConnectivityGuard>
    with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final statusAsync = ref.watch(networkStatusProvider);
    final isOffline = statusAsync.maybeWhen(
      data: (status) => status == NetworkStatus.offline,
      orElse: () => false,
    );

    return Stack(
      children: [

        AbsorbPointer(absorbing: isOffline, child: widget.child),


        if (isOffline) ...[

          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
              child: Container(color: Colors.black.withValues(alpha: 0.3)),
            ),
          ),


          Center(
            child: Material(
              type: MaterialType.transparency,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 40),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 32,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 30,
                      offset: const Offset(0, 15),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.teal.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: AnimatedBuilder(
                        animation: _rotationController,
                        builder: (context, child) {
                          return Transform.rotate(
                            angle: _rotationController.value * 2 * math.pi,
                            child: child,
                          );
                        },
                        child: Icon(
                          Icons.sync_rounded,
                          size: 40,
                          color: Colors.teal.shade400,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'SINKRONISASI TERPUTUS',
                      style: GoogleFonts.comicNeue(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2.0,
                        color: Colors.teal,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Fitur Keluarga memerlukan koneksi cloud untuk menjaga data tetap aman dan sinkron.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.comicNeue(
                        fontSize: 14,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white70
                            : Colors.black54,
                        height: 1.6,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.teal.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.teal,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Mencari Sinyal...',
                            style: GoogleFonts.comicNeue(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.teal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
