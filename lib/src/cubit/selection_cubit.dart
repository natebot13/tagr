import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:tagr/src/repository/vault_repository.dart';

part 'selection_state.dart';

class SelectionCubit extends Cubit<SelectionState> {
  final VaultRepository _repository;
  SelectionCubit(this._repository) : super(SelectionNone()) {
    // Listen to updates of the vault to ensure we're not still selecting files
    // that may have been removed.
    _repository.vault.listen((update) {
      final newSelected = <String>{};
      if (state.selected.isEmpty) return;
      for (var vaultFile in update.vault.files) {
        // For every file in the vault, if it's currently selected, keep it.
        if (state.selected.contains(vaultFile.path)) {
          newSelected.add(vaultFile.path);
        }
      }
    });
  }

  void refresh(Set<String> update) {
    if (update.isEmpty) {
      return emit(SelectionNone());
    }

    if (update.length == 1) {
      return emit(SelectionSingle(update.single));
    }

    return emit(SelectionMultiple(update));
  }

  void select(String id, {bool multi = false, bool forceSingle = false}) {
    if (state is SelectionChoosing) {
      final choosing = state as SelectionChoosing;
      return emit(SelectionChosen(choosing.tagTypeId, id, state.selected));
    }
    if (forceSingle) {
      emit(SelectionSingle(id));
    } else if (multi || state is SelectionMultiple) {
      _addOrRemoveSelection(id);
    } else {
      if (state.selected.contains(id)) {
        emit(SelectionNone());
      } else {
        emit(SelectionSingle(id));
      }
    }
  }

  void unselect() {
    if (state is SelectionChoosing) {
      emit(SelectionMultiple(state.selected));
    } else {
      emit(SelectionNone());
    }
  }

  void startChoosing(int tagTypeId) {
    emit(SelectionChoosing(tagTypeId, state.selected));
  }

  void _addOrRemoveSelection(String id) {
    if (state.selected.contains(id)) {
      final diff = state.selected.difference({id});
      if (diff.isEmpty) {
        emit(SelectionNone());
      } else {
        emit(SelectionMultiple(diff));
      }
    } else {
      emit(SelectionMultiple({...state.selected, id}));
    }
  }
}
