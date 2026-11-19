import 'package:uuid/uuid.dart';

class DesignModel {
  final String id;
  final String title;
  final double widthMm;
  final double heightMm;
  final double depthMm;
  final String fileName;
  final DateTime createdAt;
  final bool isTrashed;
  final String? thumbnailPath;

  DesignModel({
    String? id,
    required this.title,
    required this.widthMm,
    required this.heightMm,
    required this.depthMm,
    required this.fileName,
    required this.createdAt,
    this.isTrashed = false,
    this.thumbnailPath,
  }) : id = id ?? const Uuid().v4();

  DesignModel copyWith({
    String? id,
    String? title,
    double? widthMm,
    double? heightMm,
    double? depthMm,
    String? fileName,
    DateTime? createdAt,
    bool? isTrashed,
    String? thumbnailPath,
  }) {
    return DesignModel(
      id: id ?? this.id,
      title: title ?? this.title,
      widthMm: widthMm ?? this.widthMm,
      heightMm: heightMm ?? this.heightMm,
      depthMm: depthMm ?? this.depthMm,
      fileName: fileName ?? this.fileName,
      createdAt: createdAt ?? this.createdAt,
      isTrashed: isTrashed ?? this.isTrashed,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'widthMm': widthMm,
      'heightMm': heightMm,
      'depthMm': depthMm,
      'fileName': fileName,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'isTrashed': isTrashed ? 1 : 0,
      'thumbnailPath': thumbnailPath,
    };
  }

  factory DesignModel.fromMap(Map<String, dynamic> map) {
    return DesignModel(
      id: map['id'] as String,
      title: map['title'] as String,
      widthMm: (map['widthMm'] as num).toDouble(),
      heightMm: (map['heightMm'] as num).toDouble(),
      depthMm: (map['depthMm'] as num).toDouble(),
      fileName: map['fileName'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      isTrashed: (map['isTrashed'] as int) == 1,
      thumbnailPath: map['thumbnailPath'] as String?,
    );
  }

  @override
  String toString() {
    return 'DesignModel(id: $id, title: $title, widthMm: $widthMm, heightMm: $heightMm, depthMm: $depthMm, fileName: $fileName, createdAt: $createdAt, isTrashed: $isTrashed, thumbnailPath: $thumbnailPath)';
  }
}
