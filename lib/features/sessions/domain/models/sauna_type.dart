enum SaunaType {
  dry,
  steam;

  String toJson() => name;

  static SaunaType fromJson(String? json) {
    if (json == 'steam') return SaunaType.steam;
    return SaunaType.dry;
  }
}
