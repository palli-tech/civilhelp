import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/payment_model.dart';

class PaymentCard extends StatelessWidget {
  final PaymentModel payment;
  final VoidCallback? onMarkPaid;
  final VoidCallback? onCancelPayment;
  final VoidCallback? onDelete;

  const PaymentCard({
    super.key,
    required this.payment,
    this.onMarkPaid,
    this.onCancelPayment,
    this.onDelete,
  });

  Color _statusColor() {
    switch (payment.status.toLowerCase()) {
      case 'paid':
        return Colors.green;
      case 'completed': // Support legacy status string
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final periodText =
        '${DateFormat('dd MMM yyyy').format(payment.periodStart)} - ${DateFormat('dd MMM yyyy').format(payment.periodEnd)}';

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (payment.paymentNumber != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            payment.paymentNumber!,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      Text(
                        payment.labourName,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        payment.siteName,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        periodText,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) {
                    switch (value) {
                      case 'mark_paid':
                        onMarkPaid?.call();
                        break;
                      case 'cancel':
                        onCancelPayment?.call();
                        break;
                      case 'delete':
                        onDelete?.call();
                        break;
                    }
                  },
                  itemBuilder: (context) {
                    final List<PopupMenuEntry<String>> items = [];
                    final status = payment.status.toLowerCase();

                    if (status == 'pending') {
                      items.add(
                        const PopupMenuItem<String>(
                          value: 'mark_paid',
                          child: Row(
                            children: [
                              Icon(Icons.check_circle, size: 18, color: Colors.green),
                              SizedBox(width: 8),
                              Text('Mark Paid'),
                            ],
                          ),
                        ),
                      );
                      items.add(
                        const PopupMenuItem<String>(
                          value: 'cancel',
                          child: Row(
                            children: [
                              Icon(Icons.cancel, size: 18, color: Colors.orange),
                              SizedBox(width: 8),
                              Text('Cancel'),
                            ],
                          ),
                        ),
                      );
                    }

                    items.add(
                      const PopupMenuItem<String>(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 18, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete'),
                          ],
                        ),
                      ),
                    );

                    return items;
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Gross Pay', style: TextStyle(color: Colors.grey[700])),
                      Text('₹${payment.grossAmount.toStringAsFixed(0)}'),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        payment.status.toLowerCase() == 'pending'
                            ? 'Projected Advance Recovery'
                            : 'Advance Deduction',
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                      Text('₹${payment.advancesTotal.toStringAsFixed(0)}'),
                    ],
                  ),
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        payment.status.toLowerCase() == 'pending'
                            ? 'Projected Net Payable'
                            : 'Net Payable',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '₹${payment.netAmount.toStringAsFixed(0)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  if (payment.status.toLowerCase() == 'pending') ...[
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.warning_amber_rounded,
                            size: 16, color: Colors.orange[800]),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Final values will be recalculated when payment is marked Paid.',
                            style: TextStyle(
                              color: Colors.orange[800],
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Chip(
                  label: Text(
                    payment.status.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  backgroundColor: _statusColor(),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
