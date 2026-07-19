class RentalContract {
  final int? id;
  final String? contractNumber;
  final String? roomNumber;
  final String? tenantName;
  final int? tenantProfileId;
  final String? startDate;
  final String? endDate;
  final double? monthlyRent;
  final double? deposit;
  final String? status;
  final String? notes;
  final String? createdAt;
  final int? monthlyDueDay;
  final String? tenantConfirmedAt;
  final String? tenantRejectedAt;
  final String? tenantRejectionReason;
  final int? currentOccupantCount;
  final int? maxOccupants;

  const RentalContract({
    this.id,
    this.contractNumber,
    this.roomNumber,
    this.tenantName,
    this.tenantProfileId,
    this.startDate,
    this.endDate,
    this.monthlyRent,
    this.deposit,
    this.status,
    this.notes,
    this.createdAt,
    this.monthlyDueDay,
    this.tenantConfirmedAt,
    this.tenantRejectedAt,
    this.tenantRejectionReason,
    this.currentOccupantCount,
    this.maxOccupants,
  });

  factory RentalContract.fromJson(Map<String, dynamic> json) {
    final room = json['room'];
    final tenant = json['primaryTenant'] ?? json['tenantProfile'];
    return RentalContract(
      id: json['id'] as int?,
      contractNumber:
          json['contractNumber'] as String? ?? json['contractCode'] as String?,
      roomNumber:
          json['roomNumber'] as String? ??
          (room is Map<String, dynamic> ? room['roomNumber'] as String? : null),
      tenantName:
          json['tenantName'] as String? ??
          (tenant is Map<String, dynamic>
              ? tenant['fullName'] as String?
              : null),
      tenantProfileId: tenant is Map<String, dynamic>
          ? (tenant['id'] as num?)?.toInt()
          : (json['tenantProfileId'] as num?)?.toInt(),
      startDate: json['startDate'] as String?,
      endDate: json['endDate'] as String?,
      monthlyRent: ((json['monthlyRent'] ?? json['appliedRent']) as num?)
          ?.toDouble(),
      deposit: ((json['deposit'] ?? json['depositAmount']) as num?)?.toDouble(),
      status: json['status'] as String?,
      notes: json['notes'] as String? ?? json['terms'] as String?,
      createdAt: json['createdAt'] as String?,
      monthlyDueDay: (json['monthlyDueDay'] as num?)?.toInt(),
      tenantConfirmedAt: json['tenantConfirmedAt'] as String?,
      tenantRejectedAt: json['tenantRejectedAt'] as String?,
      tenantRejectionReason: json['tenantRejectionReason'] as String?,
      currentOccupantCount: (json['currentOccupantCount'] as num?)?.toInt(),
      maxOccupants: room is Map<String, dynamic>
          ? (room['maxOccupants'] as num?)?.toInt()
          : (json['maxOccupants'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'contractNumber': contractNumber,
    'roomNumber': roomNumber,
    'tenantName': tenantName,
    'tenantProfileId': tenantProfileId,
    'startDate': startDate,
    'endDate': endDate,
    'monthlyRent': monthlyRent,
    'deposit': deposit,
    'status': status,
    'notes': notes,
    'createdAt': createdAt,
    'monthlyDueDay': monthlyDueDay,
    'tenantConfirmedAt': tenantConfirmedAt,
    'tenantRejectedAt': tenantRejectedAt,
    'tenantRejectionReason': tenantRejectionReason,
    'currentOccupantCount': currentOccupantCount,
    'maxOccupants': maxOccupants,
  };

  bool get isPendingConfirmation =>
      status?.toUpperCase() == 'PENDING_CONFIRMATION';

  bool get isActive => status?.toUpperCase() == 'ACTIVE';
}

class ContractOccupant {
  final int? id;
  final int? occupantId;
  final String fullName;
  final String relationship;
  final String? phone;
  final String? identityNumber;
  final String? moveInDate;
  final String? moveOutDate;

  const ContractOccupant({
    this.id,
    this.occupantId,
    required this.fullName,
    required this.relationship,
    this.phone,
    this.identityNumber,
    this.moveInDate,
    this.moveOutDate,
  });

  factory ContractOccupant.fromJson(Map<String, dynamic> json) {
    final occupant = json['occupant'];
    final occupantMap = occupant is Map<String, dynamic> ? occupant : null;
    return ContractOccupant(
      id: (json['id'] as num?)?.toInt(),
      occupantId: (occupantMap?['id'] as num?)?.toInt(),
      fullName: occupantMap?['fullName'] as String? ?? 'Người ở cùng',
      relationship: json['relationshipToPrimary'] as String? ?? 'Khác',
      phone: occupantMap?['phone'] as String?,
      identityNumber: occupantMap?['identityNumber'] as String?,
      moveInDate: json['moveInDate'] as String?,
      moveOutDate: json['moveOutDate'] as String?,
    );
  }

  bool get isActive {
    final moveIn = DateTime.tryParse(moveInDate ?? '');
    final today = DateTime.now();
    final startOfToday = DateTime(today.year, today.month, today.day);
    return moveOutDate == null &&
        (moveIn == null || !moveIn.isAfter(startOfToday));
  }

  bool get hasMovedOut => moveOutDate != null;
}

class ContractOccupantCreateRequest {
  final String fullName;
  final String relationship;
  final String moveInDate;
  final String? phone;
  final String? identityNumber;
  final String? permanentAddress;

  const ContractOccupantCreateRequest({
    required this.fullName,
    required this.relationship,
    required this.moveInDate,
    this.phone,
    this.identityNumber,
    this.permanentAddress,
  });

  Map<String, dynamic> toJson() => {
    'fullName': fullName,
    'relationshipToPrimary': relationship,
    'moveInDate': moveInDate,
    if (phone?.isNotEmpty == true) 'phone': phone,
    if (identityNumber?.isNotEmpty == true) ...{
      'identityType': 'CCCD',
      'identityNumber': identityNumber,
    },
    if (permanentAddress?.isNotEmpty == true)
      'permanentAddress': permanentAddress,
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
    'contractCode':
        contractCode ?? 'HD-${DateTime.now().millisecondsSinceEpoch}',
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
