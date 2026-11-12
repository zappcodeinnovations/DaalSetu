class AdminRecord {
  const AdminRecord(this.data);

  final Map<String, dynamic> data;

  String get id =>
      (data['id'] ??
              data['pk'] ??
              data['product_id'] ??
              data['interest_id'] ??
              data['rfq_id'] ??
              '')
          .toString();

  Object? operator [](String key) => data[key];
}
