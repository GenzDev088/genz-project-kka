import '../models/challenge_template_model.dart';
import '../models/challenge_model.dart';
import 'package:flutter/material.dart';

class ChallengeTemplates {

  static final List<ChallengeTemplateModel> dailyChallenges = [
    ChallengeTemplateModel(
      id: 'no-jajan',
      title: 'Tidak Jajan Hari Ini',
      description:
          'Tantangan untuk tidak mengeluarkan uang untuk jajan atau makanan kecil di bawah Rp 50.000 hari ini',
      type: ChallengeType.daily,
      difficulty: ChallengeDifficulty.easy,
      defaultDurationDays: 1,
      targetType: ChallengeTargetType.categoryLimit,
      suggestedTargetAmount: 0,
      targetCategory: 'Makanan & Minuman',
      tips: [
        'Bawa bekal dari rumah',
        'Minum air putih saja',
        'Hindari melewati kantin atau warung',
        'Ajak teman untuk ikut challenge bareng',
      ],
      icon: Icons.no_meals_rounded,
      points: 10,
    ),
    ChallengeTemplateModel(
      id: 'save-20k',
      title: 'Hemat 20 Ribu',
      description: 'Sisihkan minimal Rp 20.000 untuk ditabung hari ini',
      type: ChallengeType.daily,
      difficulty: ChallengeDifficulty.easy,
      defaultDurationDays: 1,
      targetType: ChallengeTargetType.saveAmount,
      suggestedTargetAmount: 20000,
      tips: [
        'Tabung uang recehan yang ada di dompet',
        'Kurangi satu kebiasaan belanja harian',
        'Masukkan langsung ke tabungan pagi hari',
      ],
      icon: Icons.savings_rounded,
      points: 10,
    ),
    ChallengeTemplateModel(
      id: 'zero-expense',
      title: 'Zero Expense Day',
      description:
          'Tantangan untuk tidak mengeluarkan uang sama sekali hari ini. Gunakan hanya yang sudah ada!',
      type: ChallengeType.daily,
      difficulty: ChallengeDifficulty.hard,
      defaultDurationDays: 1,
      targetType: ChallengeTargetType.zeroExpense,
      suggestedTargetAmount: 0,
      tips: [
        'Siapkan semua keperluan dari kemarin',
        'Bawa bekal dan minuman dari rumah',
        'Hindari buka aplikasi shopping online',
        'Fokus pada aktivitas gratis',
      ],
      icon: Icons.lock_outline_rounded,
      points: 25,
    ),
    ChallengeTemplateModel(
      id: 'save-50k',
      title: 'Tabung 50 Ribu',
      description:
          'Challenge untuk menyisihkan Rp 50.000 dalam sehari. Perfect untuk yang dapat bonus atau gajian!',
      type: ChallengeType.daily,
      difficulty: ChallengeDifficulty.medium,
      defaultDurationDays: 1,
      targetType: ChallengeTargetType.saveAmount,
      suggestedTargetAmount: 50000,
      tips: [
        'Sisihkan dulu sebelum belanja',
        'Gunakan sistem amplop',
        'Jangan bawa uang berlebih',
      ],
      icon: Icons.account_balance_wallet_rounded,
      points: 15,
    ),
    ChallengeTemplateModel(
      id: 'kopi-homemade',
      title: 'Kopi Homemade',
      description:
          'Ganti kopi cafe mahal dengan buat sendiri di rumah atau kantor hari ini',
      type: ChallengeType.daily,
      difficulty: ChallengeDifficulty.easy,
      defaultDurationDays: 1,
      targetType: ChallengeTargetType.categoryLimit,
      targetCategory: 'Makanan & Minuman',
      tips: [
        'Bawa tumblr sendiri',
        'Stok sachet atau kopi bubuk enak di kantor',
        'Ingat harga segelas kopi di cafe bisa buat makan siang',
      ],
      icon: Icons.coffee_rounded,
      points: 12,
    ),
    ChallengeTemplateModel(
      id: 'input-all-expense',
      title: 'Input Semua Pengeluaran',
      description:
          'Catat SETIAP pengeluaran sekecil apapun hari ini di TabunganKu',
      type: ChallengeType.daily,
      difficulty: ChallengeDifficulty.easy,
      defaultDurationDays: 1,
      targetType: ChallengeTargetType.custom,
      tips: [
        'Catat segera setelah transaksi',
        'Simpan struk belanja',
        'Minta struk kalau beli di warung',
      ],
      icon: Icons.edit_note_rounded,
      points: 10,
    ),
  ];


  static final List<ChallengeTemplateModel> weeklyChallenges = [
    ChallengeTemplateModel(
      id: '52-week-mini',
      title: '52 Week Challenge (Mini)',
      description:
          'Mulai 52 week challenge! Minggu pertama tabung Rp 10.000, minggu kedua Rp 20.000, dan seterusnya',
      type: ChallengeType.weekly,
      difficulty: ChallengeDifficulty.medium,
      defaultDurationDays: 7,
      targetType: ChallengeTargetType.saveAmount,
      suggestedTargetAmount: 10000,
      tips: [
        'Siapkan toples atau celengan khusus',
        'Set reminder setiap minggu',
        'Cari side income untuk minggu-minggu selanjutnya',
        'Ajak keluarga untuk ikut',
      ],
      icon: Icons.calendar_month_rounded,
      points: 25,
    ),
    ChallengeTemplateModel(
      id: 'meal-prep',
      title: 'Meal Prep Week',
      description:
          'Hemat biaya makan dengan masak sendiri dan meal prep. Target: kurangi pengeluaran makanan 50%',
      type: ChallengeType.weekly,
      difficulty: ChallengeDifficulty.medium,
      defaultDurationDays: 7,
      targetType: ChallengeTargetType.categoryLimit,
      targetCategory: 'Makanan & Minuman',
      tips: [
        'Belanja bahan makanan weekend',
        'Masak untuk 2-3 hari sekaligus',
        'Simpan dalam container yang proper',
        'Buat menu sederhana tapi sehat',
      ],
      icon: Icons.lunch_dining_rounded,
      points: 30,
    ),
    ChallengeTemplateModel(
      id: 'no-online-shopping',
      title: 'No Online Shopping Week',
      description:
          'Pantang belanja online selama 1 minggu penuh. Buktikan kamu bisa!',
      type: ChallengeType.weekly,
      difficulty: ChallengeDifficulty.medium,
      defaultDurationDays: 7,
      targetType: ChallengeTargetType.noTransactionType,
      targetCategory: 'Belanja / Lifestyle',
      tips: [
        'Uninstall aplikasi e-commerce sementara',
        'Block notifikasi promo',
        'Buat wishlist untuk kemudian',
        'Cari aktivitas lain untuk mengisi waktu',
      ],
      icon: Icons.remove_shopping_cart_rounded,
      points: 30,
    ),
    ChallengeTemplateModel(
      id: 'save-100k-week',
      title: 'Tabung 100K Seminggu',
      description:
          'Challenge tabung total Rp 100.000 dalam seminggu. Bisa dicicil atau sekaligus!',
      type: ChallengeType.weekly,
      difficulty: ChallengeDifficulty.medium,
      defaultDurationDays: 7,
      targetType: ChallengeTargetType.saveAmount,
      suggestedTargetAmount: 100000,
      tips: [
        'Cicil Rp 15.000 per hari',
        'Cari side hustle untuk tambahan income',
        'Jual barang yang tidak terpakai',
        'Kurangi langganan yang tidak perlu',
      ],
      icon: Icons.monetization_on_rounded,
      points: 25,
    ),
    ChallengeTemplateModel(
      id: 'transport-saver',
      title: 'Hemat Transportasi',
      description:
          'Kurangi biaya transportasi 50% dengan naik kendaraan umum atau jalan kaki',
      type: ChallengeType.weekly,
      difficulty: ChallengeDifficulty.easy,
      defaultDurationDays: 7,
      targetType: ChallengeTargetType.categoryLimit,
      targetCategory: 'Transportasi & Bensin',
      tips: [
        'Gunakan transportasi umum',
        'Jalan kaki untuk jarak dekat',
        'Carpool dengan teman',
        'Gabungkan perjalanan',
      ],
      icon: Icons.directions_walk_rounded,
      points: 20,
    ),
    ChallengeTemplateModel(
      id: 'weekend-50k',
      title: 'Weekend 50K Max',
      description:
          'Habiskan maksimal Rp 50.000 untuk hiburan di hari Sabtu dan Minggu ini',
      type: ChallengeType.weekly,
      difficulty: ChallengeDifficulty.medium,
      defaultDurationDays: 7,
      targetType: ChallengeTargetType.categoryLimit,
      targetCategory: 'Hiburan & Langganan',
      suggestedTargetAmount: 50000,
      tips: [
        'Cari event gratis di kota',
        'Netflix & chill di rumah saja',
        'Masak dinner bareng pasangan/teman',
      ],
      icon: Icons.weekend_rounded,
      points: 35,
    ),
    ChallengeTemplateModel(
      id: 'grocery-lister',
      title: 'Grocery Lister',
      description:
          'Hanya beli sesuai daftar belanja saat ke supermarket/pasar seminggu ini',
      type: ChallengeType.weekly,
      difficulty: ChallengeDifficulty.medium,
      defaultDurationDays: 7,
      targetType: ChallengeTargetType.custom,
      tips: [
        'Tulis list saat perut kenyang',
        'Jangan beli barang promo yang tidak ada di list',
        'Pake cash sesuai estimasi total belanja saja',
      ],
      icon: Icons.playlist_add_check_rounded,
      points: 25,
    ),
  ];


  static final List<ChallengeTemplateModel> monthlyChallenges = [
    ChallengeTemplateModel(
      id: 'save-10-percent',
      title: '10% Saving Challenge',
      description:
          'Tabung minimal 10% dari total income bulan ini. Disiplin adalah kunci!',
      type: ChallengeType.monthly,
      difficulty: ChallengeDifficulty.medium,
      defaultDurationDays: 30,
      targetType: ChallengeTargetType.saveAmount,
      tips: [
        'Hitung total income di awal bulan',
        'Sisihkan 10% begitu terima gaji',
        'Jangan sentuh tabungan ini',
        'Buat rekening terpisah kalau perlu',
      ],
      icon: Icons.pie_chart_rounded,
      points: 50,
    ),
    ChallengeTemplateModel(
      id: 'entertainment-limit',
      title: 'Limit Hiburan',
      description:
          'Batasi pengeluaran hiburan (nonton, hangout, game) maksimal Rp 200.000 per bulan',
      type: ChallengeType.monthly,
      difficulty: ChallengeDifficulty.medium,
      defaultDurationDays: 30,
      targetType: ChallengeTargetType.categoryLimit,
      suggestedTargetAmount: 200000,
      targetCategory: 'Hiburan \u0026 Langganan',
      tips: [
        'Cari hiburan gratis atau murah',
        'Manfaatkan promo dan diskon',
        'Lebih banyak aktivitas di rumah',
        'Nonton streaming daripada bioskop',
      ],
      icon: Icons.sports_esports_rounded,
      points: 40,
    ),
    ChallengeTemplateModel(
      id: 'no-impulse-buy',
      title: 'No Impulse Buying Month',
      description:
          'Sebulan penuh hanya beli yang BENAR-BENAR diperlukan. Terapkan aturan tunggu 48 jam!',
      type: ChallengeType.monthly,
      difficulty: ChallengeDifficulty.hard,
      defaultDurationDays: 30,
      targetType: ChallengeTargetType.limitExpense,
      tips: [
        'Buat list kebutuhan di awal bulan',
        'Tunggu 48 jam sebelum beli apapun',
        'Tanya: "Apakah saya BUTUH ini?"',
        'Hindari scroll marketplace',
      ],
      icon: Icons.psychology_alt_rounded,
      points: 50,
    ),
    ChallengeTemplateModel(
      id: 'save-500k-month',
      title: 'Tabung 500K Sebulan',
      description:
          'Tantangan besar: sisihkan Rp 500.000 dalam sebulan! Bisa dengan menabung Rp 17.000/hari',
      type: ChallengeType.monthly,
      difficulty: ChallengeDifficulty.hard,
      defaultDurationDays: 30,
      targetType: ChallengeTargetType.saveAmount,
      suggestedTargetAmount: 500000,
      tips: [
        'Cicil Rp 17.000 per hari',
        'Atau Rp 125.000 per minggu',
        'Cari sumber income tambahan',
        'Potong pengeluaran tidak penting',
      ],
      icon: Icons.my_location_rounded,
      points: 60,
    ),
    ChallengeTemplateModel(
      id: 'diy-month',
      title: 'DIY Month',
      description:
          'Bulan ini, coba lakukan sendiri hal-hal yang biasanya bayar orang (potong rambut, cuci motor, dll)',
      type: ChallengeType.monthly,
      difficulty: ChallengeDifficulty.easy,
      defaultDurationDays: 30,
      targetType: ChallengeTargetType.categoryLimit,
      targetCategory: 'Biaya Admin & Lainnya',
      tips: [
        'Belajar dari YouTube',
        'Mulai dari yang sederhana',
        'Ajak keluarga untuk belajar bersama',
        'Hitung berapa yang berhasil dihemat',
      ],
      icon: Icons.handyman_rounded,
      points: 35,
    ),
    ChallengeTemplateModel(
      id: 'bill-reducer',
      title: 'Bill Reducer',
      description:
          'Turunkan tagihan listrik atau air sebesar 15% dibanding bulan lalu',
      type: ChallengeType.monthly,
      difficulty: ChallengeDifficulty.medium,
      defaultDurationDays: 30,
      targetType: ChallengeTargetType.custom,
      tips: [
        'Matikan lampu siang hari',
        'Cabut colokan yang tidak dipakai',
        'Kurangi penggunaan AC',
      ],
      icon: Icons.electric_bolt_rounded,
      points: 45,
    ),
    ChallengeTemplateModel(
      id: 'subscription-audit',
      title: 'Subscription Audit',
      description:
          'Saring dan berhentikan langganan yang sudah tidak efektif atau jarang dipakai',
      type: ChallengeType.monthly,
      difficulty: ChallengeDifficulty.medium,
      defaultDurationDays: 30,
      targetType: ChallengeTargetType.custom,
      tips: [
        'Cek mutasi bank/ewallet',
        'Matikan auto-renewal',
        'Gunakan versi gratis jika cukup',
      ],
      icon: Icons.subscriptions_rounded,
      points: 30,
    ),
  ];


  static List<ChallengeTemplateModel> getAllTemplates() {
    return [...dailyChallenges, ...weeklyChallenges, ...monthlyChallenges];
  }


  static List<ChallengeTemplateModel> getTemplatesByType(ChallengeType type) {
    switch (type) {
      case ChallengeType.daily:
        return dailyChallenges;
      case ChallengeType.weekly:
        return weeklyChallenges;
      case ChallengeType.monthly:
        return monthlyChallenges;
    }
  }


  static List<ChallengeTemplateModel> getTemplatesByDifficulty(
    ChallengeDifficulty difficulty,
  ) {
    return getAllTemplates().where((t) => t.difficulty == difficulty).toList();
  }


  static ChallengeTemplateModel? getTemplateById(String id) {
    try {
      return getAllTemplates().firstWhere((t) => t.id == id);
    } catch (e) {
      return null;
    }
  }


  static List<ChallengeTemplateModel> getRecommendedForBeginners() {
    return [
      getTemplateById('no-jajan')!,
      getTemplateById('save-20k')!,
      getTemplateById('transport-saver')!,
      getTemplateById('save-10-percent')!,
    ];
  }
}
