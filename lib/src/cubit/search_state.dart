part of 'search_cubit.dart';

@immutable
sealed class SearchState {
  String get query;
}

final class SearchDone extends SearchState {
  @override
  String get query => '';
}

final class Searching extends SearchState {
  final String query;
  Searching(this.query);
}
