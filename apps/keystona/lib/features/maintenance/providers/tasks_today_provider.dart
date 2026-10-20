import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/task_schedule.dart';

/// Today's date (midnight, local). One place to override in tests.
final tasksTodayProvider = Provider.autoDispose<DateTime>(
  (ref) => TaskSchedule.dayOf(DateTime.now()),
);
