import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('fr')
  ];

  /// No description provided for @appTitle.
  ///
  /// In ar, this message translates to:
  /// **'GCoop'**
  String get appTitle;

  /// No description provided for @login.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الدخول'**
  String get login;

  /// No description provided for @email.
  ///
  /// In ar, this message translates to:
  /// **'البريد الإلكتروني'**
  String get email;

  /// No description provided for @password.
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور'**
  String get password;

  /// No description provided for @dashboard.
  ///
  /// In ar, this message translates to:
  /// **'لوحة التحكم'**
  String get dashboard;

  /// No description provided for @invoices.
  ///
  /// In ar, this message translates to:
  /// **'الفواتير'**
  String get invoices;

  /// No description provided for @products.
  ///
  /// In ar, this message translates to:
  /// **'المنتجات'**
  String get products;

  /// No description provided for @expenses.
  ///
  /// In ar, this message translates to:
  /// **'المصاريف'**
  String get expenses;

  /// No description provided for @more.
  ///
  /// In ar, this message translates to:
  /// **'المزيد'**
  String get more;

  /// No description provided for @clients.
  ///
  /// In ar, this message translates to:
  /// **'الزبناء'**
  String get clients;

  /// No description provided for @suppliers.
  ///
  /// In ar, this message translates to:
  /// **'الموردين'**
  String get suppliers;

  /// No description provided for @totalInvoices.
  ///
  /// In ar, this message translates to:
  /// **'إجمالي الفواتير'**
  String get totalInvoices;

  /// No description provided for @totalRevenue.
  ///
  /// In ar, this message translates to:
  /// **'إجمالي الإيرادات'**
  String get totalRevenue;

  /// No description provided for @purchaseOrders.
  ///
  /// In ar, this message translates to:
  /// **'طلبات الشراء'**
  String get purchaseOrders;

  /// No description provided for @lowStockAlerts.
  ///
  /// In ar, this message translates to:
  /// **'تنبيهات انخفاض المخزون'**
  String get lowStockAlerts;

  /// No description provided for @newInvoice.
  ///
  /// In ar, this message translates to:
  /// **'فاتورة جديدة'**
  String get newInvoice;

  /// No description provided for @addProduct.
  ///
  /// In ar, this message translates to:
  /// **'إضافة منتج'**
  String get addProduct;

  /// No description provided for @newExpense.
  ///
  /// In ar, this message translates to:
  /// **'مصروف جديد'**
  String get newExpense;

  /// No description provided for @newClient.
  ///
  /// In ar, this message translates to:
  /// **'زبون جديد'**
  String get newClient;

  /// No description provided for @recentTransactions.
  ///
  /// In ar, this message translates to:
  /// **'العمليات الأخيرة'**
  String get recentTransactions;

  /// No description provided for @paid.
  ///
  /// In ar, this message translates to:
  /// **'مدفوعة'**
  String get paid;

  /// No description provided for @unpaid.
  ///
  /// In ar, this message translates to:
  /// **'غير مدفوعة'**
  String get unpaid;

  /// No description provided for @all.
  ///
  /// In ar, this message translates to:
  /// **'الكل'**
  String get all;

  /// No description provided for @search.
  ///
  /// In ar, this message translates to:
  /// **'بحث'**
  String get search;

  /// No description provided for @category.
  ///
  /// In ar, this message translates to:
  /// **'الفئة'**
  String get category;

  /// No description provided for @settings.
  ///
  /// In ar, this message translates to:
  /// **'الإعدادات'**
  String get settings;

  /// No description provided for @logout.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الخروج'**
  String get logout;

  /// No description provided for @save.
  ///
  /// In ar, this message translates to:
  /// **'حفظ'**
  String get save;

  /// No description provided for @edit.
  ///
  /// In ar, this message translates to:
  /// **'تعديل'**
  String get edit;

  /// No description provided for @delete.
  ///
  /// In ar, this message translates to:
  /// **'حذف'**
  String get delete;

  /// No description provided for @cancel.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء'**
  String get cancel;

  /// No description provided for @download.
  ///
  /// In ar, this message translates to:
  /// **'تحميل'**
  String get download;

  /// No description provided for @share.
  ///
  /// In ar, this message translates to:
  /// **'مشاركة'**
  String get share;

  /// No description provided for @print.
  ///
  /// In ar, this message translates to:
  /// **'طباعة'**
  String get print;

  /// No description provided for @arabic.
  ///
  /// In ar, this message translates to:
  /// **'العربية'**
  String get arabic;

  /// No description provided for @french.
  ///
  /// In ar, this message translates to:
  /// **'الفرنسية'**
  String get french;

  /// No description provided for @language.
  ///
  /// In ar, this message translates to:
  /// **'اللغة'**
  String get language;

  /// No description provided for @newDocument.
  ///
  /// In ar, this message translates to:
  /// **'مستند جديد'**
  String get newDocument;

  /// No description provided for @documentType.
  ///
  /// In ar, this message translates to:
  /// **'نوع المستند'**
  String get documentType;

  /// No description provided for @invoice.
  ///
  /// In ar, this message translates to:
  /// **'فاتورة'**
  String get invoice;

  /// No description provided for @deliveryNote.
  ///
  /// In ar, this message translates to:
  /// **'وصل التسليم'**
  String get deliveryNote;

  /// No description provided for @purchaseOrder.
  ///
  /// In ar, this message translates to:
  /// **'طلب شراء'**
  String get purchaseOrder;

  /// No description provided for @quote.
  ///
  /// In ar, this message translates to:
  /// **'عرض سعر'**
  String get quote;

  /// No description provided for @documentNumber.
  ///
  /// In ar, this message translates to:
  /// **'رقم المستند'**
  String get documentNumber;

  /// No description provided for @date.
  ///
  /// In ar, this message translates to:
  /// **'التاريخ'**
  String get date;

  /// No description provided for @selectClient.
  ///
  /// In ar, this message translates to:
  /// **'اختيار الزبون'**
  String get selectClient;

  /// No description provided for @selectProduct.
  ///
  /// In ar, this message translates to:
  /// **'اختيار المنتج'**
  String get selectProduct;

  /// No description provided for @quantity.
  ///
  /// In ar, this message translates to:
  /// **'الكمية'**
  String get quantity;

  /// No description provided for @unit.
  ///
  /// In ar, this message translates to:
  /// **'الوحدة'**
  String get unit;

  /// No description provided for @unitPrice.
  ///
  /// In ar, this message translates to:
  /// **'الثمن الوحدوي'**
  String get unitPrice;

  /// No description provided for @total.
  ///
  /// In ar, this message translates to:
  /// **'المجموع'**
  String get total;

  /// No description provided for @subtotal.
  ///
  /// In ar, this message translates to:
  /// **'المجموع الصافي'**
  String get subtotal;

  /// No description provided for @discount.
  ///
  /// In ar, this message translates to:
  /// **'الخصم'**
  String get discount;

  /// No description provided for @tva.
  ///
  /// In ar, this message translates to:
  /// **'الضريبة'**
  String get tva;

  /// No description provided for @totalToPay.
  ///
  /// In ar, this message translates to:
  /// **'المجموع النهائي'**
  String get totalToPay;

  /// No description provided for @deliveryFees.
  ///
  /// In ar, this message translates to:
  /// **'مصاريف التسليم'**
  String get deliveryFees;

  /// No description provided for @paymentMethod.
  ///
  /// In ar, this message translates to:
  /// **'طريقة الدفع'**
  String get paymentMethod;

  /// No description provided for @cash.
  ///
  /// In ar, this message translates to:
  /// **'نقدا'**
  String get cash;

  /// No description provided for @transfer.
  ///
  /// In ar, this message translates to:
  /// **'تحويل بنكي'**
  String get transfer;

  /// No description provided for @check.
  ///
  /// In ar, this message translates to:
  /// **'شيك'**
  String get check;

  /// No description provided for @deliveryLocation.
  ///
  /// In ar, this message translates to:
  /// **'مكان التسليم'**
  String get deliveryLocation;

  /// No description provided for @deliveryDelay.
  ///
  /// In ar, this message translates to:
  /// **'مدة التسليم'**
  String get deliveryDelay;

  /// No description provided for @notes.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظات'**
  String get notes;

  /// No description provided for @saveAndShare.
  ///
  /// In ar, this message translates to:
  /// **'حفظ ومشاركة'**
  String get saveAndShare;

  /// No description provided for @clientInfo.
  ///
  /// In ar, this message translates to:
  /// **'معلومات الزبون'**
  String get clientInfo;

  /// No description provided for @name.
  ///
  /// In ar, this message translates to:
  /// **'الاسم'**
  String get name;

  /// No description provided for @phone.
  ///
  /// In ar, this message translates to:
  /// **'الهاتف'**
  String get phone;

  /// No description provided for @address.
  ///
  /// In ar, this message translates to:
  /// **'العنوان'**
  String get address;

  /// No description provided for @addItem.
  ///
  /// In ar, this message translates to:
  /// **'إضافة منتج'**
  String get addItem;

  /// No description provided for @reference.
  ///
  /// In ar, this message translates to:
  /// **'المرجع'**
  String get reference;

  /// No description provided for @description.
  ///
  /// In ar, this message translates to:
  /// **'الوصف'**
  String get description;

  /// No description provided for @clientSignature.
  ///
  /// In ar, this message translates to:
  /// **'توقيع الزبون'**
  String get clientSignature;

  /// No description provided for @supplierSignature.
  ///
  /// In ar, this message translates to:
  /// **'توقيع المورد'**
  String get supplierSignature;

  /// No description provided for @receivedOn.
  ///
  /// In ar, this message translates to:
  /// **'استلم في'**
  String get receivedOn;

  /// No description provided for @deliveredOn.
  ///
  /// In ar, this message translates to:
  /// **'سلم في'**
  String get deliveredOn;

  /// No description provided for @warranty.
  ///
  /// In ar, this message translates to:
  /// **'الضمان'**
  String get warranty;

  /// No description provided for @thankYou.
  ///
  /// In ar, this message translates to:
  /// **'شكرا لثقتكم بنا'**
  String get thankYou;

  /// No description provided for @amountInWords.
  ///
  /// In ar, this message translates to:
  /// **'المبلغ بالحروف'**
  String get amountInWords;

  /// No description provided for @stamp.
  ///
  /// In ar, this message translates to:
  /// **'الختم'**
  String get stamp;

  /// No description provided for @orderRef.
  ///
  /// In ar, this message translates to:
  /// **'رقم الطلب'**
  String get orderRef;

  /// No description provided for @piece.
  ///
  /// In ar, this message translates to:
  /// **'قطعة'**
  String get piece;

  /// No description provided for @kg.
  ///
  /// In ar, this message translates to:
  /// **'كلغ'**
  String get kg;

  /// No description provided for @liter.
  ///
  /// In ar, this message translates to:
  /// **'لتر'**
  String get liter;

  /// No description provided for @meter.
  ///
  /// In ar, this message translates to:
  /// **'متر'**
  String get meter;

  /// No description provided for @documents.
  ///
  /// In ar, this message translates to:
  /// **'المستندات'**
  String get documents;

  /// No description provided for @documentsList.
  ///
  /// In ar, this message translates to:
  /// **'قائمة المستندات'**
  String get documentsList;

  /// No description provided for @noDocuments.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد مستندات مسجلة'**
  String get noDocuments;

  /// No description provided for @downloadPdf.
  ///
  /// In ar, this message translates to:
  /// **'تحميل PDF'**
  String get downloadPdf;

  /// No description provided for @sharePdf.
  ///
  /// In ar, this message translates to:
  /// **'مشاركة PDF'**
  String get sharePdf;

  /// No description provided for @additionalInfo.
  ///
  /// In ar, this message translates to:
  /// **'معلومات إضافية'**
  String get additionalInfo;

  /// No description provided for @status.
  ///
  /// In ar, this message translates to:
  /// **'الحالة'**
  String get status;

  /// No description provided for @draft.
  ///
  /// In ar, this message translates to:
  /// **'مسودة'**
  String get draft;

  /// No description provided for @validated.
  ///
  /// In ar, this message translates to:
  /// **'مصادق عليه'**
  String get validated;

  /// No description provided for @cancelled.
  ///
  /// In ar, this message translates to:
  /// **'ملغى'**
  String get cancelled;

  /// No description provided for @pending.
  ///
  /// In ar, this message translates to:
  /// **'قيد الانتظار'**
  String get pending;

  /// No description provided for @searchClient.
  ///
  /// In ar, this message translates to:
  /// **'بحث عن زبون...'**
  String get searchClient;

  /// No description provided for @noClients.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد زبناء حاليا'**
  String get noClients;

  /// No description provided for @noResults.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد نتائج تطابق بحثك'**
  String get noResults;

  /// No description provided for @confirmDelete.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد الحذف'**
  String get confirmDelete;

  /// No description provided for @confirmDeleteClient.
  ///
  /// In ar, this message translates to:
  /// **'هل أنت متأكد أنك تريد حذف هذا الزبون؟'**
  String get confirmDeleteClient;

  /// No description provided for @clientDeleted.
  ///
  /// In ar, this message translates to:
  /// **'تم حذف الزبون بنجاح'**
  String get clientDeleted;

  /// No description provided for @error.
  ///
  /// In ar, this message translates to:
  /// **'خطأ'**
  String get error;

  /// No description provided for @searchSupplier.
  ///
  /// In ar, this message translates to:
  /// **'بحث عن مورد...'**
  String get searchSupplier;

  /// No description provided for @noSuppliers.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد موردون حاليا'**
  String get noSuppliers;

  /// No description provided for @confirmDeleteSupplier.
  ///
  /// In ar, this message translates to:
  /// **'هل أنت متأكد أنك تريد حذف هذا المورد؟'**
  String get confirmDeleteSupplier;

  /// No description provided for @supplierDeleted.
  ///
  /// In ar, this message translates to:
  /// **'تم حذف المورد بنجاح'**
  String get supplierDeleted;

  /// No description provided for @searchProduct.
  ///
  /// In ar, this message translates to:
  /// **'بحث عن منتج...'**
  String get searchProduct;

  /// No description provided for @noProducts.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد منتجات حاليا'**
  String get noProducts;

  /// No description provided for @confirmDeleteProduct.
  ///
  /// In ar, this message translates to:
  /// **'هل أنت متأكد أنك تريد حذف هذا المنتج؟'**
  String get confirmDeleteProduct;

  /// No description provided for @productDeleted.
  ///
  /// In ar, this message translates to:
  /// **'تم حذف المنتج بنجاح'**
  String get productDeleted;

  /// No description provided for @totalExpensesToday.
  ///
  /// In ar, this message translates to:
  /// **'إجمالي المصاريف اليوم'**
  String get totalExpensesToday;

  /// No description provided for @noExpenses.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد مصاريف مسجلة'**
  String get noExpenses;

  /// No description provided for @confirmDeleteExpense.
  ///
  /// In ar, this message translates to:
  /// **'هل أنت متأكد أنك تريد حذف هذا المصروف؟'**
  String get confirmDeleteExpense;

  /// No description provided for @expenseDeleted.
  ///
  /// In ar, this message translates to:
  /// **'تم حذف المصروف بنجاح'**
  String get expenseDeleted;

  /// No description provided for @searchDocument.
  ///
  /// In ar, this message translates to:
  /// **'بحث عن مستند أو عميل...'**
  String get searchDocument;

  /// No description provided for @confirmDeleteDocument.
  ///
  /// In ar, this message translates to:
  /// **'هل أنت متأكد أنك تريد حذف هذا المستند؟'**
  String get confirmDeleteDocument;

  /// No description provided for @documentDeleted.
  ///
  /// In ar, this message translates to:
  /// **'تم حذف المستند بنجاح'**
  String get documentDeleted;

  /// No description provided for @welcome.
  ///
  /// In ar, this message translates to:
  /// **'مرحباً'**
  String get welcome;

  /// No description provided for @quickActions.
  ///
  /// In ar, this message translates to:
  /// **'أزرار سريعة'**
  String get quickActions;

  /// No description provided for @lastOperations.
  ///
  /// In ar, this message translates to:
  /// **'آخر العمليات'**
  String get lastOperations;

  /// No description provided for @dailySales.
  ///
  /// In ar, this message translates to:
  /// **'مبيعات اليوم'**
  String get dailySales;

  /// No description provided for @inventory.
  ///
  /// In ar, this message translates to:
  /// **'المخزون'**
  String get inventory;

  /// No description provided for @noOperations.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد عمليات حالياً'**
  String get noOperations;

  /// No description provided for @cooperative.
  ///
  /// In ar, this message translates to:
  /// **'التعاونية'**
  String get cooperative;

  /// No description provided for @cooperativeInfo.
  ///
  /// In ar, this message translates to:
  /// **'معلومات التعاونية'**
  String get cooperativeInfo;

  /// No description provided for @clientsAndSuppliers.
  ///
  /// In ar, this message translates to:
  /// **'الزبائن و الموردين'**
  String get clientsAndSuppliers;

  /// No description provided for @helpAndSupport.
  ///
  /// In ar, this message translates to:
  /// **'المساعدة والدعم'**
  String get helpAndSupport;

  /// No description provided for @aboutApp.
  ///
  /// In ar, this message translates to:
  /// **'حول التطبيق'**
  String get aboutApp;

  /// No description provided for @logoUpdated.
  ///
  /// In ar, this message translates to:
  /// **'تم تحديث الشعار بنجاح'**
  String get logoUpdated;

  /// No description provided for @yesterday.
  ///
  /// In ar, this message translates to:
  /// **'أمس'**
  String get yesterday;

  /// No description provided for @client.
  ///
  /// In ar, this message translates to:
  /// **'العميل'**
  String get client;

  /// No description provided for @supplier.
  ///
  /// In ar, this message translates to:
  /// **'المورد'**
  String get supplier;

  /// No description provided for @unknown.
  ///
  /// In ar, this message translates to:
  /// **'بدون اسم'**
  String get unknown;

  /// No description provided for @note.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظة'**
  String get note;

  /// No description provided for @close.
  ///
  /// In ar, this message translates to:
  /// **'إغلاق'**
  String get close;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
