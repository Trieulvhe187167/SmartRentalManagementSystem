class ServiceItem {
  final int? id;
  final String? name;
  final String? code;
  final String? type;
  final String? chargeType;
  final String? unit;
  final double? currentPrice;
  final bool? active;
  final String? status;
  final String? description;

  const ServiceItem({
    this.id,
    this.name,
    this.code,
    this.type,
    this.chargeType,
    this.unit,
    this.currentPrice,
    this.active,
    this.status,
    this.description,
  });

  factory ServiceItem.fromJson(Map<String, dynamic> json) {
    return ServiceItem(
      id: json['id'] as int?,
      name: json['name'] as String?,
      code: json['code'] as String?,
      type: json['type'] as String? ?? json['code'] as String?,
      chargeType: json['chargeType'] as String?,
      unit: json['unit'] as String?,
      currentPrice: (json['currentPrice'] as num?)?.toDouble(),
      active: json['active'] as bool? ?? json['status'] == 'ACTIVE',
      status: json['status'] as String?,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'code': code,
    'type': type,
    'chargeType': chargeType,
    'unit': unit,
    'currentPrice': currentPrice,
    'active': active,
    'status': status,
    'description': description,
  };

  bool get isMetered => chargeType == 'METERED';
}

class ServiceRequest {
  final String? name;
  final String? code;
  final String? type;
  final String? unit;
  final String? chargeType;
  final String? description;
  final bool? active;

  const ServiceRequest({
    required this.name,
    this.code,
    required this.type,
    required this.unit,
    this.chargeType,
    this.description,
    this.active,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'code': code ?? type,
    'type': type,
    'unit': unit,
    'chargeType': chargeType ?? _chargeTypeFromServiceType(type),
    if (description != null) 'description': description,
    if (active != null) 'active': active,
  };
}

class ServicePrice {
  final int? id;
  final int? serviceId;
  final String? serviceName;
  final double? price;
  final String? effectiveDate;

  const ServicePrice({
    this.id,
    this.serviceId,
    this.serviceName,
    this.price,
    this.effectiveDate,
  });

  factory ServicePrice.fromJson(Map<String, dynamic> json) {
    return ServicePrice(
      id: json['id'] as int?,
      serviceId: json['serviceId'] as int?,
      serviceName: json['serviceName'] as String?,
      price: ((json['price'] ?? json['unitPrice']) as num?)?.toDouble(),
      effectiveDate:
          json['effectiveDate'] as String? ?? json['effectiveFrom'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'serviceId': serviceId,
    'serviceName': serviceName,
    'price': price,
    'effectiveDate': effectiveDate,
  };
}

class ServicePriceRequest {
  final int serviceId;
  final double unitPrice;
  final String effectiveFrom;
  final String? effectiveTo;
  final String? notes;

  const ServicePriceRequest({
    required this.serviceId,
    required this.unitPrice,
    required this.effectiveFrom,
    this.effectiveTo,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
    'serviceId': serviceId,
    'unitPrice': unitPrice,
    'effectiveFrom': effectiveFrom,
    if (effectiveTo != null) 'effectiveTo': effectiveTo,
    if (notes != null) 'notes': notes,
  };
}

String _chargeTypeFromServiceType(String? type) {
  return switch (type) {
    'ELECTRICITY' || 'WATER' => 'METERED',
    'INTERNET' || 'CLEANING' || 'PARKING' => 'FIXED_PER_ROOM',
    _ => 'FIXED_PER_ROOM',
  };
}
