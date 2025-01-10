part of 'filter_cubit.dart';

final _r = RegExp(r'[#/]');

enum TermType {
  tag,
  meta,
  path,
  fileType,
}

class FilterTerm {
  final String term;
  final String? param;
  final bool isNegative;
  final TermType termType;
  bool get isMeta => termType == TermType.meta;
  bool get isPath => termType == TermType.path;
  bool get isPositive => !isNegative;
  FilterTerm._(
    this.term, {
    this.param,
    this.isNegative = false,
    TermType? termType,
  }) : termType = termType ?? TermType.tag;

  static FilterTerm create(String term) {
    bool isNegative = false;
    String? param;
    TermType? termType;
    if (term.startsWith('-')) {
      isNegative = true;
      term = term.substring(1);
    }
    if (term.contains(':')) {
      final t = term.split(':');
      term = t.take(t.length - 1).join(':');
      param = t.last;
    }
    if (term.startsWith('#')) {
      termType = TermType.meta;
      term = term.substring(1);
    } else if (term.startsWith('/')) {
      termType = TermType.path;
      term = term.substring(1);
    } else if (term.startsWith('.')) {
      termType = TermType.fileType;
    }
    return FilterTerm._(
      term,
      param: param,
      isNegative: isNegative,
      termType: termType,
    );
  }
}

@immutable
sealed class FilterState {}

final class FilterInitial extends FilterState {}

final class FilterResults extends FilterState {
  final String query;
  final List<VaultFile> results;
  FilterResults(this.query, this.results);
}
