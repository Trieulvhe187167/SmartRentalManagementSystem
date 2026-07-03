class ServiceItem {
  final int? id;
  final String? name;
  final String? code;
  final String? type;
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
      type: json['type'] as String? ?? json['chargeType'] as String?,
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
        'unit': unit,
        'currentPrice': currentPrice,
        'active': active,
        'status': status,
        'description': description,
      };
}

class ServiceRequest {
  final String? name;
  final String? type;
  final String? unit;
  final String? description;

  const ServiceRequest({
    required this.name,
    required this.type,
    required this.unit,
    this.description,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'type': type,
        'unit': unit,
        if (description != null) 'description': description,
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
      price: (json['price'] as num?)?.toDouble(),
      effectiveDate: json['effectiveDate'] as String?,
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
