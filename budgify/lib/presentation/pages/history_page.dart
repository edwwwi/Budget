import 'package:flutter/material.dart';
import 'package:budgify/domain/entities/transaction.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        title: const Text(
          'History',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        itemCount: 10, // Placeholder
        itemBuilder: (context, index) {
          return _buildTransactionTile(
            category: TransactionCategory.food,
            merchant: 'Zomato Order',
            amount: 450.0,
            timestamp: DateTime.now(),
            type: TransactionType.debit,
          );
        },
      ),
    );
  }

  Widget _buildTransactionTile({
    required TransactionCategory category,
    required String merchant,
    required double amount,
    required DateTime timestamp,
    required TransactionType type,
  }) {
    IconData icon;
    Color iconColor;

    switch (category) {
      case TransactionCategory.food:
        icon = Icons.restaurant;
        iconColor = Colors.orange;
        break;
      case TransactionCategory.petrol:
        icon = Icons.local_gas_station;
        iconColor = Colors.blue;
        break;
      case TransactionCategory.entertainment:
        icon = Icons.movie;
        iconColor = Colors.purple;
        break;
      case TransactionCategory.other:
        icon = Icons.more_horiz;
        iconColor = Colors.grey;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  merchant,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  '${timestamp.day}/${timestamp.month} • ${timestamp.hour}:${timestamp.minute}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
              ],
            ),
          ),
          Text(
            '${type == TransactionType.debit ? "-" : "+"} Rs $amount',
            style: TextStyle(
              color: type == TransactionType.debit ? Colors.red : Colors.green,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
