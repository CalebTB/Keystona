import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/appliance.dart';
import 'appliances_provider.dart';

part 'appliance_detail_provider.g.dart';

/// One appliance for its detail screen, or null when it does not exist (it
/// was deleted, or the link is old). Auto-disposed with the screen.
@riverpod
Future<Appliance?> applianceDetail(Ref ref, String applianceId) =>
    ref.watch(appliancesRepositoryProvider).get(applianceId);
