import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

part 'vault_state.dart';

class VaultCubit extends Cubit<VaultState> {
  VaultCubit() : super(VaultInitial());

  void openVault(String path) async {
    emit(VaultLoading());
    final files = await Directory(path)
        .list(recursive: true)
        .where((entity) => entity is File)
        .cast<File>()
        .toList();
    emit(VaultOpen(files));
  }
}
