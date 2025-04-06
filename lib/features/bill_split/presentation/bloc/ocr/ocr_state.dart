// part of 'ocr_bloc.dart'; // Link to the Bloc file
//
// // Define a simple structure for the extracted data for now
// // This should eventually become a proper Entity/Model
// class ExtractedBillData extends Equatable {
//   final List<Map<String, dynamic>>
//   items; // Example: [{'name': 'Burger', 'quantity': 1, 'price': 10.0}]
//   final double? subtotal;
//   final double? tax;
//   final double? discount;
//   final double? total;
//
//   const ExtractedBillData({
//     required this.items,
//     this.subtotal,
//     this.tax,
//     this.discount,
//     this.total,
//   });
//
//   // Factory constructor to parse from the Map received from API
//   // IMPORTANT: Adjust keys based on your ACTUAL API response structure!
//   factory ExtractedBillData.fromJson(Map<String, dynamic> json) {
//     // Defensive parsing: Check for nulls and correct types
//     final itemsList =
//         (json['items'] as List<dynamic>?)
//             ?.map((item) => item as Map<String, dynamic>)
//             .toList() ??
//         []; // Default to empty list if null or wrong type
//
//     // Helper to safely parse numeric values
//     double? parseDouble(dynamic value) {
//       if (value is num) return value.toDouble();
//       if (value is String) return double.tryParse(value);
//       return null;
//     }
//
//     return ExtractedBillData(
//       items: itemsList,
//       subtotal: parseDouble(json['subtotal']),
//       tax: parseDouble(json['tax']),
//       discount: parseDouble(json['discount']),
//       total: parseDouble(json['total']),
//     );
//   }
//
//   @override
//   List<Object?> get props => [items, subtotal, tax, discount, total];
// }
//
// abstract class OcrState extends Equatable {
//   const OcrState();
//
//   @override
//   List<Object?> get props => [];
// }
//
// // Initial state, nothing happening
// class OcrInitial extends OcrState {}
//
// // OCR process is running
// class OcrLoading extends OcrState {}
//
// // OCR succeeded, includes the extracted data
// class OcrSuccess extends OcrState {
//   final ExtractedBillData extractedData;
//
//   const OcrSuccess(this.extractedData);
//
//   @override
//   List<Object?> get props => [extractedData];
// }
//
// // OCR failed
// class OcrFailure extends OcrState {
//   final String error;
//
//   const OcrFailure(this.error);
//
//   @override
//   List<Object?> get props => [error];
// }
