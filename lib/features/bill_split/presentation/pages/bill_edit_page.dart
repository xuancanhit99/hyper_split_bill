// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:hyper_split_bill/features/bill_split/presentation/bloc/ocr/ocr_bloc.dart'; // Import state for data structure
// // Import your BillEditBloc when created:
// // import 'package:hyper_split_bill/features/bill_split/presentation/bloc/bill_edit/bill_edit_bloc.dart';
// import 'package:hyper_split_bill/injection_container.dart';
//
// class BillEditPage extends StatelessWidget {
//   final ExtractedBillData? initialData; // Receive data from previous screen
//
//   const BillEditPage({super.key, this.initialData});
//
//   @override
//   Widget build(BuildContext context) {
//     // TODO: Provide BillEditBloc here when created
//     // return BlocProvider(
//     //   create: (context) => sl<BillEditBloc>(param1: initialData), // Pass initial data to Bloc if needed
//     //   child: BillEditView(initialData: initialData),
//     // );
//
//     // --- Placeholder View ---
//     return BillEditView(initialData: initialData);
//   }
// }
//
// // --- Placeholder View Widget ---
// class BillEditView extends StatefulWidget {
//   final ExtractedBillData? initialData;
//
//   const BillEditView({super.key, this.initialData});
//
//   @override
//   State<BillEditView> createState() => _BillEditViewState();
// }
//
// class _BillEditViewState extends State<BillEditView> {
//
//   @override
//   void initState() {
//     super.initState();
//     // TODO: Initialize local state controllers (TextEditingController etc.)
//     // based on widget.initialData if provided. This should ideally happen
//     // within the BillEditBloc state.
//     if (widget.initialData != null) {
//       print("Received initial data on Edit Page:");
//       print("Items: ${widget.initialData!.items}");
//       print("Subtotal: ${widget.initialData!.subtotal}");
//       print("Tax: ${widget.initialData!.tax}");
//       print("Discount: ${widget.initialData!.discount}");
//       print("Total: ${widget.initialData!.total}");
//     } else {
//       print("Edit Page launched without initial data.");
//       // Consider navigating back or showing an error if data is mandatory
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Verify & Edit Bill'),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.save),
//             tooltip: 'Save Bill',
//             onPressed: () {
//               // TODO: Dispatch Save event to BillEditBloc
//               print('Save button pressed');
//               // TODO: Navigate to Split Page on successful save (listen to Bloc state)
//               // context.push(AppRoutes.split, extra: savedBillData);
//             },
//           ),
//         ],
//       ),
//       body: widget.initialData == null
//           ? const Center(child: Text('No bill data received.'))
//           : _buildEditForm(context, widget.initialData!),
//       // Floating action button to add items?
//       floatingActionButton: FloatingActionButton(
//         onPressed: () {
//           // TODO: Add logic to add a new empty item row (dispatch event to Bloc)
//           print("Add Item pressed");
//         },
//         tooltip: 'Add Item',
//         child: const Icon(Icons.add),
//       ),
//     );
//   }
//
//   Widget _buildEditForm(BuildContext context, ExtractedBillData data) {
//     // TODO: Replace this with a proper form and ListView.builder for items
//     // driven by BillEditBloc state.
//     return SingleChildScrollView(
//       padding: const EdgeInsets.all(16.0),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text("Review Items:", style: Theme.of(context).textTheme.titleLarge),
//           const SizedBox(height: 10),
//           // --- Item List Placeholder ---
//           if (data.items.isEmpty)
//             const Text("No items extracted. Please add items manually.")
//           else
//             ListView.builder(
//               shrinkWrap: true, // Important inside SingleChildScrollView
//               physics: const NeverScrollableScrollPhysics(), // Disable ListView scrolling
//               itemCount: data.items.length,
//               itemBuilder: (context, index) {
//                 final item = data.items[index];
//                 // TODO: Replace with an EditableBillItemWidget managed by Bloc
//                 return ListTile(
//                   title: Text(item['name']?.toString() ?? 'Unknown Item'),
//                   subtitle: Text('Qty: ${item['quantity']?.toString() ?? '1'}'),
//                   trailing: Text(
//                     '\$${(item['price'] as num?)?.toStringAsFixed(2) ?? '0.00'}',
//                     style: const TextStyle(fontWeight: FontWeight.bold),
//                   ),
//                   onTap: () {
//                     // TODO: Implement editing logic (show dialog, navigate, update Bloc state)
//                     print("Tapped item: ${item['name']}");
//                   },
//                 );
//               },
//             ),
//           const Divider(height: 30, thickness: 1),
//           // --- Totals Placeholder ---
//           Text("Review Totals:", style: Theme.of(context).textTheme.titleLarge),
//           const SizedBox(height: 10),
//           _buildTotalRow("Subtotal:", data.subtotal),
//           _buildTotalRow("Tax:", data.tax),
//           _buildTotalRow("Discount:", data.discount),
//           const Divider(),
//           _buildTotalRow("Grand Total:", data.total, isBold: true),
//
//           // TODO: Add TextFormFields to allow editing these totals, linked to Bloc state.
//         ],
//       ),
//     );
//   }
//
//   // Helper widget for displaying total rows (replace with editable fields later)
//   Widget _buildTotalRow(String label, double? value, {bool isBold = false}) {
//     final style = TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, fontSize: isBold ? 16 : 14);
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 4.0),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Text(label, style: style),
//           Text(
//               value != null ? '\$${value.toStringAsFixed(2)}' : 'N/A',
//               style: style
//           ),
//         ],
//       ),
//     );
//   }
// }