import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

part 'selection_state.dart';

class SelectionCubit extends Cubit<SelectionState> {
  SelectionCubit() : super(SelectionNone());

  void select(String id, {bool multi = false, bool forceSingle = false}) {
    if (state is SelectionChoosing) {
      final choosing = state as SelectionChoosing;
      emit(SelectionChosen(choosing.tagTypeId, id, state.selected));
      return;
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
