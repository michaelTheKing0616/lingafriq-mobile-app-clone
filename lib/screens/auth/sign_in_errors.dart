import 'package:dio/dio.dart';

/// Every sign-in failure resolves to one of these codes, and every code has
/// learner-facing copy. Raw codes are never shown.
const signInErrorCodes = [
  'provider_invalid',
  'provider_cancelled',
  'sign_in_invalid',
  'network',
  'timeout',
  'rate_limited',
  'link_invalid',
  'link_expired',
  'email_invalid',
  'account_disabled',
  'account_exists',
  'server',
  'unknown',
];

const _copy = <String, Map<String, String>>{
  'en': {
    'provider_invalid':
        "We couldn't finish signing you in with that account. Try again, or use an email link.",
    'provider_cancelled': 'Sign-in was cancelled. Pick a way to continue.',
    'sign_in_invalid':
        "Something went wrong on our side. Your progress is safe. Try again.",
    'network': "You're offline. Connect to the internet and try again.",
    'timeout': 'That took too long. Check your connection and try again.',
    'rate_limited': 'Too many tries. Wait a minute, then try again.',
    'link_invalid': "That link didn't work. Ask for a new one.",
    'link_expired': 'That link has expired. Ask for a new one.',
    'email_invalid': 'Check the email address and try again.',
    'account_disabled': 'This account is paused. Contact support for help.',
    'account_exists':
        'This email already has an account. Sign in the way you did before.',
    'server':
        "Our servers are having trouble. Your progress is safe. Try again soon.",
    'unknown': "We couldn't sign you in. Try again, or use an email link.",
  },
  'ar': {
    'provider_invalid':
        'تعذّر إكمال تسجيل الدخول بهذا الحساب. حاول مجددًا أو استخدم رابط البريد.',
    'provider_cancelled': 'أُلغي تسجيل الدخول. اختر طريقة للمتابعة.',
    'sign_in_invalid': 'حدث خطأ من جهتنا. تقدّمك محفوظ. حاول مجددًا.',
    'network': 'أنت غير متصل. اتصل بالإنترنت وحاول مجددًا.',
    'timeout': 'استغرق الأمر وقتًا طويلًا. تحقّق من اتصالك وحاول مجددًا.',
    'rate_limited': 'محاولات كثيرة. انتظر دقيقة ثم حاول مجددًا.',
    'link_invalid': 'لم يعمل هذا الرابط. اطلب رابطًا جديدًا.',
    'link_expired': 'انتهت صلاحية هذا الرابط. اطلب رابطًا جديدًا.',
    'email_invalid': 'تحقّق من عنوان البريد وحاول مجددًا.',
    'account_disabled': 'هذا الحساب موقوف. تواصل مع الدعم.',
    'account_exists': 'لهذا البريد حساب بالفعل. سجّل الدخول بالطريقة السابقة.',
    'server': 'خوادمنا تواجه مشكلة. تقدّمك محفوظ. حاول لاحقًا.',
    'unknown': 'تعذّر تسجيل دخولك. حاول مجددًا أو استخدم رابط البريد.',
  },
};

const _byStatus = {
  400: 'sign_in_invalid',
  401: 'provider_invalid',
  403: 'account_disabled',
  404: 'link_invalid',
  409: 'account_exists',
  410: 'link_expired',
  422: 'email_invalid',
  429: 'rate_limited',
};

/// Maps any thrown sign-in error (or a code string) to a known code.
String signInErrorCode(Object error) {
  if (error is String) {
    return signInErrorCodes.contains(error) ? error : 'unknown';
  }
  if (error is StateError) return signInErrorCode(error.message);
  if (error is DioException) {
    switch (error.type) {
      case DioExceptionType.connectionError:
        return 'network';
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return 'timeout';
      default:
        break;
    }
    final data = error.response?.data;
    final code = data is Map && data['error'] is Map
        ? data['error']['code']
        : null;
    if (code is String && signInErrorCodes.contains(code)) return code;
    final status = error.response?.statusCode ?? 0;
    if (status >= 500) return 'server';
    return _byStatus[status] ?? 'unknown';
  }
  return 'unknown';
}

/// Learner-facing copy for [code] in [languageCode], English otherwise.
String signInErrorText(String code, String? languageCode) {
  final table = _copy[languageCode] ?? _copy['en']!;
  return table[code] ?? table['unknown']!;
}
