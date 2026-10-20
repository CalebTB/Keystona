import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/widgets/aurora/aurora_sheet.dart';
import '../../edit/home_edit_form.dart';
import '../../home_edit_copy.dart';
import '../../home_profile_format.dart';
import '../../models/home_profile_overview.dart';
import '../../models/property_edits.dart';
import '../../models/property_kind.dart';
import '../shared/mono_section_label.dart';
import 'address_section.dart';
import 'climate_card.dart';
import 'edit_photo_row.dart';
import 'edit_top_bar.dart';
import 'kind_of_home_grid.dart';
import 'month_year_sheet.dart';
import 'purchase_section.dart';
import 'size_age_section.dart';

/// Picks a cover photo; null when the person cancels.
typedef CoverPhotoPicker = Future<File?> Function(BuildContext context);

/// Writes the edits; throws when the save fails.
typedef SaveEdits = Future<void> Function(PropertyEdits edits);

/// The HomeEdit form for a loaded property. It owns the [HomeEditForm]: later
/// refreshes of the overview do not touch what the person has typed.
class HomeEditBody extends StatefulWidget {
  const HomeEditBody({
    super.key,
    required this.overview,
    required this.pickPhoto,
    required this.onSave,
    required this.onCancel,
    required this.onSaved,
    required this.onSaveFailed,
  });

  final HomeProfileOverview overview;
  final CoverPhotoPicker pickPhoto;
  final SaveEdits onSave;
  final VoidCallback onCancel;
  final VoidCallback onSaved;
  final VoidCallback onSaveFailed;

  @override
  State<HomeEditBody> createState() => _HomeEditBodyState();
}

class _HomeEditBodyState extends State<HomeEditBody> {
  late final HomeEditForm _form = HomeEditForm(widget.overview.property);
  bool _saving = false;

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_form.canSave) return;
    setState(() => _saving = true);
    try {
      await widget.onSave(_form.toEdits());
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      widget.onSaveFailed();
      return;
    }
    if (!mounted) return;
    widget.onSaved();
  }

  Future<void> _pickPhoto() async {
    final file = await widget.pickPhoto(context);
    if (file != null && mounted) _form.setPhoto(file);
  }

  Future<void> _pickGarage() async {
    final kinds = HomeEditCopy.garageKinds;
    final choice = await AuroraSheet.actionSheet(
      context,
      title: HomeEditCopy.garageSheet,
      actions: [
        for (final k in kinds) AuroraSheetAction(label: k.label),
        const AuroraSheetAction(label: HomeEditCopy.garageNone),
      ],
    );
    if (choice == null || !mounted) return;
    _form.setGarage(choice < kinds.length ? kinds[choice].value : null);
  }

  Future<void> _pickDate() async {
    final choice = await MonthYearSheet.show(
      context,
      initial: _form.purchaseDate,
      now: DateTime.now(),
    );
    if (choice != null && mounted) _form.setPurchaseDate(choice.date);
  }

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return Scaffold(
      backgroundColor: AuroraColors.paper,
      body: SafeArea(
        child: Column(
          children: [
            ListenableBuilder(
              listenable: _form,
              builder: (context, _) => EditTopBar(
                onCancel: widget.onCancel,
                onSave: _form.canSave && !_saving ? _save : null,
                saving: _saving,
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: a.contentMaxWidth),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        a.of(AuroraSpacing.screenPadH),
                        a.of(AuroraSpacing.space8),
                        a.of(AuroraSpacing.screenPadH),
                        a.of(AuroraSpacing.space10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        spacing: a.of(AuroraSpacing.space9),
                        children: [
                          _Photo(
                            form: _form,
                            photoUrl: widget.overview.exteriorPhotoSignedUrl,
                            onPick: _pickPhoto,
                          ),
                          AddressSection(form: _form),
                          _KindOfHome(form: _form),
                          SizeAgeSection(
                            form: _form,
                            onPickGarage: _pickGarage,
                          ),
                          PurchaseSection(form: _form, onPickDate: _pickDate),
                          _Climate(form: _form),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Photo extends StatelessWidget {
  const _Photo({
    required this.form,
    required this.photoUrl,
    required this.onPick,
  });

  final HomeEditForm form;
  final String? photoUrl;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: a.of(AuroraSpacing.space3),
      children: [
        const MonoSectionLabel(HomeEditCopy.photo),
        ListenableBuilder(
          listenable: form,
          builder: (context, _) => EditPhotoRow(
            photoUrl: photoUrl,
            localPhoto: form.photo,
            onPick: onPick,
          ),
        ),
      ],
    );
  }
}

class _KindOfHome extends StatelessWidget {
  const _KindOfHome({required this.form});

  final HomeEditForm form;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: a.of(AuroraSpacing.space5),
      children: [
        const MonoSectionLabel(HomeEditCopy.kindOfHome),
        ListenableBuilder(
          listenable: form,
          builder: (context, _) => KindOfHomeGrid(
            choices: PropertyKinds.choices,
            selected: form.kind,
            onChanged: form.setKind,
          ),
        ),
      ],
    );
  }
}

class _Climate extends StatelessWidget {
  const _Climate({required this.form});

  final HomeEditForm form;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: a.of(AuroraSpacing.space3),
      children: [
        const MonoSectionLabel(HomeEditCopy.climate),
        ListenableBuilder(
          listenable: form,
          builder: (context, _) => ClimateCard(
            title:
                HomeFormat.climateLabel(form.initial) ??
                HomeEditCopy.climateUnset,
            note: form.zipHelp,
          ),
        ),
      ],
    );
  }
}
