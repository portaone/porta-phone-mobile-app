# Custom Login Flow

## Overview

This document describes how to implement a custom login/sign-up page using a `WebView`.
Communication between the custom
web page and the Flutter application is handled via the `WebtritLoginChannel` JavaScript channel,
allowing the web UI to
securely transmit user data to the app for authentication.

An example HTML file is available here: [custom_signup.html](../../assets/themes/custom_signup.html)

A page sends by posting to its parent window, which the app takes on a phone and in a browser
alike; see [Supporting a Phone and a Browser](#supporting-a-phone-and-a-browser).

## Table of Contents

- [Communication Protocol](#communication-protocol)
    - [JavaScript Channel](#javascript-channel)
    - [From Flutter to Web: Page Initialization](#from-flutter-to-web-page-initialization)
    - [From Web to Flutter: Sending User Data](#from-web-to-flutter-sending-user-data)
- [Supporting a Phone and a Browser](#supporting-a-phone-and-a-browser)
    - [How to send](#how-to-send)
    - [App versions without the listener](#app-versions-without-the-listener)
    - [Which page works where](#which-page-works-where)
    - [What else differs](#what-else-differs)
    - [Template](#template)
    - [Checklist](#checklist)
- [Migrating an Existing Page](#migrating-an-existing-page)
- [Example Implementation](#example-implementation)
- [Flutter-Side Handling](#flutter-side-handling)
- [Integration](#integration)

---

## Communication Protocol

The interaction between the web page and the Flutter app follows a clear protocol built around a
JavaScript channel.

### JavaScript Channel

On a phone the Flutter app injects a `WebtritLoginChannel` object into the `WebView`'s JavaScript
context. In a browser there is none. A page does not call it: it posts to its parent window under
the channel's name, and the app hands that to the channel on a phone and takes it directly in a
browser (see [Supporting a Phone and a Browser](#supporting-a-phone-and-a-browser)).

### From Flutter to Web: Page Initialization

After the web page is loaded, the Flutter app can call the global JavaScript function
`initializePage(initData)` to pass
initial data, such as localization settings or pre-filled form values.

**Function Signature:** `initializePage(initData)`

- **`initData`**: An object containing initialization data. Common keys include:
    - `locale`: The current language setting of the app (e.g., `"en"`).
    - `prefillEmail`: An email address to pre-populate in an input field.

It is the responsibility of the web page to implement this function to handle the incoming data.

**Example Implementation:**

```javascript
function initializePage(initData) {
  const { locale, prefillEmail } = initData || {};
  if (locale) {
    // Apply translations based on the locale
  }
  if (prefillEmail) {
    document.getElementById("email").value = prefillEmail;
  }
}
```

**Example Call from Flutter:**

```dart

final script = '''
  if (typeof window.initializePage === 'function') {
    window.initializePage({ "locale": "$locale" });
  }
''';
```

### From Web to Flutter: Sending User Data

When the user completes an action (e.g., submitting a form), the web page must gather the data and
send it to the
Flutter app with `window.parent.postMessage({ channel: "WebtritLoginChannel", message }, "*")`.
The `message` must be a stringified JSON object with a specific structure.

**JSON Payload Structure:**

- **`event`**: A string identifying the action. Currently, this must always be `"signup"`.
- **`data`**: An object containing the key-value pairs of user-submitted data.

A special key, `tenant_id`, can be included in the `data` object. If present, the app will modify
the API request URL
to `core-url/tenant/{tenant_id}/api/v1/user`.

**Example JSON Payload:**

```json
{
  "event": "signup",
  "data": {
    "email": "user@example.com",
    "key1": "value1",
    "tenant_id": "d1bbfa00-0298-4667-ba81-9c432a416a10"
  }
}
```

---

## Supporting a Phone and a Browser

The same page is opened in two places: the app's `WebView` on iOS and Android, and a browser when
the app runs on the web (the configurator's Realtime preview is one). In a browser the `WebView` is
a plain iframe, the page usually comes from another origin than the app, and there is no
`WebtritLoginChannel` object in it. The page does not need to know which place it is in: it sends
one way, and the app takes it in both.

### How to send

```javascript
window.parent.postMessage({ channel: "WebtritLoginChannel", message: message }, "*");
```

`message` is the string the channel takes: `JSON.stringify({ event: "signup", data: {...} })`.

- **In a browser** the page is an iframe and `window.parent` is the app's window. The app takes
  messages posted by its own iframe, from the origin the page was opened at, under the
  `WebtritLoginChannel` name.
- **On a phone** the page is the top window, so `window.parent` is the page itself. As soon as the
  page has finished loading, the app adds a listener to it that hands such messages to
  `WebtritLoginChannel`.

Either way `message` reaches the same handler and the sign-up goes on the same way.

**Who can frame the page.** In a browser the page posts to whatever window holds it, and the
`"*"` above does not narrow that: the page cannot know the app's origin in advance, since the
configurator and any other host serve the app from their own. So the page must decide who may hold
it. Serve it with a `Content-Security-Policy: frame-ancestors` header that names the origins
allowed to embed it (the configurator's among them); a site not on the list then cannot frame the
page and read what it sends. On a phone this does not apply: the page is not framed.

### App versions without the listener

An app built before the listener was added does not forward on a phone: there a page that posts to
its parent sends into nothing. Such builds only call the channel object directly, which in turn
does not exist in a browser. A page of your own that must work with them as well as in a browser
uses both, until those builds are no longer in use:

```javascript
if (window.WebtritLoginChannel) {
  WebtritLoginChannel.postMessage(message); // a phone, any app version
} else {
  window.parent.postMessage({ channel: "WebtritLoginChannel", message: message }, "*"); // a browser
}
```

This is for compatibility only. A page bundled with the app, such as
[custom_signup.html](../../assets/themes/custom_signup.html), always runs with the listener and
posts to its parent alone.

### Which page works where

| How the page sends | Phone, app without the listener | Phone, app with the listener | Browser |
|---|---|---|---|
| `window.parent.postMessage({ channel, message }, "*")` | fails: the message goes nowhere | works | works |
| `WebtritLoginChannel.postMessage(message)` | works | works | fails: `WebtritLoginChannel is not defined` |
| Both, as in [App versions without the listener](#app-versions-without-the-listener) | works | works | works |

### What else differs

| | Phone (`WebView`) | Browser (iframe) |
|---|---|---|
| `initializePage({ locale })` | called by the app after load | never called |
| Locale | from `initializePage` | from the `localeName` query parameter the app adds to the address |
| `onMediaQueryReady()` (safe-area insets) | called by the app | never called |

### Template

```javascript
// Called by the app on a phone.
window.initializePage = function (initData) {
  const locale = (initData && initData.locale) || "en";
  // apply translations for `locale`, prefill fields from `initData`
};

// In a browser nobody calls initializePage; the locale is in the address.
const localeName = new URLSearchParams(location.search).get("localeName");
if (localeName) {
  window.initializePage({ locale: localeName.split(/[-_]/)[0] });
}

// On submit:
const message = JSON.stringify({ event: "signup", data: { email: "user@example.com" } });
window.parent.postMessage({ channel: "WebtritLoginChannel", message: message }, "*");
```

### Checklist

- The page sends with `window.parent.postMessage`; it calls `WebtritLoginChannel` only for
  [app versions without the listener](#app-versions-without-the-listener).
- `message` is a string (`JSON.stringify(...)`), not an object.
- The channel name is exactly `WebtritLoginChannel`; any other name is ignored.
- The page sends after it has loaded, on a user action: on a phone the listener is added once the
  page has finished loading.
- The page sends from the origin it was opened at: in a browser only that origin is listened to.
- The page is served with `Content-Security-Policy: frame-ancestors` listing who may embed it.
- The page translates itself from `localeName` when `initializePage` is never called.
- The page looks right with no safe-area insets, since `onMediaQueryReady` is never called in a
  browser.

---

## Migrating an Existing Page

A page written before browsers were supported calls `WebtritLoginChannel.postMessage()` directly
and relies on `initializePage()`. It keeps working on a phone; in a browser it is drawn but cannot
sign anybody in (see [Which page works where](#which-page-works-where)). To make it work in both:

1. **Find every direct call.** Search the page, and any script it loads, for
   `WebtritLoginChannel`. Each `WebtritLoginChannel.postMessage(...)` is a place to change.

2. **Post to the parent window instead.** Keep the message exactly as it was, the same string
   built with `JSON.stringify`; only the way it is sent changes. Remove any
   `console.error("WebtritLoginChannel not found")` branch.

   ```javascript
   // Before
   WebtritLoginChannel.postMessage(JSON.stringify({ event: "signup", data: data }));

   // After
   window.parent.postMessage(
     { channel: "WebtritLoginChannel", message: JSON.stringify({ event: "signup", data: data }) },
     "*",
   );
   ```

   If the page is also opened by app versions without the listener, send both ways instead, as in
   [App versions without the listener](#app-versions-without-the-listener).

3. **Take the locale from the address too.** Keep `window.initializePage` as it is, and call it
   yourself when the app has put the locale in the address, which is what happens in a browser:

   ```javascript
   const localeName = new URLSearchParams(location.search).get("localeName");
   if (localeName) {
     window.initializePage({ locale: localeName.split(/[-_]/)[0] });
   }
   ```

   If `initializePage` was a plain `function initializePage(...)`, it still works; assigning it to
   `window.initializePage` only makes it explicit that the app calls it.

4. **Do not depend on what only a phone sends.** `onMediaQueryReady()` (safe-area insets) is never
   called in a browser: give the layout sensible defaults that the insets only adjust.

5. **Stay on one origin, and name who may embed the page.** In a browser the app listens only to
   the origin the page was opened at, so a page that redirects to another site sends from the first
   one. Serve the page with `Content-Security-Policy: frame-ancestors` listing the configurator's
   origin and any other host of the app (see [How to send](#how-to-send)).

6. **Check it in both places.** On a phone, sign in through the page as before. In a browser, open
   the theme in the configurator, choose the page as the embedded login and sign in through the
   Realtime preview; the browser console must show no `WebtritLoginChannel is not defined`.

---

## Example Implementation

Below is a minimal HTML structure demonstrating how to collect an email and send it to the Flutter
app. It works on a phone and in a browser: it posts to its parent window and takes its locale from
`initializePage` or, in a browser, from the address.

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>OTP Login</title>
</head>
<body>
<div class="form-container">
    <p class="description" id="descriptionText">
        Enter your email to receive a one-time password (OTP) for login.
    </p>
    <div class="form-group">
        <label for="email" id="emailLabel">Email</label>
        <input id="email" name="email" required>
    </div>
</div>
<button class="fixed-button" id="submitButton" onclick="handleLogin()">
    <span class="button-text" id="submitButtonText">Submit</span>
    <div class="spinner"></div>
</button>

<script>
    function handleLogin() {
      const email = document.getElementById("email").value;
      if (!email) {
        alert("Please enter your email.");
        return;
      }
      const payload = {
        event: "signup", // For now, this should always be 'signup'
        data: {
          email: email, // Here can be any key-value pairs
          key1: "value1",
          key2: "value2"
        }
      };
  
      window.parent.postMessage({ channel: "WebtritLoginChannel", message: JSON.stringify(payload) }, "*");
    }
  
    window.initializePage = function (initData) {
      const { locale, prefillEmail } = initData || {};
      if (locale) {
        // apply translations based on locale
      }
      if (prefillEmail) {
        document.getElementById("email").value = prefillEmail;
      }
    };

    const localeName = new URLSearchParams(location.search).get("localeName");
    if (localeName) {
      window.initializePage({ locale: localeName.split(/[-_]/)[0] });
    }
</script>
</body>
</html>
```

---

## Flutter-Side Handling

When the Flutter app receives a message from the web page via `postMessage()`, it performs the
following steps:

1. **Receiving the Message**
   On a phone the Flutter `WebView` has a registered JavaScript channel named
   `WebtritLoginChannel`, and an injected listener also hands it what the page posts to its own
   window. In a browser the app listens for `message` events on its window instead and takes only
   those posted by its own iframe, from the page's origin, with `channel: "WebtritLoginChannel"`.
   Either way the `message` goes to the same handler.

2. **Parsing the Data**
   The incoming message (a JSON string) is parsed into a Dart `Map`. The app verifies the `event`
   key (expecting
   `signup`) and extracts the `data` object.

3. **Handling the API Request**
   The key-value pairs from the `data` object are sent as the body of a `POST` request to the
   `api/v1/user` endpoint.
   If a `tenant_id` key is present in the `data` object, the request URL is modified to:
   `core-url/tenant/{tenant_id}/api/v1/user`

4. **Result Handling & Navigation**
   After processing the API response, the app navigates the user from the custom login `WebView` to
   the appropriate
   native screen, such as an OTP verification page or a success screen.

---

## Integration

For detailed instructions on configuring the `WebView` component and integrating custom HTML files
into your project,
please refer to the **[Features](application_config.md)** documentation.

