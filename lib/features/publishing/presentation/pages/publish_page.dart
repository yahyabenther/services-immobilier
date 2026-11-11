import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/data/owner_role_service.dart';
import '../../../auth/domain/entities/auth_user.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../property_discovery/domain/publish_permission.dart';
import '../../domain/services/listing_validator.dart';
import '../providers/publishing_provider.dart';
import '../widgets/amenities_step.dart';
import '../widgets/description_step.dart';
import '../widgets/details_step.dart';
import '../widgets/location_step.dart';
import '../widgets/property_photos_picker.dart';
import '../widgets/property_preview.dart';
import '../widgets/property_type_step.dart';

/// Module 08 entry point (route `/publish`). A 7-screen wizard; the Firestore rules,
/// not this screen, decide who may really publish.
class PublishPage extends ConsumerWidget {
  const PublishPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (!canPublishProperty(user)) return _NotAllowedView(user: user);

    final s = ref.watch(publishingControllerProvider);
    final c = ref.read(publishingControllerProvider.notifier);
    if (s.isSuccess) return _SuccessView(onReset: c.reset);

    Future<void> leave() async {
      final go = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Discard this listing?'),
          content: const Text('The information you entered will be lost.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Keep editing'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Discard'),
            ),
          ],
        ),
      );
      if (go == true && context.mounted) {
        c.reset();
        context.canPop() ? context.pop() : context.go(Routes.home);
      }
    }

    return PopScope(
      // Free to leave only when nothing would be lost.
      canPop: !s.draft.hasContent && !s.isBusy,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop || s.isBusy) return;
        // System back = previous step first, discard prompt from the first screen.
        if (s.step.previous != null || s.returnToPreview) {
          c.back();
        } else {
          leave();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Publish property'),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(4),
            child: LinearProgressIndicator(
              value: (s.step.index + 1) / PublishStep.values.length,
              minHeight: 4,
            ),
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Step ${s.step.index + 1} of ${PublishStep.values.length} · ${s.step.label}',
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontWeight: FontWeight.w600,
                      fontSize: 12.5,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  key: ValueKey(
                    s.step,
                  ), // fresh scroll position + fresh text fields per step
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.all(20),
                  child: switch (s.step) {
                    PublishStep.type => const PropertyTypeStep(),
                    PublishStep.location => const LocationStep(),
                    PublishStep.details => const DetailsStep(),
                    PublishStep.amenities => const AmenitiesStep(),
                    PublishStep.photos => const PropertyPhotosPicker(),
                    PublishStep.description => const DescriptionStep(),
                    PublishStep.preview => const PropertyPreview(),
                  },
                ),
              ),
              _BottomBar(
                state: s,
                onBack: c.back,
                onNext: c.next,
                onSubmit: c.submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.state,
    required this.onBack,
    required this.onNext,
    required this.onSubmit,
  });
  final PublishingState state;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final Future<void> Function() onSubmit;

  String get _busyLabel => state.phase == PublishPhase.uploading
      ? 'Uploading photos ${state.uploadDone}/${state.uploadTotal}…'
      : 'Submitting…';

  @override
  Widget build(BuildContext context) {
    final isPreview = state.step == PublishStep.preview;
    final canGoBack = state.step.previous != null || state.returnToPreview;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: Row(
        children: [
          if (canGoBack) ...[
            OutlinedButton(
              onPressed: state.isBusy ? null : onBack,
              style: OutlinedButton.styleFrom(minimumSize: const Size(90, 48)),
              child: const Text('Back'),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: FilledButton(
              // Disabled while busy: this is what prevents double submission.
              onPressed: state.isBusy ? null : (isPreview ? onSubmit : onNext),
              style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
              child: state.isBusy
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(_busyLabel),
                      ],
                    )
                  : Text(
                      isPreview
                          ? (state.message != null
                                ? 'Try again'
                                : 'Submit for review')
                          : (state.returnToPreview ? 'Done' : 'Continue'),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SuccessView extends StatelessWidget {
  const _SuccessView({required this.onReset});

  /// Clears the form. Also called when the user leaves with the system back button,
  /// so the next visit to /publish starts from an empty form, not this screen.
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) => PopScope(
    onPopInvokedWithResult: (didPop, _) {
      if (didPop) Future.microtask(onReset);
    },
    child: Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  size: 72,
                  color: AppColors.success,
                ),
                const SizedBox(height: 16),
                Text(
                  'Listing submitted',
                  style: Theme.of(context).textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF4D6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Status: pending review',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF8A6100),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Our team will review your listing. It will be visible to other users only after it is approved.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.muted, height: 1.4),
                ),
                const SizedBox(height: 28),
                FilledButton(
                  onPressed: () {
                    context.go(Routes.home);
                    Future.microtask(onReset);
                  },
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  child: const Text('Back to home'),
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: onReset,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  child: const Text('Publish another property'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _NotAllowedView extends ConsumerStatefulWidget {
  const _NotAllowedView({required this.user});
  final AuthUser? user;

  @override
  ConsumerState<_NotAllowedView> createState() => _NotAllowedViewState();
}

class _NotAllowedViewState extends ConsumerState<_NotAllowedView> {
  bool _busy = false;
  String? _error;

  Future<void> _becomeOwner() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(ownerRoleServiceProvider).becomeOwner();
      // Success: the profile stream delivers role=owner and PublishPage rebuilds
      // into the wizard, replacing this widget.
    } on BecomeOwnerException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String get _reason {
    final user = widget.user;
    if (user == null) return 'Please sign in to publish a property.';
    if (!user.emailVerified) {
      return 'Verify your email address before publishing.';
    }
    if (canBecomeOwner(user)) {
      return 'Publish as an owner. Every listing is reviewed by our team before it appears.';
    }
    return 'Your account is not allowed to publish listings.';
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Publish property')),
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline, size: 56, color: AppColors.muted),
            const SizedBox(height: 14),
            Text(
              _reason,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, height: 1.4),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
            ],
            const SizedBox(height: 20),
            if (canBecomeOwner(widget.user)) ...[
              FilledButton(
                onPressed: _busy ? null : _becomeOwner,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: _busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Become an owner'),
              ),
              const SizedBox(height: 10),
            ],
            OutlinedButton(
              onPressed: () =>
                  context.canPop() ? context.pop() : context.go(Routes.home),
              child: const Text('Go back'),
            ),
          ],
        ),
      ),
    ),
  );
}