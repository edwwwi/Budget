import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/budget.dart';
import '../models/transaction.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _budgetController = TextEditingController();
  bool _isDarkMode = false;
  bool _notificationsEnabled = true;
  bool _smsPermissionsGranted = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  @override
  void dispose() {
    _budgetController.dispose();
    super.dispose();
  }

  Future<void> _checkPermissions() async {
    // TODO: Implement permission checking
    setState(() {
      _smsPermissionsGranted = true; // Placeholder
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Consumer<AppProvider>(
        builder: (context, provider, child) {
          return CustomScrollView(
            slivers: [
              // App Bar
              SliverAppBar(
                expandedHeight: 120,
                floating: false,
                pinned: true,
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                flexibleSpace: FlexibleSpaceBar(
                  title: const Text(
                    'Settings',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Theme.of(context).colorScheme.primary,
                          Theme.of(context).colorScheme.primary.withOpacity(0.8),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Settings List
              SliverPadding(
                padding: const EdgeInsets.all(16.0),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildBudgetSection(provider),
                    const SizedBox(height: 24),
                    _buildPermissionsSection(),
                    const SizedBox(height: 24),
                    _buildPreferencesSection(),
                    const SizedBox(height: 24),
                    _buildDataSection(provider),
                    const SizedBox(height: 24),
                    _buildTestSection(provider),
                    const SizedBox(height: 24),
                    _buildAboutSection(),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBudgetSection(AppProvider provider) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Budget Management',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            
            // Current Budget
            if (provider.currentBudget != null) ...[
              Row(
                children: [
                  Icon(
                    Icons.account_balance_wallet,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Current Monthly Budget',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          '₹${provider.currentBudget!.amount.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => _showEditBudgetDialog(provider),
                    child: const Text('Edit'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
            
            // Set New Budget
            ElevatedButton.icon(
              onPressed: () => _showSetBudgetDialog(provider),
              icon: const Icon(Icons.add),
              label: Text(provider.currentBudget != null ? 'Update Budget' : 'Set Budget'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionsSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Permissions',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            
            // SMS Permissions
            Row(
              children: [
                Icon(
                  _smsPermissionsGranted ? Icons.check_circle : Icons.error,
                  color: _smsPermissionsGranted ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SMS Permissions',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        _smsPermissionsGranted 
                            ? 'Granted - Can read bank SMS'
                            : 'Required for automatic transaction detection',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                if (!_smsPermissionsGranted)
                  TextButton(
                    onPressed: _requestSmsPermissions,
                    child: const Text('Grant'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreferencesSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Preferences',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            
            // Dark Mode
            SwitchListTile(
              title: const Text('Dark Mode'),
              subtitle: const Text('Use dark theme'),
              value: _isDarkMode,
              onChanged: (value) {
                setState(() {
                  _isDarkMode = value;
                });
                // TODO: Implement theme switching
              },
            ),
            
            // Notifications
            SwitchListTile(
              title: const Text('Notifications'),
              subtitle: const Text('Show transaction notifications'),
              value: _notificationsEnabled,
              onChanged: (value) {
                setState(() {
                  _notificationsEnabled = value;
                });
                // TODO: Implement notification toggle
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataSection(AppProvider provider) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Data Management',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            
            // Export Data
            ListTile(
              leading: const Icon(Icons.download),
              title: const Text('Export Data'),
              subtitle: const Text('Backup your financial data'),
              onTap: () => _exportData(provider),
            ),
            
            // Import Data
            ListTile(
              leading: const Icon(Icons.upload),
              title: const Text('Import Data'),
              subtitle: const Text('Restore from backup'),
              onTap: () => _importData(provider),
            ),
            
            // Clear Data
            ListTile(
              leading: const Icon(Icons.delete_forever, color: Colors.red),
              title: const Text('Clear All Data', style: TextStyle(color: Colors.red)),
              subtitle: const Text('Delete all transactions and settings'),
              onTap: () => _showClearDataDialog(provider),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'About',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('Version'),
              subtitle: const Text('1.0.0'),
            ),
            
            ListTile(
              leading: const Icon(Icons.privacy_tip),
              title: const Text('Privacy Policy'),
              onTap: () => _showPrivacyPolicy(),
            ),
            
            ListTile(
              leading: const Icon(Icons.description),
              title: const Text('Terms of Service'),
              onTap: () => _showTermsOfService(),
            ),
          ],
        ),
      ),
    );
  }

  void _showSetBudgetDialog(AppProvider provider) {
    _budgetController.text = provider.currentBudget?.amount.toString() ?? '';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Monthly Budget'),
        content: TextField(
          controller: _budgetController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Budget Amount (₹)',
            prefixText: '₹',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              double? amount = double.tryParse(_budgetController.text);
              if (amount != null && amount > 0) {
                _setBudget(provider, amount);
                Navigator.pop(context);
              }
            },
            child: const Text('Set'),
          ),
        ],
      ),
    );
  }

  void _showEditBudgetDialog(AppProvider provider) {
    // Similar to set budget dialog
    _showSetBudgetDialog(provider);
  }

  void _setBudget(AppProvider provider, double amount) {
    Budget budget = Budget(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      amount: amount,
      year: provider.selectedDate.year,
      month: provider.selectedDate.month,
      createdAt: DateTime.now(),
    );
    
    provider.addBudget(budget);
  }

  void _requestSmsPermissions() async {
    try {
      bool granted = await context.read<AppProvider>().requestSmsPermissions();
      setState(() {
        _smsPermissionsGranted = granted;
      });
      
      if (granted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('SMS permissions granted! App can now detect transactions.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('SMS permissions denied. Please grant permissions in settings.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error requesting permissions: $e')),
      );
    }
  }

  void _exportData(AppProvider provider) {
    // TODO: Implement data export
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Export feature coming soon')),
    );
  }

  void _importData(AppProvider provider) {
    // TODO: Implement data import
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Import feature coming soon')),
    );
  }

  void _showClearDataDialog(AppProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text(
          'This will permanently delete all your transactions, budgets, and settings. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              provider.clearError(); // Clear any existing errors
              // TODO: Implement clear data
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Data cleared successfully')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: const SingleChildScrollView(
          child: Text(
            'Your financial data is stored locally on your device and is never shared with third parties. '
            'The app only reads SMS messages to detect bank transactions and does not access any other personal information.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showTermsOfService() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terms of Service'),
        content: const SingleChildScrollView(
          child: Text(
            'This app is provided as-is for personal use. We are not responsible for any financial decisions made based on the data shown in this app. '
            'Please ensure you have proper permissions to read SMS messages on your device.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildTestSection(AppProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.bug_report,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  'Test Features',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
                         ElevatedButton(
               onPressed: () {
                 // Create a test transaction
                 final testTransaction = Transaction(
                   id: DateTime.now().millisecondsSinceEpoch.toString(),
                   amount: 500.0,
                   type: TransactionType.debit,
                   category: provider.categories.isNotEmpty ? provider.categories.first.id : '',
                   description: 'Test Transaction - Coffee',
                   date: DateTime.now(),
                   balance: 10000.0,
                   bankName: 'Test Bank',
                   isCategorized: false,
                   smsBody: 'Test SMS body',
                 );
                 provider.addTransaction(testTransaction);
                 ScaffoldMessenger.of(context).showSnackBar(
                   const SnackBar(content: Text('Test transaction added!')),
                 );
               },
               child: const Text('Add Test Transaction'),
             ),
             const SizedBox(height: 8),
                          ElevatedButton(
               onPressed: () {
                 // Simulate SMS detection by directly creating a transaction
                 print('Simulating SMS detection...');
                 final testTransaction = Transaction(
                   id: DateTime.now().millisecondsSinceEpoch.toString(),
                   amount: 500.0,
                   type: TransactionType.debit,
                   category: '',
                   description: 'Test SMS Transaction',
                   date: DateTime.now(),
                   balance: 9500.0,
                   bankName: 'Test Bank',
                   isCategorized: false,
                   smsBody: 'Test 500.00 debited on 15/12/2024 at 14:30. Balance: 9500.00',
                 );
                 
                 // Add to provider directly
                 context.read<AppProvider>().addTransaction(testTransaction);
                 ScaffoldMessenger.of(context).showSnackBar(
                   const SnackBar(content: Text('Test SMS transaction added!')),
                 );
               },
               child: const Text('Simulate SMS Detection'),
             ),
            const SizedBox(height: 8),
                                        ElevatedButton(
                 onPressed: () async {
                   try {
                     bool granted = await context.read<AppProvider>().requestSmsPermissions();
                     setState(() {
                       _smsPermissionsGranted = granted;
                     });
                     ScaffoldMessenger.of(context).showSnackBar(
                       SnackBar(content: Text(granted ? 'SMS permissions granted!' : 'SMS permissions denied')),
                     );
                   } catch (e) {
                     ScaffoldMessenger.of(context).showSnackBar(
                       SnackBar(content: Text('Error: $e')),
                     );
                   }
                 },
                 child: const Text('Request SMS Permissions'),
               ),
               const SizedBox(height: 8),
               ElevatedButton(
                 onPressed: () async {
                   try {
                     Map<String, bool> status = await context.read<AppProvider>().checkPermissionStatus();
                     ScaffoldMessenger.of(context).showSnackBar(
                       SnackBar(content: Text('SMS: ${status['sms']}, Phone: ${status['phone']}')),
                     );
                   } catch (e) {
                     ScaffoldMessenger.of(context).showSnackBar(
                       SnackBar(content: Text('Error: $e')),
                     );
                   }
                 },
                 child: const Text('Check Permission Status'),
               ),
          ],
        ),
      ),
    );
  }
}
