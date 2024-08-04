import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

part 'search_state.dart';

class SearchCubit extends Cubit<SearchState> {
  SearchCubit() : super(SearchDone());

  void search([String value = '']) {
    emit(Searching(value));
  }

  void done() {
    emit(SearchDone());
  }
}
