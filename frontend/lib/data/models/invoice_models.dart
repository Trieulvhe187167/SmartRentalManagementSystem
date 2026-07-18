import 'payment_models.dart';
import 'tenant_models.dart';

class Invoice {
  final int? id;
  final String? invoiceNumber;
  final int? billingMonth;
  final int? billingYear;
  final double? totalAmount;
  final double? paidAmount;
  final double? remainingAmount;
  final String? status;
  final String? dueDate;
  final String? issuedDate;
  final String? roomNumber;
  final String? buildingName;
  final int? roomId;
  final TenantProfile? tenantProfile;
  final List<InvoiceItem> items;

  const Invoice({
    this.id,
    this.invoiceNumber,
    this.billingMonth,
    this.billingYear,
    this.totalAmount,
    this.paidAmount,
    this.remainingAmount,
    this.status,
    this.dueDate,
    this.issuedDate,
    this.roomNumber,
    this.buildingName,
    this.roomId,
    this.tenantProfile,
    this.items = const [],
  });

  String get tenantName => tenantProfile?.fullName ?? '—';

  bool get isVisibleToTenant => const {
    'ISSUED',
    'PARTIALLY_PAID',
    'PAID',
    'OVERDUE',
  }.contains(status?.toUpperCase());

  factory Invoice.fromJson(Map<String, dynamic> json) {
    final contract = json['contract'];
    final tenantProfileData =
        json['tenantProfile'] ??
        (contract is Map<String, dynamic> ? contract['primaryTenant'] : null);
    return Invoice(
      id: json['id'] as int?,
      invoiceNumber: json['invoiceNumber'] as String?,
      billingMonth: json['billingMonth'] as int?,
      billingYear: json['billingYear'] as int?,
      totalAmount: (json['totalAmount'] as num?)?.toDouble(),
      paidAmount: (json['paidAmount'] as num?)?.toDouble() ?? 0,
      remainingAmount: (json['remainingAmount'] as num?)?.toDouble(),
      status: json['status'] as String?,
      dueDate: json['dueDate'] as String?,
      issuedDate: json['issuedDate'] as String? ?? json['issuedAt'] as String?,
      roomNumber:
          json['roomNumber'] as String? ??
          _roomString(json['room'], 'roomNumber'),
      buildingName:
          json['buildingName'] as String? ?? _buildingName(json['room']),
      roomId: (json['roomId'] as num?)?.toInt() ?? _roomInt(json['room'], 'id'),
      tenantProfile: tenantProfileData is Map<String, dynamic>
          ? TenantProfile.fromJson(tenantProfileData)
          : null,
      items: (json['items'] as List<dynamic>? ?? [])
          .map((e) => InvoiceItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'invoiceNumber': invoiceNumber,
    'billingMonth': billingMonth,
    'billingYear': billingYear,
    'totalAmount': totalAmount,
    'paidAmount': paidAmount,
    'remainingAmount': remainingAmount,
    'status': status,
    'dueDate': dueDate,
    'issuedDate': issuedDate,
    'roomNumber': roomNumber,
    'buildingName': buildingName,
    'roomId': roomId,
    if (tenantProfile != null) 'tenantProfile': tenantProfile!.toJson(),
    'items': items.map((e) => e.toJson()).toList(),
  };
}

String? _roomString(dynamic room, String key) {
  if (room is Map<String, dynamic>) return room[key] as String?;
  return null;
}

int? _roomInt(dynamic room, String key) {
  if (room is Map<String, dynamic>) return (room[key] as num?)?.toInt();
  return null;
}

String? _buildingName(dynamic room) {
  if (room is! Map<String, dynamic>) return null;
  final building = room['building'];
  if (building is String) return building;
  if (building is Map<String, dynamic>) return building['name'] as String?;
  return null;
}

class InvoiceItem {
  final int? id;
  final String? description;
  final double? quantity;
  final double? unitPrice;
  final double? amount;
  final String? type;

  const InvoiceItem({
    this.id,
    this.description,
    this.quantity,
    this.unitPrice,
    this.amount,
    this.type,
  });

  factory InvoiceItem.fromJson(Map<String, dynamic> json) {
    return InvoiceItem(
      id: json['id'] as int?,
      description: json['description'] as String?,
      quantity: (json['quantity'] as num?)?.toDouble(),
      unitPrice: (json['unitPrice'] as num?)?.toDouble(),
      amount: (json['amount'] as num?)?.toDouble(),
      type: json['type'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'description': description,
    'quantity': quantity,
    'unitPrice': unitPrice,
    'amount': amount,
    'type': type,
  };
}

class InvoiceDetail {
  final Invoice? invoice;
  final List<InvoiceItem> items;
  final List<Payment> payments;

  const InvoiceDetail({
    this.invoice,
    this.items = const [],
    this.payments = const [],
  });

  factory InvoiceDetail.fromJson(Map<String, dynamic> json) {
    final invoiceData = json['invoice'] as Map<String, dynamic>?;
    return InvoiceDetail(
      invoice: invoiceData != null ? Invoice.fromJson(invoiceData) : null,
      items: (json['items'] as List<dynamic>? ?? [])
          .map((e) => InvoiceItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      payments: (json['payments'] as List<dynamic>? ?? [])
          .map((e) => Payment.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class GenerateInvoiceRequest {
  final int contractId;
  final int billingMonth;
  final int billingYear;

  const GenerateInvoiceRequest({
    required this.contractId,
    required this.billingMonth,
    required this.billingYear,
  });

  Map<String, dynamic> toJson() => {
    'contractId': contractId,
    'billingMonth': billingMonth,
    'billingYear': billingYear,
  };
}

class GenerateMonthlyInvoicesRequest {
  final int billingMonth;
  final int billingYear;

  const GenerateMonthlyInvoicesRequest({
    required this.billingMonth,
    required this.billingYear,
  });

  Map<String, dynamic> toJson() => {
    'billingMonth': billingMonth,
    'billingYear': billingYear,
  };
}

class InvoiceIssueRequest {
  final String dueDate;
  final String? issueDate;

  const InvoiceIssueRequest({required this.dueDate, this.issueDate});

  Map<String, dynamic> toJson() => {
    'issueDate': issueDate ?? DateTime.now().toIso8601String().substring(0, 10),
    'dueDate': dueDate,
  };
}
