/// Turns a long spoken sentence into short, tactile-friendly text suitable
/// for Braille/haptic rendering, e.g.:
///
/// ```text
/// "Would you like to attend the event tomorrow?"
///   -> "EVENT TOMORROW.\nATTEND?"
/// ```
abstract class MessageSimplifier {
  Future<String> simplify(String spokenText);
}
