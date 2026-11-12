class OfferOption {
  const OfferOption({required this.id, required this.name, this.subtitle = ''});

  final int id;
  final String name;
  final String subtitle;
}

class OfferBranch extends OfferOption {
  const OfferBranch({
    required super.id,
    required super.name,
    required this.code,
    required this.city,
    required this.state,
  }) : super(subtitle: '$city, $state');

  final String code;
  final String city;
  final String state;
}
