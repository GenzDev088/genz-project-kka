import 'dart:io';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../models/family_group_model.dart';
import '../models/transaction_model.dart';
import './transaction_provider.dart';


final familyBalanceSyncProvider = Provider.autoDispose<void>((ref) {
  final groupId = ref.watch(userGroupIdProvider);
  if (groupId == null || groupId.isEmpty) return;

  ref.listen(transactionsByGroupProvider(groupId), (previous, next) {
    final userName = ref.read(userNameProvider);

    final myContribution = next
        .where((t) => t.creatorName == userName)
        .fold(
          0.0,
          (acc, t) =>
              acc + (t.type == TransactionType.income ? t.amount : -t.amount),
        );


    ref.read(familyGroupServiceProvider).syncLocalBalance(myContribution);
  }, fireImmediately: true);
});


class UserProfile {
  final String name;
  final int avatarIndex;
  final int colorIndex;
  final String? photoUrl;

  UserProfile({
    required this.name,
    this.avatarIndex = 0,
    this.colorIndex = 0,
    this.photoUrl,
  });

  UserProfile copyWith({
    String? name,
    int? avatarIndex,
    int? colorIndex,
    String? photoUrl,
    bool clearPhoto = false,
  }) {
    return UserProfile(
      name: name ?? this.name,
      avatarIndex: avatarIndex ?? this.avatarIndex,
      colorIndex: colorIndex ?? this.colorIndex,
      photoUrl: clearPhoto ? null : (photoUrl ?? this.photoUrl),
    );
  }
}


final userProfileProvider =
    StateNotifierProvider<UserProfileNotifier, UserProfile>((ref) {
      return UserProfileNotifier(ref);
    });


final userNameProvider = Provider<String>((ref) {
  return ref.watch(userProfileProvider).name;
});

class UserProfileNotifier extends StateNotifier<UserProfile> {
  final Ref ref;
  UserProfileNotifier(this.ref) : super(UserProfile(name: '')) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();

    String name = prefs.getString('username') ?? '';
    int avatar = prefs.getInt('user_avatar') ?? 0;
    int color = prefs.getInt('user_color') ?? 0;
    String? photoUrl = prefs.getString('profile_image_path');


    final prefixes = [
      'Sultan',
      'Jagoan',
      'Pejuang',
      'Juragan',
      'Master',
      'Pendekar',
      'Bintang',
    ];
    final suffixes = [
      'Hemat',
      'Cuan',
      'Tabung',
      'MasaDepan',
      'Bijak',
      'Sukses',
    ];

    bool isRandom = false;
    for (var p in prefixes) {
      for (var s in suffixes) {
        if (name == '$p $s') {
          isRandom = true;
          break;
        }
      }
    }

    if (isRandom) {
      await prefs.remove('username');
      name = '';
    }

    if (name.isEmpty) {

      final randomId = Random().nextInt(9000) + 1000;
      name = 'user-$randomId';
      await prefs.setString('username', name);
    }

    state = UserProfile(
      name: name,
      avatarIndex: avatar,
      colorIndex: color,
      photoUrl: photoUrl,
    );
  }

  Future<void> updateProfile({
    String? name,
    int? avatarIndex,
    int? colorIndex,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final oldName = state.name;
    final newName = name?.trim() ?? oldName;

    if (newName.isEmpty && oldName.isEmpty) return;


    if (name != null) await prefs.setString('username', newName);
    if (avatarIndex != null) await prefs.setInt('user_avatar', avatarIndex);
    if (colorIndex != null) await prefs.setInt('user_color', colorIndex);

    state = state.copyWith(
      name: newName,
      avatarIndex: avatarIndex,
      colorIndex: colorIndex,
    );
  }


  Future<String?> uploadAndSetPhoto(File imageFile) async {
    final userName = state.name;
    if (userName.isEmpty) {
      print("ERROR: Nama pengguna kosong, tidak bisa simpan foto.");
      return null;
    }

    try {

      final appDir = await getApplicationDocumentsDirectory();
      final photosDir = Directory(path.join(appDir.path, 'profile_photos'));


      if (!await photosDir.exists()) {
        await photosDir.create(recursive: true);
      }


      final fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final localPath = path.join(photosDir.path, fileName);


      print("DEBUG: Menyimpan foto ke lokasi lokal: $localPath");
      final savedImage = await imageFile.copy(localPath);


      if (state.photoUrl != null && state.photoUrl!.startsWith('/')) {
        final oldFile = File(state.photoUrl!);
        if (await oldFile.exists()) {
          print("DEBUG: Menghapus foto profil lama...");
          await oldFile.delete();
        }
      }


      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('profile_image_path', savedImage.path);
      state = state.copyWith(photoUrl: savedImage.path);

      print(
        "DEBUG: Foto berhasil disimpan secara lokal dan tersinkronisasi dengan key profile_image_path.",
      );

      return savedImage.path;
    } catch (e) {
      print("CRITICAL ERROR: Gagal simpan foto ke lokal: $e");
      return null;
    }
  }

  Future<void> setName(String name) => updateProfile(name: name);


  Future<void> deletePhoto() async {
    try {

      if (state.photoUrl != null && state.photoUrl!.startsWith('/')) {
        final file = File(state.photoUrl!);
        if (await file.exists()) {
          await file.delete();
        }
      }


      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('profile_image_path');


      state = state.copyWith(clearPhoto: true);
      print("DEBUG: Foto profil berhasil dihapus.");
    } catch (e) {
      print("ERROR: Gagal menghapus foto profil: $e");
    }
  }
}


final userGroupIdProvider = StateNotifierProvider<UserGroupIdNotifier, String?>(
  (ref) {
    return UserGroupIdNotifier();
  },
);

class UserGroupIdNotifier extends StateNotifier<String?> {
  UserGroupIdNotifier() : super(null) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getString('group_id');
  }

  Future<void> setGroupId(String? id) async {
    final prefs = await SharedPreferences.getInstance();
    if (id == null) {
      await prefs.remove('group_id');
    } else {
      await prefs.setString('group_id', id);
    }
    state = id;
  }
}


final familyGroupStreamProvider = StreamProvider.autoDispose<FamilyGroupModel?>(
  (ref) {
    final groupId = ref.watch(userGroupIdProvider);
    if (groupId == null || groupId.isEmpty) return Stream.value(null);

    bool isFirebaseReady = false;
    try {
      Firebase.app();
      isFirebaseReady = true;
    } catch (_) {}

    if (!isFirebaseReady) return Stream.value(null);

    return FirebaseFirestore.instance
        .collection('family_groups')
        .doc(groupId)
        .snapshots()
        .map((snapshot) {
          if (!snapshot.exists) return null;
          return FamilyGroupModel.fromJson(snapshot.data()!);
        });
  },
);


final familyGroupServiceProvider = Provider<FamilyGroupService>((ref) {
  return FamilyGroupService(ref);
});

class FamilyGroupService {
  final Ref ref;

  FamilyGroupService(this.ref);

  bool _isFirebaseReady() {
    try {
      Firebase.app();
      return true;
    } catch (_) {
      return false;
    }
  }

  String _generateUniqueCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    String code = '';
    for (int i = 0; i < 6; i++) {
      code += chars[random.nextInt(chars.length)];
    }
    return code;
  }

  Future<void> createGroup(String groupName) async {
    final userName = ref.read(userNameProvider);
    if (userName.isEmpty)
      throw Exception(
        "Nama belum diatur. Silakan atur nama kamu terlebih dahulu!",
      );

    final code = _generateUniqueCode();
    if (!_isFirebaseReady()) throw Exception("Koneksi Cloud tidak tersedia.");
    final docRef = FirebaseFirestore.instance.collection('family_groups').doc();

    final group = FamilyGroupModel(
      id: docRef.id,
      code: code,
      name: groupName,
      adminName: userName,
      members: [userName],
      memberBalances: {userName: 0.0},
      memberPhotos: {},
    );


    try {
      await docRef.set(group.toJson());

      await ref.read(userGroupIdProvider.notifier).setGroupId(docRef.id);
    } catch (e) {
      throw Exception(
        "Gagal membuat grup: Izin ditolak. Pastikan aturan (Rules) di Firebase Console sudah diizinkan.",
      );
    }
  }

  Future<void> joinGroup(String code) async {
    final userName = ref.read(userNameProvider);
    if (userName.isEmpty)
      throw Exception(
        "Nama belum diatur. Silakan atur nama kamu terlebih dahulu!",
      );

    if (!_isFirebaseReady()) throw Exception("Koneksi Cloud tidak tersedia.");
    final query = await FirebaseFirestore.instance
        .collection('family_groups')
        .where('code', isEqualTo: code.toUpperCase())
        .limit(1)
        .get();

    if (query.docs.isEmpty)
      throw Exception("Kode keluarga salah atau kadaluarsa.");

    final doc = query.docs.first;
    final groupData = doc.data();
    final List<String> members = List<String>.from(groupData['members'] ?? []);

    if (members.length >= 5) {
      throw Exception(
        "Gagal bergabung: Anggota keluarga sudah maksimal (5 orang).",
      );
    }

    final groupId = doc.id;


    try {
      final updates = {
        'members': FieldValue.arrayUnion([userName]),
        'memberBalances.$userName': 0.0,
      };

      await doc.reference.update(updates);


      await ref.read(userGroupIdProvider.notifier).setGroupId(groupId);
    } catch (e) {
      throw Exception("Gagal bergabung: $e");
    }
  }

  Future<void> leaveGroup() async {
    final groupId = ref.read(userGroupIdProvider);
    final userName = ref.read(userNameProvider);

    if (groupId != null &&
        groupId.isNotEmpty &&
        userName.isNotEmpty &&
        _isFirebaseReady()) {
      final docRef = FirebaseFirestore.instance
          .collection('family_groups')
          .doc(groupId);

      try {
        await docRef.update({
          'members': FieldValue.arrayRemove([userName]),
        });
      } catch (_) {

      }
    }

    await ref.read(userGroupIdProvider.notifier).setGroupId(null);
  }


  Future<void> syncLocalBalance(double localTotalBalance) async {
    final groupId = ref.read(userGroupIdProvider);
    final userName = ref.read(userNameProvider);

    if (groupId == null ||
        groupId.isEmpty ||
        userName.isEmpty ||
        !_isFirebaseReady())
      return;

    final docRef = FirebaseFirestore.instance
        .collection('family_groups')
        .doc(groupId);


    await docRef.set({
      'memberBalances': {userName: localTotalBalance},
    }, SetOptions(merge: true));
  }



  Future<void> trySyncMemberName(String currentUserName) async {
    final groupId = ref.read(userGroupIdProvider);
    if (groupId == null ||
        groupId.isEmpty ||
        currentUserName.isEmpty ||
        !_isFirebaseReady())
      return;

    final docRef = FirebaseFirestore.instance
        .collection('family_groups')
        .doc(groupId);
    final snapshot = await docRef.get();
    if (!snapshot.exists) return;

    final data = snapshot.data()!;
    final List<String> members = List<String>.from(data['members'] ?? []);

    if (members.contains(currentUserName)) return;


    final prefixes = [
      'Sultan',
      'Jagoan',
      'Pejuang',
      'Juragan',
      'Master',
      'Pendekar',
      'Bintang',
    ];
    final suffixes = [
      'Hemat',
      'Cuan',
      'Tabung',
      'MasaDepan',
      'Bijak',
      'Sukses',
    ];

    String? foundRandomName;
    for (var member in members) {
      for (var p in prefixes) {
        for (var s in suffixes) {
          if (member == '$p $s') {
            foundRandomName = member;
            break;
          }
        }
        if (foundRandomName != null) break;
      }
      if (foundRandomName != null) break;
    }

    if (foundRandomName != null) {


      await updateMemberName(foundRandomName, currentUserName);
    }
  }


  Future<void> updateMemberName(String oldName, String newName) async {
    final groupId = ref.read(userGroupIdProvider);
    if (groupId == null || groupId.isEmpty || !_isFirebaseReady()) return;

    final docRef = FirebaseFirestore.instance
        .collection('family_groups')
        .doc(groupId);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) return;

      final data = snapshot.data()!;
      final members = List<String>.from(data['members'] ?? []);
      final balances = Map<String, dynamic>.from(data['memberBalances'] ?? {});
      final photos = Map<String, dynamic>.from(data['memberPhotos'] ?? {});
      String adminName = data['adminName'] ?? '';


      members.remove(oldName);
      if (!members.contains(newName)) {
        members.add(newName);
      }


      if (balances.containsKey(oldName)) {
        final balanceValue = balances[oldName];
        balances.remove(oldName);
        balances[newName] = balanceValue;
      } else if (!balances.containsKey(newName)) {
        balances[newName] = 0.0;
      }



      if (photos.containsKey(oldName)) {
        final photoValue = photos[oldName];
        photos.remove(oldName);
        photos[newName] = photoValue;
      }


      if (adminName == oldName) {
        adminName = newName;
      }

      transaction.update(docRef, {
        'members': members,
        'memberBalances': balances,
        'memberPhotos': photos,
        'adminName': adminName,
      });
    });
  }


  Future<void> updateMemberPhoto(String memberName, String photoUrl) async {
    final groupId = ref.read(userGroupIdProvider);
    if (groupId == null ||
        groupId.isEmpty ||
        memberName.isEmpty ||
        !_isFirebaseReady())
      return;

    final docRef = FirebaseFirestore.instance
        .collection('family_groups')
        .doc(groupId);
    await docRef.set({
      'memberPhotos': {memberName: photoUrl},
    }, SetOptions(merge: true));
  }
}
