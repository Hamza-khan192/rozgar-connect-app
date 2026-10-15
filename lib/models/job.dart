/// Maps to the `Jobs` table.
class Job {
  final int jobId;
  final int customerId;
  final int? laborId; // null until a laborer is hired
  final String jobDescription;
  final double? budget;
  final String status; // 'pending' | 'in_progress' | 'completed'
  final DateTime? createdAt;

  const Job({
    required this.jobId,
    required this.customerId,
    this.laborId,
    required this.jobDescription,
    this.budget,
    this.status = 'pending',
    this.createdAt,
  });

  factory Job.fromJson(Map<String, dynamic> json) {
    return Job(
      jobId: (json['job_id'] as num?)?.toInt() ?? 0,
      customerId: (json['customer_id'] as num?)?.toInt() ?? 0,
      laborId: (json['labor_id'] as num?)?.toInt(),
      jobDescription: json['job_description'] as String? ?? '',
      budget: (json['budget'] as num?)?.toDouble(),
      status: json['status'] as String? ?? 'pending',
      createdAt: json['created_at'] == null
          ? null
          : DateTime.tryParse(json['created_at'].toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'job_id': jobId,
      'customer_id': customerId,
      'labor_id': laborId,
      'job_description': jobDescription,
      'budget': budget,
      'status': status,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  Job copyWith({
    int? jobId,
    int? customerId,
    int? laborId,
    String? jobDescription,
    double? budget,
    String? status,
    DateTime? createdAt,
  }) {
    return Job(
      jobId: jobId ?? this.jobId,
      customerId: customerId ?? this.customerId,
      laborId: laborId ?? this.laborId,
      jobDescription: jobDescription ?? this.jobDescription,
      budget: budget ?? this.budget,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
