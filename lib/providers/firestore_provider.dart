// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/foundation.dart';
// import 'package:hooks_riverpod/hooks_riverpod.dart';
// import 'package:orkida/models/text_setting.dart';
// import 'package:orkida/models/word.dart';
// import 'package:orkida/providers/dialog_provider.dart';

// import '../models/app_user.dart';
// import 'app_user_provider.dart';

// final firestoreProvider = Provider.autoDispose<FirestoreProvider>((ref) {
//   return FirestoreProvider(ref.read);
// });

// class FirestoreProvider {
//   FirestoreProvider(this._read);
//   final Reader _read;
//   final _firestore = FirebaseFirestore.instance;

//   Future<AppUser?> getCurrentUser(String userId) async {
//     final user = await _firestore.collection('users').doc(userId).get();
//     if (user.exists) {
//       return AppUser.fromMap(user.data()!);
//     }
//     return null;
//   }

//   Stream<AppUser> watchUser(String userId) {
//     final user = _firestore.collection('users').doc(userId).snapshots();
//     return user.map((event) => AppUser.fromMap(event.data()!));
//   }

//   Future<AppUser> getUser(String userId) async {
//     final user = await _firestore.collection('users').doc(userId).get();
//     return AppUser.fromMap(user.data()!);
//   }

//   Future<AppUser> createUser() async {
//     final appUser = _read(appUserProvider.notifier).user!;
//     try {
//       final docRef = _firestore.collection('users').doc(appUser.userId);
//       await docRef.set(appUser.toMap(), SetOptions(merge: true));
//       return appUser;
//     } catch (e) {
//       _read(dialogProvider(e)).showExceptionDialog();
//       rethrow;
//     }
//   }

//   Future<AppUser> updateUser() async {
//     final appUser = _read(appUserProvider.notifier).user!;
//     try {
//       final docRef = _firestore.collection('users').doc(appUser.userId);
//       await docRef.update(appUser.toMap());
//       return appUser;
//     } catch (e) {
//       debugPrint(e.toString());
//       _read(dialogProvider(e)).showExceptionDialog();
//       rethrow;
//     }
//   }

//   Query<Word> getWordsQuery(String query) {
//     return _firestore
//         .collection("orkidadictionary")
//         .orderBy('hw')
//         .where('keywords', arrayContains: query)
//         .withConverter<Word>(
//           fromFirestore: (snapshot, _) => Word.fromMap(snapshot.data()!, snapshot.id),
//           toFirestore: (word, _) => word.toMap(),
//         );
//   }

//   Query<Word> getFavouriteWordsQuery() {
//     final userId = _read(appUserProvider)!.userId;

//     return _firestore
//         .collection("orkidadictionary")
//         .orderBy('hw')
//         .where('favouriteBy', arrayContains: userId)
//         .withConverter<Word>(
//           fromFirestore: (snapshot, _) => Word.fromMap(snapshot.data()!, snapshot.id),
//           toFirestore: (word, _) => word.toMap(),
//         );
//   }

//   void favouriteWord(String? uid) {
//     final userId = _read(appUserProvider)!.userId;
//     _firestore.collection('orkidadictionary').doc(uid!).set({
//       'favouriteBy': FieldValue.arrayUnion([userId])
//     }, SetOptions(merge: true));
//   }

//   void unfavouriteWord(String? uid) {
//     final userId = _read(appUserProvider)!.userId;
//     _firestore.collection('orkidadictionary').doc(uid!).set({
//       'favouriteBy': FieldValue.arrayRemove([userId])
//     }, SetOptions(merge: true));
//   }

//   void updateTextSettings(List<TextSetting> updatedSettings) {
//     final userId = _read(appUserProvider)!.userId;
//     _firestore.collection('users').doc(userId).set(
//       {'textSetting': updatedSettings.map((setting) => setting.toMap()).toList()},
//       SetOptions(merge: true),
//     );
//   }

//   void restoreDefaultTextSettings() {
//     final userId = _read(appUserProvider)!.userId;
//     _firestore.collection('users').doc(userId).update(
//       {'textSetting': TextSetting.defaultSetting.map((setting) => setting.toMap()).toList()},
//     );
//   }

//   void updateTextScaleFactor() {
//     final user = _read(appUserProvider)!;
//     final userId = user.userId;
//     final textScaleFactor = user.textScaleFactor;
//     _firestore.collection('users').doc(userId).update({'textScaleFactor': textScaleFactor});
//   }
// }
