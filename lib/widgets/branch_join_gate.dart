import 'dart:async';

import 'package:daalsetu/modules/profile/controller/profile_controller.dart';
import 'package:daalsetu/modules/profile/model/profile_model.dart';
import 'package:daalsetu/services/seller_services.dart';
import 'package:daalsetu/utils/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// KYC approved -> Branch Code -> branch admin approval -> trading (same rule and data as the web).
///
/// Wraps the logged-in app (buyer / seller / transporter). It reads the profile's branch state, asks for a
/// branch code once KYC is approved, shows the pending / rejected status (with the admin's remark), and
/// re-reads the profile when the app comes back to the foreground (and every minute while a request is
/// pending), so trading opens as soon as the admin approves. The server enforces the rule either way.
class BranchJoinGate extends StatefulWidget {
  const BranchJoinGate({super.key, required this.child});

  final Widget child;

  @override
  State<BranchJoinGate> createState() => _BranchJoinGateState();
}

class _BranchJoinGateState extends State<BranchJoinGate> with WidgetsBindingObserver {
  late final ProfileController _profile;
  Timer? _pendingPoll;
  Worker? _profileWorker;

  /// The dialog opens once per state (a new rejection asks again), not on every rebuild.
  String? _promptedFor;
  String? _lastStatus;
  bool _dialogOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _profile = Get.isRegistered<ProfileController>() ? Get.find<ProfileController>() : Get.put(ProfileController());
    _profileWorker = ever<ProfileModel?>(_profile.profile, _onProfile);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_profile.profile.value != null) _onProfile(_profile.profile.value);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pendingPoll?.cancel();
    _profileWorker?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Back in the app: the admin may have approved the KYC or the branch meanwhile.
    if (state == AppLifecycleState.resumed) _profile.fetchProfile(silent: true);
  }

  void _onProfile(ProfileModel? user) {
    if (!mounted || user == null) return;
    final status = user.branchStatus;
    if (_lastStatus != null && _lastStatus != 'approved' && status == 'approved') {
      AppSnackbar.showSuccess(
        title: 'Branch approved',
        message: 'You joined branch ${user.branchCode}. Trading is now open.',
      );
    }
    _lastStatus = status;

    _pendingPoll?.cancel();
    if (status == 'pending') {
      _pendingPoll = Timer.periodic(const Duration(minutes: 1), (_) => _profile.fetchProfile(silent: true));
    }

    final key = '${user.id}|$status|${user.branchReviewNote}';
    if (user.needsBranchCode && _promptedFor != key && !_dialogOpen) {
      _promptedFor = key;
      _askForBranchCode(user);
    }
    setState(() {});
  }

  Future<void> _askForBranchCode(ProfileModel user) async {
    _dialogOpen = true;
    await showDialog<void>(
      context: context,
      builder: (_) => _BranchCodeDialog(
        rejectedCode: user.branchStatus == 'rejected' ? user.branchCode : null,
        rejectionNote: user.branchReviewNote,
        onSent: () => _profile.fetchProfile(silent: true),
      ),
    );
    _dialogOpen = false;
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final user = _profile.profile.value;
      // Branch status after KYC approval, otherwise the server's reason trading is closed (KYC pending,
      // KYC rejected, no company yet): the app shows the same restriction the server enforces.
      final message = user?.branchMessage ??
          ((user != null && !user.canPerformActions && user.actionBlockMessage.trim().isNotEmpty)
              ? user.actionBlockMessage
              : null);
      if (user == null || message == null) return widget.child;
      return Column(
        children: [
          SafeArea(bottom: false, child: _banner(context, user, message)),
          Expanded(child: MediaQuery.removePadding(context: context, removeTop: true, child: widget.child)),
        ],
      );
    });
  }

  Widget _banner(BuildContext context, ProfileModel user, String message) {
    final theme = Theme.of(context);
    final rejected = user.branchStatus == 'rejected';
    final color = rejected ? theme.colorScheme.error : const Color(0xFFE65100);
    return Material(
      key: const Key('branch-join-banner'),
      color: color.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
        child: Row(
          children: [
            Icon(rejected ? Icons.error_outline : Icons.account_tree_outlined, color: color, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: theme.textTheme.bodySmall?.copyWith(color: color, fontWeight: FontWeight.w600),
              ),
            ),
            if (user.needsBranchCode)
              TextButton(
                onPressed: () => _askForBranchCode(user),
                child: const Text('Enter code'),
              )
            else
              IconButton(
                tooltip: 'Check status',
                icon: Icon(Icons.refresh_rounded, color: color),
                onPressed: () => _profile.fetchProfile(silent: true),
              ),
          ],
        ),
      ),
    );
  }
}

class _BranchCodeDialog extends StatefulWidget {
  const _BranchCodeDialog({required this.onSent, this.rejectedCode, this.rejectionNote = ''});

  final VoidCallback onSent;
  final String? rejectedCode;
  final String rejectionNote;

  @override
  State<_BranchCodeDialog> createState() => _BranchCodeDialogState();
}

class _BranchCodeDialogState extends State<_BranchCodeDialog> {
  final _code = TextEditingController();
  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final code = _code.text.trim().toUpperCase();
    if (code.isEmpty) {
      setState(() => _error = 'Please enter the branch code.');
      return;
    }
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      final response = await SellerServices.requestBranchByCode(code);
      if (!mounted) return;
      if (response['success'] == false) {
        setState(() => _error = (response['message'] ?? 'Could not send the request.').toString());
        return;
      }
      Navigator.of(context).pop();
      AppSnackbar.showSuccess(
        title: 'Request sent',
        message: (response['message'] ?? 'Your branch joining request was sent for approval.').toString(),
      );
      widget.onSent();
    } catch (error) {
      if (mounted) setState(() => _error = error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      key: const Key('branch-code-dialog'),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Join your branch'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your KYC is approved. Enter the branch code from your branch to send a joining request. '
            'Trading opens once the branch admin approves it.',
          ),
          if (widget.rejectedCode != null) ...[
            const SizedBox(height: 10),
            Text(
              'Your request for ${widget.rejectedCode} was rejected: '
              '${widget.rejectionNote.isEmpty ? 'Not specified' : widget.rejectionNote}',
              style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 13),
            ),
          ],
          const SizedBox(height: 14),
          TextField(
            controller: _code,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              labelText: 'Branch Code',
              hintText: 'e.g. AMA462M',
              errorText: _error,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onSubmitted: (_) => _send(),
          ),
        ],
      ),
      actions: [
        ElevatedButton(
          onPressed: _sending ? null : _send,
          child: _sending
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Send Request'),
        ),
        OutlinedButton(
          onPressed: _sending ? null : () => Navigator.of(context).pop(),
          child: const Text('Later'),
        ),
      ],
    );
  }
}
