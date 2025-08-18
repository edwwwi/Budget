# Finance App Test Plan

## Functional Testing

### SMS Parsing
- [ ] Verify that SMS messages from different banks are correctly parsed
- [ ] Verify that transaction amount is correctly extracted
- [ ] Verify that transaction type (credit/debit) is correctly identified
- [ ] Verify that transaction date is correctly extracted
- [ ] Verify that bank name is correctly identified

### Notification System
- [ ] Verify that notifications are shown when a new transaction is detected
- [ ] Verify that category selection buttons are displayed in the notification
- [ ] Verify that tapping a category button correctly categorizes the transaction
- [ ] Verify that tapping the notification opens the transaction details

### Transaction Categorization
- [ ] Verify that transactions can be categorized from the notification
- [ ] Verify that transactions can be categorized from the unlabeled transactions section
- [ ] Verify that categorized transactions appear in the correct category filter
- [ ] Verify that the transaction card shows the correct category icon and color

### Local Storage
- [ ] Verify that transactions are persisted after app restart
- [ ] Verify that categories are persisted after app restart
- [ ] Verify that budgets are persisted after app restart
- [ ] Verify that transaction categorization is persisted after app restart

### Dashboard
- [ ] Verify that the dashboard shows the correct total income
- [ ] Verify that the dashboard shows the correct total expenses
- [ ] Verify that the dashboard shows the correct balance
- [ ] Verify that the dashboard updates when new transactions are added

### Analytics
- [ ] Verify that the category pie chart shows the correct spending by category
- [ ] Verify that the monthly line chart shows the correct spending trend
- [ ] Verify that the year selector changes the data displayed in the charts
- [ ] Verify that the summary cards show the correct income, expenses, and balance

## UI Testing

### General UI
- [ ] Verify that the app has a clean white background
- [ ] Verify that cards have rounded corners
- [ ] Verify that cards have soft shadows
- [ ] Verify that the app uses consistent colors and typography

### Navigation
- [ ] Verify that the bottom navigation bar works correctly
- [ ] Verify that the app bar shows the correct title for each screen
- [ ] Verify that the app transitions smoothly between screens

### Responsiveness
- [ ] Verify that the app displays correctly on different screen sizes
- [ ] Verify that the app adapts to landscape and portrait orientations

## Performance Testing

- [ ] Verify that the app starts up quickly
- [ ] Verify that the app responds quickly to user interactions
- [ ] Verify that the app handles a large number of transactions efficiently
- [ ] Verify that the app uses memory efficiently

## Security Testing

- [ ] Verify that the app requests appropriate permissions
- [ ] Verify that the app handles permission denials gracefully
- [ ] Verify that sensitive data is stored securely

## Compatibility Testing

- [ ] Verify that the app works on different Android versions
- [ ] Verify that the app works on different device manufacturers
- [ ] Verify that the app works with different system themes (light/dark)