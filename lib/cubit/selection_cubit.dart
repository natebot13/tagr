import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

part 'selection_state.dart';

class SelectionCubit extends Cubit<SelectionState> {
  SelectionCubit() : super(SelectionNone());

  void select(int i) {
    final state_ = state;
    if (state_ is SelectionMultiple) {
      _addOrRemoveSelection(i, state_.selected);
    } else {
      emit(SelectionSingle(i));
    }
  }

  void _addOrRemoveSelection(int i, Set<int> selections) {
    if (selections.contains(i)) {
      final diff = selections.difference({i});
      if (diff.isEmpty) {
        emit(SelectionNone());
      } else {
        emit(SelectionMultiple(diff));
      }
    } else {
      emit(SelectionMultiple({...selections, i}));
    }
  }

  void longSelect(int i) {
    final state_ = state;
    if (state_ is SelectionMultiple) {
      _addOrRemoveSelection(i, state_.selected);
    } else {
      emit(SelectionMultiple({i}));
    }
  }
}
