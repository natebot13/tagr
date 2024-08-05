part of 'search_cubit.dart';

@immutable
sealed class SearchState {
  String get query;
}

final class SearchValue extends SearchState {
  @override
  final String query;
  SearchValue(this.query);
}
