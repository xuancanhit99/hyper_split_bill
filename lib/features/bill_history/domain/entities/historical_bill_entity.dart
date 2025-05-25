import 'package:equatable/equatable.dart';

class HistoricalBillEntity extends Equatable {
  final String id;
  final String userId;
  final String? description;
  final double totalAmount;
  final String currencyCode;
  final DateTime billDate;
  final Map<String, dynamic>? rawOcrJson;
  final Map<String, dynamic> finalBillDataJson;
  final DateTime createdAt;
  final DateTime updatedAt;

  const HistoricalBillEntity({
    required this.id,
    required this.userId,
    this.description,
    required this.totalAmount,
    required this.currencyCode,
    required this.billDate,
    this.rawOcrJson,
    required this.finalBillDataJson,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        userId,
        description,
        totalAmount,
        currencyCode,
        billDate,
        rawOcrJson,
        finalBillDataJson,
        createdAt,
        updatedAt,
      ];

  HistoricalBillEntity copyWith({
    String? id,
    String? userId,
    String? description,
    double? totalAmount,
    String? currencyCode,
    DateTime? billDate,
    Map<String, dynamic>? rawOcrJson,
    Map<String, dynamic>? finalBillDataJson,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return HistoricalBillEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      description: description ?? this.description,
      totalAmount: totalAmount ?? this.totalAmount,
      currencyCode: currencyCode ?? this.currencyCode,
      billDate: billDate ?? this.billDate,
      rawOcrJson: rawOcrJson ?? this.rawOcrJson,
      finalBillDataJson: finalBillDataJson ?? this.finalBillDataJson,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
