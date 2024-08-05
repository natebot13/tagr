part of 'tag_filter_cubit.dart';

@immutable
sealed class TagFilterState {
  String get query;
}

final class TagFilterDone extends TagFilterState {
  @override
  String get query => '';
}

final class FilteringTags extends TagFilterState {
  final String query;
  FilteringTags(this.query);
}
