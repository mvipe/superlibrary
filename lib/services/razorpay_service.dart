import 'dart:async';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../config/razorpay_config.dart';

class PaymentResult {
  final bool success;
  final String? paymentId;
  final String? message;
  PaymentResult(this.success, {this.paymentId, this.message});
}

/// Wraps Razorpay's callback API in a single awaitable [checkout] call.
///
/// NOTE: For production you must create the order and verify the returned
/// signature on a server (Supabase Edge Function) with your key SECRET. The
/// client only ever holds the public key ID.
class RazorpayService {
  RazorpayService._();
  static final instance = RazorpayService._();

  Razorpay? _rzp;
  Completer<PaymentResult>? _completer;

  Future<PaymentResult> checkout({
    required double amount,
    required String memberName,
    required String description,
    String contact = '',
    String email = '',
  }) {
    if (!RazorpayConfig.isConfigured) {
      return Future.value(PaymentResult(false,
          message: 'Razorpay key not set in razorpay_config.dart'));
    }

    _completer = Completer<PaymentResult>();
    _rzp = Razorpay();
    _rzp!.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onSuccess);
    _rzp!.on(Razorpay.EVENT_PAYMENT_ERROR, _onError);
    _rzp!.on(Razorpay.EVENT_EXTERNAL_WALLET, _onWallet);

    final options = {
      'key': RazorpayConfig.keyId,
      'amount': (amount * 100).toInt(), // paise
      'currency': RazorpayConfig.currency,
      'name': RazorpayConfig.companyName,
      'description': description,
      'prefill': {'contact': contact, 'email': email, 'name': memberName},
      'theme': {'color': '#EF3E36'},
    };

    try {
      _rzp!.open(options);
    } catch (e) {
      _finish(PaymentResult(false, message: e.toString()));
    }
    return _completer!.future;
  }

  void _onSuccess(PaymentSuccessResponse r) =>
      _finish(PaymentResult(true, paymentId: r.paymentId));

  void _onError(PaymentFailureResponse r) =>
      _finish(PaymentResult(false, message: r.message ?? 'Payment failed'));

  void _onWallet(ExternalWalletResponse r) =>
      _finish(PaymentResult(false, message: 'Wallet: ${r.walletName}'));

  void _finish(PaymentResult result) {
    _rzp?.clear();
    _rzp = null;
    if (_completer != null && !_completer!.isCompleted) {
      _completer!.complete(result);
    }
  }
}
