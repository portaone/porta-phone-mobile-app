/// What Android does with an incoming call that arrives while another incoming call rings.
///
/// Telecom lets one self-managed incoming call ring at a time and refuses the next one.
///
/// - [queue]: callkeep holds the second call back before it reaches Telecom. The report of it
///   succeeds, a silent notification offers to answer it (ending the ringing call) or to decline
///   the ringing call, and it rings once the ringing call ends or is answered.
/// - [reject]: the second call goes to Telecom and is refused; its report returns
///   [CallkeepIncomingCallError.callRejectedBySystem] and the app declines it on the server.
enum CallkeepIncomingCallWhileRinging { queue, reject }
