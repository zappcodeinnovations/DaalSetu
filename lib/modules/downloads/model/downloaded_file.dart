class DownloadedFile {
  const DownloadedFile({
    required this.name,
    required this.target,
    required this.size,
    required this.modifiedAt,
    required this.mimeType,
  });

  final String name;
  final String target;
  final int size;
  final DateTime modifiedAt;
  final String mimeType;

  factory DownloadedFile.fromMap(Map<dynamic, dynamic> map) {
    final rawModified = map['modifiedAt'];
    final modifiedMillis = rawModified is num
        ? rawModified.toInt()
        : int.tryParse(rawModified?.toString() ?? '') ?? 0;
    return DownloadedFile(
      name: map['name']?.toString() ?? 'Download',
      target: map['target']?.toString() ?? '',
      size: map['size'] is num
          ? (map['size'] as num).toInt()
          : int.tryParse(map['size']?.toString() ?? '') ?? 0,
      modifiedAt: DateTime.fromMillisecondsSinceEpoch(modifiedMillis),
      mimeType: map['mimeType']?.toString() ?? 'application/octet-stream',
    );
  }
}
