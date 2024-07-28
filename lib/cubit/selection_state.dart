part of 'selection_cubit.dart';

@immutable
sealed class SelectionState {}

final class SelectionNone extends SelectionState {}

final class SelectionSingle extends SelectionState {
  final String selected;
  SelectionSingle(this.selected);
}

final class SelectionMultiple extends SelectionState {
  final Set<String> selected;
  SelectionMultiple(this.selected);
}
