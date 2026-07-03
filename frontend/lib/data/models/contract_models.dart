class RentalContract {
  final int? id;
  final String? contractNumber;
  final String? roomNumber;
  final String? tenantName;
  final String? startDate;
  final String? endDate;
  final double? monthlyRent;
  final double? deposit;
  final String? status;
  final String? notes;
  final String? createdAt;

  const RentalContract({
    this.id,
    this.contractNumber,
    this.roomNumber,
    this.tenantName,
    this.startDate,
    this.endDate,
    this.monthlyRent,
    this.deposit,
    this.status,
    this.notes,
    this.createdAt,
  });

  factory RentalContract.fromJson(Map<String, dynamic> json) {
    final room = json['room'];
    final tenant = json['primaryTenant'] ?? json['tenantProfile'];
    return RentalContract(
      id: json['id'] as int?,
      contractNumber: json['contractNumber'] as String? ?? json['contractCode'] as String?,
      roomNumber: json['roomNumber'] as String? ??
          (room is Map<String, dynamic> ? room['roomNumber'] as String? : null),
      tenantName: json['tenantName'] as String? ??
          (tenant is Map<String, dynamic> ? tenant['fullName'] as String? : null),
      startDate: json['startDate'] as String?,
      endDate: json['endDate'] as String?,
      monthlyRent: ((json['monthlyRent'] ?? json['appliedRent']) as num?)?.toDouble(),
      deposit: ((json['deposit'] ?? json['depositAmount']) as num?)?.toDouble(),
      status: json['status'] as String?,
      notes: json['notes'] as String? ?? json['terms'] as String?,
      createdAt: json['createdAt'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'contractNumber': contractNumber,
        'roomNumber': roomNumber,
        'tenantName': tenantName,
        'startDate': startDate,
        'endDate': endDate,
        'monthlyRent': monthlyRent,
        'deposit': deposit,
        'status': status,
        'notes': notes,
        'createdAt': createdAt,
      };
}

class ContractCreateRequest {
  final int? roomId;
  final int? tenantProfileId;
  final String? startDate;
  final String? endDate;
  final double? monthlyRent;
  final double? deposit;
  final int monthlyDueDay;
  final String? contractCode;
  final String? notes;

  const ContractCreateRequest({
    required this.roomId,
    required this.tenantProfileId,
    required this.startDate,
    required this.endDate,
    required this.monthlyRent,
    required this.deposit,
    this.monthlyDueDay = 5,
    this.contractCode,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
        'contractCode': contractCode ??
            'HD-${DateTime.now().millisecondsSinceEpoch}',
        'roomId': roomId,
        'primaryTenantId': tenantProfileId,
        'startDate': startDate,
        'endDate': endDate,
        'appliedRent': monthlyRent,
        'depositAmount': deposit,
        'monthlyDueDay': monthlyDueDay,
        if (notes != null) 'terms': notes,
      };
}

class ContractTerminateRequest {
  final String? terminationDate;
  final String? reason;

  const ContractTerminateRequest({
    required this.terminationDate,
    required this.reason,
  });

  Map<String, dynamic> toJson() => {
        'terminationDate': terminationDate,
        'reason': reason,
      };
}
