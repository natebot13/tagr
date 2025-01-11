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

part 'filter_state.dart';

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
    final tagTypePairs = file.tags.values.entries.map(
      (entry) => TagTypeValuePair(
        tagType: vaultOpen.vault.tagTypes[entry.key]!,
        tagValue: entry.value,
      ),
    );

    final hiddenTags = tagTypePairs.where((pair) => pair.tagType.isHidden);
    final filteredForHidden = hiddenTags.any(
      (pair) => filterTerms.any(
        (term) => pair.tagType.name.toLowerCase() == term.term,
      ),
    );
    if (hiddenTags.isNotEmpty && !filteredForHidden) return false;

    final matches = await Future.wait(
      filterTerms.map(
        (term) => term.matches(tagTypePairs, vaultOpen.root, file.path),
      ),
    );
    return matches.every((b) => b);
  }
}

extension on FilterTerm {
  /// To be used from an "every" context
  Future<bool> matches(
    Iterable<TagTypeValuePair> tagTypePairs,
    Directory root,
    String filePath,
  ) async {
    final fullPath = path.join(root.path, filePath);
    if (isMeta) {
      String lhs = '';
      String rhs = '';
      if (term == 'tags') {
        lhs = '${tagTypePairs.length}';
        rhs = param?.isNotEmpty == true ? param! : '>0';
      }
      if (term == 'modified') {
        final stat = await FileStat.stat(fullPath);
        lhs = '${stat.modified.millisecondsSinceEpoch}';
        rhs = param?.isNotEmpty == true ? param! : '>0';
      }
      // IDK if this should return false or true. Ideally there would be some
      // feedback to the user that they've used an invalid meta term.
      if (lhs.isEmpty) return false;

      var exp = Expression('$lhs$rhs');
      exp.addFunc(FunctionImpl(
        'NOW',
        0,
        fEval: (params) =>
            Decimal.fromInt(DateTime.now().millisecondsSinceEpoch),
      ));
      exp.addFunc(FunctionImpl(
        'DAYS',
        1,
        fEval: (params) => Decimal.fromInt(Duration(
          days: params.first.toBigInt().toInt(),
        ).inMilliseconds),
      ));

      try {
        if (!exp.isBoolean()) exp = Expression("$lhs=$rhs");
        return exp.eval().toString() == '1';
      } on ExpressionException {
        return false;
      }
    }

    if (isPath) {
      final parts = path.split(path.dirname(filePath));
      if (isPositive) return parts.contains(term);
      return !parts.contains(term);
    }

    if (termType == TermType.fileType) {
      final ext = path.extension(filePath);
      if (isPositive) return term == ext;
      return term != ext;
    }

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
    final valueString = tagValue.asStringValue();
    var exp = Expression('$valueString$param');

    try {
      if (!exp.isBoolean()) exp = Expression('$valueString=$param');
      return exp.eval().toString() == '1';
    } on ExpressionException {
      return false;
    }
  }
}
