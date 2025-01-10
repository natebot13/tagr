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

final class SelectionChoosing extends SelectionState {
  @override
  final Set<String> selected;
  final int tagTypeId;
  SelectionChoosing(this.tagTypeId, this.selected);
}

final class SelectionChosen extends SelectionState {
  @override
  final Set<String> selected;
  final String chosen;
  final int tagTypeId;
  SelectionChosen(this.tagTypeId, this.chosen, this.selected);
}
