import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

part 'tag_filter_state.dart';

class TagFilterCubit extends Cubit<TagFilterState> {
  TagFilterCubit() : super(TagFilterDone());

  void search([String value = '']) {
    emit(FilteringTags(value));
  }

  void done() {
    emit(TagFilterDone());
  }
}
