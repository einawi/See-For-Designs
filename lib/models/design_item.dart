import 'package:uuid/uuid.dart';

class DesignItem {
  final String id;
  final String title;
  final double widthMm;
  final double heightMm;
  final double depthMm;
  final String filePath;
  final String thumbnailPath;
  final DateTime createdAt;
  final bool isTrashed;

  DesignItem({
    String? id,
    required this.title,
    required this.widthMm,
    required this.heightMm,
    required this.depthMm,
    required this.filePath,
    required this.thumbnailPath,
    DateTime? createdAt,
    this.isTrashed = false,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  DesignItem copyWith({
    String? id,
    String? title,
    double? widthMm,
    double? heightMm,
    double? depthMm,
    String? filePath,
    String? thumbnailPath,
    DateTime? createdAt,
    bool? isTrashed,
  }) {
    return DesignItem(
      id: id ?? this.id,
      title: title ?? this.title,
      widthMm: widthMm ?? this.widthMm,
      heightMm: heightMm ?? this.heightMm,
      depthMm: depthMm ?? this.depthMm,
      filePath: filePath ?? this.filePath,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      createdAt: createdAt ?? this.createdAt,
      isTrashed: isTrashed ?? this.isTrashed,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'widthMm': widthMm,
      'heightMm': heightMm,
      'depthMm': depthMm,
      'filePath': filePath,
      'thumbnailPath': thumbnailPath,
      'createdAt': createdAt.toIso8601String(),
      'isTrashed': isTrashed ? 1 : 0,
    };
  }

  factory DesignItem.fromMap(Map<String, dynamic> map) {
    return DesignItem(
      id: map['id'],
      title: map['title'],
      widthMm: map['widthMm'],
      heightMm: map['heightMm'],
      depthMm: map['depthMm'],
      filePath: map['filePath'],
      thumbnailPath: map['thumbnailPath'],
      createdAt: DateTime.parse(map['createdAt']),
      isTrashed: map['isTrashed'] == 1,
    );
  }

  String get dimensionsText => '${widthMm.toStringAsFixed(1)} × ${heightMm.toStringAsFixed(1)} × ${depthMm.toStringAsFixed(1)} mm';
}
