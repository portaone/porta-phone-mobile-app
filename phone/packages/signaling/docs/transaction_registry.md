# Transaction registry

What `TransactionRegistry` (`lib/src/transaction_registry.dart`) does, what it leaves to the client
that owns it, and the rules it keeps about requests and their answers. The one place this is
written; the package's `AGENTS.md` and `README.md` link here.

Last reviewed: 2026-11-16, against this package. Nothing here was run on a stand: the registry was
taken out of `WebtritSignalingClient` without a change of behaviour, and the client's own tests
(`test/signaling_integration_test.dart` and the rest under `test/`) pass unchanged on it. The
registry's own tests are `test/src/transaction_registry_test.dart`: every rule below, with a
mocked socket and `fake_async`.

Contents

1. Purpose
2. The split with the client
3. A request and its answer
4. Answers nobody waits for
5. The end of a connection
6. Using it from a client

## 1. Purpose

A Core socket answers every request with exactly one message that names the request's
`transaction`: `{"response": "ack", ...}`, `{"response": "error", "code": ..., "reason": ...}`,
or, for a keepalive, the `{"handshake": "keepalive", ...}` echoed back. Pairing those answers with
the requests that wait for them is the same work whatever the socket carries. `TransactionRegistry`
is that work, written once: a client hands it the socket and keeps only what is its own - what the
events mean, a state handshake if the socket has one, when to ask for a keepalive.

It is not a socket and not a client. It does not listen to the socket, does not decode events and
has no timers of its own besides each request's timeout. The owner reads the socket, gives the
registry the messages that are answers, and decides when the connection is over.

## 2. The split with the client

| The registry | The client that owns it |
| --- | --- |
| the open transactions, by id | the socket subscription (`listen`, `onDone`, `onError`) |
| writing a request, and writing any other frame (`send`) | telling an answer from an event (`TransactionRegistry.isAnswer` is there to ask) |
| each request's timeout (`Transaction`) | turning an answer into an outcome: `ack` returns, `error` throws `SignalingErrorException` |
| pairing an answer with its transaction (`handleAnswer`) | the state handshake, the keepalive and receive watchdog timers ([connection_liveness.md](connection_liveness.md)) |
| ending what waits when the connection ends (`terminateAll`, `timeOutAll`) | deciding that the connection ended, and calling those |

`WebtritSignalingClient` builds one registry per connection, in `WebtritSignalingClient.inner`,
with its own id and logger, so the log lines read as they did before the registry existed.

## 3. A request and its answer

`execute(requestJson, timeoutDuration)` returns the answer's JSON, or throws.

1. A request without a `transaction` is given one (`Transaction.generateId`). The answer is handed
   back without it, so a caller that sent none gets none back.
2. The request is written (`send`) **before** its `Transaction` is created. A write that fails
   throws `SignalingBadStateException` to the caller and leaves no timeout behind; a timeout armed
   first would fire later into a zone with nobody listening.
3. The `Transaction` is put in the table under its id and its timeout starts.
4. The answer cannot overtake the request: the socket stream delivers it asynchronously, after the
   transaction is in the table.
5. The transaction ends on the first of four events, and only the first counts
   (`Transaction`'s own guard):

| Event | `execute` |
| --- | --- |
| `handleAnswer` with its id | returns the answer's JSON |
| its timeout (`timeoutDuration`; 10 s unless the caller of `WebtritSignalingClient.execute` passes another, `defaultExecuteTransactionTimeoutDuration`) | throws `SignalingTransactionTimeoutException` |
| `terminateAll` | throws `SignalingTransactionTerminateByDisconnectException` with the close code and reason |
| `timeOutAll` | throws `SignalingTransactionTimeoutException` at once |

On any error the transaction is taken out of the table, so a late answer for it is the case of
section 4.

`send(messageJson)` writes one frame and nothing else: it refuses with
`SignalingBadStateException` once the peer's close frame has come (`isClosed`, from the socket's
`closeCode`), or when the sink itself refuses the write.

## 4. Answers nobody waits for

`handleAnswer` takes the transaction out of the table and completes it. An answer whose
transaction is not there - it timed out under a congested network and the server's `ack` came
after the client gave up - is logged as a warning and dropped. It is not an error of the
connection: taking it for one would end a working connection and cost a reconnect.

## 5. The end of a connection

Two ways out, both called by the client, never by the registry itself:

- `terminateAll(code, reason)` - the socket closed (`onDone`) or the client disconnected: every
  waiting request fails as terminated by the disconnect, with the close code and reason.
- `timeOutAll()` - the client found the connection dead though nothing closed it (its keepalive
  went unanswered, see [connection_liveness.md](connection_liveness.md), section 3): every waiting
  request fails now with the timeout it would have got at its own time, instead of each waiting
  out its own.

Both empty the table. The registry stays usable afterwards, but a client does not reuse it: it
belongs to one connection, and a new connection gets a new client and a new registry.

## 6. Using it from a client

```dart
final registry = TransactionRegistry(webSocketChannel, clientId: id, logger: logger);

// Reading the socket:
void onData(Map<String, dynamic> message) {
  if (TransactionRegistry.isAnswer(message)) {
    registry.handleAnswer(message);
  } else {
    // an event, a state handshake: the client's own
  }
}

// A request:
final answer = await registry.execute(request.toJson(), timeout);
final response = Response.fromJson(answer); // ack returns, error throws

// The end:
void onDone() => registry.terminateAll(closeCode, closeReason);
void onDead() => registry.timeOutAll();
```

A keepalive goes through `execute` like any request (`KeepaliveHandshake().toJson()`): the server
echoes it with the same `transaction`, and `isAnswer` counts the echo as an answer.
