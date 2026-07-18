import 'invoice_models.dart';
import 'maintenance_models.dart';

class TenantDashboardResponse {
  final CurrentRoomInfo? currentRoom;
  final Invoice? currentInvoice;
  final double? totalDebt;
  final List<MaintenanceRequest> recentMaintenanceRequests;
  final int unreadNotifications;

  const TenantDashboardResponse({
    this.currentRoom,
    this.currentInvoice,
    this.totalDebt,
    this.recentMaintenanceRequests = const [],
    this.unreadNotifications = 0,
  });

  factory TenantDashboardResponse.fromJson(Map<String, dynamic> json) {
    final invoiceData = json['currentInvoice'] ?? json['latestInvoice'];
    final parsedInvoice = invoiceData is Map<String, dynamic>
        ? Invoice.fromJson(invoiceData)
        : null;

    return TenantDashboardResponse(
      currentRoom: json['currentRoom'] != null
          ? CurrentRoomInfo.fromJson(
              json['currentRoom'] as Map<String, dynamic>,
            )
          : null,
      currentInvoice: parsedInvoice?.isVisibleToTenant == true
          ? parsedInvoice
          : null,
      totalDebt:
          ((json['totalDebt'] ?? json['currentDebt']) as num?)?.toDouble() ?? 0,
      recentMaintenanceRequests:
          (json['recentMaintenanceRequests'] as List<dynamic>? ?? [])
              .map(
                (e) => MaintenanceRequest.fromJson(e as Map<String, dynamic>),
              )
              .toList(),
      unreadNotifications: json['unreadNotifications'] as int? ?? 0,
    );
  }
}

class CurrentRoomInfo {
  final int? id;
  final String? roomNumber;
  final int? floor;
  final String? buildingName;
  final double? monthlyRent;
  final String? status;
  final String? type;
  final double? area;

  const CurrentRoomInfo({
    this.id,
    this.roomNumber,
    this.floor,
    this.buildingName,
    this.monthlyRent,
    this.status,
    this.type,
    this.area,
  });

  factory CurrentRoomInfo.fromJson(Map<String, dynamic> json) {
    return CurrentRoomInfo(
      id: json['id'] as int?,
      roomNumber: json['roomNumber'] as String?,
      floor: _floorNumber(json['floor']),
      buildingName:
          json['buildingName'] as String? ??
          (json['building'] as Map<String, dynamic>?)?['name'] as String?,
      monthlyRent: ((json['monthlyRent'] ?? json['defaultRent']) as num?)
          ?.toDouble(),
      status: json['status'] as String?,
      type: json['type'] as String?,
      area: ((json['area'] ?? json['areaM2']) as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'roomNumber': roomNumber,
    'floor': floor,
    'buildingName': buildingName,
    'monthlyRent': monthlyRent,
    'status': status,
    'type': type,
    'area': area,
  };
}

int? _floorNumber(dynamic value) {
  if (value is num) return value.toInt();
  if (value is Map<String, dynamic>) {
    return (value['floorNumber'] as num?)?.toInt() ??
        (value['number'] as num?)?.toInt();
  }
  return null;
}

class TenantProfile {
  final int? id;
  final int? userId;
  final String? username;
  final String? fullName;
  final String? email;
  final String? phone;
  final String? idNumber;
  final String? idType;
  final String? address;
  final String? dateOfBirth;
  final String? identityIssuedDate;
  final String? identityIssuedPlace;
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final String? currentRoom;
  final bool? active;
  final String? status;
  final String? userStatus;
  final bool? mustChangePassword;
  final String? createdAt;

  const TenantProfile({
    this.id,
    this.userId,
    this.username,
    this.fullName,
    this.email,
    this.phone,
    this.idNumber,
    this.idType,
    this.address,
    this.dateOfBirth,
    this.identityIssuedDate,
    this.identityIssuedPlace,
    this.emergencyContactName,
    this.emergencyContactPhone,
    this.currentRoom,
    this.active,
    this.status,
    this.userStatus,
    this.mustChangePassword,
    this.createdAt,
  });

  factory TenantProfile.fromJson(Map<String, dynamic> json) {
    final user = json['user'];
    final status = json['status'] as String?;
    final userStatus = user is Map<String, dynamic>
        ? user['status'] as String?
        : null;
    return TenantProfile(
      id: (json['id'] as num?)?.toInt(),
      userId: user is Map<String, dynamic>
          ? (user['id'] as num?)?.toInt()
          : (json['userId'] as num?)?.toInt(),
      username:
          json['username'] as String? ??
          (user is Map<String, dynamic> ? user['username'] as String? : null),
      fullName: json['fullName'] as String?,
      email:
          json['email'] as String? ??
          (user is Map<String, dynamic> ? user['email'] as String? : null),
      phone:
          json['phone'] as String? ??
          (user is Map<String, dynamic> ? user['phone'] as String? : null),
      idNumber:
          json['idNumber'] as String? ?? json['identityNumber'] as String?,
      idType: json['idType'] as String? ?? json['identityType'] as String?,
      address:
          json['address'] as String? ?? json['permanentAddress'] as String?,
      dateOfBirth: json['dateOfBirth'] as String?,
      identityIssuedDate: json['identityIssuedDate'] as String?,
      identityIssuedPlace: json['identityIssuedPlace'] as String?,
      emergencyContactName: json['emergencyContactName'] as String?,
      emergencyContactPhone: json['emergencyContactPhone'] as String?,
      currentRoom: json['currentRoom'] as String?,
      active:
          json['active'] as bool? ??
          (status == null ? null : status == 'ACTIVE') ??
          (userStatus == null ? null : userStatus == 'ACTIVE'),
      status: status ?? userStatus,
      userStatus: userStatus,
      mustChangePassword:
          json['mustChangePassword'] as bool? ??
          (user is Map<String, dynamic>
              ? user['mustChangePassword'] as bool?
              : null),
      createdAt: json['createdAt'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'username': username,
    'fullName': fullName,
    'email': email,
    'phone': phone,
    'idNumber': idNumber,
    'idType': idType,
    'address': address,
    'dateOfBirth': dateOfBirth,
    'identityIssuedDate': identityIssuedDate,
    'identityIssuedPlace': identityIssuedPlace,
    'emergencyContactName': emergencyContactName,
    'emergencyContactPhone': emergencyContactPhone,
    'currentRoom': currentRoom,
    'active': active,
    'status': status,
    'userStatus': userStatus,
    'mustChangePassword': mustChangePassword,
    'createdAt': createdAt,
  };
}

class TenantRequest {
  final int? userId;
  final String? fullName;
  final String? email;
  final String? phone;
  final String? idNumber;
  final String? idType;
  final String? address;
  final String? dateOfBirth;
  final String? identityIssuedDate;
  final String? identityIssuedPlace;
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final String? username;
  final String? password;

  const TenantRequest({
    this.userId,
    this.fullName,
    this.email,
    this.phone,
    this.idNumber,
    this.idType,
    this.address,
    this.dateOfBirth,
    this.identityIssuedDate,
    this.identityIssuedPlace,
    this.emergencyContactName,
    this.emergencyContactPhone,
    this.username,
    this.password,
  });

  Map<String, dynamic> toAccountJson() => {
    'username': username,
    'temporaryPassword': password,
    'fullName': fullName,
    'phone': phone,
    'email': email,
  };

  Map<String, dynamic> toProfileJson(int linkedUserId) => {
    'userId': linkedUserId,
    'fullName': fullName,
    'email': email,
    'phone': phone,
    'dateOfBirth': dateOfBirth ?? '1990-01-01',
    'identityType': idType,
    'identityNumber': idNumber,
    'identityIssuedDate': identityIssuedDate,
    'identityIssuedPlace': identityIssuedPlace,
    'permanentAddress': address,
    'emergencyContactName': emergencyContactName,
    'emergencyContactPhone': emergencyContactPhone,
  };
}
