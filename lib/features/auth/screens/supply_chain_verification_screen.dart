import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/session/session_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/models.dart';

/// Aggregator/Transporter/Distributor accounts can touch OTHER people's
/// produce, so — unlike Farmer/Chef/Grocery Shopper — they need a real
/// trust gate before the dashboard unlocks: either a pre-issued invite
/// code (instant), or a request that sits in an admin's review queue.
class SupplyChainVerificationScreen extends ConsumerStatefulWidget {
  final UserRole role;
  const SupplyChainVerificationScreen({super.key, required this.role});

  @override
  ConsumerState<SupplyChainVerificationScreen> createState() =>
      _SupplyChainVerificationScreenState();
}

class _SupplyChainVerificationScreenState
    extends ConsumerState<SupplyChainVerificationScreen> {
  bool _requestMode = false;
  final _codeCtrl = TextEditingController();
  final _orgCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  Color get _accent => switch (widget.role) {
        UserRole.aggregator => AppColors.aggregatorAccent,
        UserRole.transporter => AppColors.transporterAccent,
        UserRole.distributor => AppColors.distributorAccent,
        _ => AppColors.leaf,
      };

  Future<void> _redeemCode() async {
    final code = _codeCtrl.text.trim();
    if (code.isEmpty) {
      setState(() => _error = 'Enter the invite code you were given.');
      return;
    }
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() => _error =
          'Sign in with a real account first — invite codes need a signed-in '
          'session to redeem (dev quick-sign-in buttons skip this).');
      return;
    }
    final normalizedCode = code.toUpperCase();
    setState(() { _loading = true; _error = null; });

    final orgLabel = await ref.read(verificationServiceProvider).redeemInviteCode(
          code: normalizedCode,
          role: widget.role,
          uid: uid,
        );

    if (!mounted) return;
    if (orgLabel == null) {
      setState(() {
        _loading = false;
        _error = 'That code isn\'t valid, was already used, or is for a '
            'different role. Double-check it or request access instead.';
      });
      return;
    }

    try {
      await ref.read(sessionProvider.notifier).setRole(
            widget.role,
            organizationName: widget.role == UserRole.transporter ? null : orgLabel,
            vehicleInfo: widget.role == UserRole.transporter ? orgLabel : null,
            verificationStatus: VerificationStatus.approved,
            verifiedByCode: normalizedCode,
          );
      // Router auto-redirects to the dashboard now that verificationStatus == approved.
    } catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; _error = 'Verified, but couldn\'t save your session. Try again.'; });
    }
  }

  Future<void> _submitRequest() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _error =
          'Sign in with a real account first — access requests need a '
          'signed-in session (dev quick-sign-in buttons skip this).');
      return;
    }
    if (_orgCtrl.text.trim().isEmpty) {
      setState(() => _error = widget.role == UserRole.transporter
          ? 'Enter your vehicle/registration details.'
          : 'Enter your organization or business name.');
      return;
    }
    setState(() { _loading = true; _error = null; });

    try {
      await ref.read(verificationServiceProvider).submitRoleRequest(RoleRequest(
            uid: user.uid,
            name: user.displayName ?? user.email?.split('@').first ?? 'User',
            email: user.email ?? '',
            requestedRole: widget.role,
            organizationDetail: _orgCtrl.text.trim(),
            status: VerificationStatus.pending,
            requestedAt: DateTime.now(),
          ));
      await ref.read(sessionProvider.notifier).setRole(
            widget.role,
            organizationName: widget.role == UserRole.transporter ? null : _orgCtrl.text.trim(),
            vehicleInfo: widget.role == UserRole.transporter ? _orgCtrl.text.trim() : null,
            verificationStatus: VerificationStatus.pending,
          );
      if (!mounted) return;
      context.go('/pending-approval');
    } catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; _error = 'Could not submit your request. Try again.'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.night,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text('Verify ${widget.role.label} Access',
            style: const TextStyle(color: Colors.white)),
      ),
      body: SafeArea(child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${widget.role.emoji} ${widget.role.label} accounts can receive '
              'other farmers\' produce, so we verify these before the dashboard '
              'unlocks.',
              style: AppTextStyles.sans(13.5, color: Colors.white70, height: 1.5)),
          const SizedBox(height: 24),
          Row(children: [
            Expanded(child: _ModeTab(
              label: 'I have a code', selected: !_requestMode, accent: _accent,
              onTap: () => setState(() { _requestMode = false; _error = null; }))),
            const SizedBox(width: 10),
            Expanded(child: _ModeTab(
              label: 'Request access', selected: _requestMode, accent: _accent,
              onTap: () => setState(() { _requestMode = true; _error = null; }))),
          ]),
          const SizedBox(height: 20),
          if (!_requestMode) ...[
            Text('Invite Code', style: AppTextStyles.sans(12.5, color: Colors.white60)),
            const SizedBox(height: 6),
            TextField(
              controller: _codeCtrl,
              textCapitalization: TextCapitalization.characters,
              style: const TextStyle(color: Colors.white, letterSpacing: 2),
              decoration: _fieldDecoration('e.g. AGG-4F2K'),
            ),
            const SizedBox(height: 8),
            Text('Given to you by a co-op lead, JHUB program staff, or '
                'whoever vetted your organization offline.',
                style: AppTextStyles.sans(11.5, color: Colors.white38)),
          ] else ...[
            Text(widget.role == UserRole.transporter
                    ? 'Vehicle / Registration'
                    : 'Organization / Business Name',
                style: AppTextStyles.sans(12.5, color: Colors.white60)),
            const SizedBox(height: 6),
            TextField(
              controller: _orgCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: _fieldDecoration(widget.role == UserRole.transporter
                  ? 'e.g. KDA 245J — refrigerated pickup'
                  : 'e.g. Kiambu Growers Cooperative'),
            ),
            const SizedBox(height: 8),
            Text('No code? Submit this and an admin will review your account. '
                'You\'ll see a Pending screen until it\'s approved.',
                style: AppTextStyles.sans(11.5, color: Colors.white38)),
          ],
          if (_error != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: AppColors.red.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12)),
              child: Text(_error!, style: const TextStyle(color: Colors.white, fontSize: 12.5)),
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(width: double.infinity, height: 52, child: ElevatedButton(
            onPressed: _loading ? null : (_requestMode ? _submitRequest : _redeemCode),
            style: ElevatedButton.styleFrom(
              backgroundColor: _accent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: _loading
                ? const SizedBox(width: 22, height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                : Text(_requestMode ? 'Submit Request' : 'Activate',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
          )),
        ]),
      )),
    );
  }

  InputDecoration _fieldDecoration(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.06),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      );
}

class _ModeTab extends StatelessWidget {
  final String label;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;
  const _ModeTab({required this.label, required this.selected, required this.accent, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? accent.withValues(alpha: 0.18) : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? accent : Colors.white24, width: selected ? 1.6 : 1),
        ),
        child: Text(label,
            style: TextStyle(color: selected ? Colors.white : Colors.white60,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500, fontSize: 13)),
      ),
    );
  }
}
