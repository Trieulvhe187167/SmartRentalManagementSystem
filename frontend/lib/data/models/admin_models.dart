class AdminDashboardResponse {
  final int totalRooms;
  final int occupiedRooms;
  final int availableRooms;
  final int maintenanceRooms;
  final double monthlyRevenue;
  final double monthlyCollectedAmount;
  final double monthlyDebtAmount;
  final double totalDebt;
  final int pendingMaintenanceCount;
  final int expiringContractsCount;

  const AdminDashboardResponse({
    required this.totalRooms,
    required this.occupiedRooms,
    required this.availableRooms,
    required this.maintenanceRooms,
    required this.monthlyRevenue,
    required this.monthlyCollectedAmount,
    required this.monthlyDebtAmount,
    required this.totalDebt,
    required this.pendingMaintenanceCount,
    required this.expiringContractsCount,
  });

  double get currentMonthRevenue => monthlyCollectedAmount;
  double get currentMonthDebt => monthlyDebtAmount;

  factory AdminDashboardResponse.fromJson(Map<String, dynamic> json) {
    return AdminDashboardResponse(
      totalRooms: (json['totalRooms'] as num?)?.toInt() ?? 0,
      occupiedRooms: (json['occupiedRooms'] as num?)?.toInt() ?? 0,
      availableRooms: (json['availableRooms'] as num?)?.toInt() ?? 0,
      maintenanceRooms: (json['maintenanceRooms'] as num?)?.toInt() ?? 0,
      monthlyRevenue:
          ((json['monthlyRevenue'] ?? json['monthlyInvoiceAmount']) as num?)
              ?.toDouble() ??
          0,
      monthlyCollectedAmount:
          (json['monthlyCollectedAmount'] as num?)?.toDouble() ?? 0,
      monthlyDebtAmount:
          ((json['monthlyDebtAmount'] ?? json['totalDebt']) as num?)
              ?.toDouble() ??
          0,
      totalDebt: (json['totalDebt'] as num?)?.toDouble() ?? 0,
      pendingMaintenanceCount:
          ((json['pendingMaintenanceCount'] ?? json['openMaintenanceRequests'])
                  as num?)
              ?.toInt() ??
          0,
      expiringContractsCount:
          ((json['expiringContractsCount'] ?? json['expiringContracts'])
                  as num?)
              ?.toInt() ??
          0,
    );
  }
}

class MonthlyRevenueData {
  final int month;
  final int year;
  final double totalRevenue;
  final double collectedRevenue;
  final double debtAmount;

  const MonthlyRevenueData({
    required this.month,
    required this.year,
    required this.totalRevenue,
    required this.collectedRevenue,
    required this.debtAmount,
  });

  factory MonthlyRevenueData.fromJson(Map<String, dynamic> json) {
    return MonthlyRevenueData(
      month: (json['month'] as num?)?.toInt() ?? 0,
      year: (json['year'] as num?)?.toInt() ?? 0,
      totalRevenue: (json['totalRevenue'] as num?)?.toDouble() ?? 0,
      collectedRevenue: (json['collectedRevenue'] as num?)?.toDouble() ?? 0,
      debtAmount: (json['debtAmount'] as num?)?.toDouble() ?? 0,
    );
  }
}
