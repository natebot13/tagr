part of 'selection_cubit.dart';

@immutable
sealed class SelectionState {}

final class SelectionNone extends SelectionState {}

final class SelectionSingle extends SelectionState {
  final int selected;
  SelectionSingle(this.selected);
}

final class SelectionMultiple extends SelectionState {
  final Set<int> selected;
  SelectionMultiple(this.selected);
}
