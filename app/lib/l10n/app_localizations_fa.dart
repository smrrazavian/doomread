// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Persian (`fa`).
class AppLocalizationsFa extends AppLocalizations {
  AppLocalizationsFa([String locale = 'fa']) : super(locale);

  @override
  String get appTitle => 'باز گوشی؟!';

  @override
  String get navTonight => 'امشب';

  @override
  String get navBooks => 'کتاب‌ها';

  @override
  String get navBuilding => 'ساختمون';

  @override
  String get navFriends => 'دوستا';

  @override
  String get tonightEmpty => 'کتابی که داری می‌خونی رو اضافه کن';

  @override
  String get settings => 'تنظیمات';

  @override
  String get language => 'زبان';

  @override
  String get account => 'حساب کاربری';

  @override
  String get accountSignedOutHint =>
      'با حساب کاربری، کتاب‌خوندنت روی همهٔ دستگاه‌هات باهاته. بدون حساب هم برنامه کامل کار می‌کنه.';

  @override
  String get accountUsername => 'نام کاربری';

  @override
  String get accountPassword => 'رمز';

  @override
  String get accountSignIn => 'ورود';

  @override
  String get accountSignUp => 'ثبت‌نام';

  @override
  String get accountSignOut => 'خروج';

  @override
  String accountSignedInAs(String username) {
    return 'با $username وارد شدی';
  }

  @override
  String get accountErrorUsername =>
      'نام کاربری باید ۳ تا ۳۲ حرف کوچیک انگلیسی، عدد، _ یا . باشه.';

  @override
  String get accountErrorPassword => 'رمز حداقل ۸ تا کاراکتر باشه.';

  @override
  String get accountErrorTaken => 'این نام کاربری قبلاً گرفته شده.';

  @override
  String get accountErrorWrong => 'نام کاربری یا رمز اشتباهه.';

  @override
  String get accountErrorRejected => 'سرور قبولش نکرد. دوباره امتحان کن.';

  @override
  String get accountErrorUnreachable =>
      'به سرور وصل نمی‌شه. بقیهٔ برنامه کار می‌کنه؛ بعداً دوباره امتحان کن.';
}
