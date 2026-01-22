import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// サブスクリプションが有効かどうかを判定し、
/// 有効なら child を表示、無効なら lockedChild を表示する
class SubscriptionGate extends StatelessWidget {
  final Widget child;
  final Widget lockedChild;

  const SubscriptionGate({
    super.key,
    required this.child,
    required this.lockedChild,
  });

  Future<bool> _checkSubscription() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    // 匿名ユーザーは常に OK（無料利用）
    if (user.isAnonymous) return true;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (!doc.exists) return false;

    final data = doc.data()!;
    final hasSubscription = data['hasSubscription'] == true;
    final expirationDateStr = data['expirationDate'];

    if (expirationDateStr is String) {
      final expiration = DateTime.tryParse(expirationDateStr);
      if (expiration == null) return false;

      return hasSubscription && expiration.isAfter(DateTime.now());
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _checkSubscription(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final isSubscribed = snapshot.data!;
        return isSubscribed ? child : lockedChild;
      },
    );
  }
}
