import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

part 'selection_state.dart';

class SelectionCubit extends Cubit<SelectionState> {
  SelectionCubit() : super(SelectionNone());

  void select(String id, {bool multi = false}) {
    if (multi || state is SelectionMultiple) {
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
    emit(SelectionNone());
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
