import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/aurora_scale.dart';
import '../../../core/theme/aurora_spacing.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/photo_picker.dart';
import '../../../core/widgets/snackbar_service.dart';
import '../home_edit_copy.dart';
import '../providers/home_profile_provider.dart';
import '../widgets/home_common/home_page_frame.dart';
import '../widgets/home_edit/edit_skeleton.dart';
import '../widgets/home_edit/edit_top_bar.dart';
import '../widgets/home_edit/home_edit_body.dart';

/// Edit home (kit: HomeEdit): the cover photo, address, kind of home, size and
/// age, purchase details and the locked climate zone. Cancel leaves without a
/// prompt; Save turns on once something valid has changed. Route:
/// `/home/edit`.
class HomeEditScreen extends ConsumerWidget {
  const HomeEditScreen({super.key, this.pickPhoto = _pickFromPicker});

  /// Opens the photo picker. Tests pass a fake.
  final CoverPhotoPicker pickPhoto;

  static Future<File?> _pickFromPicker(BuildContext context) =>
      PhotoPicker.showPicker(context);

  void _leave(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.homeProfile);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overview = ref.watch(homeProfileProvider);
    // A refresh while editing must not rebuild the form: keep showing it.
    return overview.when(
      skipLoadingOnReload: true,
      skipLoadingOnRefresh: true,
      loading: () => _Frame(
        onCancel: () => _leave(context),
        child: const EditSkeleton(),
      ),
      error: (error, _) => _Frame(
        onCancel: () => _leave(context),
        child: error is NoPropertyException
            ? const EmptyState(
                icon: Icons.home_outlined,
                title: HomeEditCopy.noHomeTitle,
                subtitle: HomeEditCopy.noHomeBody,
              )
            : ErrorView(
                message: HomeEditCopy.loadError,
                onRetry: () => ref.invalidate(homeProfileProvider),
              ),
      ),
      data: (data) => HomeEditBody(
        key: ValueKey(data.property.id),
        overview: data,
        pickPhoto: pickPhoto,
        onSave: (edits) =>
            ref.read(homeProfileProvider.notifier).saveEdits(edits),
        onCancel: () => _leave(context),
        onSaved: () => _leave(context),
        onSaveFailed: () =>
            SnackbarService.showError(context, HomeEditCopy.saveError),
      ),
    );
  }
}

/// The top bar over a message or the skeleton, before the form exists.
class _Frame extends StatelessWidget {
  const _Frame({required this.onCancel, required this.child});

  final VoidCallback onCancel;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return Column(
      children: [
        Expanded(
          child: HomePageFrame(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                EditTopBar(onCancel: onCancel, onSave: null),
                SizedBox(height: a.of(AuroraSpacing.space8)),
                child,
              ],
            ),
          ),
        ),
      ],
    );
  }
}
