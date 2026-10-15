/// Maps to the `Reviews` table.
class Review {
  final int reviewId;
  final int jobId;
  final int customerId;
  final int laborId;
  final int rating; // 1..5
  final String? comment;

  const Review({
    required this.reviewId,
    required this.jobId,
    required this.customerId,
    required this.laborId,
    required this.rating,
    this.comment,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      reviewId: (json['review_id'] as num?)?.toInt() ?? 0,
      jobId: (json['job_id'] as num?)?.toInt() ?? 0,
      customerId: (json['customer_id'] as num?)?.toInt() ?? 0,
      laborId: (json['labor_id'] as num?)?.toInt() ?? 0,
      rating: (json['rating'] as num?)?.toInt() ?? 0,
      comment: json['comment'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'review_id': reviewId,
      'job_id': jobId,
      'customer_id': customerId,
      'labor_id': laborId,
      'rating': rating,
      'comment': comment,
    };
  }
}
