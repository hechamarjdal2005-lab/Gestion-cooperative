import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gcoop/features/cooperative/providers/expenses_provider.dart';
import 'package:gcoop/features/cooperative/providers/incomes_provider.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tz.initializeTimeZones();
    
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _notificationsPlugin.initialize(initializationSettings);
  }

  static Future<void> checkAndSendMonthlySummary(WidgetRef ref) async {
    final now = DateTime.now();
    if (now.day != 1) return;

    final prefs = await SharedPreferences.getInstance();
    final lastSentMonth = prefs.getString('last_monthly_summary_sent');
    final currentMonthStr = DateFormat('yyyy-MM', 'en_US').format(now);

    if (lastSentMonth == currentMonthStr) return;

    final lastMonth = DateTime(now.year, now.month - 1);
    
    final expenses = await ref.read(expensesProvider.future);
    final incomes = await ref.read(incomesProvider.future);

    final totalExpenses = expenses
        .where((e) => e.date.year == lastMonth.year && e.date.month == lastMonth.month)
        .fold(0.0, (sum, e) => sum + e.amount);

    final totalIncomes = incomes
        .where((e) => e.date.year == lastMonth.year && e.date.month == lastMonth.month)
        .fold(0.0, (sum, e) => sum + e.amount);

    await showMonthlySummary(
      income: totalIncomes,
      expenses: totalExpenses,
      balance: totalIncomes - totalExpenses,
      month: lastMonth,
    );

    await prefs.setString('last_monthly_summary_sent', currentMonthStr);
  }

  static Future<void> showMonthlySummary({
    required double income,
    required double expenses,
    required double balance,
    required DateTime month,
  }) async {
    final monthName = DateFormat('MMMM', 'ar').format(month);
    final String title = 'ملخص شهر $monthName';
    final String body = 'المداخيل: ${NumberFormat('#,##0.00', 'en_US').format(income)} درهم، المصاريف: ${NumberFormat('#,##0.00', 'en_US').format(expenses)} درهم، الرصيد: ${NumberFormat('#,##0.00', 'en_US').format(balance)} درهم';

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'monthly_summary',
      'Monthly Financial Summary',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _notificationsPlugin.show(
      0,
      title,
      body,
      platformChannelSpecifics,
    );
  }

  static Future<void> scheduleMonthlyNotification() async {
    // Background task implementation...
  }
}
