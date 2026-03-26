class PaymeItem {
  final String title;
  final int price;
  final num count;
  final String code;
  final num units;
  final num vatPercent;
  final String packageCode;
  PaymeItem({
    required this.title,
    required this.price,
    required this.count,
    required this.code,
    required this.units,
    required this.vatPercent,
    required this.packageCode,
  });

  Map<String, dynamic> toJson() => {
        "title": title,
        "price": price,
        "count": count,
        "code": code,
        "units": units,
        "vat_percent": vatPercent,
        "package_code": packageCode,
      };
}
