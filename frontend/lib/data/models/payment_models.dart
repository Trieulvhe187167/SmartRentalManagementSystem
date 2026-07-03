class Payment {
  final int? id;
  final double? amount;
  final String? paymentDate;
  final String? method;
  final String? status;
  final String? transactionId;
  final String? note;
  final int? invoiceId;
  final String? invoiceNumber;

  const Payment({
    this.id,
    this.amount,
    this.paymentDate,
    this.method,
    this.status,
    this.transactionId,
    this.note,
    this.invoiceId,
    this.invoiceNumber,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    final invoice = json['invoice'];
    return Payment(
      id: json['id'] as int?,
      amount: (json['amount'] as num?)?.toDouble(),
      paymentDate: json['paymentDate'] as String?,
      method: json['method'] as String? ?? json['paymentMethod'] as String?,
      status: json['status'] as String?,
      transactionId: json['transactionId'] as String? ??
          json['transactionReference'] as String?,
      note: json['note'] as String? ?? json['notes'] as String?,
      invoiceId: (json['invoiceId'] as num?)?.toInt() ??
          (invoice is Map<String, dynamic>
              ? (invoice['id'] as num?)?.toInt()
              : null),
      invoiceNumber: json['invoiceNumber'] as String? ??
          (invoice is Map<String, dynamic>
              ? invoice['invoiceNumber'] as String?
              : null),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'amount': amount,
        'paymentDate': paymentDate,
        'method': method,
        'status': status,
        'transactionId': transactionId,
        'note': note,
        'invoiceId': invoiceId,
        'invoiceNumber': invoiceNumber,
      };

  String get methodLabel {
    return switch ((method ?? '').toUpperCase()) {
      'CASH' => 'Tiền mặt',
      'BANK_TRANSFER' => 'Chuyển khoản',
      'MOMO' => 'MoMo',
      'VNPAY' => 'VNPay',
      'ZALOPAY' => 'ZaloPay',
      _ => method ?? 'Không rõ',
    };
  }
}

class PaymentCreateRequest {
  final double amount;
  final String method;
  final String paymentDate;
  final String? transactionReference;
  final String notes;

  const PaymentCreateRequest({
    required this.amount,
    required this.method,
    required this.paymentDate,
    this.transactionReference,
    required this.notes,
  });

  Map<String, dynamic> toJson() => {
        'amount': amount,
        'method': method,
        'paymentDate': paymentDate,
        if (transactionReference != null) 'transactionReference': transactionReference,
        'notes': notes,
      };
}

class PaymentCancelRequest {
  final String reason;

  const PaymentCancelRequest({
    required this.reason,
  });

  Map<String, dynamic> toJson() => {
        'cancellationReason': reason,
      };
}
