part of 'search_cubit.dart';

class SearchTerm {
  final String term;
  final String? param;
  final bool isNegative;
  bool get isPositive => !isNegative;
  bool get isMeta => term.startsWith("#");
  SearchTerm(this.term, {this.param, this.isNegative = false});
}

@immutable
sealed class SearchState {}

final class SearchResults extends SearchState {
  final List<VaultFile> results;
  SearchResults(this.results);
}
