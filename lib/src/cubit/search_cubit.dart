import 'dart:async';
import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:collection/collection.dart';
import 'package:decimal/decimal.dart';
import 'package:eval_ex/built_ins.dart';
import 'package:eval_ex/expression.dart';
import 'package:meta/meta.dart';
import 'package:rxdart/rxdart.dart';
import 'package:tagr/src/cubit/vault_cubit.dart';
import 'package:tagr/src/extensions.dart';
import 'package:tagr/src/generated/tagr.pb.dart';
import 'package:tagr/src/generated/tagr.pbserver.dart';

part 'search_state.dart';

class _FilterPair {
  bool keep;
  VaultFile file;
  _FilterPair(this.keep, this.file);
}

class SearchCubit extends Cubit<SearchState> {
  VaultOpen vaultOpen;
  SearchCubit(this.vaultOpen) : super(SearchResults(vaultOpen.vault.files));

  void search(value) async {
    final searchTerms = parse(value);

    final progress = <VaultFile>[];
    final bufferedFilterStream = Stream.fromIterable(vaultOpen.vault.files)
        .asyncMap((file) async => _FilterPair(
              await filterFunction(searchTerms, file, vaultOpen),
              file,
            ))
        .where((pair) => pair.keep)
        .map((pair) => pair.file)
        .bufferTime(const Duration(milliseconds: 200));
    // This could use a periodic
    await for (final files in bufferedFilterStream) {
      progress.addAll(files);
      emit(SearchResults(progress));
    }
    emit(SearchResults(progress));
  }

  List<SearchTerm> parse(String query) {
    // https://stackoverflow.com/questions/366202/regex-for-splitting-a-string-using-space-when-not-surrounded-by-single-or-double#comment40428033_366532
    // For example: 'this is a string with "quoted text"' => ['this', 'is', 'a', 'string', 'with', 'quoted text']
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

  Future<bool> filterFunction(
    List<SearchTerm> searchTerms,
    VaultFile file,
    VaultOpen vaultOpen,
  ) async {
    final matches = await Future.wait(
      searchTerms.map((term) => term.matches(file, vaultOpen)),
    );
    return matches.every((b) => b);
  }
}

extension on SearchTerm {
  /// To be used from an "every" context
  Future<bool> matches(VaultFile file, VaultOpen vaultOpen) async {
    if (isMeta) {
      String lhs = '';
      String rhs = '';
      if (term == '#tags') {
        lhs = '${file.tags.values.length}';
        rhs = param?.isNotEmpty == true ? param! : '>0';
      }
      if (term == '#modified') {
        final stat = await FileStat.stat(vaultOpen.fullPath(file.path));
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

    // Not a meta tag, see if it matches a file tag
    final matchedPair = file.tags.values.entries
        .map(
          (entry) => TagTypeValuePair(
            tagType: vaultOpen.vault.tagTypes[entry.key]!,
            tagValue: entry.value,
          ),
        )
        .firstWhereOrNull(
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
    final exp = Expression('$valueString$param');

    try {
      return exp.eval().toString() == '1';
    } on ExpressionException {
      return false;
    }
  }
}
