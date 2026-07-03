class MeterReading {
  final int? id;
  final int? roomId;
  final String? roomNumber;
  final int? serviceId;
  final String? serviceName;
  final String? type;
  final int? billingMonth;
  final int? billingYear;
  final double? previousReading;
  final double? currentReading;
  final double? consumption;
  final String? readingDate;
  final String? status;
  final String? createdAt;

  const MeterReading({
    this.id,
    this.roomId,
    this.roomNumber,
    this.serviceId,
    this.serviceName,
    this.type,
    this.billingMonth,
    this.billingYear,
    this.previousReading,
    this.currentReading,
    this.consumption,
    this.readingDate,
    this.status,
    this.createdAt,
  });

  factory MeterReading.fromJson(Map<String, dynamic> json) {
    final room = json['room'];
    final service = json['serviceItem'];
    return MeterReading(
      id: json['id'] as int?,
      roomId: (json['roomId'] as num?)?.toInt() ??
          (room is Map<String, dynamic> ? (room['id'] as num?)?.toInt() : null),
      roomNumber: json['roomNumber'] as String? ??
          (room is Map<String, dynamic> ? room['roomNumber'] as String? : null),
      serviceId: (json['serviceId'] as num?)?.toInt() ??
          (service is Map<String, dynamic>
              ? (service['id'] as num?)?.toInt()
              : null),
      serviceName: json['serviceName'] as String? ??
          (service is Map<String, dynamic> ? service['name'] as String? : null),
      type: json['type'] as String? ??
          (service is Map<String, dynamic> ? service['code'] as String? : null),
      billingMonth: json['billingMonth'] as int?,
      billingYear: json['billingYear'] as int?,
      previousReading: (json['previousReading'] as num?)?.toDouble(),
      currentReading: (json['currentReading'] as num?)?.toDouble(),
      consumption: (json['consumption'] as num?)?.toDouble(),
      readingDate: json['readingDate'] as String?,
      status: json['status'] as String?,
      createdAt: json['createdAt'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'roomId': roomId,
        'roomNumber': roomNumber,
        'serviceId': serviceId,
        'serviceName': serviceName,
        'type': type,
        'billingMonth': billingMonth,
        'billingYear': billingYear,
        'previousReading': previousReading,
        'currentReading': currentReading,
        'consumption': consumption,
        'readingDate': readingDate,
        'status': status,
        'createdAt': createdAt,
      };
}

class MeterReadingRequest {
  final int? roomId;
  final int? serviceId;
  final int? billingMonth;
  final int? billingYear;
  final double? previousReading;
  final double? currentReading;
  final String? readingDate;
  final String? notes;

  MeterReadingRequest({
    required this.roomId,
    required this.serviceId,
    required this.billingMonth,
    required this.billingYear,
    required this.previousReading,
    required this.currentReading,
    required this.readingDate,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
        'roomId': roomId,
        'serviceId': serviceId,
        'billingMonth': billingMonth,
        'billingYear': billingYear,
        'previousReading': previousReading,
        'currentReading': currentReading,
        'readingDate': readingDate,
        if (notes != null) 'notes': notes,
      };
}
