import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/aurora_colors.dart';
import '../../../core/theme/aurora_typography.dart';
import '../../../core/theme/aurora_spacing.dart';
import '../../../core/widgets/aurora/aurora.dart';

import '../providers/project_contractors_provider.dart';
import '../providers/project_detail_provider.dart';
import '../widgets/contractor_form_sheet.dart';
import '../widgets/contractor_skeleton.dart';
import '../widgets/contractors/story/contractors_story_view.dart';

class ProjectContractorsScreen extends ConsumerWidget {
  const ProjectContractorsScreen({super.key, required this.projectId});

  final String projectId;

  void _onAdd(BuildContext context, WidgetRef ref) =>
      showContractorFormSheet(context: context, projectId: projectId, ref: ref);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncProject = ref.watch(projectDetailProvider(projectId));
    final asyncContractors = ref.watch(projectContractorsProvider(projectId));
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;

    final body = asyncProject.when(
      loading: () => const ContractorSkeleton(),
      error: (_, _) => _ErrorState(
        onRetry: () {
          ref.invalidate(projectDetailProvider(projectId));
          ref.invalidate(projectContractorsProvider(projectId));
        },
      ),
      data: (project) => asyncContractors.when(
        loading: () => const ContractorSkeleton(),
        error: (_, _) => _ErrorState(
          onRetry: () => ref.invalidate(projectContractorsProvider(projectId)),
        ),
        data: (contractors) => contractors.isEmpty
            ? _EmptyState(onAdd: () => _onAdd(context, ref))
            : ContractorsStoryView(contractors: contractors, project: project),
      ),
    );

    if (isIOS) {
      return CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: const Text('Contractors'),
          trailing: CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => _onAdd(context, ref),
            child: const Icon(CupertinoIcons.add),
          ),
        ),
        child: SafeArea(bottom: false, child: body),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Contractors')),
      body: body,
      floatingActionButton: AuroraFAB(
        icon: Icons.add,
        onPressed: () => _onAdd(context, ref),
        tooltip: 'Add contractor',
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AuroraSpacing.screenPadH),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people_outline,
                size: 48.0, color: AuroraColors.inkTertiary),
            const SizedBox(height: AuroraSpacing.space7),
            Text('No contractors yet',
                style: AuroraType.h3, textAlign: TextAlign.center),
            const SizedBox(height: AuroraSpacing.space3),
            Text(
              'Add the people working on this project — your existing emergency contacts can be added with one tap.',
              style: AuroraType.body
                  .copyWith(color: AuroraColors.inkSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AuroraSpacing.space10),
            PrimaryButton(label: '+ Add Contractor', onPressed: onAdd),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AuroraSpacing.screenPadH),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline,
                size: 48.0, color: AuroraColors.coral),
            const SizedBox(height: AuroraSpacing.space7),
            Text("Couldn't load contractors",
                style: AuroraType.h3, textAlign: TextAlign.center),
            const SizedBox(height: AuroraSpacing.space9),
            PrimaryButton(label: 'Retry', onPressed: onRetry),
          ],
        ),
      ),
    );
  }
}
