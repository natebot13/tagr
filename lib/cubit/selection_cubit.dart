import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

part 'selection_state.dart';

class SelectionCubit extends Cubit<SelectionState> {
  SelectionCubit() : super(SelectionNone());

  void select(String id) {
    final state_ = state;
    if (state_ is SelectionMultiple) {
      _addOrRemoveSelection(id, state_.selected);
    } else {
      emit(SelectionSingle(id));
    }
  }

  void _addOrRemoveSelection(String id, Set<String> selections) {
    if (selections.contains(id)) {
      final diff = selections.difference({id});
      if (diff.isEmpty) {
        emit(SelectionNone());
      } else {
        emit(SelectionMultiple(diff));
      }
    } else {
      emit(SelectionMultiple({...selections, id}));
    }
  }

  void longSelect(String id) {
    final state_ = state;
    if (state_ is SelectionMultiple) {
      _addOrRemoveSelection(id, state_.selected);
    } else {
      emit(SelectionMultiple({id}));
    }
  }
}
