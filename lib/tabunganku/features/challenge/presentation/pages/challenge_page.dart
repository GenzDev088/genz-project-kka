import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:otax/tabunganku/models/challenge_model.dart';
import 'package:otax/tabunganku/models/challenge_template_model.dart';
import 'package:otax/tabunganku/models/badge_model.dart';
import 'package:otax/tabunganku/providers/challenge_provider.dart';
import 'package:otax/tabunganku/core/theme/app_colors.dart';
import 'package:intl/intl.dart';

class ChallengePage extends ConsumerStatefulWidget {
  const ChallengePage({super.key});

  @override
  ConsumerState<ChallengePage> createState() => _ChallengePageState();
}

class _ChallengePageState extends ConsumerState<ChallengePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final stats = ref.watch(challengeStatsProvider);
    final streak = ref.watch(currentStreakProvider);
    final points = ref.watch(totalPointsProvider);

    final contentColor = isDark ? Colors.white : AppColors.primaryDark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : const Color(0xFFF8FAF9),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: contentColor,
            size: 20,
          ),
        ),
        title: Text(
          'Challenge Menabung',
          style: GoogleFonts.comicNeue(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: contentColor,
          ),
        ),
      ),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  children: [_buildStatsCard(streak, points, stats, isDark)],
                ),
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverTabBarDelegate(
                TabBar(
                  controller: _tabController,
                  indicatorColor: AppColors.primary,
                  indicatorWeight: 3,
                  labelColor: isDark ? Colors.white : AppColors.primary,
                  unselectedLabelColor: Colors.grey.shade500,
                  labelStyle: GoogleFonts.comicNeue(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  unselectedLabelStyle: GoogleFonts.comicNeue(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  tabs: const [
                    Tab(text: 'Aktif'),
                    Tab(text: 'Jelajahi'),
                    Tab(text: 'Badge'),
                  ],
                ),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: const [
            _ActiveChallengesTab(),
            _TemplatesTab(),
            _BadgesTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard(
    AsyncValue<int> streak,
    AsyncValue<int> points,
    Map<String, dynamic> stats,
    bool isDark,
  ) {
    final hexBg = isDark ? AppColors.surfaceDark : Colors.white;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: hexBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildModernStatItem(
            icon: Icons.local_fire_department_rounded,
            iconColor: Colors.orange,
            value: streak.when(
              data: (s) => s.toString(),
              loading: () => '-',
              error: (_, __) => '0',
            ),
            label: 'Streak',
            isDark: isDark,
          ),
          _buildDivider(isDark),
          _buildModernStatItem(
            icon: Icons.stars_rounded,
            iconColor: Colors.amber,
            value: points.when(
              data: (p) => p.toString(),
              loading: () => '-',
              error: (_, __) => '0',
            ),
            label: 'Poin',
            isDark: isDark,
          ),
          _buildDivider(isDark),
          _buildModernStatItem(
            icon: Icons.check_circle_rounded,
            iconColor: AppColors.primary,
            value: stats['completed'].toString(),
            label: 'Selesai',
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Container(
      height: 30,
      width: 1,
      color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
    );
  }

  Widget _buildModernStatItem({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
    required bool isDark,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, color: iconColor, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.comicNeue(
            color: isDark ? Colors.white : AppColors.primaryDark,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          label.toUpperCase(),
          style: GoogleFonts.comicNeue(
            color: (isDark ? Colors.white : AppColors.primaryDark).withValues(
              alpha: 0.4,
            ),
            fontSize: 9,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _SliverTabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height + 8; // Added spacing

  @override
  double get maxExtent => tabBar.preferredSize.height + 8;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Center(child: tabBar),
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return false;
  }
}

class _ActiveChallengesTab extends ConsumerWidget {
  const _ActiveChallengesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final activeChallenges = ref.watch(activeChallengesProvider);
    final isDark = theme.brightness == Brightness.dark;

    return activeChallenges.when(
      data: (challenges) {
        if (challenges.isEmpty) {
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : AppColors.primary.withValues(alpha: 0.08),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.emoji_events_outlined,
                        size: 72,
                        color: isDark
                            ? Colors.grey.shade400
                            : AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Belum Ada Challenge',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Pilih challenge pertamamu dan bangun kebiasaan menabung yang seru!',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 15,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          itemCount: challenges.length,
          itemBuilder: (context, index) {
            return _buildChallengeCard(context, ref, challenges[index]);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Terjadi kesalahan: $error')),
    );
  }

  Widget _buildChallengeCard(
    BuildContext context,
    WidgetRef ref,
    ChallengeModel challenge,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final progressPercent = challenge.progressPercentage / 100;
    const baseColor = AppColors.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.grey.shade100,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 20, 16),
          child: Row(
            children: [

              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 54,
                    height: 54,
                    child: CircularProgressIndicator(
                      value: progressPercent,
                      strokeWidth: 5,
                      backgroundColor: baseColor.withValues(alpha: 0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getProgressColor(progressPercent),
                      ),
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: baseColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getTemplateIcon(challenge.title),
                      color: baseColor,
                      size: 20,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      challenge.title.toUpperCase(),
                      style: GoogleFonts.comicNeue(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                        color: isDark ? Colors.white : AppColors.primaryDark,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.timer_outlined,
                          size: 12,
                          color: isDark ? Colors.white24 : Colors.grey.shade400,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${challenge.daysRemaining} hari lagi',
                          style: GoogleFonts.comicNeue(
                            fontSize: 11,
                            color: isDark
                                ? Colors.white38
                                : Colors.grey.shade600,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '•',
                          style: TextStyle(
                            color: isDark
                                ? Colors.white12
                                : Colors.grey.shade300,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.stars_rounded,
                          size: 12,
                          color: Colors.amber.withValues(alpha: 0.7),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${challenge.id.hashCode % 50 + 10} Poin',
                          style: GoogleFonts.comicNeue(
                            fontSize: 11,
                            color: Colors.amber.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${(progressPercent * 100).toInt()}%',
                    style: GoogleFonts.comicNeue(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: _getProgressColor(progressPercent),
                    ),
                  ),
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: () => _showDeleteDialog(context, ref, challenge),
                    child: Icon(
                      Icons.delete_outline_rounded,
                      color: isDark
                          ? Colors.white12
                          : Colors.redAccent.withValues(alpha: 0.3),
                      size: 18,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getTemplateIcon(String title) {
    if (title.contains('Kopi')) return Icons.coffee_rounded;
    if (title.contains('Jajan')) return Icons.no_meals_rounded;
    if (title.contains('Hemat') || title.contains('Tabung'))
      return Icons.savings_rounded;
    if (title.contains('Zero')) return Icons.lock_outline_rounded;
    if (title.contains('Weekend')) return Icons.weekend_rounded;
    return Icons.emoji_events_rounded;
  }

  void _showDeleteDialog(
    BuildContext context,
    WidgetRef ref,
    ChallengeModel challenge,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: Row(
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: Colors.orange,
              size: 28,
            ),
            const SizedBox(width: 12),
            Text(
              'Hapus Challenge?',
              style: GoogleFonts.comicNeue(
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        content: Text(
          'Challenge "${challenge.title}" akan dihapus. Semua progres di dalamnya akan hilang.',
          style: GoogleFonts.comicNeue(
            fontSize: 14,
            height: 1.5,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Batal',
              style: GoogleFonts.comicNeue(
                color: Colors.grey,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final service = ref.read(challengeServiceProvider);
                await service.deleteChallenge(challenge.id);
                ref.invalidate(activeChallengesProvider);

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Challenge berhasil dihapus',
                        style: GoogleFonts.comicNeue(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      backgroundColor: Colors.redAccent,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Hapus',
              style: GoogleFonts.comicNeue(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }

  Color _getProgressColor(double progress) {
    if (progress < 0.3) return Colors.red;
    if (progress < 0.7) return Colors.orange;
    return Colors.green;
  }
}

Color _getDifficultyColor(ChallengeDifficulty difficulty) {
  switch (difficulty) {
    case ChallengeDifficulty.easy:
      return Colors.green;
    case ChallengeDifficulty.medium:
      return Colors.orange;
    case ChallengeDifficulty.hard:
      return Colors.red;
  }
}

String _getDifficultyLabel(ChallengeDifficulty difficulty) {
  switch (difficulty) {
    case ChallengeDifficulty.easy:
      return 'MUDAH';
    case ChallengeDifficulty.medium:
      return 'SEDANG';
    case ChallengeDifficulty.hard:
      return 'SULIT';
  }
}





class _TemplatesTab extends ConsumerWidget {
  const _TemplatesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final templates = ref.watch(challengeTemplatesProvider);

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      children: [
        Text(
          'Pilih Challenge',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: theme.textTheme.bodyLarge?.color,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Mulai perjalanan menabungmu dengan challenge yang cocok!',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 13,
            height: 1.5,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 24),
        _buildSection(
          context,
          '🌟 Challenge Harian',
          templates.where((t) => t.type == ChallengeType.daily).toList(),
        ),
        const SizedBox(height: 4),
        _buildSection(
          context,
          '📅 Challenge Mingguan',
          templates.where((t) => t.type == ChallengeType.weekly).toList(),
        ),
        const SizedBox(height: 4),
        _buildSection(
          context,
          '🎯 Challenge Bulanan',
          templates.where((t) => t.type == ChallengeType.monthly).toList(),
        ),
      ],
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    List<ChallengeTemplateModel> templates,
  ) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 12,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: theme.textTheme.bodyLarge?.color,
              letterSpacing: 0.3,
            ),
          ),
        ),
        ...templates.map((template) => _TemplateCard(template: template)),
      ],
    );
  }
}

class _TemplateCard extends ConsumerWidget {
  final ChallengeTemplateModel template;

  const _TemplateCard({required this.template});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.grey.shade100,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _showTemplateDetail(context, ref, theme),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 20, 16),
            child: Row(
              children: [

                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    template.icon ?? Icons.emoji_events_rounded,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        template.title,
                        style: GoogleFonts.comicNeue(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : AppColors.primaryDark,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          _buildMiniBadge(
                            template.difficultyLabel,
                            _getDifficultyColor(template.difficulty),
                          ),
                          const SizedBox(width: 8),
                          _buildMiniBadge(
                            '${template.points} pts',
                            Colors.amber.shade700,
                          ),
                          const SizedBox(width: 8),
                          _buildMiniBadge(
                            '${template.defaultDurationDays} Hari',
                            AppColors.primary,
                            icon: Icons.timer_outlined,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: isDark ? Colors.white12 : Colors.grey.shade300,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMiniBadge(String text, Color color, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: color, size: 10),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: GoogleFonts.comicNeue(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  void _showTemplateDetail(
    BuildContext parentContext,
    WidgetRef ref,
    ThemeData theme,
  ) {

    final durationController = TextEditingController(
      text: template.defaultDurationDays.toString(),
    );

    showModalBottomSheet(
      context: parentContext,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final currentDuration =
                int.tryParse(durationController.text) ??
                template.defaultDurationDays;
            final endDate = DateTime.now().add(Duration(days: currentDuration));
            final isDarkMode = theme.brightness == Brightness.dark;

            return Container(
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    Row(
                      children: [
                        if (template.icon != null)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              template.icon,
                              color: AppColors.primary,
                              size: 32,
                            ),
                          ),
                        if (template.icon != null) const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            template.title,
                            style: GoogleFonts.comicNeue(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: theme.textTheme.bodyLarge?.color,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      template.description,
                      style: GoogleFonts.comicNeue(
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),


                    Row(
                      children: [
                        _buildBadge(
                          template.difficultyLabel,
                          _getDifficultyColor(template.difficulty),
                        ),
                        const SizedBox(width: 8),
                        _buildBadge(
                          '${template.points} poin',
                          Colors.amber[700]!,
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),


                    Text(
                      'Target Waktu Pengerjaan:',
                      style: GoogleFonts.comicNeue(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDarkMode
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDarkMode
                              ? Colors.white10
                              : Colors.grey.shade200,
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                onPressed: () {
                                  final val =
                                      int.tryParse(durationController.text) ??
                                      1;
                                  if (val > 1) {
                                    setSheetState(() {
                                      durationController.text = (val - 1)
                                          .toString();
                                    });
                                  }
                                },
                                icon: const Icon(
                                  Icons.remove_circle_outline_rounded,
                                  color: AppColors.primary,
                                ),
                              ),
                              Expanded(
                                child: TextField(
                                  controller: durationController,
                                  keyboardType: TextInputType.number,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    suffixText: ' Hari',
                                    suffixStyle: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.normal,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  onChanged: (_) => setSheetState(() {}),
                                ),
                              ),
                              IconButton(
                                onPressed: () {
                                  final val =
                                      int.tryParse(durationController.text) ??
                                      0;
                                  setSheetState(() {
                                    durationController.text = (val + 1)
                                        .toString();
                                  });
                                },
                                icon: const Icon(
                                  Icons.add_circle_outline_rounded,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                          const Divider(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.calendar_today_rounded,
                                size: 14,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Akan berakhir pada: ${DateFormat('d MMM yyyy').format(endDate)}',
                                style: GoogleFonts.comicNeue(
                                  fontSize: 12,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    if (template.tips.isNotEmpty) ...[
                      Text(
                        'Tips Sukses:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: theme.textTheme.bodyLarge?.color,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...template.tips.map(
                        (tip) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.check_circle_rounded,
                                color: Colors.green,
                                size: 18,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  tip,
                                  style: TextStyle(
                                    color: isDarkMode
                                        ? Colors.grey[400]
                                        : Colors.grey[700],
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          final duration =
                              int.tryParse(durationController.text) ??
                              template.defaultDurationDays;

                          if (duration < 1) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Durasi challenge minimal 1 hari!',
                                ),
                                backgroundColor: Colors.red,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                            return;
                          }

                          Navigator.pop(context);
                          final service = ref.read(challengeServiceProvider);
                          await service.createChallenge(
                            template,
                            customDuration: duration,
                          );

                          if (parentContext.mounted) {
                            ScaffoldMessenger.of(parentContext).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Challenge "${template.title}" dimulai selama $duration hari!',
                                ),
                                backgroundColor: AppColors.primary,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            );
                            ref.invalidate(activeChallengesProvider);
                            try {
                              DefaultTabController.of(
                                parentContext,
                              ).animateTo(0);
                            } catch (_) {}
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Mulai Challenge Sekarang',
                          style: GoogleFonts.comicNeue(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: GoogleFonts.comicNeue(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}





class _BadgesTab extends ConsumerWidget {
  const _BadgesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final badgesAsync = ref.watch(allBadgesProvider);
    final badgeStats = ref.watch(badgeStatsProvider);

    return Column(
      children: [

        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.primaryLight],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Column(
                children: [
                  Text(
                    badgeStats['earned'].toString(),
                    style: GoogleFonts.comicNeue(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Badge Diraih',
                    style: GoogleFonts.comicNeue(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.white.withValues(alpha: 0.3),
              ),
              Column(
                children: [
                  Text(
                    '${badgeStats['percentage']}%',
                    style: GoogleFonts.comicNeue(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Koleksi',
                    style: GoogleFonts.comicNeue(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),


        Expanded(
          child: badgesAsync.when(
            data: (badges) {
              return GridView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 0.78, // Taller cards to accommodate text
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                ),
                itemCount: badges.length,
                itemBuilder: (context, index) {
                  return _BadgeItem(badge: badges[index]);
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: 16,
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    Text(
                      'Terjadi kesalahan',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BadgeItem extends StatelessWidget {
  final BadgeModel badge;

  const _BadgeItem({required this.badge});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      elevation: badge.isEarned ? 3 : 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      color: badge.isEarned
          ? theme.cardColor
          : (isDark ? Colors.grey[850] : Colors.grey[200]),
      child: InkWell(
        onTap: () => _showBadgeDetail(context),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 4, // Reduced spacing
            children: [

              Container(
                width: 48, // Reduced from 56
                height: 48, // Reduced from 56
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: badge.isEarned
                      ? _getCategoryColor()
                      : (theme.brightness == Brightness.dark
                            ? Colors.grey[700]
                            : Colors.grey[400]),
                  boxShadow: badge.isEarned
                      ? [
                          BoxShadow(
                            color: _getCategoryColor().withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Icon(
                  _getCategoryIcon(),
                  color: Colors.white,
                  size: 24, // Reduced from 28
                ),
              ),
              Text(
                badge.name,
                textAlign: TextAlign.center,
                style: GoogleFonts.comicNeue(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: badge.isEarned
                      ? (isDark ? Colors.white : AppColors.primaryDark)
                      : Colors.grey[600],
                  height: 1.2,
                  letterSpacing: 0.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showBadgeDetail(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: Row(
          children: [
            Icon(_getCategoryIcon(), color: _getCategoryColor(), size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                badge.name,
                style: GoogleFonts.comicNeue(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              badge.description,
              style: GoogleFonts.comicNeue(
                fontSize: 14,
                height: 1.5,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 14),
            if (badge.requiredPoints > 0)
              _buildRequirement('🎯 Butuh ${badge.requiredPoints} poin'),
            if (badge.requiredStreak != null)
              _buildRequirement('🔥 Butuh ${badge.requiredStreak} hari streak'),
            if (badge.isEarned) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.green.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      color: Colors.green,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Sudah Diraih!',
                      style: GoogleFonts.comicNeue(
                        color: Colors.green,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Tutup',
              style: GoogleFonts.comicNeue(
                fontWeight: FontWeight.w900,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequirement(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_outline_rounded,
            size: 14,
            color: Colors.grey,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: GoogleFonts.comicNeue(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor() {
    switch (badge.category) {
      case BadgeCategory.streak:
        return Colors.orange;
      case BadgeCategory.challenge:
        return Colors.blue;
      case BadgeCategory.saving:
        return Colors.green;
      case BadgeCategory.special:
        return Colors.purple;
    }
  }

  IconData _getCategoryIcon() {
    switch (badge.category) {
      case BadgeCategory.streak:
        return Icons.local_fire_department_rounded;
      case BadgeCategory.challenge:
        return Icons.emoji_events_rounded;
      case BadgeCategory.saving:
        return Icons.savings_rounded;
      case BadgeCategory.special:
        return Icons.stars_rounded;
    }
  }
}
