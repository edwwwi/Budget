import 'package:flutter/material.dart';
import '../../models/transaction_model.dart';
import '../../models/transaction_category.dart';
import '../../models/transaction_type.dart';
import 'package:intl/intl.dart';

class BudifyTransactionTile extends StatelessWidget {
  final TransactionModel transaction;
  final VoidCallback? onDelete;

  const BudifyTransactionTile({
    super.key,
    required this.transaction,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _getCategoryIcon(),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.merchant,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  DateFormat('dd MMM, hh:mm a').format(transaction.timestamp),
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            '${transaction.type == TransactionType.debit ? "-" : "+"} Rs ${transaction.amount.toStringAsFixed(2)}',
            style: TextStyle(
              color: transaction.type == TransactionType.debit
                  ? Colors.red
                  : Colors.green,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          if (onDelete != null)
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              onPressed: onDelete,
              color: Colors.grey,
            ),
        ],
      ),
    );
  }

  Widget _getCategoryIcon() {
    IconData icon;
    Color color;
    switch (transaction.category) {
      case TransactionCategory.food:
        icon = Icons.restaurant;
        color = Colors.orange;
        break;
      case TransactionCategory.petrol:
        icon = Icons.local_gas_station;
        color = Colors.blue;
        break;
      case TransactionCategory.entertainment:
        icon = Icons.movie;
        color = Colors.purple;
        break;
      case TransactionCategory.other:
        icon = Icons.more_horiz;
        color = Colors.grey;
        break;
      case TransactionCategory.income:
        icon = Icons.attach_money;
        color = Colors.green;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }
}
