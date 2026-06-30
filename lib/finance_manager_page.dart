import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:ui';
import 'dart:convert';

class FinanceManagerPage extends StatefulWidget {
  const FinanceManagerPage({super.key});

  @override
  State<FinanceManagerPage> createState() => _FinanceManagerPageState();
}

class _FinanceManagerPageState extends State<FinanceManagerPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Box _box;
  bool _isLoading = true;
  int _currentTabIndex = 0;

  bool _isEnglish = true;
  double _fontSizeMultiplier = 1.0;

  List<Map<String, dynamic>> _transactions = [];
  List<Map<String, dynamic>> _wishlist = [];

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _wishNameController = TextEditingController();
  final TextEditingController _wishTargetController = TextEditingController();
  final TextEditingController _wishSavedAmountController =
      TextEditingController();

  bool _isIncomeInput = false;
  String _selectedCategory = 'Other';
  String _selectedWishIcon = '💰';
  String? _selectedWishlistId;
  String? _editingId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _currentTabIndex = _tabController.index);
      }
    });
    _initHive();
  }

  Future<void> _initHive() async {
    _box = await Hive.openBox('finance_box');
    _loadData();
    _loadSettings();
    setState(() => _isLoading = false);
  }

  void _loadSettings() {
    setState(() {
      _isEnglish = _box.get('is_english', defaultValue: true);
      _fontSizeMultiplier = _box.get('font_size', defaultValue: 1.0);
    });
  }

  void _saveSettings() {
    _box.put('is_english', _isEnglish);
    _box.put('font_size', _fontSizeMultiplier);
  }

  void _loadData() {
    final String? transJson = _box.get('transactions');
    final String? wishJson = _box.get('wishlist');
    setState(() {
      if (transJson != null) {
        final decoded = jsonDecode(transJson) as List;
        _transactions = decoded
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
      if (wishJson != null) {
        final decoded = jsonDecode(wishJson) as List;
        _wishlist = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
      } else {
        _wishlist = [
          {
            'id': 'w1',
            'name': _t('Savings'),
            'targetAmount': 5000000.0,
            'savedAmount': 0.0,
            'icon': '🐋',
          },
        ];
      }
    });
  }

  void _saveData() {
    _box.put('transactions', jsonEncode(_transactions));
    _box.put('wishlist', jsonEncode(_wishlist));
  }

  void _confirmDel(int index, bool isTransaction) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0D1117),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          isTransaction ? "DELETE TRANSACTION" : "DELETE WISH",
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          "Are you sure you want to delete this item?",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "CANCEL",
              style: TextStyle(color: Colors.white38),
            ),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                if (isTransaction) {
                  _transactions.removeAt(index);
                } else {
                  _wishlist.removeAt(index);
                }
              });
              _saveData();
              Navigator.pop(context);
            },
            child: const Text(
              "DELETE",
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _t(String key) {
    final Map<String, Map<String, String>> translations = {
      'FINANCE': {'EN': 'FINANCE', 'ID': 'KEUANGAN'},
      'TOTAL BALANCE': {'EN': 'TOTAL BALANCE', 'ID': 'TOTAL SALDO'},
      'INCOME': {'EN': 'INCOME', 'ID': 'PEMASUKAN'},
      'EXPENSE': {'EN': 'EXPENSE', 'ID': 'PENGELUARAN'},
      'STATS': {'EN': 'STATS', 'ID': 'STATISTIK'},
      'HISTORY': {'EN': 'HISTORY', 'ID': 'RIWAYAT'},
      'WISHLIST': {'EN': 'WISHLIST', 'ID': 'WISHLIST'},
      'NO DATA': {'EN': 'NO DATA YET', 'ID': 'BELUM ADA DATA'},
      'DAYS LEFT': {'EN': 'DAYS LEFT', 'ID': 'HARI LAGI'},
      'Savings': {'EN': 'Savings', 'ID': 'Tabungan'},
    };
    return translations[key]?[_isEnglish ? 'EN' : 'ID'] ?? key;
  }

  double get totalIncome => _transactions
      .where((t) => t['isIncome'])
      .fold(0.0, (sum, t) => sum + (t['amount'] as num).toDouble());
  double get totalExpense => _transactions
      .where((t) => !t['isIncome'])
      .fold(0.0, (sum, t) => sum + (t['amount'] as num).toDouble());
  double get balance => totalIncome - totalExpense;

  double get todayIncome => _transactions
      .where((t) {
        if (!t['isIncome']) return false;
        DateTime dt = DateTime.parse(t['date']);
        DateTime now = DateTime.now();
        return dt.year == now.year &&
            dt.month == now.month &&
            dt.day == now.day;
      })
      .fold(0.0, (sum, t) => sum + (t['amount'] as num).toDouble());

  double get todayExpense => _transactions
      .where((t) {
        if (t['isIncome']) return false;
        DateTime dt = DateTime.parse(t['date']);
        DateTime now = DateTime.now();
        return dt.year == now.year &&
            dt.month == now.month &&
            dt.day == now.day;
      })
      .fold(0.0, (sum, t) => sum + (t['amount'] as num).toDouble());

  double get weekIncome => _transactions
      .where((t) {
        if (!t['isIncome']) return false;
        DateTime dt = DateTime.parse(t['date']);
        DateTime now = DateTime.now();
        return now.difference(dt).inDays < 7;
      })
      .fold(0.0, (sum, t) => sum + (t['amount'] as num).toDouble());

  double get weekExpense => _transactions
      .where((t) {
        if (t['isIncome']) return false;
        DateTime dt = DateTime.parse(t['date']);
        DateTime now = DateTime.now();
        return now.difference(dt).inDays < 7;
      })
      .fold(0.0, (sum, t) => sum + (t['amount'] as num).toDouble());

  String _formatCurrency(double amount) {
    return "Rp ${amount.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}";
  }

  void _processTransaction() {
    String cleanAmt = _amountController.text
        .replaceAll('.', '')
        .replaceAll(',', '.');
    final double? amt = double.tryParse(cleanAmt);
    if (amt == null) return;
    setState(() {
      String id =
          _editingId ?? DateTime.now().millisecondsSinceEpoch.toString();
      Map<String, dynamic> trans = {
        'id': id,
        'title': _titleController.text,
        'amount': amt,
        'isIncome': _isIncomeInput,
        'category': _selectedCategory,
        'date': DateTime.now().toIso8601String(),
        'wishlistId': _selectedWishlistId,
      };

      if (_editingId != null) {
        int idx = _transactions.indexWhere((t) => t['id'] == _editingId);
        _transactions[idx] = trans;
      } else {
        _transactions.insert(0, trans);
      }


      if (_selectedWishlistId != null) {
        int wIdx = _wishlist.indexWhere((w) => w['id'] == _selectedWishlistId);
        if (wIdx != -1) {
          _wishlist[wIdx]['savedAmount'] =
              (_wishlist[wIdx]['savedAmount'] as num).toDouble() + amt;
        }
      }
    });
    _saveData();
    Navigator.pop(context);
    _clearInputs();
  }

  void _processWishlist() {
    String cleanTgt = _wishTargetController.text
        .replaceAll('.', '')
        .replaceAll(',', '.');
    final double? tgt = double.tryParse(cleanTgt);
    if (tgt == null) return;

    String cleanSaved = _wishSavedAmountController.text
        .replaceAll('.', '')
        .replaceAll(',', '.');
    final double saved = double.tryParse(cleanSaved) ?? 0.0;
    setState(() {
      if (_editingId != null) {
        int idx = _wishlist.indexWhere((w) => w['id'] == _editingId);
        _wishlist[idx] = {
          'id': _editingId,
          'name': _wishNameController.text,
          'targetAmount': tgt,
          'savedAmount': saved,
          'icon': _selectedWishIcon,
        };
      } else {
        _wishlist.add({
          'id': DateTime.now().millisecondsSinceEpoch.toString(),
          'name': _wishNameController.text,
          'targetAmount': tgt,
          'savedAmount': saved,
          'icon': _selectedWishIcon,
        });
      }
    });
    _saveData();
    Navigator.pop(context);
    _clearInputs();
  }

  void _clearInputs() {
    _titleController.clear();
    _amountController.clear();
    _wishNameController.clear();
    _wishTargetController.clear();
    _wishSavedAmountController.clear();
    _editingId = null;
    _selectedCategory = 'Other';
    _selectedWishlistId = null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF030508),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.cyanAccent),
            )
          : Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(painter: _BackgroundPainter()),
                ),
                Positioned(
                  top: -100,
                  right: -50,
                  child: _glow(Colors.cyan.withOpacity(0.08)),
                ),
                Positioned(
                  bottom: -50,
                  left: -50,
                  child: _glow(Colors.blue.withOpacity(0.08)),
                ),

                SafeArea(
                  child: Column(
                    children: [
                      _buildHeader(),
                      _buildBalanceCard()
                          .animate()
                          .fadeIn(duration: 600.ms)
                          .slideY(begin: 0.1, curve: Curves.easeOutBack),
                      _buildTabBar().animate().fadeIn(delay: 200.ms),
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          physics: const BouncingScrollPhysics(),
                          children: [
                            _buildStatsView()
                                .animate()
                                .fadeIn(duration: 400.ms)
                                .slideX(begin: 0.1, curve: Curves.easeOutCubic),
                            _buildHistoryView()
                                .animate()
                                .fadeIn(duration: 400.ms)
                                .slideX(begin: 0.1, curve: Curves.easeOutCubic),
                            _buildWishlistView()
                                .animate()
                                .fadeIn(duration: 400.ms)
                                .slideX(begin: 0.1, curve: Curves.easeOutCubic),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _editingId = null;
          _titleController.clear();
          _amountController.clear();
          _currentTabIndex == 2 ? _showWishSheet() : _showTransSheet();
        },
        backgroundColor: Colors.transparent,
        elevation: 0,
        label: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF00B4D8), Color(0xFF0077B6)],
            ),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(color: Colors.cyan.withOpacity(0.3), blurRadius: 15),
            ],
          ),
          child: Row(
            children: [
              const Icon(Iconsax.add, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                _currentTabIndex == 2 ? "NEW WISH" : "NEW DATA",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 12 * _fontSizeMultiplier,
                ),
              ),
            ],
          ),
        ),
      ).animate().scale(delay: 500.ms),
    );
  }

  Widget _glow(Color c) => Container(
    width: 300,
    height: 300,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      boxShadow: [BoxShadow(color: c, blurRadius: 100, spreadRadius: 50)],
    ),
  );

  Widget _buildStatsView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          _buildTodaySummaryCard(),
          const SizedBox(height: 25),
          Text(
            _t('DISTRIBUSI PENGELUARAN'),
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 15),
          _buildCategoryChart(),
          const SizedBox(height: 25),
          Text(
            _t('CASH FLOW'),
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 15),
          _buildCashFlowCard(),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildCategoryChart() {
    final chartData = _getChartData();
    if (chartData.isEmpty) return _emptyStateChart();

    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          SizedBox(
            height: 150,
            width: 150,
            child: PieChart(
              PieChartData(
                sections: chartData,
                centerSpaceRadius: 40,
                sectionsSpace: 5,
              ),
            ),
          ),
          const SizedBox(width: 30),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: _getChartLegend(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyStateChart() => Container(
    width: double.infinity,
    height: 100,
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.02),
      borderRadius: BorderRadius.circular(20),
    ),
    child: const Center(
      child: Text(
        "BELUM ADA DATA PENGELUARAN",
        style: TextStyle(
          color: Colors.white24,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
  );

  List<PieChartSectionData> _getChartData() {
    Map<String, double> categoryMap = {};
    for (var t in _transactions.where((t) => !t['isIncome'])) {
      String cat = t['category'] ?? "Lainnya";
      categoryMap[cat] =
          (categoryMap[cat] ?? 0) + (t['amount'] as num).toDouble();
    }
    if (categoryMap.isEmpty) return [];
    List<Color> colors = [
      Colors.cyanAccent,
      Colors.blueAccent,
      Colors.purpleAccent,
      Colors.orangeAccent,
      Colors.pinkAccent,
    ];
    int i = 0;
    return categoryMap.entries
        .map(
          (e) => PieChartSectionData(
            value: e.value,
            title: "",
            radius: 15,
            color: colors[i++ % colors.length],
            showTitle: false,
          ),
        )
        .toList();
  }

  List<Widget> _getChartLegend() {
    Map<String, double> categoryMap = {};
    for (var t in _transactions.where((t) => !t['isIncome'])) {
      String cat = t['category'] ?? "Lainnya";
      categoryMap[cat] =
          (categoryMap[cat] ?? 0) + (t['amount'] as num).toDouble();
    }
    List<Color> colors = [
      Colors.cyanAccent,
      Colors.blueAccent,
      Colors.purpleAccent,
      Colors.orangeAccent,
      Colors.pinkAccent,
    ];
    int i = 0;
    return categoryMap.entries.take(4).map((e) {
      Color c = colors[i++ % colors.length];
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: c, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                e.key.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              _formatCurrency(e.value),
              style: TextStyle(
                color: c,
                fontSize: 9,
                fontWeight: FontWeight.bold,
                fontFamily: 'ShareTechMono',
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildTodaySummaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "SUMMARY HARI INI",
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.cyanAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Iconsax.calendar_1,
                  color: Colors.cyanAccent,
                  size: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _summaryItem("MASUK", todayIncome, Colors.greenAccent),
              ),
              Container(width: 1, height: 40, color: Colors.white10),
              Expanded(
                child: _summaryItem("KELUAR", todayExpense, Colors.redAccent),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryItem(String l, double a, Color c) => Column(
    children: [
      Text(
        l,
        style: const TextStyle(
          color: Colors.white38,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 6),
      Text(
        _formatCurrency(a),
        style: TextStyle(
          color: c,
          fontSize: 18,
          fontWeight: FontWeight.w900,
          fontFamily: 'ShareTechMono',
        ),
      ),
    ],
  );

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(width: 15),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _t('FINANCE'),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22 * _fontSizeMultiplier,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.cyanAccent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: const Text(
                      "INTELLIGENCE",
                      style: TextStyle(
                        color: Colors.cyanAccent,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          IconButton(
            onPressed: _showSettingsSheet,
            icon: const Icon(Iconsax.setting_2, color: Colors.cyanAccent),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.08),
            Colors.white.withOpacity(0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(35),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _t('TOTAL BALANCE'),
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 10 * _fontSizeMultiplier,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
              const Icon(Iconsax.card_pos, color: Colors.white12, size: 20),
            ],
          ),
          const SizedBox(height: 15),
          Text(
            _formatCurrency(balance),
            style: TextStyle(
              color: Colors.white,
              fontSize: 36 * _fontSizeMultiplier,
              fontWeight: FontWeight.w900,
              fontFamily: 'ShareTechMono',
              shadows: [
                Shadow(
                  color: Colors.cyanAccent.withOpacity(0.3),
                  blurRadius: 15,
                ),
              ],
            ),
          ),
          const SizedBox(height: 35),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _balItem(_t('INCOME'), totalIncome, Colors.greenAccent),
              Container(
                width: 1,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withOpacity(0),
                      Colors.white.withOpacity(0.1),
                      Colors.white.withOpacity(0),
                    ],
                  ),
                ),
              ),
              _balItem(_t('EXPENSE'), totalExpense, Colors.redAccent),
            ],
          ),
        ],
      ),
    );
  }

  Widget _balItem(String l, double a, Color c) => Column(
    children: [
      Text(
        l,
        style: const TextStyle(
          color: Colors.white24,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
      Text(
        _formatCurrency(a),
        style: TextStyle(color: c, fontWeight: FontWeight.w900, fontSize: 15),
      ),
    ],
  );

  Widget _buildTabBar() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
    child: Container(
      height: 56,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: const LinearGradient(
            colors: [Color(0xFF00B4D8), Color(0xFF0077B6)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00B4D8).withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white38,
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: 11,
          letterSpacing: 1,
        ),
        tabs: [
          Tab(text: _t('STATS')),
          Tab(text: _t('HISTORY')),
          Tab(text: _t('WISHLIST')),
        ],
      ),
    ),
  );

  Widget _buildCashFlowCard() {
    double total = totalIncome + totalExpense;
    double incPr = total == 0 ? 0.5 : totalIncome / total;
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _flowItem("INCOME", totalIncome, Colors.greenAccent),
              _flowItem("EXPENSE", totalExpense, Colors.redAccent),
            ],
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: incPr,
              minHeight: 8,
              backgroundColor: Colors.redAccent.withOpacity(0.2),
              valueColor: const AlwaysStoppedAnimation(Colors.greenAccent),
            ),
          ),
        ],
      ),
    );
  }

  Widget _flowItem(String l, double a, Color c) => Column(
    crossAxisAlignment: l == "INCOME"
        ? CrossAxisAlignment.start
        : CrossAxisAlignment.end,
    children: [
      Text(
        l,
        style: const TextStyle(
          color: Colors.white24,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
      Text(
        _formatCurrency(a),
        style: TextStyle(color: c, fontWeight: FontWeight.w900, fontSize: 16),
      ),
    ],
  );

  Widget _buildHistoryView() {
    if (_transactions.isEmpty) return _emptyState();
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _transactions.length,
      itemBuilder: (context, i) {
        final t = _transactions[i];
        bool isInc = t['isIncome'];
        return InkWell(
              onTap: () {
                setState(() {
                  _editingId = t['id'];
                  _titleController.text = t['title'];
                  _amountController.text = (t['amount'] as num)
                      .toInt()
                      .toString();
                  _isIncomeInput = t['isIncome'];
                  _selectedCategory = t['category'];
                });
                _showTransSheet();
              },
              onLongPress: () => _confirmDel(i, true),
              child: Container(
                margin: const EdgeInsets.only(bottom: 15),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.05),
                      Colors.white.withOpacity(0.02),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: (isInc ? Colors.greenAccent : Colors.redAccent)
                            .withOpacity(0.12),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color:
                                (isInc ? Colors.greenAccent : Colors.redAccent)
                                    .withOpacity(0.1),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Icon(
                        isInc ? Iconsax.receive_square : Iconsax.send_2,
                        color: isInc ? Colors.greenAccent : Colors.redAccent,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t['title'],
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  (t['category'] ?? "Other").toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 8,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                isInc ? _t('INCOME') : _t('EXPENSE'),
                                style: TextStyle(
                                  color: isInc
                                      ? Colors.greenAccent.withOpacity(0.7)
                                      : Colors.redAccent.withOpacity(0.7),
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
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
                          (isInc ? "+" : "-") +
                              _formatCurrency((t['amount'] as num).toDouble()),
                          style: TextStyle(
                            color: isInc
                                ? Colors.greenAccent
                                : Colors.redAccent,
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            fontFamily: 'ShareTechMono',
                          ),
                        ),
                        Text(
                          DateTime.parse(t['date']).toString().split(' ')[0],
                          style: const TextStyle(
                            color: Colors.white12,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            )
            .animate(delay: (i * 30).ms)
            .fadeIn(duration: 400.ms)
            .slideX(begin: 0.1, curve: Curves.easeOutCubic);
      },
    );
  }

  Widget _buildWishlistView() {
    if (_wishlist.isEmpty) return _emptyState();
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _wishlist.length,
      itemBuilder: (context, i) {
        final item = _wishlist[i];
        double pr = (item['savedAmount'] / item['targetAmount']).clamp(
          0.0,
          1.0,
        );
        return InkWell(
              onTap: () {
                setState(() {
                  _editingId = item['id'];
                  _wishNameController.text = item['name'];
                  _wishTargetController.text = item['targetAmount']
                      .toInt()
                      .toString();
                  _wishSavedAmountController.text = item['savedAmount']
                      .toInt()
                      .toString();
                  _selectedWishIcon = item['icon'];
                });
                _showWishSheet();
              },
              onLongPress: () => _confirmDel(i, false),
              child: Container(
                margin: const EdgeInsets.only(bottom: 15),
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Text(
                            item['icon'],
                            style: const TextStyle(fontSize: 24),
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['name'],
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 15 * _fontSizeMultiplier,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Text(
                                "${_t('TARGET')}: ${_formatCurrency((item['targetAmount'] as num).toDouble())}",
                                style: const TextStyle(
                                  color: Colors.white38,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          "${(pr * 100).toInt()}%",
                          style: const TextStyle(
                            color: Colors.cyanAccent,
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _isIncomeInput = false;
                              _selectedCategory = 'Wishlist';
                              _selectedWishlistId = item['id'];
                              _titleController.text =
                                  "${_t('SAVE FOR')} ${item['name']}";
                            });
                            _showTransSheet();
                          },
                          icon: const Icon(
                            Iconsax.add_square,
                            color: Colors.cyanAccent,
                            size: 22,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 25),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: pr,
                        backgroundColor: Colors.white.withOpacity(0.05),
                        valueColor: AlwaysStoppedAnimation(
                          pr >= 1 ? Colors.greenAccent : Colors.cyanAccent,
                        ),
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(height: 15),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _t('SAVED'),
                              style: const TextStyle(
                                color: Colors.white24,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              _formatCurrency(
                                (item['savedAmount'] as num).toDouble(),
                              ),
                              style: const TextStyle(
                                color: Colors.greenAccent,
                                fontWeight: FontWeight.w900,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              _t('NEEDED'),
                              style: const TextStyle(
                                color: Colors.white24,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              _formatCurrency(
                                ((item['targetAmount'] as num) -
                                        (item['savedAmount'] as num))
                                    .toDouble()
                                    .clamp(0.0, double.infinity),
                              ),
                              style: const TextStyle(
                                color: Colors.redAccent,
                                fontWeight: FontWeight.w900,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            )
            .animate(delay: (i * 50).ms)
            .fadeIn()
            .slideY(begin: 0.1, curve: Curves.easeOutBack);
      },
    );
  }

  Widget _emptyState() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Iconsax.document_filter, color: Colors.white10, size: 60),
        const SizedBox(height: 15),
        Text(
          _t('NO DATA'),
          style: const TextStyle(
            color: Colors.white24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  );

  void _showTransSheet() => showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => StatefulBuilder(
      builder: (context, st) => _sheetWrap(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _editingId != null ? "EDIT DATA" : "TAMBAH DATA",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (_editingId != null)
                  IconButton(
                    onPressed: () {
                      int idx = _transactions.indexWhere(
                        (t) => t['id'] == _editingId,
                      );
                      setState(() => _transactions.removeAt(idx));
                      _saveData();
                      Navigator.pop(context);
                    },
                    icon: const Icon(Iconsax.trash, color: Colors.redAccent),
                  ),
              ],
            ),
            const SizedBox(height: 30),
            _inp(_titleController, "DESKRIPSI / KETERANGAN"),
            const SizedBox(height: 20),
            _inp(_amountController, "NOMINAL (Rp)", isNum: true),
            const SizedBox(height: 25),
            const Text(
              "CATEGORY",
              style: TextStyle(
                color: Colors.white38,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  [
                        'Makanan',
                        'Minuman',
                        'Transport',
                        'Belanja',
                        'Tagihan',
                        'Hiburan',
                        'Transfer',
                        'Lainnya',
                        'Wishlist',
                      ]
                      .map(
                        (e) => InkWell(
                          onTap: () => st(() => _selectedCategory = e),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: _selectedCategory == e
                                  ? Colors.cyanAccent.withOpacity(0.2)
                                  : Colors.white10,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: _selectedCategory == e
                                    ? Colors.cyanAccent
                                    : Colors.transparent,
                              ),
                            ),
                            child: Text(
                              e,
                              style: TextStyle(
                                color: _selectedCategory == e
                                    ? Colors.cyanAccent
                                    : Colors.white60,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
            ),
            const SizedBox(height: 25),
            if (_isIncomeInput || _selectedCategory == 'Wishlist') ...[
              const Text(
                "ALLOCATE TO WISHLIST",
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _wishlist
                    .map(
                      (w) => InkWell(
                        onTap: () => st(
                          () => _selectedWishlistId =
                              (_selectedWishlistId == w['id'] ? null : w['id']),
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _selectedWishlistId == w['id']
                                ? Colors.cyanAccent.withOpacity(0.2)
                                : Colors.white10,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _selectedWishlistId == w['id']
                                  ? Colors.cyanAccent
                                  : Colors.transparent,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                w['icon'],
                                style: const TextStyle(fontSize: 14),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                w['name'],
                                style: TextStyle(
                                  color: _selectedWishlistId == w['id']
                                      ? Colors.cyanAccent
                                      : Colors.white60,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 25),
            ],
            Row(
              children: [
                _typeB(
                  _t('EXPENSE'),
                  Colors.redAccent,
                  !_isIncomeInput,
                  () => st(() => _isIncomeInput = false),
                ),
                const SizedBox(width: 15),
                _typeB(
                  _t('INCOME'),
                  Colors.greenAccent,
                  _isIncomeInput,
                  () => st(() => _isIncomeInput = true),
                ),
              ],
            ),
            const Spacer(),
            _btn(_processTransaction),
          ],
        ),
      ),
    ),
  );

  void _showWishSheet() => showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _sheetWrap(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _editingId != null ? "EDIT WISH" : "ADD WISH",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (_editingId != null)
                IconButton(
                  onPressed: () {
                    int idx = _wishlist.indexWhere(
                      (w) => w['id'] == _editingId,
                    );
                    setState(() => _wishlist.removeAt(idx));
                    _saveData();
                    Navigator.pop(context);
                  },
                  icon: const Icon(Iconsax.trash, color: Colors.redAccent),
                ),
            ],
          ),
          const SizedBox(height: 30),
          _inp(_wishNameController, "NAME"),
          const SizedBox(height: 20),
          _inp(_wishTargetController, "TARGET PRICE", isNum: true),
          const SizedBox(height: 20),
          _inp(_wishSavedAmountController, "ALREADY SAVED", isNum: true),
          const SizedBox(height: 30),
          StatefulBuilder(
            builder: (context, st) => Wrap(
              spacing: 10,
              children: ['💰', '🎮', '🚗', '🏠', '📱', '✈️']
                  .map(
                    (e) => InkWell(
                      onTap: () => st(() => _selectedWishIcon = e),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _selectedWishIcon == e
                              ? Colors.cyanAccent.withOpacity(0.2)
                              : Colors.white10,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Text(e, style: const TextStyle(fontSize: 22)),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const Spacer(),
          _btn(_processWishlist),
        ],
      ),
    ),
  );

  Widget _sheetWrap({required Widget child}) => BackdropFilter(
    filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
    child: Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117).withOpacity(0.85),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 40),
        ],
      ),
      padding: const EdgeInsets.all(35),
      child: child,
    ),
  );
  Widget _inp(TextEditingController c, String l, {bool isNum = false}) =>
      TextField(
        controller: c,
        keyboardType: isNum ? TextInputType.number : TextInputType.text,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: l,
          labelStyle: const TextStyle(color: Colors.white38),
          enabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.white12),
          ),
        ),
      );
  Widget _typeB(String l, Color c, bool s, VoidCallback t) => Expanded(
    child: InkWell(
      onTap: t,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: s ? c.withOpacity(0.1) : Colors.white10,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: s ? c : Colors.white12),
        ),
        child: Center(
          child: Text(
            l,
            style: TextStyle(
              color: s ? c : Colors.white38,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    ),
  );
  Widget _btn(VoidCallback tap) => SizedBox(
    width: double.infinity,
    height: 60,
    child: ElevatedButton(
      onPressed: tap,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.cyanAccent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      child: const Text(
        "CONFIRM DATA",
        style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900),
      ),
    ),
  );

  void _showSettingsSheet() => showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) => _sheetWrap(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "SETTINGS",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 30),
          StatefulBuilder(
            builder: (context, st) => Column(
              children: [
                Row(
                  children: [
                    _chip('ID', !_isEnglish, () {
                      st(() => _isEnglish = false);
                      setState(() => _isEnglish = false);
                      _saveSettings();
                    }),
                    const SizedBox(width: 15),
                    _chip('EN', _isEnglish, () {
                      st(() => _isEnglish = true);
                      setState(() => _isEnglish = true);
                      _saveSettings();
                    }),
                  ],
                ),
                const SizedBox(height: 30),
                Slider(
                  value: _fontSizeMultiplier,
                  min: 0.8,
                  max: 1.4,
                  divisions: 3,
                  activeColor: Colors.cyanAccent,
                  onChanged: (v) {
                    st(() => _fontSizeMultiplier = v);
                    setState(() => _fontSizeMultiplier = v);
                    _saveSettings();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
  Widget _chip(String l, bool s, VoidCallback t) => Expanded(
    child: InkWell(
      onTap: t,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: s ? Colors.cyanAccent.withOpacity(0.1) : Colors.white10,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: s ? Colors.cyanAccent : Colors.transparent),
        ),
        child: Center(
          child: Text(
            l,
            style: TextStyle(
              color: s ? Colors.cyanAccent : Colors.white38,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    ),
  );
}

class _BackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.015)
      ..strokeWidth = 1.0;
    const double gap = 40;
    for (double i = -size.height; i < size.width; i += gap) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        paint,
      );
    }
    for (double i = size.width + size.height; i > 0; i -= gap) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i - size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(CustomPainter o) => false;
}
