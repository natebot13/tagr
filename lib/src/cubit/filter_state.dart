part of 'filter_cubit.dart';

class FilterTerm {
  final String term;
  final String? param;
  final bool isNegative;
  bool get isPositive => !isNegative;
  bool get isMeta => term.startsWith("#");
  FilterTerm(this.term, {this.param, this.isNegative = false});
}

@immutable
sealed class FilterState {}

final class FilterInitial extends FilterState {}

final class FilterResults extends FilterState {
  final String query;
  final List<VaultFile> results;
  FilterResults(this.query, this.results);
}
