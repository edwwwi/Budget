#  Budify --- Smart Automated Expense Tracker (Flutter)

>  A high-performance Flutter expense tracking app that automatically
> detects bank transactions via SMS, categorizes expenses with
> actionable notifications, and delivers powerful financial insights ---
> all with a clean, minimalist UI.

------------------------------------------------------------------------

##  Why Budify?

Budify is a production-grade Flutter application designed to automate
personal expense tracking using real-time SMS interception, SQLite local
storage, and interactive notifications.

Unlike traditional budget apps that require manual entry, Budify:

 Automatically detects transactions from bank SMS\
 Extracts amount, merchant & transaction type using Regex\
 Instantly shows actionable category notifications\
 Provides real-time expense analytics & donut charts\
 Works fully offline with local database

------------------------------------------------------------------------

##  Key Features

###  Automated SMS Expense Detection

-   Listens to Federal Bank SMS
-   Extracts transaction details using Regex parsing
-   Prevents duplicate entries using SMS hashing
-   Secure and local-only storage

###  Actionable Smart Notifications

-   Instant expense detection alert
-   One-tap categorization:
    -    Food
    -    Petrol
    -    Entertainment
    -    Other
-   Updates database instantly on selection

###  Insights & Analytics Dashboard

-   Donut Chart (fl_chart)
-   Day / Month / Year filtering
-   Income vs Expense comparison
-   Category-wise breakdown with percentages
-   Net balance calculation
-   Top spending category detection

###  Smart Transaction History

-   Categorized & Uncategorized highlighting
-   Editable transaction bottom sheet
-   Manual transaction entry
-   Clean and fast ListView rendering

###  Modern Soft UI Design

-   Minimalist white layout
-   Smooth UI
-   Category-based accent colors
-   Rounded cards & clean typography

------------------------------------------------------------------------

## 🏗 Architecture

Budify follows Clean Architecture principles:

UI Layer\
↓\
Riverpod State Management\
↓\
Repository Layer\
↓\
SQLite Database Layer\
↓\
Background SMS Listener

### Folder Structure

    lib/
     ├── core/
     ├── data/
     │   ├── models/
     │   ├── database/
     │   └── repositories/
     ├── background/
     ├── features/
     │   ├── analysis/
     │   └── history/
     ├── providers/
     ├── widgets/
     └── main.dart

------------------------------------------------------------------------

## 🛠 Tech Stack

-   Flutter
-   Dart
-   Riverpod
-   SQLite (sqflite)
-   fl_chart
-   flutter_local_notifications
-   telephony (SMS Listener)
-   permission_handler
-   workmanager
-   intl
-   uuid

------------------------------------------------------------------------

## 🗄 Database Schema

Transactions Table:

-   id
-   amount
-   merchant
-   timestamp
-   type (Credit / Debit)
-   category
-   is_categorized
-   sms_body
-   source (SMS / MANUAL)
-   sms_hash
-   created_at
-   updated_at

Indexed for performance optimization.

------------------------------------------------------------------------

## ⚡ Performance Optimizations

-   Indexed SQLite queries
-   Async DB operations
-   Efficient ListView.builder rendering
-   StateNotifier-based Riverpod architecture
-   Duplicate SMS prevention logic

------------------------------------------------------------------------

## 🔐 Permissions Used

-   READ_SMS
-   RECEIVE_SMS
-   POST_NOTIFICATIONS

All data remains stored locally on device.

------------------------------------------------------------------------

## 📈 Future Enhancements

-   Multi-bank support
-   AI-based smart categorization
-   Budget alerts
-   Cloud backup & sync
-   CSV export
-   Dark mode
-   Spending trend graphs

------------------------------------------------------------------------

## 🎯 SEO Keywords (For Discoverability)

Flutter Expense Tracker\
SMS Expense Tracker App\
Automated Budget App\
Flutter Finance App\
Riverpod SQLite App\
Flutter Clean Architecture Project\
Expense Manager Flutter\
Personal Finance App Flutter\
Bank SMS Parser Flutter\
Offline Expense Tracker

------------------------------------------------------------------------

## 🚀 Getting Started

``` bash
git clone https://github.com/yourusername/budify.git
cd budify
flutter pub get
flutter run
```

------------------------------------------------------------------------

## 🏆 Project Highlights

-   Real-world problem solving
-   Background service implementation
-   Advanced notification handling
-   Local database indexing
-   Clean architecture design
-   Production-ready scalable structure
