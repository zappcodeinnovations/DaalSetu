enum AdminDetailFieldType {
  text,
  date,
  status,
  boolean,
  phone,
  email,
  image,
  video,
  download,
}

class AdminDetailField {
  final String key;
  final String label;
  final AdminDetailFieldType type;
  final bool copyable;

  const AdminDetailField(
    this.key,
    this.label, {
    this.type = AdminDetailFieldType.text,
    this.copyable = false,
  });
}

class AdminDetailSection {
  final String title;
  final List<AdminDetailField> fields;

  const AdminDetailSection({
    required this.title,
    required this.fields,
  });
}
