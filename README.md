# Finance Tracker App

A comprehensive Flutter application for automatic transaction tracking via SMS with budget management and analytics.

## 📱 Features

### 🔄 Automatic Transaction Tracking
- **SMS Reading**: Automatically reads incoming bank SMS messages
- **Smart Parsing**: Extracts transaction amount, type (credit/debit), and balance
- **Bank Support**: Supports major Indian banks (HDFC, SBI, ICICI, Axis, Kotak)
- **OTP Safety**: Automatically ignores OTP messages for security

### 🏷️ Category Selection via Notification
- **Quick Notifications**: Receive notifications for new transactions
- **One-Tap Categorization**: Categorize transactions directly from notifications
- **Smart Categories**: Pre-defined categories with custom icons and colors

### 💰 Monthly Budget Management
- **Budget Setting**: Set monthly spending limits
- **Progress Tracking**: Visual progress bar showing budget usage
- **Over-Budget Alerts**: Get notified when approaching or exceeding budget
- **Real-time Updates**: Automatic budget tracking as transactions are detected

### 📊 Charts & Analytics
- **Pie Charts**: Visual breakdown of spending by category
- **Line Charts**: Monthly spending trends over time
- **Summary Cards**: Total income, expenses, and current balance
- **Interactive Charts**: Tap to view detailed information

### 🔒 Data Privacy & Safety
- **Local Storage**: All data stored locally using Hive database
- **No Bank Login**: No sensitive banking credentials required
- **Encrypted Storage**: Optional encryption for enhanced security
- **Privacy First**: No data shared with third parties

### 🎨 Modern UI/UX
- **Material Design 3**: Latest Material Design guidelines
- **Dark/Light Mode**: Automatic theme switching
- **Responsive Design**: Works on all screen sizes
- **Smooth Animations**: Fluid transitions and interactions

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (3.9.0 or higher)
- Android Studio / VS Code
- Android device or emulator

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd finance
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Generate Hive adapters**
   ```bash
   flutter packages pub run build_runner build
   ```

4. **Run the app**
   ```bash
   flutter run
   ```

### Permissions Required

The app requires the following permissions:
- **SMS Permission**: To read bank transaction SMS
- **Phone Permission**: Required for SMS access on some devices
- **Notification Permission**: To show transaction notifications

## 📱 App Structure

```
lib/
├── models/           # Data models with Hive annotations
│   ├── transaction.dart
│   ├── budget.dart
│   └── category.dart
├── services/         # Business logic and external services
│   ├── sms_service.dart
│   ├── notification_service.dart
│   └── storage_service.dart
├── providers/        # State management
│   └── app_provider.dart
├── screens/          # UI screens
│   ├── main_screen.dart
│   ├── transactions_screen.dart
│   ├── categories_screen.dart
│   ├── charts_screen.dart
│   └── settings_screen.dart
├── widgets/          # Reusable UI components
│   ├── transaction_card.dart
│   ├── budget_overview_card.dart
│   ├── category_card.dart
│   └── search_bar_widget.dart
└── main.dart         # App entry point
```

## 🏦 Supported Banks

The app currently supports SMS parsing for:
- **HDFC Bank**
- **State Bank of India (SBI)**
- **ICICI Bank**
- **Axis Bank**
- **Kotak Bank**

### SMS Format Support
The app recognizes common SMS formats like:
```
Rs.1,000.00 credited to your account XXX1234 on 15/12/2024 at 14:30 IST. Avl Bal: Rs.25,000.00
```

## 📊 Features in Detail

### Transaction Management
- **Automatic Detection**: New transactions appear instantly
- **Manual Entry**: Add transactions manually if needed
- **Search & Filter**: Find transactions by description, bank, or category
- **Edit & Delete**: Modify or remove transactions
- **Date Grouping**: Transactions grouped by date for easy viewing

### Category Management
- **Default Categories**: Pre-configured categories (Food, Travel, Shopping, etc.)
- **Custom Categories**: Add your own categories with custom icons
- **Spending Analytics**: View spending by category
- **Color Coding**: Each category has a unique color for easy identification

### Budget Features
- **Monthly Budgets**: Set different budgets for each month
- **Visual Progress**: See budget usage at a glance
- **Smart Alerts**: Get notified at 80%, 90%, and 100% usage
- **Over-Budget Tracking**: Track spending beyond budget limits

### Analytics Dashboard
- **Income vs Expenses**: Clear overview of monthly finances
- **Category Breakdown**: See where your money goes
- **Trend Analysis**: Track spending patterns over time
- **Balance Tracking**: Monitor account balance changes

## 🔧 Configuration

### Adding New Bank Support
To add support for a new bank, update the `_bankPatterns` in `lib/services/sms_service.dart`:

```dart
{
  'name': 'Your Bank Name',
  'patterns': [
    r'Your SMS pattern regex here',
  ]
}
```

### Custom Categories
Default categories can be modified in `lib/models/category.dart`. Add new categories by extending the `defaultCategories` list.

## 🛠️ Development

### State Management
The app uses the Provider pattern for state management:
- **AppProvider**: Main provider managing all app state
- **Reactive Updates**: UI automatically updates when data changes
- **Error Handling**: Comprehensive error handling and user feedback

### Database
- **Hive**: Fast, lightweight NoSQL database
- **Local Storage**: All data stored on device
- **Type Safety**: Strong typing with generated adapters

### Notifications
- **Local Notifications**: Transaction alerts and category selection
- **Background Processing**: Works even when app is closed
- **Custom Actions**: Quick categorization from notifications

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## ⚠️ Disclaimer

This app is for personal use only. The developers are not responsible for any financial decisions made based on the data shown in this app. Always verify your financial information with your bank.
