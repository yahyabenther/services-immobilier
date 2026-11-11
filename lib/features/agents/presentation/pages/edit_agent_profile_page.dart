import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes.dart';
import '../../../../core/constants/tunisia_governorates.dart';
import '../../../../core/errors/agent_failure.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../data/agent_media_service.dart';
import '../../domain/entities/agent_profile.dart';
import '../../domain/services/agent_profile_validator.dart';
import '../providers/agent_providers.dart';
import '../widgets/agent_gate.dart';
import '../widgets/agent_header.dart';
import '../widgets/agent_states.dart';

/// Creates (`/agent/setup`) or edits (`/agent/profile/edit`) the professional profile.
class EditAgentProfilePage extends ConsumerWidget {
  const EditAgentProfilePage({super.key, required this.setup});

  /// true -> first-time creation flow.
  final bool setup;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!setup) {
      return AgentGate(
        title: 'Edit profile',
        builder: (_, _, profile) => _AgentProfileForm(initial: profile, isCreate: false),
      );
    }

    final existing = ref.watch(agentProfileStreamProvider);
    return existing.when(
      loading: () => Scaffold(appBar: AppBar(title: const Text('Professional profile')), body: const AgentLoading()),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Professional profile')),
        body: AgentErrorView(
          message: e is AgentFailure ? e.message : const AgentFailure(AgentFailureType.unknown).message,
          onRetry: () => ref.invalidate(agentProfileStreamProvider),
        ),
      ),
      data: (profile) {
        if (profile != null) {
          // A profile already exists (e.g. just created): go to the dashboard.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) context.go(Routes.agentDashboard);
          });
          return const Scaffold(body: AgentLoading());
        }
        final user = ref.read(currentUserProvider);
        return _AgentProfileForm(
          isCreate: true,
          initial: AgentProfile(
            userId: user?.id ?? '',
            professionalName: user?.name ?? '',
            description: '',
            phone: user?.phone ?? '',
            publicEmail: user?.email ?? '',
            city: '',
          ),
        );
      },
    );
  }
}

class _AgentProfileForm extends ConsumerStatefulWidget {
  const _AgentProfileForm({required this.initial, required this.isCreate});

  final AgentProfile initial;
  final bool isCreate;

  @override
  ConsumerState<_AgentProfileForm> createState() => _AgentProfileFormState();
}

class _AgentProfileFormState extends ConsumerState<_AgentProfileForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _agencyName;
  late final TextEditingController _phone;
  late final TextEditingController _email;
  late final TextEditingController _description;
  late final TextEditingController _address;
  late final TextEditingController _website;
  late final TextEditingController _years;

  late AgentProfileKind _kind;
  late String? _city;
  late Set<String> _languages;
  late Set<String> _areas;
  late bool _showPhone;
  late bool _showEmail;
  PickedAgentImage? _newImage;
  String? _imageError;

  @override
  void initState() {
    super.initState();
    final p = widget.initial;
    _name = TextEditingController(text: p.professionalName);
    _agencyName = TextEditingController(text: p.agencyName ?? '');
    _phone = TextEditingController(text: p.phone);
    _email = TextEditingController(text: p.publicEmail);
    _description = TextEditingController(text: p.description);
    _address = TextEditingController(text: p.address ?? '');
    _website = TextEditingController(text: p.website ?? '');
    _years = TextEditingController(text: p.yearsOfExperience?.toString() ?? '');
    _kind = p.kind;
    _city = tunisiaGovernorates.contains(p.city) ? p.city : null;
    _languages = {...p.languages};
    _areas = {...p.serviceAreas};
    _showPhone = p.showPhone;
    _showEmail = p.showEmail;
    // Start every visit from a clean saving state.
    WidgetsBinding.instance.addPostFrameCallback((_) => ref.read(agentProfileFormProvider.notifier).reset());
  }

  @override
  void dispose() {
    for (final c in [_name, _agencyName, _phone, _email, _description, _address, _website, _years]) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _isAgency => _kind == AgentProfileKind.agency;

  Future<void> _pickImage() async {
    setState(() => _imageError = null);
    try {
      final picked = await ref.read(agentMediaServiceProvider).pickProfileImage();
      if (picked != null && mounted) setState(() => _newImage = picked);
    } on AgentFailure catch (e) {
      if (mounted) setState(() => _imageError = e.fieldErrors['image'] ?? e.message);
    } catch (_) {
      if (mounted) setState(() => _imageError = 'The image could not be loaded.');
    }
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final base = widget.initial;
    final draft = AgentProfile(
      userId: base.userId,
      professionalName: _name.text.trim(),
      description: _description.text.trim(),
      phone: _phone.text.trim(),
      publicEmail: _email.text.trim(),
      city: _city ?? '',
      kind: _kind,
      agencyName: _isAgency ? _agencyName.text.trim() : null,
      agencyId: base.agencyId,
      profileImageUrl: base.profileImageUrl,
      address: _address.text.trim().isEmpty ? null : _address.text.trim(),
      website: _website.text.trim().isEmpty ? null : _website.text.trim(),
      yearsOfExperience: int.tryParse(_years.text.trim()),
      languages: _languages.toList(),
      serviceAreas: _areas.toList(),
      verificationStatus: base.verificationStatus,
      showPhone: _showPhone,
      showEmail: _showEmail,
      isPublic: base.isPublic,
    );

    final ok = await ref
        .read(agentProfileFormProvider.notifier)
        .save(draft: draft, isCreate: widget.isCreate, newImage: _newImage);
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    if (ok) {
      messenger.showSnackBar(SnackBar(
        content: Text(widget.isCreate ? 'Your professional profile is ready.' : 'Profile updated.'),
      ));
      if (widget.isCreate) {
        context.go(Routes.agentDashboard);
      } else if (context.canPop()) {
        context.pop();
      }
    } else {
      final f = ref.read(agentProfileFormProvider).failure;
      final text = f == null
          ? const AgentFailure(AgentFailureType.unknown).message
          : (f.type == AgentFailureType.validation && f.fieldErrors.isNotEmpty ? f.fieldErrors.values.first : f.message);
      messenger.showSnackBar(SnackBar(content: Text(text)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final form = ref.watch(agentProfileFormProvider);
    final busy = form.isBusy;
    final title = widget.isCreate ? 'Create professional profile' : 'Edit profile';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              children: [
                if (widget.isCreate)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 16),
                    child: Text(
                      'Tell visitors who you are. Creating a profile does not verify it: verification is a separate step.',
                      style: TextStyle(color: AppColors.muted, height: 1.4),
                    ),
                  ),
                _photoPicker(busy),
                const SizedBox(height: 18),
                SegmentedButton<AgentProfileKind>(
                  segments: const [
                    ButtonSegment(value: AgentProfileKind.agent, icon: Icon(Icons.person_outline), label: Text('Individual agent')),
                    ButtonSegment(value: AgentProfileKind.agency, icon: Icon(Icons.apartment_outlined), label: Text('Agency')),
                  ],
                  selected: {_kind},
                  onSelectionChanged: busy ? null : (s) => setState(() => _kind = s.first),
                ),
                const SizedBox(height: 16),
                _field(
                  controller: _name,
                  label: 'Professional name',
                  validator: AgentProfileValidator.name,
                  action: TextInputAction.next,
                  maxLength: AgentProfileValidator.nameMax,
                  enabled: !busy,
                ),
                if (_isAgency)
                  _field(
                    controller: _agencyName,
                    label: 'Agency name',
                    validator: (v) => AgentProfileValidator.agencyName(v, isAgency: true),
                    action: TextInputAction.next,
                    maxLength: AgentProfileValidator.nameMax,
                    enabled: !busy,
                  ),
                _field(
                  controller: _phone,
                  label: 'Phone',
                  hint: '+216 XX XXX XXX',
                  keyboard: TextInputType.phone,
                  validator: AgentProfileValidator.phone,
                  action: TextInputAction.next,
                  enabled: !busy,
                ),
                _field(
                  controller: _email,
                  label: 'Public email',
                  keyboard: TextInputType.emailAddress,
                  validator: AgentProfileValidator.email,
                  action: TextInputAction.next,
                  enabled: !busy,
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: DropdownButtonFormField<String>(
                    value: _city,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'City', border: OutlineInputBorder()),
                    items: [for (final g in tunisiaGovernorates) DropdownMenuItem(value: g, child: Text(g))],
                    onChanged: busy ? null : (v) => setState(() => _city = v),
                    validator: AgentProfileValidator.city,
                  ),
                ),
                _field(
                  controller: _description,
                  label: 'Short description',
                  hint: 'Who you are and which properties you handle',
                  validator: AgentProfileValidator.description,
                  maxLines: 5,
                  maxLength: AgentProfileValidator.descriptionMax,
                  enabled: !busy,
                ),
                _field(
                  controller: _address,
                  label: _isAgency ? 'Office address (optional)' : 'Business address (optional)',
                  validator: AgentProfileValidator.address,
                  maxLength: AgentProfileValidator.addressMax,
                  enabled: !busy,
                ),
                _field(
                  controller: _website,
                  label: 'Website (optional)',
                  hint: 'https://',
                  keyboard: TextInputType.url,
                  validator: AgentProfileValidator.website,
                  enabled: !busy,
                ),
                _field(
                  controller: _years,
                  label: 'Years of experience (optional)',
                  keyboard: TextInputType.number,
                  formatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: AgentProfileValidator.years,
                  enabled: !busy,
                ),
                const SectionTitle('Languages spoken'),
                Wrap(spacing: 8, runSpacing: 4, children: [
                  for (final l in AgentProfileValidator.supportedLanguages)
                    FilterChip(
                      label: Text(l),
                      selected: _languages.contains(l),
                      onSelected: busy
                          ? null
                          : (on) => setState(() {
                                if (on && _languages.length < AgentProfileValidator.maxLanguages) _languages.add(l);
                                if (!on) _languages.remove(l);
                              }),
                    ),
                ]),
                const SectionTitle('Areas served'),
                Text('Choose up to ${AgentProfileValidator.maxServiceAreas}. Selected: ${_areas.length}',
                    style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                const SizedBox(height: 8),
                Wrap(spacing: 8, runSpacing: 4, children: [
                  for (final g in tunisiaGovernorates)
                    FilterChip(
                      label: Text(g),
                      selected: _areas.contains(g),
                      onSelected: busy
                          ? null
                          : (on) => setState(() {
                                if (on && _areas.length < AgentProfileValidator.maxServiceAreas) _areas.add(g);
                                if (!on) _areas.remove(g);
                              }),
                    ),
                ]),
                const SectionTitle('Privacy'),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Show my phone on my public profile'),
                  value: _showPhone,
                  onChanged: busy ? null : (v) => setState(() => _showPhone = v),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Show my email on my public profile'),
                  value: _showEmail,
                  onChanged: busy ? null : (v) => setState(() => _showEmail = v),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: busy ? null : _save,
                  style: FilledButton.styleFrom(padding: const EdgeInsets.all(15)),
                  child: busy
                      ? Row(mainAxisSize: MainAxisSize.min, children: [
                          const SizedBox(
                              width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                          const SizedBox(width: 10),
                          Text(form.phase == AgentSavePhase.uploading ? 'Uploading image…' : 'Saving…'),
                        ])
                      : Text(widget.isCreate ? 'Create profile' : 'Save changes'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _photoPicker(bool busy) {
    final p = widget.initial;
    final preview = _newImage;
    return Column(children: [
      Center(
        child: Stack(alignment: Alignment.bottomRight, children: [
          preview != null
              ? CircleAvatar(radius: 48, backgroundImage: MemoryImage(preview.bytes))
              : AgentAvatar(
                  name: _isAgency && _agencyName.text.trim().isNotEmpty ? _agencyName.text : _name.text,
                  imageUrl: p.profileImageUrl,
                  radius: 48,
                ),
          Material(
            color: AppColors.primary,
            shape: const CircleBorder(),
            child: IconButton(
              tooltip: _isAgency ? 'Choose logo' : 'Choose photo',
              onPressed: busy ? null : _pickImage,
              icon: const Icon(Icons.photo_camera_outlined, color: Colors.white, size: 20),
            ),
          ),
        ]),
      ),
      if (_imageError != null)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(_imageError!, style: const TextStyle(color: AppColors.error, fontSize: 12)),
        ),
    ]);
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    String? Function(String?)? validator,
    String? hint,
    TextInputType? keyboard,
    TextInputAction? action,
    int maxLines = 1,
    int? maxLength,
    List<TextInputFormatter>? formatters,
    bool enabled = true,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: TextFormField(
          controller: controller,
          enabled: enabled,
          keyboardType: keyboard,
          textInputAction: action,
          maxLines: maxLines,
          maxLength: maxLength,
          inputFormatters: formatters,
          validator: validator,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          decoration: InputDecoration(labelText: label, hintText: hint, border: const OutlineInputBorder()),
        ),
      );
}
