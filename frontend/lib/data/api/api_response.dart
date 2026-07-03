/// Generic API response wrapper matching backend ApiResponse<T>
/// Backend format: { "success": true, "message": "...", "data": {} }
class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;

  const ApiResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic json)? fromJsonT,
  ) {
    return ApiResponse<T>(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      data: json['data'] != null && fromJsonT != null
          ? fromJsonT(json['data'])
          : json['data'] as T?,
    );
  }
}

/// Paginated response wrapper matching backend PageResponse<T>
/// Backend format:
/// {
///   "content": [...],
///   "page": { "size": 20, "number": 0, "totalElements": 100, "totalPages": 5 }
/// }
class PageResponse<T> {
  final List<T> content;
  final int page;
  final int size;
  final int totalElements;
  final int totalPages;
  final bool last;

  const PageResponse({
    required this.content,
    required this.page,
    required this.size,
    required this.totalElements,
    required this.totalPages,
    this.last = false,
  });

  bool get hasNextPage => page < totalPages - 1;
  bool get isEmpty => content.isEmpty;

  factory PageResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final contentList = ((json['content'] ?? json['items']) as List<dynamic>? ?? [])
        .map((e) => fromJson(e as Map<String, dynamic>))
        .toList();

    // Spring Boot 3.x uses nested "page" object
    final rawPage = json['page'];
    final pageInfo = rawPage is Map<String, dynamic> ? rawPage : null;
    if (pageInfo != null) {
      return PageResponse<T>(
        content: contentList,
        page: pageInfo['number'] as int? ?? 0,
        size: pageInfo['size'] as int? ?? 20,
        totalElements: pageInfo['totalElements'] as int? ?? 0,
        totalPages: pageInfo['totalPages'] as int? ?? 1,
        last: json['last'] as bool? ?? true,
      );
    }

    // Fallback: flat format
    return PageResponse<T>(
      content: contentList,
      page: json['number'] as int? ?? json['page'] as int? ?? 0,
      size: json['size'] as int? ?? 20,
      totalElements: (json['totalElements'] as int?) ??
          (json['totalItems'] as int?) ??
          contentList.length,
      totalPages: json['totalPages'] as int? ?? 1,
      last: json['last'] as bool? ?? true,
    );
  }

  PageResponse<T> copyWith({List<T>? content}) {
    return PageResponse<T>(
      content: content ?? this.content,
      page: page,
      size: size,
      totalElements: totalElements,
      totalPages: totalPages,
      last: last,
    );
  }
}
