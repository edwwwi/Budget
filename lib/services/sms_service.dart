import 'dart:async';
import 'package:telephony/telephony.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/transaction.dart';

class SmsService {
  // Static instance for testing
  static final SmsService instance = SmsService._internal();
  
  // Private constructor
  SmsService._internal();
  static final Telephony telephony = Telephony.instance;
  static final StreamController<Transaction> _transactionController = 
      StreamController<Transaction>.broadcast();
      
  // Store processed transaction hashes to prevent duplicates
  static final Set<String> _processedTransactionHashes = <String>{};
  
  // Maximum number of transaction hashes to store (to prevent memory issues)
  static const int _maxStoredHashes = 100;

  static Stream<Transaction> get transactionStream => _transactionController.stream;

  // Common bank SMS patterns
  static final List<Map<String, dynamic>> _bankPatterns = [
    {
      'name': 'South Indian Bank',
      'patterns': [
        r'(?:SIB|South\s+Indian\s+Bank).*?(?:Rs|INR)\s*(\d+(?:,\d+)*(?:\.\d{2})?)\s+(?:has been|is|was)?\s*(?:credited|debited)\s+(?:to|from|in)?\s*(?:your|ur)?\s*(?:a/c|account)?.*?(?:on|dated)?\s*(\d{2}[-/]\d{2}[-/]\d{2,4})?(?:.*?(?:at)?\s*(\d{2}:\d{2}))?.*?(?:Avl\.?\s+bal|Available\s+balance|Bal)?\s*(?:is|:)?\s*(?:Rs|INR)?\s*(\d+(?:,\d+)*(?:\.\d{2})?)',
        r'(?:SIB|South\s+Indian\s+Bank).*?(?:Rs|INR)\s*(\d+(?:,\d+)*(?:\.\d{2})?)\s+(?:withdrawn|deposit|purchase|payment|transfer).*?(?:on|dated)?\s*(\d{2}[-/]\d{2}[-/]\d{2,4})?(?:.*?(?:at)?\s*(\d{2}:\d{2}))?.*?(?:Avl\.?\s+bal|Available\s+balance|Bal)?\s*(?:is|:)?\s*(?:Rs|INR)?\s*(\d+(?:,\d+)*(?:\.\d{2})?)',
        r'(?:SIB|South\s+Indian\s+Bank).*?(?:transaction|txn).*?(?:Rs|INR)\s*(\d+(?:,\d+)*(?:\.\d{2})?).*?(?:on|dated)?\s*(\d{2}[-/]\d{2}[-/]\d{2,4})?(?:.*?(?:at)?\s*(\d{2}:\d{2}))?.*?(?:Avl\.?\s+bal|Available\s+balance|Bal)?\s*(?:is|:)?\s*(?:Rs|INR)?\s*(\d+(?:,\d+)*(?:\.\d{2})?)',
        r'Your account [Xx\d]+ has been (credited|debited) with INR (\d+(?:,\d+)*(?:\.\d{2})?) on (\d{2}/\d{2}/\d{4}).*?Available balance is INR (\d+(?:,\d+)*(?:\.\d{2})?)',
      ]
    },
    {
      'name': 'HDFC Bank',
      'patterns': [
        r'Rs\.?\s*(\d+(?:,\d+)*(?:\.\d{2})?)\s+(?:has been|is|was)\s+(?:credited|debited)\s+(?:to|from)\s+your\s+a/c.*?(?:on|dated)\s+(\d{2}-\d{2}-\d{2}|\d{2}/\d{2}/\d{4})\s+(?:by|info)\s+(.*?)(?:\.\s+|\s+)(?:Avl\s+bal|Available\s+balance|Bal)\s*(?:is|:)\s*Rs\.?\s*(\d+(?:,\d+)*(?:\.\d{2})?)',
        r'Rs\.?(\d+(?:,\d+)*(?:\.\d{2})?)\s+(?:credited|debited)\s+to\s+your\s+account\s+(\w+)\s+on\s+(\d{2}/\d{2}/\d{4})\s+at\s+(\d{2}:\d{2})\s+(?:IST|AM|PM)?\s*\.?\s*Avl\s+Bal\s*:?\s*Rs\.?(\d+(?:,\d+)*(?:\.\d{2})?)',
        r'Rs\.?(\d+(?:,\d+)*(?:\.\d{2})?)\s+(?:credited|debited)\s+to\s+your\s+account\s+(\w+)\s+on\s+(\d{2}/\d{2}/\d{4})\s+at\s+(\d{2}:\d{2})\s+(?:IST|AM|PM)?\s*\.?\s*Balance\s*:?\s*Rs\.?(\d+(?:,\d+)*(?:\.\d{2})?)',
      ]
    },
    {
      'name': 'SBI Bank',
      'patterns': [
        r'(?:Ac|A/c)\s+(?:no|No|NO)\s*[Xx\*]+\d{4}\s+(?:debited|credited)\s+(?:with|for)\s+INR\s*(\d+(?:,\d+)*(?:\.\d{2})?)\s+(?:on|dated)\s+(\d{2}\s+[A-Za-z]{3}\s+\d{2}|\d{2}/\d{2}/\d{4})\s+(?:by|info)\s+(.*?)(?:\.\s+|\s+)(?:Avl\s+bal|Available\s+balance|Bal)\s*(?:is|:)\s*INR\s*(\d+(?:,\d+)*(?:\.\d{2})?)',
        r'Rs\.?(\d+(?:,\d+)*(?:\.\d{2})?)\s+(?:credited|debited)\s+to\s+your\s+account\s+(\w+)\s+on\s+(\d{2}/\d{2}/\d{4})\s+at\s+(\d{2}:\d{2})\s+(?:IST|AM|PM)?\s*\.?\s*Avl\s+Bal\s*:?\s*Rs\.?(\d+(?:,\d+)*(?:\.\d{2})?)',
        r'Rs\.?(\d+(?:,\d+)*(?:\.\d{2})?)\s+(?:credited|debited)\s+to\s+your\s+account\s+(\w+)\s+on\s+(\d{2}/\d{2}/\d{4})\s+at\s+(\d{2}:\d{2})\s+(?:IST|AM|PM)?\s*\.?\s*Balance\s*:?\s*Rs\.?(\d+(?:,\d+)*(?:\.\d{2})?)',
      ]
    },
    {
      'name': 'ICICI Bank',
      'patterns': [
        r'INR\s*(\d+(?:,\d+)*(?:\.\d{2})?)\s+(?:credited|debited)\s+to\s+(?:your|ur)\s+(?:a/c|account).*?(?:on|dated)\s+(\d{2}-[A-Za-z]{3}-\d{2}|\d{2}/\d{2}/\d{4}).*?(?:Info|by)\s*:?\s*(.*?)(?:\.\s+|\s+)(?:Avl\s+bal|Available\s+balance|Bal)\s*(?:is|:)\s*INR\s*(\d+(?:,\d+)*(?:\.\d{2})?)',
        r'Rs\.?(\d+(?:,\d+)*(?:\.\d{2})?)\s+(?:credited|debited)\s+to\s+your\s+account\s+(\w+)\s+on\s+(\d{2}/\d{2}/\d{4})\s+at\s+(\d{2}:\d{2})\s+(?:IST|AM|PM)?\s*\.?\s*Avl\s+Bal\s*:?\s*Rs\.?(\d+(?:,\d+)*(?:\.\d{2})?)',
        r'Rs\.?(\d+(?:,\d+)*(?:\.\d{2})?)\s+(?:credited|debited)\s+to\s+your\s+account\s+(\w+)\s+on\s+(\d{2}/\d{2}/\d{4})\s+at\s+(\d{2}:\d{2})\s+(?:IST|AM|PM)?\s*\.?\s*Balance\s*:?\s*Rs\.?(\d+(?:,\d+)*(?:\.\d{2})?)',
      ]
    },
    {
      'name': 'Axis Bank',
      'patterns': [
        r'(?:Your|Yr)\s+(?:A/c|Ac|account)\s+(?:no|No|NO)?\s*[Xx\*]+\d{4}\s+(?:is|was)\s+(?:credited|debited)\s+(?:with|by|for)\s+(?:Rs|INR)\s*(\d+(?:,\d+)*(?:\.\d{2})?)\s+(?:on|dated)\s+(\d{2}-\d{2}-\d{2}|\d{2}/\d{2}/\d{4}).*?(?:Info|by)\s*:?\s*(.*?)(?:\.\s+|\s+)(?:Net|Avbl|Available)\s+(?:Bal|Balance)\s*:?\s*(?:Rs|INR)\s*(\d+(?:,\d+)*(?:\.\d{2})?)',
        r'Rs\.?(\d+(?:,\d+)*(?:\.\d{2})?)\s+(?:credited|debited)\s+to\s+your\s+account\s+(\w+)\s+on\s+(\d{2}/\d{2}/\d{4})\s+at\s+(\d{2}:\d{2})\s+(?:IST|AM|PM)?\s*\.?\s*Avl\s+Bal\s*:?\s*Rs\.?(\d+(?:,\d+)*(?:\.\d{2})?)',
        r'Rs\.?(\d+(?:,\d+)*(?:\.\d{2})?)\s+(?:credited|debited)\s+to\s+your\s+account\s+(\w+)\s+on\s+(\d{2}/\d{2}/\d{4})\s+at\s+(\d{2}:\d{2})\s+(?:IST|AM|PM)?\s*\.?\s*Balance\s*:?\s*Rs\.?(\d+(?:,\d+)*(?:\.\d{2})?)',
      ]
    },
    {
      'name': 'Kotak Bank',
      'patterns': [
        r'Rs\.?(\d+(?:,\d+)*(?:\.\d{2})?)\s+(?:credited|debited)\s+to\s+your\s+account\s+(\w+)\s+on\s+(\d{2}/\d{2}/\d{4})\s+at\s+(\d{2}:\d{2})\s+(?:IST|AM|PM)?\s*\.?\s*Avl\s+Bal\s*:?\s*Rs\.?(\d+(?:,\d+)*(?:\.\d{2})?)',
        r'Rs\.?(\d+(?:,\d+)*(?:\.\d{2})?)\s+(?:credited|debited)\s+to\s+your\s+account\s+(\w+)\s+on\s+(\d{2}/\d{2}/\d{4})\s+at\s+(\d{2}:\d{2})\s+(?:IST|AM|PM)?\s*\.?\s*Balance\s*:?\s*Rs\.?(\d+(?:,\d+)*(?:\.\d{2})?)',
      ]
    },
  ];

  // Patterns to ignore (OTP, test messages, demo messages)
  static final List<RegExp> _otpPatterns = [
    // OTP patterns
    RegExp(r'OTP|otp'),
    RegExp(r'\b\d{4,6}\b.*(?:OTP|otp|verification|code)'),
    RegExp(r'(?:OTP|otp).*\b\d{4,6}\b'),
    RegExp(r'verification.*\b\d{4,6}\b'),
    RegExp(r'code.*\b\d{4,6}\b'),
    // Test/demo message patterns
    RegExp(r'(?:test|demo|sample)\s+(?:sms|message|transaction)', caseSensitive: false),
    RegExp(r'(?:this\s+is\s+a|for)\s+(?:test|demo|sample)', caseSensitive: false),
    RegExp(r'example', caseSensitive: false),
  ];

  static Future<bool> requestPermissions() async {
    // Check current status first
    PermissionStatus smsStatus = await Permission.sms.status;
    PermissionStatus phoneStatus = await Permission.phone.status;
    
    // If not granted, request permissions
    if (smsStatus != PermissionStatus.granted) {
      smsStatus = await Permission.sms.request();
    }
    if (phoneStatus != PermissionStatus.granted) {
      phoneStatus = await Permission.phone.request();
    }
    
    print('SMS Permission Status: $smsStatus');
    print('Phone Permission Status: $phoneStatus');
    
    return smsStatus == PermissionStatus.granted && phoneStatus == PermissionStatus.granted;
  }

  static Future<void> startListening() async {
    if (!await requestPermissions()) {
      throw Exception('SMS permissions not granted');
    }

    telephony.listenIncomingSms(
      onNewMessage: (SmsMessage message) {
        instance._processSms(message);
      },
      onBackgroundMessage: _backgroundMessageHandler,
    );
  }

  static Future<void> _backgroundMessageHandler(SmsMessage message) async {
    instance._processSms(message);
  }

  void _processSms(SmsMessage message) {
    print('Processing SMS: ${message.body}');
    
    // Skip if message is null or empty
    if (message.body == null || message.body!.isEmpty) {
      print('Skipping empty SMS');
      return;
    }
    
    // Skip if message contains OTP patterns
    if (_isOtpMessage(message.body!)) {
      print('Skipping OTP message');
      return;
    }
    
    // Try to parse transaction from SMS
    Transaction? transaction = _parseTransactionFromSms(message.body!, message.address ?? 'Unknown');
    
    if (transaction != null) {
      // Create a unique hash for this transaction to prevent duplicates
      // Combine amount, date, and part of the SMS body to create a unique identifier
      String transactionHash = '${transaction.amount}_${transaction.date.millisecondsSinceEpoch}_${message.body!.hashCode}';
      
      // Check if we've already processed this transaction
      if (_processedTransactionHashes.contains(transactionHash)) {
        print('Skipping duplicate transaction');
        return;
      }
      
      // Add to processed transactions
      _processedTransactionHashes.add(transactionHash);
      
      // Limit the size of the hash set to prevent memory issues
      if (_processedTransactionHashes.length > _maxStoredHashes) {
        // Remove the oldest entries (approximation by taking a subset)
        _processedTransactionHashes.clear();
        // Keep the latest transaction hash
        _processedTransactionHashes.add(transactionHash);
      }
      
      print('Transaction detected: ${transaction.description} - ₹${transaction.amount}');
      _transactionController.add(transaction);
    } else {
      print('Not a transaction SMS');
    }
  }

  // Public methods for testing
  void processSmsForTesting(SmsMessage message) {
    _processSms(message);
  }
  
  // Public method to parse transaction from SMS (for testing)
  Transaction? parseTransactionFromSms(String smsBody, String sender) {
    return _parseTransactionFromSms(smsBody, sender);
  }

  // Helper method to parse date and time from SMS
  DateTime _parseDateTime(String dateStr, String timeStr) {
    try {
      // Handle common date formats (DD/MM/YYYY or MM/DD/YYYY)
      List<String> dateParts = dateStr.split('/');
      if (dateParts.length != 3) {
        return DateTime.now();
      }
      
      int day = int.parse(dateParts[0]);
      int month = int.parse(dateParts[1]);
      int year = int.parse(dateParts[2]);
      
      // Handle time if available
      int hour = 0;
      int minute = 0;
      if (timeStr.isNotEmpty) {
        List<String> timeParts = timeStr.split(':');
        if (timeParts.length >= 2) {
          hour = int.parse(timeParts[0]);
          minute = int.parse(timeParts[1]);
        }
      }
      
      return DateTime(year, month, day, hour, minute);
    } catch (e) {
      print('Error parsing date/time: $e');
      return DateTime.now();
    }
  }
  
  // Helper method to create a meaningful description from SMS
  String _createDescriptionFromSms(String smsBody) {
    // Extract merchant name or transaction description
    // This is a simple implementation - can be enhanced with more patterns
    
    // Try to find common transaction keywords
    List<String> keywords = [
      'purchase', 'payment', 'spent', 'paid', 'buy', 'shopping',
      'restaurant', 'food', 'grocery', 'transfer', 'withdraw', 'deposit'
    ];
    
    for (String keyword in keywords) {
      RegExp regex = RegExp(r'\b' + keyword + r'\b.*?(?=\bat\b|\bin\b|\bfor\b|\.$|$)', 
          caseSensitive: false);
      Match? match = regex.firstMatch(smsBody);
      if (match != null && match.group(0) != null) {
        return match.group(0)!.trim();
      }
    }
    
    // If no specific description found, return a generic one
    return 'Transaction';
  }
  
  bool _isOtpMessage(String smsBody) {
    return _otpPatterns.any((pattern) => pattern.hasMatch(smsBody));
  }

  Transaction? _parseTransactionFromSms(String smsBody, String sender) {
    print('Parsing transaction from SMS: $smsBody');
    
    // Try to match with bank patterns
    for (var bank in _bankPatterns) {
      String bankName = bank['name'];
      List<String> patterns = bank['patterns'];
      
      for (var pattern in patterns) {
        RegExp regex = RegExp(pattern, caseSensitive: false);
        Match? match = regex.firstMatch(smsBody);
        
        if (match != null) {
          print('Matched pattern for bank: $bankName');
          
          try {
            // Extract transaction details
            String amountStr = match.group(1)?.replaceAll(',', '') ?? '0';
            double amount = double.parse(amountStr);
            
            // Determine transaction type
            String typeStr = match.group(2)?.toLowerCase() ?? '';
            TransactionType type = typeStr.contains('credit') || typeStr.contains('credited') 
                ? TransactionType.credit 
                : TransactionType.debit;
            
            // Extract date and time if available
            DateTime date = DateTime.now();
            if (match.groupCount >= 3) {
              try {
                String dateStr = match.group(3) ?? '';
                String timeStr = match.groupCount >= 4 ? match.group(4) ?? '' : '';
                date = _parseDateTime(dateStr, timeStr);
              } catch (e) {
                print('Error parsing date/time: $e');
              }
            }
            
            // Extract balance if available
            double balance = 0.0;
            if (match.groupCount >= 5) {
              try {
                String balanceStr = match.group(5)?.replaceAll(',', '') ?? '0';
                balance = double.parse(balanceStr);
              } catch (e) {
                print('Error parsing balance: $e');
              }
            }
            
            // Create description from SMS
            String description = _createDescriptionFromSms(smsBody);
            
            // Create transaction object
            return Transaction(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              amount: amount,
              type: type,
              category: 'uncategorized',  // Default category
              description: description,
              date: date,
              balance: balance,
              bankName: bankName,
              isCategorized: false,
              smsBody: smsBody,
            );
          } catch (e) {
            print('Error parsing transaction: $e');
          }
        }
      }
    }
    
    return null;
  }

  static double _parseAmount(String amountStr) {
    // Remove commas and convert to double
    String cleanAmount = amountStr.replaceAll(',', '');
    return double.tryParse(cleanAmount) ?? 0.0;
  }

  static DateTime _parseDate(String dateStr, String timeStr) {
    try {
      int day = 0, month = 0, year = 0;
      
      // Handle different date formats
      if (dateStr.contains('/')) {
        // DD/MM/YYYY or MM/DD/YYYY format
        List<String> dateParts = dateStr.split('/');
        if (dateParts.length == 3) {
          day = int.parse(dateParts[0]);
          month = int.parse(dateParts[1]);
          year = int.parse(dateParts[2]);
          // Handle 2-digit year
          if (year < 100) year += 2000;
        }
      } else if (dateStr.contains('-')) {
        // DD-MM-YY or YYYY-MM-DD format
        List<String> dateParts = dateStr.split('-');
        if (dateParts.length == 3) {
          // Check if first part is 4 digits (YYYY-MM-DD)
          if (dateParts[0].length == 4) {
            year = int.parse(dateParts[0]);
            month = int.parse(dateParts[1]);
            day = int.parse(dateParts[2]);
          } else {
            day = int.parse(dateParts[0]);
            month = int.parse(dateParts[1]);
            year = int.parse(dateParts[2]);
            // Handle 2-digit year
            if (year < 100) year += 2000;
          }
        }
      } else if (dateStr.contains(' ')) {
        // DD MMM YY format (e.g., "01 Jan 22")
        List<String> dateParts = dateStr.split(' ');
        if (dateParts.length >= 3) {
          day = int.parse(dateParts[0]);
          
          // Convert month name to number
          String monthStr = dateParts[1].toLowerCase();
          Map<String, int> monthMap = {
            'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6,
            'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12
          };
          month = monthMap[monthStr] ?? 1;
          
          year = int.parse(dateParts[2]);
          // Handle 2-digit year
          if (year < 100) year += 2000;
        }
      }
      
      // If we couldn't parse the date, use current date
      if (day == 0 || month == 0 || year == 0) {
        final now = DateTime.now();
        day = now.day;
        month = now.month;
        year = now.year;
      }
      
      // Parse time in HH:MM format if available
      int hour = 0, minute = 0;
      if (timeStr.isNotEmpty && timeStr.contains(':')) {
        List<String> timeParts = timeStr.split(':');
        if (timeParts.length >= 2) {
          hour = int.parse(timeParts[0]);
          minute = int.parse(timeParts[1]);
        }
      }
      
      return DateTime(year, month, day, hour, minute);
    } catch (e) {
      print('Error parsing date: $e');
      // Return current date if parsing fails
      return DateTime.now();
    }
  }

  static void dispose() {
    _transactionController.close();
  }
}
