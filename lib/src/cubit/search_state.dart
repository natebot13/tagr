part of 'search_cubit.dart';

class SearchTerm {
  final String term;
  final String? param;
  final bool isNegative;
  bool get isPositive => !isNegative;
  SearchTerm(this.term, {this.param, this.isNegative = false});
}

@immutable
sealed class SearchState {
  List<SearchTerm> get searchTerms;
}

List<SearchTerm> parse(String query) {
  // https://stackoverflow.com/questions/366202/regex-for-splitting-a-string-using-space-when-not-surrounded-by-single-or-double#comment40428033_366532
  final quoteSplitPattern = RegExp(r'''"([^"]*)"|'([^']*)'|[^\s]+''');

  // https://stackoverflow.com/a/366532/2577975
  return quoteSplitPattern.allMatches(query).map((match) {
    if (match.group(1) != null) return match.group(1)!;
    if (match.group(2) != null) return match.group(2)!;
    return match.group(0)!;
  }).map((term) {
    bool isNegative = false;
    String? param;
    if (term.startsWith('-')) {
      isNegative = true;
      term = term.replaceFirst('-', '');
    }
    if (term.contains(':')) {
      final t = term.split(':');
      term = t.take(t.length - 1).join(':');
      param = t.last;
    }
    return SearchTerm(term, isNegative: isNegative, param: param);
  }).toList();
}

final class SearchValue extends SearchState {
  @override
  final List<SearchTerm> searchTerms;
  SearchValue(String query) : searchTerms = parse(query);
}

extension SearchFiltering on Iterable<SearchTerm> {
  bool containsName(String name) {
    return any((searchTerm) => searchTerm.term == name);
  }
}
