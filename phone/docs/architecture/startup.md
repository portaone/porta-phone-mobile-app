# Where cold start time goes

What the app spends before its first frame, measured rather than assumed, and what is
worth attacking next.
Last reviewed: 2026-09-11.

## How this was measured

Profile builds of the same commit range on one device, signed in against a real backend,
three interleaved blocks of `install -> one discarded warm-up -> three measured starts`.
A start is made cold by sending the app to the home screen, killing it with `am kill` and
waiting for its pid to disappear; `am kill` only reaches background processes, so killing
a foregrounded app silently leaves it running and every later number describes a warm
start instead.

Two numbers per run: `am start -W` `TotalTime`, which ends at the first frame, and the
app's own startup trace, which the app logs as `startup_complete total_ms=... stages=[...]`
from `main()` to the first frame.

Device: Xiaomi 25028RN03Y, Android 15. Numbers from a Huawei MAO-LX9N (Android 12, no
Google services) are quoted where they differ enough to matter - the shape holds, the
magnitudes do not.

## The breakdown

Medians of nine cold starts, milliseconds, with the spread in brackets.

| Segment | Median | Range | What it is |
|---|---|---|---|
| Before `main()` | ~1665 | - | Process start, engine, Dart snapshot, plugin registration. Not traced; inferred from `TotalTime` minus the trace. |
| `system-ui` | 225 | 181..268 | One awaited `SystemChrome.setEnabledSystemUIMode` in `lib/main.dart`, before anything else runs. |
| `bootstrap` | 439 | 408..488 | Everything in `lib/bootstrap.dart`: the parallel root wave plus the serial work after it. |
| trace total | 698 | 672..756 | `main()` to first frame. |
| `am start -W` | 2363 | 2323..2435 | Process launch to first frame. |

Inside `bootstrap`, the root wave runs its members concurrently, so the wave lasts as long
as its slowest member, not as long as their sum:

| Root | Median | Range |
|---|---|---|
| `secure-storage` | 342 | 321..370 |
| `app-info` | 96 | 48..343 |
| `app-themes` | 36 | 27..85 |
| `device-info` | 36 | 34..83 |
| `package-info` | 23 | 21..35 |
| `app-preferences` | 5 | 4..5 |
| `remote-config-cache` | 3 | 2..5 |

The serial tail after the wave - api clients, callkeep, connectivity, work manager - is
around 80 ms in total, with `callkeep` (15) the largest single item. The database is not
opened at startup: drift's server isolate is spawned by whichever isolate opens it first.

Outside the wave but inside `bootstrap`: `platform` 53 (Firebase core 51 and local
notifications 43 run inside it).

## What this says

**Most of a cold start is not ours.** About 1.6 of the 2.4 seconds is spent before the
first line of Dart in `main()` runs. Nothing in the composition root can move it; app
size, the number of registered plugins and their native initialisation are what change it.

**Of what is ours, the single largest item is not in `bootstrap` at all.** `system-ui` is
one awaited platform call in `main.dart` and costs 225 ms here - and 1122 ms (201..1132)
on the Huawei, which is more than that device's entire `bootstrap`. It is awaited before
`bootstrap` starts, so it is pure serial cost.

**The root wave is bounded by its longest member, and there are two candidates.** Reading
the keychain is 342 ms; `app-info` is 96 ms with spikes past 400. Removing one leaves the
other: taking the keychain read out of the wave moved `bootstrap` only from 439 to 426 ms.

**The keychain costs its start-up, not its records.** Reading four records costs 344 ms and
reading the whole keychain 329 ms: what is paid is bringing the keystore up. The platform
calls of the startup path run one after another on one thread, so starting the read earlier
or reading records lazily does not shorten startup.

**The first frame is not the first useful screen.** The route guard for the main shell
waits for the cached system info. Making the first frame arrive earlier without giving that
window something to show only replaces the system splash with the app's own empty background.

If that wait cannot end - no cached system info and a core that will not answer - the
guard ends the session (`AppLogoutReason.coreUnreachable`) rather than routing to login.
Routing there does not settle: the login guard sends a logged-in session straight back,
so the two guards swap routes indefinitely and neither screen is built. Ending the
session is also the only way out for the user, because the login screen is where a
different core is entered. Local data is cleared; the remote session is left alone,
since the core never answered and may well still hold a valid one.

## Candidates, in the order the numbers justify

1. **`system-ui`.** 225 ms here, over a second on the Huawei, awaited before `bootstrap`
   for a call that configures how system bars are drawn. Worth establishing whether the
   mode has to be applied before the first frame at all, and if it does, whether it has to
   be awaited on the startup path. Largest single controllable number in the trace.

2. **`app-info`.** Now the longest member of the wave when the keychain is not, 96 ms
   median with spikes past 400. When measured it resolved an installation identifier through
   Firebase. Since WT-2087 the identifier comes from the device (`durable_device_id`: a digest
   of ANDROID_ID, a Keychain item on iOS), asked on every start; an install made by an earlier
   version keeps the identifier it saved, and Firebase is asked only when the device has none
   to give (`lib/common/app_id_provider.dart`). Not measured again since.

3. **Something to show while the shell resolves.** The guard waits for cached system info
   even today. Any work that makes the first frame earlier is only worth doing together
   with a screen that belongs in that window.

4. **Before `main()`.** The largest segment by far, and the only lever is what the app
   loads at process start: plugin count, native initialisers, app size.

## Caveats

One device, one build flavour, medians of nine runs. The spread on individual roots is
wide - `app-info` ranged 48..343 ms in the same nine runs - so differences under about
30 ms are not distinguishable here. Cross-device magnitudes differ a lot: the same
keychain read is 342 ms on the Xiaomi and 151 ms on the Huawei, while `system-ui` is 225
against 1122. Conclusions about ordering hold; absolute numbers do not travel.
