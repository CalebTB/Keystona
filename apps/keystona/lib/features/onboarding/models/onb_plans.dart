import '../../../core/theme/aurora_onboarding.dart';
import 'onboarding_models.dart';

/// Plans and prices shown on OnbTrial. RevenueCat will supply the real
/// products; these match the kit until it is wired.
abstract final class OnbPlans {
  /// Length of the free trial in days.
  static final int trialDays = AuroraOnbDurations.trial.inDays;

  /// The day the trial ends. Calendar days, not 24-hour blocks, so a daylight
  /// saving change cannot shift the date.
  static DateTime trialEnd(DateTime start) =>
      DateTime(start.year, start.month, start.day + trialDays);

  static const String yearlyPrice = r'$79.99';
  static const String monthlyPrice = r'$9.99';
  static const String yearlyPerMonth = r'$6.67 a month';
  static const String yearlyPerYear = r'$79.99 a year';
  static const String monthlyPerMonth = r'$9.99 a month';

  static String finePrint(OnbPlan plan, String endDate) =>
      'Free until $endDate, then '
      '${plan == OnbPlan.yearly ? yearlyPerYear : monthlyPerMonth}. '
      'We remind you 3 days before. Cancel in the App Store any time.';
}
