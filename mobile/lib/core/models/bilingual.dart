/// A string paired with its Tamil rendering.
///
/// The pilot region is the Palk Strait, so every label the user must act on is
/// shown in both scripts. Regional-language coverage is a stated requirement of
/// the problem statement, not a nicety.
class Bilingual {
  const Bilingual(this.en, this.ta);

  final String en;
  final String ta;

  @override
  String toString() => en;
}
