class QuestionManager {
  final List<Map<String, String>> _questions;
  int _index;

  QuestionManager(this._questions, this._index);

  Map<String, String> get current => _questions[_index % _questions.length];

  int get currentIndex => _index;

  void next() {
    _index++;
  }
}
