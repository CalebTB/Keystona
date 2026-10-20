import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_typography.dart';
import '../../../../services/providers/service_providers.dart';
import '../../../subscription/providers/subscription_provider.dart';
import '../../providers/documents_provider.dart';
import 'forward_email_card.dart';
import 'upload_source_row.dart';

/// Where a new document can come from.
enum UploadSource { photo, library, file, smartScan }

/// Contents of the "Add a document" sheet (kit: DocAddFrom).
class AddFromSheetBody extends ConsumerWidget {
  const AddFromSheetBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final a = context.aurora;
    void pick(UploadSource source) => Navigator.of(context).pop(source);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Add a document',
          style: AuroraType.h1.copyWith(fontWeight: FontWeight.w800),
        ),
        const _PlanLine(),
        SizedBox(height: a.of(AuroraSpacing.space3)),
        UploadSourceRow(
          icon: Icons.photo_camera_outlined,
          title: 'Take a photo',
          subtitle: 'Snap a paper document · several pages is fine',
          showDivider: false,
          onTap: () => pick(UploadSource.photo),
        ),
        UploadSourceRow(
          icon: Icons.image_outlined,
          title: 'Choose from Photos',
          subtitle: 'A picture you already took',
          onTap: () => pick(UploadSource.library),
        ),
        UploadSourceRow(
          icon: Icons.folder_outlined,
          title: 'Choose a file',
          subtitle: 'PDFs from Files, iCloud or email downloads',
          onTap: () => pick(UploadSource.file),
        ),
        UploadSourceRow(
          icon: Icons.auto_awesome,
          title: 'Smart scan',
          subtitle:
              'Snap it and we fill in the name, dates and what it belongs to',
          badge: '★ PREMIUM',
          highlight: true,
          onTap: () => pick(UploadSource.smartScan),
        ),
        const ForwardEmailCard(),
      ],
    );
  }
}

/// "12 OF 25 ON FREE": how full the free plan is. Premium has no limit to show.
class _PlanLine extends ConsumerWidget {
  const _PlanLine();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPremium = ref.watch(isPremiumProvider);
    final used = ref.watch(documentQuotaCountProvider).value;
    if (isPremium || used == null) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.only(top: context.aurora.of(AuroraSpacing.space1)),
      child: Text(
        '$used OF $kFreeDocumentLimit ON FREE',
        style: AuroraType.meta.copyWith(color: AuroraColors.inkSecondary),
      ),
    );
  }
}
