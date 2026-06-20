import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../services/supabase_service.dart';
import '../../../models/project.dart';
import '../../../models/project_contractor.dart';
import '../../contractor_form_sheet.dart';
import 'contractor_story_card.dart';

/// Full-screen swipeable card-stack view for project contractors.
///
/// One card per contractor, swiped horizontally via [PageView.builder].
/// Data comes entirely from constructor params — no provider needed.
class ContractorsStoryView extends ConsumerStatefulWidget {
  const ContractorsStoryView({
    super.key,
    required this.contractors,
    required this.project,
  });

  final List<ProjectContractor> contractors;
  final Project project;

  @override
  ConsumerState<ContractorsStoryView> createState() =>
      _ContractorsStoryViewState();
}

class _ContractorsStoryViewState extends ConsumerState<ContractorsStoryView> {
  final _controller = PageController();
  int _currentPage = 0;
  String _reviewerName = '';

  @override
  void initState() {
    super.initState();
    _loadReviewerName();
  }

  void _openDocs(ProjectContractor contractor) {
    context.push(
      '/projects/${widget.project.id}/documents',
      extra: {
        'contractorId': contractor.contactId,
        'contractorName': contractor.contactName,
      },
    );
  }

  Future<void> _openEdit(ProjectContractor contractor) async {
    await showContractorFormSheet(
      context: context,
      projectId: widget.project.id,
      ref: ref,
      existingContractor: contractor,
    );
  }

  void _loadReviewerName() {
    final user = SupabaseService.client.auth.currentUser;
    if (user == null) return;

    SupabaseService.client
        .from('profiles')
        .select('display_name')
        .eq('id', user.id)
        .maybeSingle()
        .then((row) {
      if (!mounted) return;
      final name = row?['display_name'] as String?;
      if (name != null && name.isNotEmpty) {
        setState(() => _reviewerName = name);
      }
    }).catchError((_) {
      // Non-critical — quote attribution falls back to 'You'.
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final contractors = widget.contractors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Eyebrow + H1 ────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Plum/olive dot per spec
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: AppColors.plum,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${widget.project.name.toUpperCase()} · THE CAST',
                      style: const TextStyle(
                        fontFamily: 'IBMPlexMono',
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: AppColors.textSecondary,
                        height: 1.2,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // ── Card PageView ────────────────────────────────────────────────────
        Expanded(
          child: PageView.builder(
            controller: _controller,
            itemCount: contractors.length,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemBuilder: (_, i) => ContractorStoryCard(
              key: ValueKey(contractors[i].id),
              contractor: contractors[i],
              project: widget.project,
              isLead: i == 0,
              reviewerName: _reviewerName,
              onEdit: () => _openEdit(contractors[i]),
              onDocs: () => _openDocs(contractors[i]),
            ),
          ),
        ),

        // ── Page indicator dots ──────────────────────────────────────────────
        if (contractors.length > 1)
          _PageDots(
            count: contractors.length,
            current: _currentPage,
          ),

        const SizedBox(height: 16),
      ],
    );
  }
}

// ── Page dots ──────────────────────────────────────────────────────────────────

class _PageDots extends StatelessWidget {
  const _PageDots({required this.count, required this.current});

  final int count;
  final int current;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(count, (i) {
          final isActive = i == current;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: isActive ? 16 : 6,
            height: 6,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              color: AppColors.textPrimary.withValues(alpha: isActive ? 0.6 : 0.2),
              borderRadius: BorderRadius.circular(3),
            ),
          );
        }),
      ),
    );
  }
}
