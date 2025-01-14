import 'dart:async';
import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:collection/collection.dart';
import 'package:decimal/decimal.dart';
import 'package:eval_ex/built_ins.dart';
import 'package:eval_ex/expression.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;
import 'package:rxdart/rxdart.dart';
import 'package:tagr/src/cubit/vault_cubit.dart';
import 'package:tagr/src/extensions.dart';
import 'package:tagr/src/generated/tagr.pb.dart';
import 'package:tagr/src/helpers.dart';

part 'filter_state.dart';

enum MetaTerm {
  tags,
  created,
  modified,
  size,
}

final Map<String, MetaTerm> metaTermNameMap = MetaTerm.values.asNameMap();

class FilterTerm {
  final String term;
  final String? param;
  final bool isNegative;
  final TermType termType;
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

/// Helper class for expressions
class FilterExpressionBuilder {
  String lhs = '';
  String rhs = '';
  String defaultOp = '=';

  Expression? build() {
    final expression = Expression('$lhs$rhs');
    _addCustom(expression);

    try {
      if (!expression.isBoolean()) return Expression('$lhs$defaultOp$rhs');
      return expression;
    } on ExpressionException catch (e) {
      logger.e(e);
      return null;
    }
  }

  // Adds all the custom functions to the expression
  void _addCustom(Expression exp) {
    exp.addFunc(FunctionImpl(
      'NOW',
      0,
      fEval: (params) => Decimal.fromInt(DateTime.now().millisecondsSinceEpoch),
    ));
    exp.addFunc(FunctionImpl(
      'DAYS',
      1,
      fEval: (params) => Decimal.fromInt(Duration(
        days: params.first.toBigInt().toInt(),
      ).inMilliseconds),
    ));
    for (final unit in SizeUnit.values) {
      exp.addOperator(OperatorSuffixImpl(
        unit.name,
        62,
        false,
        fEval: (d) => d * Decimal.fromInt(unit.getScale()),
      ));
    }
  }
}

class _FilterPair {
  bool keep;
  VaultFile file;
  _FilterPair(this.keep, this.file);
}

class FilterCubit extends Cubit<FilterState> {
  FilterCubit() : super(FilterInitial());

  void filter(String query, VaultOpen vaultOpen) async {
    final filterTerms = parse(query);

    final progress = <VaultFile>[];
    final bufferedFilterStream = Stream.fromIterable(vaultOpen.vault.files)
        .asyncMap((file) async => _FilterPair(
              await filterFunction(filterTerms, file, vaultOpen),
              file,
            ))
        .where((pair) => pair.keep)
        .map((pair) => pair.file)
        .bufferTime(const Duration(milliseconds: 200));

    await for (final files in bufferedFilterStream) {
      progress.addAll(files);
      emit(FilterResults(query, progress));
    }
    emit(FilterResults(query, progress));
  }

  List<FilterTerm> parse(String query) {
    // https://stackoverflow.com/questions/366202/regex-for-splitting-a-string-using-space-when-not-surrounded-by-single-or-double#comment40428033_366532
    // For example: 'unquoted and "quoted text"' => ['unquoted', 'and', 'quoted text']
    final quoteSplitPattern = RegExp(r'''"([^"]*)"|'([^']*)'|[^\s]+''');

    // https://stackoverflow.com/a/366532/2577975
    return quoteSplitPattern
        .allMatches(query)
        .map((match) {
          if (match.group(1) != null) return match.group(1)!;
          if (match.group(2) != null) return match.group(2)!;
          return match.group(0)!;
        })
        .map(FilterTerm.create)
        .toList();
  }

  Future<bool> filterFunction(
    List<FilterTerm> filterTerms,
    VaultFile file,
    VaultOpen vaultOpen,
  ) async {
    // Collect each tag on this file with its tag type from the vault
    final tagTypePairs = file.tags.values.entries.map(
      (entry) => TagTypeValuePair(
        tagType: vaultOpen.vault.tagTypes[entry.key]!,
        tagValue: entry.value,
      ),
    );

    // Filter out hidden tags unless they any were explicitly searched for
    final hiddenTags = tagTypePairs.where((pair) => pair.tagType.isHidden);
    final filteredForHidden = hiddenTags.any(
      (pair) => filterTerms.any(
        (term) => pair.tagType.name.toLowerCase() == term.term,
      ),
    );
    if (hiddenTags.isNotEmpty && !filteredForHidden) return false;

    // Collect a future for each search term
    final matches = await Future.wait(
      filterTerms.map(
        (term) => term.matches(tagTypePairs, vaultOpen.root, file.path),
      ),
    );

    // This file matches the query if every search term returns true
    return matches.every((b) => b);
  }
}

extension on FilterTerm {
  /// Returns false only if the term doesn't match the file. Otherwise, assumes
  /// that the term is malformed and returns true. This enables this function to
  /// be used in an 'every' context, only filtering out files that are
  /// definitely not a match, but keeping files that are unsure if it's a match.
  Future<bool> matches(
    Iterable<TagTypeValuePair> tagTypePairs,
    Directory root,
    String filePath,
  ) async {
    final fullPath = path.join(root.path, filePath);
    final expressionBuilder = FilterExpressionBuilder();
    if (termType == TermType.meta) {
      final metaTerm = metaTermNameMap[term];

      // TODO: Notify the user about using an invalid meta tag name
      if (metaTerm == null) return true;

      switch (metaTerm) {
        case MetaTerm.tags:
          expressionBuilder.lhs = '${tagTypePairs.length}';
          expressionBuilder.rhs = param?.isNotEmpty == true ? param! : '>0';
          break;
        case MetaTerm.modified:
        case MetaTerm.created:
          final stat = await FileStat.stat(fullPath);
          final date =
              metaTerm == MetaTerm.modified ? stat.modified : stat.changed;
          expressionBuilder.lhs = '${date.millisecondsSinceEpoch}';
          expressionBuilder.rhs = param?.isNotEmpty == true ? param! : '>0';
          break;
        case MetaTerm.size:
          final stat = await FileStat.stat(fullPath);
          if (param == null) return true;
          if (param!.isEmpty) return true;
          expressionBuilder.lhs = '${stat.size}';
          expressionBuilder.rhs = param!;
          break;
      }
    }

    if (termType == TermType.path) {
      final parts = path.split(path.dirname(filePath));
      if (isPositive) return parts.contains(term);
      return !parts.contains(term);
    }

    if (termType == TermType.fileType) {
      final ext = path.extension(filePath);
      if (isPositive) return term == ext;
      return term != ext;
    }

    if (termType == TermType.tag) {
      // Not a meta tag, see if it matches a file tag
      final matchedPair = tagTypePairs.firstWhereOrNull(
        (typeValuePair) => typeValuePair.tagType.name.toLowerCase() == term,
      );

      if (matchedPair == null && isPositive) return false;
      if (matchedPair != null && isNegative) return false;
      if (isNegative) return true;

      // Being here means we have a nameMatch and we're positive

      // Flags are always matches
      if (matchedPair!.tagType.isFlag) return true;

      // If the param is null or empty, it's a match
      if (param == null || param!.isEmpty) return true;

      // Check the param
      var tagValue = matchedPair.tagValue!;
      if (tagValue.whichValue() == TagValue_Value.notSet) {
        tagValue = matchedPair.tagType.defaultValue;
      }

      expressionBuilder.lhs = tagValue.asStringValue();
      expressionBuilder.rhs = '$param';
    }

    final expression = expressionBuilder.build();
    if (expression == null) return true;

    try {
      return expression.eval().toString() == '1';
    } on ExpressionException catch (e) {
      logger.e(e);
      return false;
    }
  }
}
