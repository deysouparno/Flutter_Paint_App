import 'package:bloc/bloc.dart';

part 'slider_cubit_state.dart';

class SliderCubit extends Cubit<SliderCubitState> {
  SliderCubit() : super(SliderCubitState(strokeWidth: 5.0));

  void emitSliderValue(double width) =>
      emit(SliderCubitState(strokeWidth: width));
}
