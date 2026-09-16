/// Call direction of a record, mirroring `api.CdrDirection`.
///
/// [unknown] is a value of the API contract - the switch reported a leg it
/// could not attribute a direction to - while [unrecognized] is what a value
/// this build does not model maps to. The two are kept apart so a record whose
/// direction the network never knew is not confused with one this app is too
/// old to read (WT-1983).
enum CallDirection { incoming, outgoing, forwarded, unknown, unrecognized }
