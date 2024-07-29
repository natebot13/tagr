part of 'selection_cubit.dart';

@immutable
sealed class SelectionState {
  Set<String> get selected;
}

final class SelectionNone extends SelectionState {
  @override
  Set<String> get selected => {};
}

final class SelectionSingle extends SelectionState {
  final String _selected;
  SelectionSingle(this._selected);

  @override
  Set<String> get selected => {_selected};
}

final class SelectionMultiple extends SelectionState {
  @override
  final Set<String> selected;
  SelectionMultiple(this.selected);
}
