enum SessionSource {
  manual(labelKey: 'source_manual'),
  watchHttp(labelKey: 'source_watch');

  const SessionSource({required this.labelKey});

  /// Translation key (AppLocalizations) for the source name.
  final String labelKey;

  /// Stable (English) name used in data export (CSV/JSON).
  String get displayName {
    switch (this) {
      case SessionSource.manual:
        return 'Manual';
      case SessionSource.watchHttp:
        return 'Watch (HTTP)';
    }
  }

  String toJson() => name;

  static SessionSource fromJson(String value) {
    return SessionSource.values.firstWhere(
      (e) => e.name == value,
      orElse: () => SessionSource.manual,
    );
  }
}
