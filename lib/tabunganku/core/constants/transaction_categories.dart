import 'package:flutter/material.dart';

class TransactionCategory {
  final String label;
  final IconData icon;
  final String group;
  final Color color;

  const TransactionCategory({
    required this.label,
    required this.icon,
    required this.color,
    this.group = '',
  });
}

class AppCategories {

  static const String otherLabel = 'Lainnya';

  static const List<TransactionCategory> expenseCategories = [

    TransactionCategory(
      label: 'Makanan & Minuman Harian',
      icon: Icons.restaurant_rounded,
      group: 'Kebutuhan Pokok',
      color: Color(0xFF1E88E5),
    ),
    TransactionCategory(
      label: 'Belanja Sembako / Pasar',
      icon: Icons.shopping_basket_rounded,
      group: 'Kebutuhan Pokok',
      color: Color(0xFF00ACC1),
    ),
    TransactionCategory(
      label: 'Belanja Bulanan (Supermarket)',
      icon: Icons.shopping_cart_rounded,
      group: 'Kebutuhan Pokok',
      color: Color(0xFF0097A7),
    ),
    TransactionCategory(
      label: 'Token Listrik / PLN',
      icon: Icons.electric_bolt_rounded,
      group: 'Kebutuhan Pokok',
      color: Color(0xFFFFB300),
    ),
    TransactionCategory(
      label: 'Tagihan Air (PDAM)',
      icon: Icons.water_drop_rounded,
      group: 'Kebutuhan Pokok',
      color: Color(0xFF039BE5),
    ),
    TransactionCategory(
      label: 'Gas LPG & Isi Ulang Air',
      icon: Icons.propane_tank_rounded,
      group: 'Kebutuhan Pokok',
      color: Color(0xFFFB8C00),
    ),
    TransactionCategory(
      label: 'Sewa Kos / Kontrakan / KPR',
      icon: Icons.house_rounded,
      group: 'Kebutuhan Pokok',
      color: Color(0xFF43A047),
    ),
    TransactionCategory(
      label: 'Iuran Kebersihan & Keamanan',
      icon: Icons.security_rounded,
      group: 'Kebutuhan Pokok',
      color: Color(0xFF757575),
    ),
    TransactionCategory(
      label: 'Laundry & Kebersihan Rumah',
      icon: Icons.dry_cleaning_rounded,
      group: 'Kebutuhan Pokok',
      color: Color(0xFF42A5F5),
    ),
    TransactionCategory(
      label: 'Peralatan Rumah Tangga',
      icon: Icons.chair_rounded,
      group: 'Kebutuhan Pokok',
      color: Color(0xFF546E7A),
    ),


    TransactionCategory(
      label: 'Bahan Bakar (BBM)',
      icon: Icons.local_gas_station_rounded,
      group: 'Transportasi',
      color: Color(0xFFE53935),
    ),
    TransactionCategory(
      label: 'Ojek Online (Gojek/Grab)',
      icon: Icons.moped_rounded,
      group: 'Transportasi',
      color: Color(0xFF43A047),
    ),
    TransactionCategory(
      label: 'Taksi Online (Gocar/GrabCar)',
      icon: Icons.local_taxi_rounded,
      group: 'Transportasi',
      color: Color(0xFF2E7D32),
    ),
    TransactionCategory(
      label: 'Servis Kendaraan & Oli',
      icon: Icons.build_rounded,
      group: 'Transportasi',
      color: Color(0xFF455A64),
    ),
    TransactionCategory(
      label: 'Parkir & Uang Tol',
      icon: Icons.local_parking_rounded,
      group: 'Transportasi',
      color: Color(0xFFF4511E),
    ),
    TransactionCategory(
      label: 'Tiket Pesawat / Travel',
      icon: Icons.airplane_ticket_rounded,
      group: 'Transportasi',
      color: Color(0xFF3949AB),
    ),
    TransactionCategory(
      label: 'Tiket Kereta / Bus / KRL',
      icon: Icons.train_rounded,
      group: 'Transportasi',
      color: Color(0xFF1A237E),
    ),
    TransactionCategory(
      label: 'Cuci Motor / Mobil',
      icon: Icons.local_see_rounded,
      group: 'Transportasi',
      color: Color(0xFF0288D1),
    ),
    TransactionCategory(
      label: 'Pajak Kendaraan (STNK)',
      icon: Icons.description_rounded,
      group: 'Transportasi',
      color: Color(0xFF5E35B1),
    ),
    TransactionCategory(
      label: 'Aksesoris / Variasi Kendaraan',
      icon: Icons.settings_input_component_rounded,
      group: 'Transportasi',
      color: Color(0xFF78909C),
    ),


    TransactionCategory(
      label: 'Pulsa & Paket Data Seluler',
      icon: Icons.signal_cellular_alt_rounded,
      group: 'Teknologi',
      color: Color(0xFF8E24AA),
    ),
    TransactionCategory(
      label: 'WiFi / Internet Rumah',
      icon: Icons.wifi_rounded,
      group: 'Teknologi',
      color: Color(0xFF1E88E5),
    ),
    TransactionCategory(
      label: 'Langganan Netflix / Disney+',
      icon: Icons.subscriptions_rounded,
      group: 'Teknologi',
      color: Color(0xFFE50914),
    ),
    TransactionCategory(
      label: 'Spotify / YouTube Premium',
      icon: Icons.music_note_rounded,
      group: 'Teknologi',
      color: Color(0xFF1DB954),
    ),
    TransactionCategory(
      label: 'Servis HP / Laptop',
      icon: Icons.devices_other_rounded,
      group: 'Teknologi',
      color: Color(0xFF455A64),
    ),
    TransactionCategory(
      label: 'Pembelian Gadget / Aksesoris',
      icon: Icons.smartphone_rounded,
      group: 'Teknologi',
      color: Color(0xFF263238),
    ),
    TransactionCategory(
      label: 'Top Up Game / Voucher',
      icon: Icons.sports_esports_rounded,
      group: 'Teknologi',
      color: Color(0xFFAD1457),
    ),
    TransactionCategory(
      label: 'Cloud Storage (Google/iCloud)',
      icon: Icons.cloud_queue_rounded,
      group: 'Teknologi',
      color: Color(0xFF0288D1),
    ),
    TransactionCategory(
      label: 'Software / App Berbayar',
      icon: Icons.apps_rounded,
      group: 'Teknologi',
      color: Color(0xFF5C6BC0),
    ),


    TransactionCategory(
      label: 'SPP / UKT / Uang Sekolah',
      icon: Icons.school_rounded,
      group: 'Pendidikan',
      color: Color(0xFF1A237E),
    ),
    TransactionCategory(
      label: 'Buku & Alat Tulis',
      icon: Icons.book_rounded,
      group: 'Pendidikan',
      color: Color(0xFF5E35B1),
    ),
    TransactionCategory(
      label: 'Kursus Online / Pelatihan',
      icon: Icons.psychology_rounded,
      group: 'Pendidikan',
      color: Color(0xFF512DA8),
    ),
    TransactionCategory(
      label: 'Uang Kas / Ekskul / Organisasi',
      icon: Icons.groups_rounded,
      group: 'Pendidikan',
      color: Color(0xFF3949AB),
    ),
    TransactionCategory(
      label: 'Seminar / Workshop',
      icon: Icons.co_present_rounded,
      group: 'Pendidikan',
      color: Color(0xFF673AB7),
    ),
    TransactionCategory(
      label: 'Fotokopi / Jilid / Print',
      icon: Icons.print_rounded,
      group: 'Pendidikan',
      color: Color(0xFF1976D2),
    ),
    TransactionCategory(
      label: 'Biaya Wisuda / Kelulusan',
      icon: Icons.workspace_premium_rounded,
      group: 'Pendidikan',
      color: Color(0xFFC2185B),
    ),
    TransactionCategory(
      label: 'Seragam / Perlengkapan Sekolah',
      icon: Icons.checkroom_rounded,
      group: 'Pendidikan',
      color: Color(0xFFAD1457),
    ),
    TransactionCategory(
      label: 'Beasiswa / Infaq Pendidikan',
      icon: Icons.volunteer_activism_rounded,
      group: 'Pendidikan',
      color: Color(0xFF43A047),
    ),


    TransactionCategory(
      label: 'Obat & Vitamin',
      icon: Icons.medication_rounded,
      group: 'Kesehatan',
      color: Color(0xFFEC407A),
    ),
    TransactionCategory(
      label: 'Konsultasi Dokter / Klinik',
      icon: Icons.medical_services_rounded,
      group: 'Kesehatan',
      color: Color(0xFF7CB342),
    ),
    TransactionCategory(
      label: 'BPJS Kesehatan / Asuransi',
      icon: Icons.admin_panel_settings_rounded,
      group: 'Kesehatan',
      color: Color(0xFF43A047),
    ),
    TransactionCategory(
      label: 'Cek Lab / Rumah Sakit',
      icon: Icons.local_hospital_rounded,
      group: 'Kesehatan',
      color: Color(0xFFD32F2F),
    ),
    TransactionCategory(
      label: 'Skincare & Bodycare',
      icon: Icons.face_retouching_natural_rounded,
      group: 'Kesehatan',
      color: Color(0xFF00897B),
    ),
    TransactionCategory(
      label: 'Salon / Potong Rambut',
      icon: Icons.content_cut_rounded,
      group: 'Kesehatan',
      color: Color(0xFF009688),
    ),
    TransactionCategory(
      label: 'Gym / Fitness / Yoga',
      icon: Icons.fitness_center_rounded,
      group: 'Kesehatan',
      color: Color(0xFF558B2F),
    ),
    TransactionCategory(
      label: 'Olahraga (Futsal/Badminton)',
      icon: Icons.sports_soccer_rounded,
      group: 'Kesehatan',
      color: Color(0xFF2E7D32),
    ),
    TransactionCategory(
      label: 'Alat Kesehatan (Masker, dll)',
      icon: Icons.health_and_safety_rounded,
      group: 'Kesehatan',
      color: Color(0xFF00796B),
    ),


    TransactionCategory(
      label: 'Nongkrong / Coffee Shop',
      icon: Icons.coffee_rounded,
      group: 'Gaya Hidup',
      color: Color(0xFF795548),
    ),
    TransactionCategory(
      label: 'Nonton Bioskop',
      icon: Icons.movie_filter_rounded,
      group: 'Gaya Hidup',
      color: Color(0xFF673AB7),
    ),
    TransactionCategory(
      label: 'Konser / Event / Hiburan',
      icon: Icons.confirmation_number_rounded,
      group: 'Gaya Hidup',
      color: Color(0xFF9C27B0),
    ),
    TransactionCategory(
      label: 'Traveling / Liburan',
      icon: Icons.luggage_rounded,
      group: 'Gaya Hidup',
      color: Color(0xFF0277BD),
    ),
    TransactionCategory(
      label: 'Hobi / Koleksi / Games',
      icon: Icons.videogame_asset_rounded,
      group: 'Gaya Hidup',
      color: Color(0xFFAD1457),
    ),
    TransactionCategory(
      label: 'Belanja Pakaian / Fashion',
      icon: Icons.shopping_bag_rounded,
      group: 'Gaya Hidup',
      color: Color(0xFFE91E63),
    ),
    TransactionCategory(
      label: 'Staycation / Hotel',
      icon: Icons.hotel_rounded,
      group: 'Gaya Hidup',
      color: Color(0xFF01579B),
    ),
    TransactionCategory(
      label: 'Karaoke / Billiard / Fun',
      icon: Icons.celebration_rounded,
      group: 'Gaya Hidup',
      color: Color(0xFFFF4081),
    ),
    TransactionCategory(
      label: 'Jajan Cemilan / Street Food',
      icon: Icons.cookie_rounded,
      group: 'Gaya Hidup',
      color: Color(0xFFFFA000),
    ),


    TransactionCategory(
      label: 'Susu & Makanan Bayi',
      icon: Icons.child_friendly_rounded,
      group: 'Keluarga',
      color: Color(0xFFF06292),
    ),
    TransactionCategory(
      label: 'Popok & Kebutuhan Bayi',
      icon: Icons.baby_changing_station_rounded,
      group: 'Keluarga',
      color: Color(0xFFEC407A),
    ),
    TransactionCategory(
      label: 'Mainan & Rekreasi Anak',
      icon: Icons.toys_rounded,
      group: 'Keluarga',
      color: Color(0xFFAFB42B),
    ),
    TransactionCategory(
      label: 'Uang Saku Anak',
      icon: Icons.savings_rounded,
      group: 'Keluarga',
      color: Color(0xFFFBC02D),
    ),
    TransactionCategory(
      label: 'Kirim Orang Tua / Keluarga',
      icon: Icons.volunteer_activism_rounded,
      group: 'Keluarga',
      color: Color(0xFFE91E63),
    ),
    TransactionCategory(
      label: 'Kebutuhan Hewan (Pets)',
      icon: Icons.pets_rounded,
      group: 'Keluarga',
      color: Color(0xFF8D6E63),
    ),
    TransactionCategory(
      label: 'Hadiah Keluarga / Hampers',
      icon: Icons.redeem_rounded,
      group: 'Keluarga',
      color: Color(0xFFF48FB1),
    ),
    TransactionCategory(
      label: 'Acara Keluarga / Arisan',
      icon: Icons.groups_3_rounded,
      group: 'Keluarga',
      color: Color(0xFFD81B60),
    ),


    TransactionCategory(
      label: 'Zakat / Infak / Sedekah',
      icon: Icons.spa_rounded,
      group: 'Sosial & Ibadah',
      color: Color(0xFF388E3C),
    ),
    TransactionCategory(
      label: 'Donasi Kemanusiaan / Galang Dana',
      icon: Icons.favorite_rounded,
      group: 'Sosial & Ibadah',
      color: Color(0xFFD32F2F),
    ),
    TransactionCategory(
      label: 'Perpuluhan / Iuran Ibadah',
      icon: Icons.church_rounded,
      group: 'Sosial & Ibadah',
      color: Color(0xFF5C6BC0),
    ),
    TransactionCategory(
      label: 'Kondangan / Amplop Nikah',
      icon: Icons.card_giftcard_rounded,
      group: 'Sosial & Ibadah',
      color: Color(0xFFFF7043),
    ),
    TransactionCategory(
      label: 'Kado Ulang Tahun / Hadiah',
      icon: Icons.cake_rounded,
      group: 'Sosial & Ibadah',
      color: Color(0xFFF06292),
    ),
    TransactionCategory(
      label: 'Bakti Sosial / Community Service',
      icon: Icons.handshake_rounded,
      group: 'Sosial & Ibadah',
      color: Color(0xFF2E7D32),
    ),


    TransactionCategory(
      label: 'Biaya Admin Bank',
      icon: Icons.account_balance_rounded,
      group: 'Keuangan',
      color: Color(0xFF607D8B),
    ),
    TransactionCategory(
      label: 'Biaya Admin App / Top Up',
      icon: Icons.account_balance_wallet_rounded,
      group: 'Keuangan',
      color: Color(0xFF455A64),
    ),
    TransactionCategory(
      label: 'Cicilan Kendaraan / Leasing',
      icon: Icons.credit_card_rounded,
      group: 'Keuangan',
      color: Color(0xFF1976D2),
    ),
    TransactionCategory(
      label: 'Bayar Hutang / Pinjol',
      icon: Icons.money_off_rounded,
      group: 'Keuangan',
      color: Color(0xFFD32F2F),
    ),
    TransactionCategory(
      label: 'Alokasi Tabungan / Investasi',
      icon: Icons.trending_up_rounded,
      group: 'Keuangan',
      color: Color(0xFF388E3C),
    ),
    TransactionCategory(
      label: 'Pajak Penghasilan (PPh)',
      icon: Icons.request_quote_rounded,
      group: 'Keuangan',
      color: Color(0xFF455A64),
    ),
    TransactionCategory(
      label: 'Pajak Bumi Bangunan (PBB)',
      icon: Icons.location_city_rounded,
      group: 'Keuangan',
      color: Color(0xFF37474F),
    ),
    TransactionCategory(
      label: 'Asuransi Jiwa / Unit Link',
      icon: Icons.verified_user_rounded,
      group: 'Keuangan',
      color: Color(0xFF1565C0),
    ),
    TransactionCategory(
      label: 'Denda / Biaya Keterlambatan',
      icon: Icons.warning_rounded,
      group: 'Keuangan',
      color: Color(0xFFC62828),
    ),


    TransactionCategory(
      label: 'Beli Stok / Bahan Baku',
      icon: Icons.inventory_2_rounded,
      group: 'Bisnis',
      color: Color(0xFF0097A7),
    ),
    TransactionCategory(
      label: 'Gaji Karyawan / Helper',
      icon: Icons.badge_rounded,
      group: 'Bisnis',
      color: Color(0xFF2E7D32),
    ),
    TransactionCategory(
      label: 'Sewa Toko / Kantor / Gudang',
      icon: Icons.storefront_rounded,
      group: 'Bisnis',
      color: Color(0xFF00796B),
    ),
    TransactionCategory(
      label: 'Iklan & Marketing (Ads)',
      icon: Icons.campaign_rounded,
      group: 'Bisnis',
      color: Color(0xFFC2185B),
    ),
    TransactionCategory(
      label: 'Biaya Kirim / Ongkir Bisnis',
      icon: Icons.local_shipping_rounded,
      group: 'Bisnis',
      color: Color(0xFFF57C00),
    ),
    TransactionCategory(
      label: 'Peralatan & ATK Bisnis',
      icon: Icons.handyman_rounded,
      group: 'Bisnis',
      color: Color(0xFF616161),
    ),
    TransactionCategory(
      label: 'Sertifikasi / Izin Usaha',
      icon: Icons.gavel_rounded,
      group: 'Bisnis',
      color: Color(0xFF455A64),
    ),


    TransactionCategory(
      label: 'Dana Darurat / Urgent',
      icon: Icons.warning_amber_rounded,
      group: 'Lainnya',
      color: Color(0xFFF57C00),
    ),
    TransactionCategory(
      label: 'Kehilangan / Musibah',
      icon: Icons.sentiment_very_dissatisfied_rounded,
      group: 'Lainnya',
      color: Color(0xFFD32F2F),
    ),
    TransactionCategory(
      label: 'Titipan Beli Barang',
      icon: Icons.shopping_cart_checkout_rounded,
      group: 'Lainnya',
      color: Color(0xFF7B1FA2),
    ),
    TransactionCategory(
      label: otherLabel,
      icon: Icons.more_horiz_rounded,
      group: 'Lainnya',
      color: Color(0xFF9E9E9E),
    ),
  ];

  static const List<TransactionCategory> incomeCategories = [

    TransactionCategory(
      label: 'Gaji Pokok',
      icon: Icons.payments_rounded,
      group: 'Pekerjaan Utama',
      color: Color(0xFF2E7D32),
    ),
    TransactionCategory(
      label: 'Gaji Ke-13 / Gaji Spesial',
      icon: Icons.redeem_rounded,
      group: 'Pekerjaan Utama',
      color: Color(0xFF1B5E20),
    ),
    TransactionCategory(
      label: 'Uang Lembur (Overtime)',
      icon: Icons.more_time_rounded,
      group: 'Pekerjaan Utama',
      color: Color(0xFF1976D2),
    ),
    TransactionCategory(
      label: 'Tunjangan Transportasi',
      icon: Icons.commute_rounded,
      group: 'Pekerjaan Utama',
      color: Color(0xFF0288D1),
    ),
    TransactionCategory(
      label: 'Tunjangan Makan & Konsumsi',
      icon: Icons.restaurant_rounded,
      group: 'Pekerjaan Utama',
      color: Color(0xFF0097A7),
    ),
    TransactionCategory(
      label: 'Tunjangan Kesehatan / Asuransi',
      icon: Icons.health_and_safety_rounded,
      group: 'Pekerjaan Utama',
      color: Color(0xFF388E3C),
    ),
    TransactionCategory(
      label: 'Tunjangan Jabatan / Posisi',
      icon: Icons.badge_rounded,
      group: 'Pekerjaan Utama',
      color: Color(0xFF00897B),
    ),
    TransactionCategory(
      label: 'Bonus Tahunan & Performa',
      icon: Icons.stars_rounded,
      group: 'Pekerjaan Utama',
      color: Color(0xFFFFA000),
    ),
    TransactionCategory(
      label: 'THR (Tunjangan Hari Raya)',
      icon: Icons.celebration_rounded,
      group: 'Pekerjaan Utama',
      color: Color(0xFFFBC02D),
    ),
    TransactionCategory(
      label: 'Pesangon / Uang Pisah',
      icon: Icons.work_history_rounded,
      group: 'Pekerjaan Utama',
      color: Color(0xFFD32F2F),
    ),
    TransactionCategory(
      label: 'Pencairan JHT / BPJS',
      icon: Icons.assured_workload_rounded,
      group: 'Pekerjaan Utama',
      color: Color(0xFFC2185B),
    ),
    TransactionCategory(
      label: 'Reimbursement Kantor',
      icon: Icons.receipt_long_rounded,
      group: 'Pekerjaan Utama',
      color: Color(0xFF7B1FA2),
    ),
    TransactionCategory(
      label: 'Perjalanan Dinas (Perdiem)',
      icon: Icons.flight_takeoff_rounded,
      group: 'Pekerjaan Utama',
      color: Color(0xFF5E35B1),
    ),
    TransactionCategory(
      label: 'Uang Rapel / Kekurangan Gaji',
      icon: Icons.history_rounded,
      group: 'Pekerjaan Utama',
      color: Color(0xFF455A64),
    ),
    TransactionCategory(
      label: 'Tunjangan Istri & Anak',
      icon: Icons.family_restroom_rounded,
      group: 'Pekerjaan Utama',
      color: Color(0xFFF06292),
    ),
    TransactionCategory(
      label: 'Fasilitas / Subsidi Kantor',
      icon: Icons.card_giftcard_rounded,
      group: 'Pekerjaan Utama',
      color: Color(0xFF8E24AA),
    ),


    TransactionCategory(
      label: 'Proyek Freelance Umum',
      icon: Icons.laptop_mac_rounded,
      group: 'Pekerjaan Tambahan',
      color: Color(0xFF5E35B1),
    ),
    TransactionCategory(
      label: 'Jasa Desain Grafis / Video',
      icon: Icons.brush_rounded,
      group: 'Pekerjaan Tambahan',
      color: Color(0xFF673AB7),
    ),
    TransactionCategory(
      label: 'Jasa Pembuatan Web / Aplikasi',
      icon: Icons.code_rounded,
      group: 'Pekerjaan Tambahan',
      color: Color(0xFF3949AB),
    ),
    TransactionCategory(
      label: 'Jasa Penulisan / Copywriting',
      icon: Icons.edit_note_rounded,
      group: 'Pekerjaan Tambahan',
      color: Color(0xFF1976D2),
    ),
    TransactionCategory(
      label: 'Komisi Penjualan / Marketing',
      icon: Icons.add_moderator_rounded,
      group: 'Pekerjaan Tambahan',
      color: Color(0xFF43A047),
    ),
    TransactionCategory(
      label: 'Insentif & Tips Pelanggan',
      icon: Icons.volunteer_activism_rounded,
      group: 'Pekerjaan Tambahan',
      color: Color(0xFF00ACC1),
    ),
    TransactionCategory(
      label: 'Jasa Konsultasi Profesional',
      icon: Icons.psychology_rounded,
      group: 'Pekerjaan Tambahan',
      color: Color(0xFF00897B),
    ),
    TransactionCategory(
      label: 'Jasa Terjemahan (Translation)',
      icon: Icons.translate_rounded,
      group: 'Pekerjaan Tambahan',
      color: Color(0xFF00796B),
    ),
    TransactionCategory(
      label: 'Jasa Fotografi / Videografi',
      icon: Icons.camera_alt_rounded,
      group: 'Pekerjaan Tambahan',
      color: Color(0xFFD81B60),
    ),
    TransactionCategory(
      label: 'Gaji Paruh Waktu (Part-Time)',
      icon: Icons.schedule_rounded,
      group: 'Pekerjaan Tambahan',
      color: Color(0xFFE64A19),
    ),
    TransactionCategory(
      label: 'Jasa Tutor / Mengajar Privat',
      icon: Icons.school_rounded,
      group: 'Pekerjaan Tambahan',
      color: Color(0xFFF57C00),
    ),
    TransactionCategory(
      label: 'Jasa Perbaikan / Servis',
      icon: Icons.build_rounded,
      group: 'Pekerjaan Tambahan',
      color: Color(0xFF616161),
    ),


    TransactionCategory(
      label: 'Omzet Penjualan Produk Fisik',
      icon: Icons.storefront_rounded,
      group: 'Bisnis & Usaha',
      color: Color(0xFF00796B),
    ),
    TransactionCategory(
      label: 'Omzet Jasa / Servis Bisnis',
      icon: Icons.support_agent_rounded,
      group: 'Bisnis & Usaha',
      color: Color(0xFF00695C),
    ),
    TransactionCategory(
      label: 'Jual Produk Digital (Ebook/Course)',
      icon: Icons.menu_book_rounded,
      group: 'Bisnis & Usaha',
      color: Color(0xFF004D40),
    ),
    TransactionCategory(
      label: 'Sharing Profit / Bagi Hasil',
      icon: Icons.monetization_on_rounded,
      group: 'Bisnis & Usaha',
      color: Color(0xFFF57C00),
    ),
    TransactionCategory(
      label: 'Pendapatan Konten / YouTube',
      icon: Icons.smart_display_rounded,
      group: 'Bisnis & Usaha',
      color: Color(0xFFD32F2F),
    ),
    TransactionCategory(
      label: 'AdSense / Penghasilan Web',
      icon: Icons.campaign_rounded,
      group: 'Bisnis & Usaha',
      color: Color(0xFFE91E63),
    ),
    TransactionCategory(
      label: 'Sponsorship / Endorsement',
      icon: Icons.recommend_rounded,
      group: 'Bisnis & Usaha',
      color: Color(0xFFC2185B),
    ),
    TransactionCategory(
      label: 'Komisi Affiliate (Shopee, dll)',
      icon: Icons.hub_rounded,
      group: 'Bisnis & Usaha',
      color: Color(0xFFFF8F00),
    ),
    TransactionCategory(
      label: 'Pendapatan Dropship / Reseller',
      icon: Icons.local_shipping_rounded,
      group: 'Bisnis & Usaha',
      color: Color(0xFFE65100),
    ),
    TransactionCategory(
      label: 'Monetisasi Live Streaming (Tip)',
      icon: Icons.favorite_rounded,
      group: 'Bisnis & Usaha',
      color: Color(0xFFAD1457),
    ),
    TransactionCategory(
      label: 'Pendapatan Katering / Makanan',
      icon: Icons.fastfood_rounded,
      group: 'Bisnis & Usaha',
      color: Color(0xFFEF6C00),
    ),
    TransactionCategory(
      label: 'Event Organizer / Jual Tiket',
      icon: Icons.confirmation_number_rounded,
      group: 'Bisnis & Usaha',
      color: Color(0xFF8E24AA),
    ),


    TransactionCategory(
      label: 'Profit Trading Saham',
      icon: Icons.candlestick_chart_rounded,
      group: 'Investasi',
      color: Color(0xFF2E7D32),
    ),
    TransactionCategory(
      label: 'Profit Trading Crypto',
      icon: Icons.currency_bitcoin_rounded,
      group: 'Investasi',
      color: Color(0xFFF57F17),
    ),
    TransactionCategory(
      label: 'Profit Trading Forex / Valas',
      icon: Icons.currency_exchange_rounded,
      group: 'Investasi',
      color: Color(0xFF1565C0),
    ),
    TransactionCategory(
      label: 'Dividen Saham / RUPS',
      icon: Icons.trending_up_rounded,
      group: 'Investasi',
      color: Color(0xFF1B5E20),
    ),
    TransactionCategory(
      label: 'Profit Reksadana / ETF',
      icon: Icons.pie_chart_rounded,
      group: 'Investasi',
      color: Color(0xFF00838F),
    ),
    TransactionCategory(
      label: 'Keuntungan Jual Emas',
      icon: Icons.diamond_rounded,
      group: 'Investasi',
      color: Color(0xFFFBC02D),
    ),
    TransactionCategory(
      label: 'Kupon Obligasi / SBN / Sukuk',
      icon: Icons.description_rounded,
      group: 'Investasi',
      color: Color(0xFF00695C),
    ),
    TransactionCategory(
      label: 'Staking / Yield Farming',
      icon: Icons.account_balance_wallet_rounded,
      group: 'Investasi',
      color: Color(0xFF009688),
    ),
    TransactionCategory(
      label: 'Pencairan Deposito',
      icon: Icons.assured_workload_rounded,
      group: 'Investasi',
      color: Color(0xFF283593),
    ),
    TransactionCategory(
      label: 'Pencairan Asuransi Unit Link',
      icon: Icons.health_and_safety_rounded,
      group: 'Investasi',
      color: Color(0xFFAD1457),
    ),
    TransactionCategory(
      label: 'Profit P2P Lending',
      icon: Icons.handshake_rounded,
      group: 'Investasi',
      color: Color(0xFF43A047),
    ),
    TransactionCategory(
      label: 'Pencairan Modal Ventura',
      icon: Icons.cases_rounded,
      group: 'Investasi',
      color: Color(0xFF455A64),
    ),


    TransactionCategory(
      label: 'Sewa Rumah / Kontrakan',
      icon: Icons.house_rounded,
      group: 'Pendapatan Pasif',
      color: Color(0xFF6D4C41),
    ),
    TransactionCategory(
      label: 'Sewa Kos-Kosan',
      icon: Icons.meeting_room_rounded,
      group: 'Pendapatan Pasif',
      color: Color(0xFF5D4037),
    ),
    TransactionCategory(
      label: 'Sewa Apartemen',
      icon: Icons.apartment_rounded,
      group: 'Pendapatan Pasif',
      color: Color(0xFF4E342E),
    ),
    TransactionCategory(
      label: 'Sewa Ruko / Kios / Gudang',
      icon: Icons.store_mall_directory_rounded,
      group: 'Pendapatan Pasif',
      color: Color(0xFF3E2723),
    ),
    TransactionCategory(
      label: 'Sewa Kendaraan (Mobil/Motor)',
      icon: Icons.car_rental_rounded,
      group: 'Pendapatan Pasif',
      color: Color(0xFF455A64),
    ),
    TransactionCategory(
      label: 'Sewa Alat / Kamera / Mesin',
      icon: Icons.camera_enhance_rounded,
      group: 'Pendapatan Pasif',
      color: Color(0xFF37474F),
    ),
    TransactionCategory(
      label: 'Royalti Hak Cipta / Paten',
      icon: Icons.copyright_rounded,
      group: 'Pendapatan Pasif',
      color: Color(0xFFAD1457),
    ),
    TransactionCategory(
      label: 'Royalti Buku / Musik / Seni',
      icon: Icons.auto_stories_rounded,
      group: 'Pendapatan Pasif',
      color: Color(0xFF880E4F),
    ),
    TransactionCategory(
      label: 'Penghasilan Pasif Lainnya',
      icon: Icons.all_inclusive_rounded,
      group: 'Pendapatan Pasif',
      color: Color(0xFF616161),
    ),


    TransactionCategory(
      label: 'Uang Saku Harian (Sekolah)',
      icon: Icons.backpack_rounded,
      group: 'Pendidikan & Sekolah',
      color: Color(0xFF3949AB),
    ),
    TransactionCategory(
      label: 'Uang Saku Bulanan (Kampus)',
      icon: Icons.account_balance_wallet_rounded,
      group: 'Pendidikan & Sekolah',
      color: Color(0xFF303F9F),
    ),
    TransactionCategory(
      label: 'Beasiswa Pemerintah (LPDP/KIP)',
      icon: Icons.account_balance_rounded,
      group: 'Pendidikan & Sekolah',
      color: Color(0xFF283593),
    ),
    TransactionCategory(
      label: 'Beasiswa Swasta / Yayasan',
      icon: Icons.business_rounded,
      group: 'Pendidikan & Sekolah',
      color: Color(0xFF1A237E),
    ),
    TransactionCategory(
      label: 'Hadiah Prestasi / Ranking Kelas',
      icon: Icons.stars_rounded,
      group: 'Pendidikan & Sekolah',
      color: Color(0xFFFBC02D),
    ),
    TransactionCategory(
      label: 'Uang Jajan Ekstra dari Guru/Dosen',
      icon: Icons.emoji_emotions_rounded,
      group: 'Pendidikan & Sekolah',
      color: Color(0xFFFFA000),
    ),
    TransactionCategory(
      label: 'Bantuan Biaya Pendidikan',
      icon: Icons.volunteer_activism_rounded,
      group: 'Pendidikan & Sekolah',
      color: Color(0xFF0288D1),
    ),
    TransactionCategory(
      label: 'Sponsor Penelitian / Skripsi',
      icon: Icons.science_rounded,
      group: 'Pendidikan & Sekolah',
      color: Color(0xFF0097A7),
    ),
    TransactionCategory(
      label: 'Dana Hibah Pendidikan',
      icon: Icons.assured_workload_rounded,
      group: 'Pendidikan & Sekolah',
      color: Color(0xFF00838F),
    ),


    TransactionCategory(
      label: 'Pemberian Orang Tua (Ayah/Ibu)',
      icon: Icons.family_restroom_rounded,
      group: 'Sosial & Keluarga',
      color: Color(0xFFF06292),
    ),
    TransactionCategory(
      label: 'Pemberian Kakek / Nenek / Paman',
      icon: Icons.elderly_rounded,
      group: 'Sosial & Keluarga',
      color: Color(0xFFEC407A),
    ),
    TransactionCategory(
      label: 'Angpao Lebaran / Imlek / Natal',
      icon: Icons.mail_rounded,
      group: 'Sosial & Keluarga',
      color: Color(0xFFE53935),
    ),
    TransactionCategory(
      label: 'Kado Uang Ulang Tahun',
      icon: Icons.cake_rounded,
      group: 'Sosial & Keluarga',
      color: Color(0xFFFF8A65),
    ),
    TransactionCategory(
      label: 'Kado Uang Pernikahan / Sunatan',
      icon: Icons.celebration_rounded,
      group: 'Sosial & Keluarga',
      color: Color(0xFFFF7043),
    ),
    TransactionCategory(
      label: 'Warisan / Pembagian Harta',
      icon: Icons.real_estate_agent_rounded,
      group: 'Sosial & Keluarga',
      color: Color(0xFF8D6E63),
    ),
    TransactionCategory(
      label: 'Hibah / Hadiah Keluarga Besar',
      icon: Icons.handshake_rounded,
      group: 'Sosial & Keluarga',
      color: Color(0xFF795548),
    ),
    TransactionCategory(
      label: 'Uang Belanja dari Pasangan',
      icon: Icons.favorite_rounded,
      group: 'Sosial & Keluarga',
      color: Color(0xFFD81B60),
    ),
    TransactionCategory(
      label: 'Uang Arisan Keluarga (Didapat)',
      icon: Icons.groups_rounded,
      group: 'Sosial & Keluarga',
      color: Color(0xFFC2185B),
    ),


    TransactionCategory(
      label: 'Donasi / Santunan Diterima',
      icon: Icons.volunteer_activism_rounded,
      group: 'Donasi & Bantuan',
      color: Color(0xFF009688),
    ),
    TransactionCategory(
      label: 'Bansos Pemerintah (PKH/BLT)',
      icon: Icons.assured_workload_rounded,
      group: 'Donasi & Bantuan',
      color: Color(0xFF3949AB),
    ),
    TransactionCategory(
      label: 'Subsidi Listrik / Air',
      icon: Icons.electric_bolt_rounded,
      group: 'Donasi & Bantuan',
      color: Color(0xFF1976D2),
    ),
    TransactionCategory(
      label: 'Tunjangan / Bantuan Prakerja',
      icon: Icons.badge_rounded,
      group: 'Donasi & Bantuan',
      color: Color(0xFF0288D1),
    ),
    TransactionCategory(
      label: 'Dana Kemanusiaan / Bencana',
      icon: Icons.healing_rounded,
      group: 'Donasi & Bantuan',
      color: Color(0xFF43A047),
    ),
    TransactionCategory(
      label: 'Bantuan Modal UMKM',
      icon: Icons.store_rounded,
      group: 'Donasi & Bantuan',
      color: Color(0xFF388E3C),
    ),
    TransactionCategory(
      label: 'Sumbangan Acara / Kegiatan',
      icon: Icons.event_rounded,
      group: 'Donasi & Bantuan',
      color: Color(0xFF00897B),
    ),
    TransactionCategory(
      label: 'Penggalangan Dana (Crowdfund)',
      icon: Icons.diversity_1_rounded,
      group: 'Donasi & Bantuan',
      color: Color(0xFF00796B),
    ),
    TransactionCategory(
      label: 'Zakat / Infak Diterima',
      icon: Icons.spa_rounded,
      group: 'Donasi & Bantuan',
      color: Color(0xFF2E7D32),
    ),


    TransactionCategory(
      label: 'Bunga Tabungan Reguler',
      icon: Icons.account_balance_rounded,
      group: 'Keuangan & Bank',
      color: Color(0xFF0D47A1),
    ),
    TransactionCategory(
      label: 'Bunga Deposito Berjangka',
      icon: Icons.lock_clock_rounded,
      group: 'Keuangan & Bank',
      color: Color(0xFF1565C0),
    ),
    TransactionCategory(
      label: 'Cashback e-Wallet (OVO/GoPay)',
      icon: Icons.account_balance_wallet_rounded,
      group: 'Keuangan & Bank',
      color: Color(0xFF00897B),
    ),
    TransactionCategory(
      label: 'Cashback Kartu Kredit / Belanja',
      icon: Icons.credit_score_rounded,
      group: 'Keuangan & Bank',
      color: Color(0xFF009688),
    ),
    TransactionCategory(
      label: 'Refund / Pengembalian Belanja',
      icon: Icons.replay_rounded,
      group: 'Keuangan & Bank',
      color: Color(0xFF546E7A),
    ),
    TransactionCategory(
      label: 'Refund Tiket Pesawat / Kereta',
      icon: Icons.airplane_ticket_rounded,
      group: 'Keuangan & Bank',
      color: Color(0xFF455A64),
    ),
    TransactionCategory(
      label: 'Bonus Referral (Undang Teman)',
      icon: Icons.add_reaction_rounded,
      group: 'Keuangan & Bank',
      color: Color(0xFFD81B60),
    ),
    TransactionCategory(
      label: 'Klaim Asuransi Kesehatan',
      icon: Icons.health_and_safety_rounded,
      group: 'Keuangan & Bank',
      color: Color(0xFF43A047),
    ),
    TransactionCategory(
      label: 'Klaim Asuransi Kendaraan',
      icon: Icons.car_crash_rounded,
      group: 'Keuangan & Bank',
      color: Color(0xFF388E3C),
    ),
    TransactionCategory(
      label: 'Reward Poin Tukar Uang',
      icon: Icons.loyalty_rounded,
      group: 'Keuangan & Bank',
      color: Color(0xFFE65100),
    ),


    TransactionCategory(
      label: 'Pinjaman Tunai dari Bank',
      icon: Icons.account_balance_rounded,
      group: 'Pinjaman & Hutang',
      color: Color(0xFF5E35B1),
    ),
    TransactionCategory(
      label: 'Pinjaman Online (Pinjol)',
      icon: Icons.phone_iphone_rounded,
      group: 'Pinjaman & Hutang',
      color: Color(0xFF4527A0),
    ),
    TransactionCategory(
      label: 'Pinjaman Tunai dari Koperasi',
      icon: Icons.handshake_rounded,
      group: 'Pinjaman & Hutang',
      color: Color(0xFF311B92),
    ),
    TransactionCategory(
      label: 'Pinjaman dari Teman/Keluarga',
      icon: Icons.people_rounded,
      group: 'Pinjaman & Hutang',
      color: Color(0xFF6A1B9A),
    ),
    TransactionCategory(
      label: 'Teman Mengembalikan Hutang',
      icon: Icons.money_off_rounded,
      group: 'Pinjaman & Hutang',
      color: Color(0xFF43A047),
    ),
    TransactionCategory(
      label: 'Keluarga Mengembalikan Hutang',
      icon: Icons.handshake_rounded,
      group: 'Pinjaman & Hutang',
      color: Color(0xFF2E7D32),
    ),
    TransactionCategory(
      label: 'Uang Kasbon Karyawan Diterima',
      icon: Icons.request_quote_rounded,
      group: 'Pinjaman & Hutang',
      color: Color(0xFF1B5E20),
    ),


    TransactionCategory(
      label: 'Jual Pakaian Bekas (Preloved)',
      icon: Icons.checkroom_rounded,
      group: 'Aset & Barang Bekas',
      color: Color(0xFF7CB342),
    ),
    TransactionCategory(
      label: 'Jual Elektronik / Gadget Bekas',
      icon: Icons.devices_rounded,
      group: 'Aset & Barang Bekas',
      color: Color(0xFF689F38),
    ),
    TransactionCategory(
      label: 'Jual Kendaraan (Mobil/Motor)',
      icon: Icons.directions_car_rounded,
      group: 'Aset & Barang Bekas',
      color: Color(0xFF558B2F),
    ),
    TransactionCategory(
      label: 'Jual Perabotan / Furniture',
      icon: Icons.chair_rounded,
      group: 'Aset & Barang Bekas',
      color: Color(0xFF33691E),
    ),
    TransactionCategory(
      label: 'Jual Properti / Tanah / Rumah',
      icon: Icons.house_rounded,
      group: 'Aset & Barang Bekas',
      color: Color(0xFF6D4C41),
    ),
    TransactionCategory(
      label: 'Jual Rongsokan / Daur Ulang',
      icon: Icons.recycling_rounded,
      group: 'Aset & Barang Bekas',
      color: Color(0xFF5D4037),
    ),
    TransactionCategory(
      label: 'Tukar Tambah (Cashback) Aset',
      icon: Icons.swap_horiz_rounded,
      group: 'Aset & Barang Bekas',
      color: Color(0xFF4E342E),
    ),
    TransactionCategory(
      label: 'Jual Mainan / Koleksi / Hobi',
      icon: Icons.toys_rounded,
      group: 'Aset & Barang Bekas',
      color: Color(0xFF3E2723),
    ),


    TransactionCategory(
      label: 'Hadiah Undian / Giveaway',
      icon: Icons.card_giftcard_rounded,
      group: 'Lainnya',
      color: Color(0xFFFFA000),
    ),
    TransactionCategory(
      label: 'Menang Lomba / Kompetisi',
      icon: Icons.emoji_events_rounded,
      group: 'Lainnya',
      color: Color(0xFFFF8F00),
    ),
    TransactionCategory(
      label: 'Jackpot / Hadiah Utama',
      icon: Icons.workspace_premium_rounded,
      group: 'Lainnya',
      color: Color(0xFFFF6F00),
    ),
    TransactionCategory(
      label: 'Uang Temuan (Rejeki Nomplok)',
      icon: Icons.savings_rounded,
      group: 'Lainnya',
      color: Color(0xFFFBC02D),
    ),
    TransactionCategory(
      label: 'Kompensasi / Ganti Rugi',
      icon: Icons.gavel_rounded,
      group: 'Lainnya',
      color: Color(0xFF455A64),
    ),
    TransactionCategory(
      label: 'Uang Arisan Rutin (Menang)',
      icon: Icons.groups_rounded,
      group: 'Lainnya',
      color: Color(0xFF607D8B),
    ),
    TransactionCategory(
      label: otherLabel,
      icon: Icons.more_horiz_rounded,
      group: 'Lainnya',
      color: Color(0xFF9E9E9E),
    ),
  ];

  static IconData getIconForCategory(String categoryName) {
    final allCategories = [...expenseCategories, ...incomeCategories];
    try {
      return allCategories.firstWhere((c) => c.label == categoryName).icon;
    } catch (_) {
      return Icons.help_outline_rounded;
    }
  }

  static Color getColorForCategory(String categoryName) {
    final allCategories = [...expenseCategories, ...incomeCategories];
    try {
      return allCategories.firstWhere((c) => c.label == categoryName).color;
    } catch (_) {
      return Colors.grey;
    }
  }
}
