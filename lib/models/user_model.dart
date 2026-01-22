import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore からの日時フィールドを安全に Dart の DateTime? に変換するヘルパー
DateTime? _parseDateTime(dynamic value) {
  if (value == null) return null;
  if (value is Timestamp) {
    return value.toDate();
  }
  if (value is String) {
    return DateTime.tryParse(value);
  }
  return null;
}

/// ユーザーデータモデル
class UserModel {
  final String uid;
  final String email;
  final DateTime createdAt;
  final String? displayName;
  final bool hasSubscription;
  final String subscriptionPlan;
  final DateTime? purchasedAt;
  final DateTime? expirationDate;
  final DateTime? updatedAt;
  final String? latestSessionId;
  final String? status;

  UserModel({
    required this.uid,
    required this.email,
    required this.createdAt,
    this.displayName,
    required this.hasSubscription,
    required this.subscriptionPlan,
    this.purchasedAt,
    this.expirationDate,
    this.updatedAt,
    this.latestSessionId,
    this.status,
  });

  /// Firestore 用に Map に変換
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'createdAt': createdAt,
      'hasSubscription': hasSubscription,
      'subscriptionPlan': subscriptionPlan,
      'purchasedAt': purchasedAt,
      'expirationDate': expirationDate,
      'updatedAt': updatedAt,
      'latestSessionId': latestSessionId,
      'status': status,
    };
  }

  /// Firestore の Map から UserModel に変換
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] as String? ?? '',
      email: map['email'] as String? ?? '',
      createdAt: _parseDateTime(map['createdAt'])
          ?? DateTime.fromMillisecondsSinceEpoch(0),
      displayName: map['displayName'] as String?,  // OK to be null
      hasSubscription: map['hasSubscription'] as bool? ?? false,
      subscriptionPlan: map['subscriptionPlan'] as String? ?? '',
      purchasedAt: _parseDateTime(map['purchasedAt']),
      expirationDate: _parseDateTime(map['expirationDate']),
      updatedAt: _parseDateTime(map['updatedAt']),
      latestSessionId: map['latestSessionId'] as String? ?? '',
      status: map['status'] as String? ?? '',
    );
  }
}
