part of 'filter_cubit.dart';

enum TermType {
  tag,
  meta,
  path,
  fileType,
}

@immutable
sealed class FilterState {}

final class FilterInitial extends FilterState {}

final class FilterResults extends FilterState {
  final String query;
  final List<VaultFile> results;
  FilterResults(this.query, this.results);
}
