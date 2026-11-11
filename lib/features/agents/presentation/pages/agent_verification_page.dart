import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/errors/agent_failure.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../properties/domain/entities/property.dart';
import '../../data/agent_media_service.dart';
import '../../domain/entities/agent_profile.dart';
import '../../domain/entities/verification_request.dart';
import '../../domain/entities/verification_upload.dart';
import '../providers/agent_providers.dart';
import '../widgets/agent_gate.dart';
import '../widgets/agent_states.dart';
import '../widgets/verification_status_card.dart';

/// `/agent/verification` (spec §11.3): status, submission date, rejection
/// reason, next action, and the resubmit form when the state machine allows it.
/// Documents go to PRIVATE storage and are never shown in any public screen.
class AgentVerificationPage extends StatelessWidget {
  const AgentVerificationPage({super.key});

  @override
  Widget build(BuildContext context) => AgentGate(
        title: 'Verification',
        builder: (context, ref, profile) => _VerificationBody(profile: profile),
      );
}

class _VerificationBody extends ConsumerStatefulWidget {
  const _VerificationBody({required this.profile});

  final AgentProfile profile;

  @override
  ConsumerState<_VerificationBody> createState() => _VerificationBodyState();
}

class _VerificationBodyState extends ConsumerState<_VerificationBody> {
  final Map<VerificationCategory, List<PickedAgentImage>> _picked = {};
  String? _error;

  Set<VerificationCategory> get _required => AgentVerificationPolicy.requiredFor(isAgency: widget.profile.isAgency);

  bool get _complete => _required.every((c) => (_picked[c] ?? const []).isNotEmpty);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => ref.read(agentProfileFormProvider.notifier).reset());
  }

  Future<void> _add(VerificationCategory category, ImageSource source) async {
    setState(() => _error = null);
    final list = _picked[category] ?? [];
    if (list.length >= AgentVerificationPolicy.maxFilesPerCategory) {
      setState(() => _error = 'You can add up to ${AgentVerificationPolicy.maxFilesPerCategory} files per document type.');
      return;
    }
    try {
      final img = await ref.read(agentMediaServiceProvider).pickDocument(source);
      if (img != null && mounted) setState(() => _picked[category] = [...list, img]);
    } on AgentFailure catch (e) {
      if (mounted) setState(() => _error = e.fieldErrors['document'] ?? e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'The file could not be loaded.');
    }
  }

  Future<void> _submit() async {
    final docs = <VerificationUpload>[
      for (final e in _picked.entries)
        for (final img in e.value) VerificationUpload(category: e.key, fileName: img.name, bytes: img.bytes),
    ];
    final ok = await ref
        .read(agentProfileFormProvider.notifier)
        .submitVerification(profile: widget.profile, documents: docs);
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    if (ok) {
      setState(_picked.clear);
      messenger.showSnackBar(const SnackBar(content: Text('Your documents were submitted for review.')));
    } else {
      final f = ref.read(agentProfileFormProvider).failure;
      messenger.showSnackBar(SnackBar(
        content: Text(f?.message ?? const AgentFailure(AgentFailureType.verificationUploadFailed).message),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final request = ref.watch(agentVerificationProvider).value;
    final status = effectiveVerificationStatus(widget.profile.verificationStatus, request);
    final busy = ref.watch(agentProfileFormProvider).isBusy;
    final canSubmit = canSubmitVerification(status);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Verification')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            children: [
              VerificationStatusCard(status: status, request: request),
              if (!canSubmit) ...[
                const SizedBox(height: 14),
                Text(
                  status == VerificationStatus.pending
                      ? 'An administrator is reviewing your documents. You will be notified of the decision.'
                      : 'Your professional profile is verified.',
                  style: const TextStyle(color: AppColors.muted, height: 1.4),
                ),
              ] else ...[
                SectionTitle(status == VerificationStatus.notSubmitted ? 'Submit your documents' : 'Resubmit your documents'),
                const Text(
                  'Your documents are stored privately and are only visible to you and ImmoFind administrators. '
                  'They never appear on your public profile.',
                  style: TextStyle(color: AppColors.muted, height: 1.4, fontSize: 13),
                ),
                const SizedBox(height: 12),
                for (final c in _required) _CategoryPicker(
                  category: c,
                  files: _picked[c] ?? const [],
                  busy: busy,
                  onAdd: (src) => _add(c, src),
                  onRemove: (i) => setState(() => _picked[c] = [...?_picked[c]]..removeAt(i)),
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 12)),
                  ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: (_complete && !busy) ? _submit : null,
                  style: FilledButton.styleFrom(padding: const EdgeInsets.all(15)),
                  child: busy
                      ? const Row(mainAxisSize: MainAxisSize.min, children: [
                          SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                          SizedBox(width: 10),
                          Text('Uploading…'),
                        ])
                      : const Text('Submit for review'),
                ),
                if (!_complete)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text('Add at least one file for every document type above.',
                        style: TextStyle(fontSize: 12, color: AppColors.muted)),
                  ),
              ],
              const SizedBox(height: 16),
              TextButton(onPressed: () => context.pop(), child: const Text('Back')),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryPicker extends StatelessWidget {
  const _CategoryPicker({
    required this.category,
    required this.files,
    required this.busy,
    required this.onAdd,
    required this.onRemove,
  });

  final VerificationCategory category;
  final List<PickedAgentImage> files;
  final bool busy;
  final void Function(ImageSource) onAdd;
  final void Function(int) onRemove;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: AgentCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(category.label, style: const TextStyle(fontWeight: FontWeight.w800))),
              if (files.isNotEmpty) const Icon(Icons.check_circle, color: AppColors.success, size: 20),
            ]),
            const SizedBox(height: 8),
            if (files.isNotEmpty)
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (var i = 0; i < files.length; i++)
                  Stack(children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.memory(Uint8List.fromList(files[i].bytes), width: 72, height: 72, fit: BoxFit.cover),
                    ),
                    Positioned(
                      right: 0,
                      top: 0,
                      child: InkWell(
                        onTap: busy ? null : () => onRemove(i),
                        child: const CircleAvatar(radius: 11, backgroundColor: Colors.black54, child: Icon(Icons.close, size: 14, color: Colors.white)),
                      ),
                    ),
                  ]),
              ]),
            Wrap(spacing: 8, children: [
              TextButton.icon(
                onPressed: busy ? null : () => onAdd(ImageSource.camera),
                icon: const Icon(Icons.photo_camera_outlined, size: 18),
                label: const Text('Take photo'),
              ),
              TextButton.icon(
                onPressed: busy ? null : () => onAdd(ImageSource.gallery),
                icon: const Icon(Icons.photo_library_outlined, size: 18),
                label: const Text('Choose file'),
              ),
            ]),
          ]),
        ),
      );
}
