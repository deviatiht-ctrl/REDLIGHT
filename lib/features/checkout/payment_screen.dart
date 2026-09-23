import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/utils/format.dart';
import '../../providers/commerce_providers.dart';
import '../../providers/core_providers.dart';
import '../../providers/locale_provider.dart';
import '../../providers/orders_provider.dart';
import '../../services/commerce_service.dart';

class PaymentScreen extends ConsumerStatefulWidget {
  const PaymentScreen({super.key, required this.orderId});
  final String orderId;
  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> with WidgetsBindingObserver {
  final _phone = TextEditingController();
  Map<String, dynamic>? _order;
  Map<String, dynamic>? _payment;
  String? _error;
  bool _busy = false;
  Timer? _timer;
  int _polls = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _phone.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _payment != null) _verify();
  }

  Future<void> _load() async {
    try {
      final client = ref.read(supabaseClientProvider);
      final user = ref.read(currentUserProvider);
      if (user == null) return;
      final order = await client.from('orders').select().eq('id', widget.orderId).eq('user_id', user.id).single();
      final payment = await client.from('payments').select().eq('order_id', widget.orderId).maybeSingle();
      if (!mounted) return;
      setState(() { _order = order; _payment = payment; _error = null; });
      if (payment != null) { _schedule(); await _verify(); }
    } catch (_) {
      if (mounted) setState(() => _error = 'generic_error');
    }
  }

  void _schedule() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (++_polls > 20 || _payment?['status'] == 'paid') { _timer?.cancel(); return; }
      _verify();
    });
  }

  Future<void> _start() async {
    if (_busy) return;
    if (_order?['payment_method'] == 'moncash_ussd' && !RegExp(r'^509\d{8}$').hasMatch(_phone.text.trim())) {
      setState(() => _error = 'invalid_phone');
      return;
    }
    await _request('payment.start');
    if (mounted) _schedule();
  }

  Future<void> _verify() => _request('payment.verify');

  Future<void> _request(String action) async {
    if (_busy) return;
    setState(() { _busy = true; _error = null; });
    try {
      final result = await ref.read(commerceServiceProvider).call(action, {'order_id': widget.orderId, 'phone_number': _phone.text.trim()});
      if (mounted) setState(() => _payment = result);
      ref.invalidate(myOrdersProvider);
    } catch (error) {
      if (mounted) setState(() => _error = error is CommerceException ? 'commerce_${error.code}' : 'generic_error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openPayment() async {
    final uri = Uri.tryParse(_payment?['redirect_url'] as String? ?? '');
    try {
      if (uri == null || uri.scheme != 'https' || uri.host.isEmpty || !await launchUrl(uri, mode: LaunchMode.externalApplication, webOnlyWindowName: '_blank')) {
        throw const CommerceException('OPEN_URL_FAILED');
      }
    } catch (_) {
      if (mounted) setState(() => _error = 'open_payment_failed');
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final paid = _payment?['status'] == 'paid';
    final status = _payment?['status'] ?? 'unpaid';
    return Scaffold(
      appBar: AppBar(title: Text(s.t('secure_payment')), leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/orders'))),
      body: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 520), child: ListView(padding: const EdgeInsets.all(24), children: [
        Icon(paid ? Icons.verified_outlined : Icons.lock_outline, size: 76, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 24),
        Text(s.t('payment_state_$status'), textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 12),
        if (_order != null) Text(formatPrice((_order!['total'] as num).toDouble()), textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 20),
        if (_error != null) Padding(padding: const EdgeInsets.only(bottom: 16), child: Text(s.t(_error!), style: TextStyle(color: Theme.of(context).colorScheme.error))),
        if (_order == null) TextButton(onPressed: _load, child: Text(s.t('retry'))),
        if (_order != null && _payment == null) ...[
          if (_order!['payment_method'] == 'moncash_ussd') TextField(controller: _phone, keyboardType: TextInputType.phone, decoration: InputDecoration(labelText: s.t('phone'), hintText: '509XXXXXXXX')),
          const SizedBox(height: 16),
          FilledButton(onPressed: _busy ? null : _start, child: Text(s.t('start_payment'))),
        ],
        if (!paid && _payment != null) ...[
          Text(s.t(_payment!['method'] == 'moncash_ussd' ? 'ussd_instructions' : 'payment_instructions'), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          if (_payment!['redirect_url'] != null) FilledButton.icon(onPressed: _openPayment, icon: const Icon(Icons.open_in_new), label: Text(s.t('open_payment'))),
        ],
        if (!paid && _order != null) OutlinedButton(onPressed: _busy ? null : _verify, child: Text(s.t('verify_payment'))),
        if (_busy) const LinearProgressIndicator(),
        const SizedBox(height: 16),
        TextButton(onPressed: () => context.go('/orders'), child: Text(s.t('view_my_orders'))),
      ]))),
    );
  }
}
