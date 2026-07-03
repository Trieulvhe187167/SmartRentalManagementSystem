class Building {
  final int id;
  final String code;
  final String name;
  final String? address;
  final String? status;

  const Building({
    required this.id,
    required this.code,
    required this.name,
    this.address,
    this.status,
  });

  factory Building.fromJson(Map<String, dynamic> json) {
    return Building(
      id: (json['id'] as num).toInt(),
      code: json['code'] as String? ?? '',
      name: json['name'] as String? ?? '',
      address: json['address'] as String?,
      status: json['status'] as String?,
    );
  }
}

class Floor {
  final int id;
  final int floorNumber;
  final String? name;
  final int? buildingId;
  final String? buildingName;
  final String? status;

  const Floor({
    required this.id,
    required this.floorNumber,
    this.name,
    this.buildingId,
    this.buildingName,
    this.status,
  });

  factory Floor.fromJson(Map<String, dynamic> json) {
    final building = json['building'];
    return Floor(
      id: (json['id'] as num).toInt(),
      floorNumber: (json['floorNumber'] as num?)?.toInt() ?? 0,
      name: json['name'] as String?,
      buildingId: building is Map<String, dynamic>
          ? (building['id'] as num?)?.toInt()
          : (json['buildingId'] as num?)?.toInt(),
      buildingName: building is Map<String, dynamic>
          ? building['name'] as String?
          : json['buildingName'] as String?,
      status: json['status'] as String?,
    );
  }
}

class Room {
  final int id;
  final String roomNumber;
  final int? buildingId;
  final int? floorId;
  final int? floor;
  final String? building;
  final double? area;
  final int? maxOccupants;
  final String status; // AVAILABLE, OCCUPIED, MAINTENANCE, INACTIVE
  final double monthlyRent;
  final double defaultDeposit;
  final String? description;
  final String? currentTenantName;
  final int? currentTenantId;
  final String? currentTenantPhone;
  final int? activeContractId;
  final DateTime? contractStartDate;
  final DateTime? contractEndDate;

  const Room({
    required this.id,
    required this.roomNumber,
    this.buildingId,
    this.floorId,
    this.floor,
    this.building,
    this.area,
    this.maxOccupants,
    required this.status,
    required this.monthlyRent,
    this.defaultDeposit = 0,
    this.description,
    this.currentTenantName,
    this.currentTenantId,
    this.currentTenantPhone,
    this.activeContractId,
    this.contractStartDate,
    this.contractEndDate,
  });

  factory Room.fromJson(Map<String, dynamic> json) {
    return Room(
      id: (json['id'] as num).toInt(),
      roomNumber: json['roomNumber'] as String? ?? '',
      buildingId: _buildingId(json['building']),
      floorId: _floorId(json['floor']),
      floor: _floorNumber(json['floor']),
      building: _buildingName(json['buildingName'] ?? json['building']),
      area: ((json['area'] ?? json['areaM2']) as num?)?.toDouble(),
      maxOccupants: (json['maxOccupants'] as num?)?.toInt(),
      status: json['status'] as String? ?? 'AVAILABLE',
      monthlyRent:
          ((json['monthlyRent'] ?? json['defaultRent']) as num?)?.toDouble() ?? 0,
      defaultDeposit: (json['defaultDeposit'] as num?)?.toDouble() ?? 0,
      description: json['description'] as String?,
      currentTenantName: json['currentTenantName'] as String?,
      currentTenantId: (json['currentTenantId'] as num?)?.toInt(),
      currentTenantPhone: json['currentTenantPhone'] as String?,
      activeContractId: (json['activeContractId'] as num?)?.toInt(),
      contractStartDate: json['contractStartDate'] != null
          ? DateTime.tryParse(json['contractStartDate'] as String)
          : null,
      contractEndDate: json['contractEndDate'] != null
          ? DateTime.tryParse(json['contractEndDate'] as String)
          : null,
    );
  }

  bool get isOccupied => status == 'OCCUPIED';
  bool get isAvailable => status == 'AVAILABLE';
}

int? _floorNumber(dynamic value) {
  if (value is num) return value.toInt();
  if (value is Map<String, dynamic>) {
    return (value['floorNumber'] as num?)?.toInt() ?? (value['number'] as num?)?.toInt();
  }
  return null;
}

int? _floorId(dynamic value) {
  if (value is Map<String, dynamic>) return (value['id'] as num?)?.toInt();
  return null;
}

int? _buildingId(dynamic value) {
  if (value is Map<String, dynamic>) return (value['id'] as num?)?.toInt();
  return null;
}

String? _buildingName(dynamic value) {
  if (value is String) return value;
  if (value is Map<String, dynamic>) return value['name'] as String?;
  return null;
}

class RoomRequest {
  final String roomNumber;
  final int buildingId;
  final int floorId;
  final double areaM2;
  final double defaultDeposit;
  final int? maxOccupants;
  final double defaultRent;
  final String? description;

  RoomRequest({
    required this.roomNumber,
    int? buildingId,
    int? floorId,
    int? floor,
    String? building,
    double? areaM2,
    double? area,
    double? defaultRent,
    double? monthlyRent,
    double? defaultDeposit,
    String? status,
    this.maxOccupants,
    this.description,
  })  : buildingId = buildingId ?? 1,
        floorId = floorId ?? floor ?? 1,
        areaM2 = areaM2 ?? area ?? 0,
        defaultRent = defaultRent ?? monthlyRent ?? 0,
        defaultDeposit = defaultDeposit ?? monthlyRent ?? 0;

  Map<String, dynamic> toJson() => {
        'buildingId': buildingId,
        'floorId': floorId,
        'roomNumber': roomNumber,
        'areaM2': areaM2,
        'defaultRent': defaultRent,
        'defaultDeposit': defaultDeposit,
        if (maxOccupants != null) 'maxOccupants': maxOccupants,
        if (description != null) 'description': description,
      };
}
