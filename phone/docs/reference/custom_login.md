# Custom Login Flow

## Overview

This document describes how to implement a custom login/sign-up page using a `WebView`.
Communication between the custom
web page and the Flutter application is handled via the `WebtritLoginChannel` JavaScript channel,
allowing the web UI to
securely transmit user data to the app for authentication.

An example HTML file is available here: [custom_signup.html](../../assets/themes/custom_signup.html)

The same page works on a phone and in a browser when it sends through one function that checks for
the channel; see [Supporting a Phone and a Browser](#supporting-a-phone-and-a-browser).

## Table of Contents

- [Communication Protocol](#communication-protocol)
    - [JavaScript Channel](#javascript-channel)
    - [From Flutter to Web: Page Initialization](#from-flutter-to-web-page-initialization)
    - [From Web to Flutter: Sending User Data](#from-web-to-flutter-sending-user-data)
- [Supporting a Phone and a Browser](#supporting-a-phone-and-a-browser)
    - [How to send](#how-to-send)
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
context. In a browser there is none, and the page posts to its parent window instead; a page does
both through one function (see [Supporting a Phone and a Browser](#supporting-a-phone-and-a-browser)).

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
Flutter app through `sendToApp(message)`, which calls `WebtritLoginChannel.postMessage()` on a phone
and posts to the parent window in a browser. The `message` must be a stringified JSON object with a
specific structure.

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
`WebtritLoginChannel` object in it.

### How to send

A page sends through one function that checks for the channel object:

```javascript
function sendToApp(message) {
  if (window.WebtritLoginChannel) {
    WebtritLoginChannel.postMessage(message);
  } else {
    window.parent.postMessage({ channel: "WebtritLoginChannel", message: message }, "*");
  }
}
```

`message` is the string the channel takes: `JSON.stringify({ event: "signup", data: {...} })`.

- **On a phone** the app has defined `WebtritLoginChannel`, so the message goes straight to it,
  with every app version and at any moment after the page has started.
- **In a browser** there is no such object. The page is an iframe, `window.parent` is the app's
  window, and the app takes messages posted by its own iframe, from the origin the page was opened
  at, under the `WebtritLoginChannel` name.

Either way `message` reaches the same handler and the sign-up goes on the same way. A bare
`WebtritLoginChannel.postMessage(message)` works on a phone but throws
`WebtritLoginChannel is not defined` in a browser, and the app cannot add that object to a page on
another origin.

**Who can frame the page.** In a browser the page posts to whatever window holds it, and the
`"*"` above does not narrow that: the page cannot know the app's origin in advance, since the
configurator and any other host serve the app from their own. So the page must decide who may hold
it. Serve it with a `Content-Security-Policy: frame-ancestors` header that names the origins
allowed to embed it (the configurator's among them); a site not on the list then cannot frame the
page and read what it sends. On a phone this does not apply: the page is not framed.

**Posting to the parent alone.** On a phone `window.parent` is the page itself, and an app with
the window listener forwards what the page posts there to the channel, so
`window.parent.postMessage(...)` with no check also works on a phone. Two things keep the check the
recommended form: an app built before the listener forwards nothing, and the listener is in place
only once the page has finished loading, so a message posted earlier is lost.

### Which page works where

| How the page sends | Phone, app before the listener | Phone, app with the listener | Browser |
|---|---|---|---|
| `WebtritLoginChannel.postMessage(message)` only | works | works | fails: `WebtritLoginChannel is not defined`, the sign-up never reaches the app |
| `window.parent.postMessage({ channel, message }, "*")` only | fails: the message goes nowhere | works | works |
| `sendToApp` above: the channel object if there is one, the parent window otherwise | works | works | works |

Give pages `sendToApp`. Posting to the parent alone is enough only for a page that sends after it
has loaded and is never opened by an app built before the listener.

### What else differs

| | Phone (`WebView`) | Browser (iframe) |
|---|---|---|
| `initializePage({ locale })` | called by the app after load | never called |
| Locale | from `initializePage` | from the `localeName` query parameter the app adds to the address |
| `onMediaQueryReady()` (safe-area insets) | called by the app | never called |

### Template

```javascript
function sendToApp(message) {
  if (window.WebtritLoginChannel) {
    WebtritLoginChannel.postMessage(message);
  } else {
    window.parent.postMessage({ channel: "WebtritLoginChannel", message: message }, "*");
  }
}

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
// sendToApp(JSON.stringify({ event: "signup", data: { email: "user@example.com" } }));
```

### Checklist

- Every message goes through `sendToApp`; nothing calls `WebtritLoginChannel.postMessage`
  directly.
- `message` is a string (`JSON.stringify(...)`), not an object.
- The channel name is exactly `WebtritLoginChannel`; any other name is ignored.
- The page sends from where it is opened: in a browser only its own origin is listened to, so a
  page that moves to another origin on the way cannot send from there.
- The page is served with `Content-Security-Policy: frame-ancestors` listing who may embed it.
- The page translates itself from `localeName` when `initializePage` is never called.
- The page looks right with no safe-area insets, since `onMediaQueryReady` is never called in a
  browser.

---

## Migrating an Existing Page

A page written before browsers were supported calls `WebtritLoginChannel.postMessage()` directly
and relies on `initializePage()`. It keeps working on a phone with any app version; in a browser it
is drawn but cannot sign anybody in (see [Which page works where](#which-page-works-where)). To make
it work in both, without breaking app versions already installed:

1. **Find every direct call.** Search the page, and any script it loads, for
   `WebtritLoginChannel`. Each `WebtritLoginChannel.postMessage(...)` is a place to change.

2. **Send through one function that checks for the channel.** Add it once and call it everywhere
   the page used to call the channel:

   ```javascript
   // Before
   WebtritLoginChannel.postMessage(JSON.stringify({ event: "signup", data: data }));

   // After
   function sendToApp(message) {
     if (window.WebtritLoginChannel) {
       WebtritLoginChannel.postMessage(message);
     } else {
       window.parent.postMessage({ channel: "WebtritLoginChannel", message: message }, "*");
     }
   }

   sendToApp(JSON.stringify({ event: "signup", data: data }));
   ```

   Keep the message exactly as it was: the same string, built with `JSON.stringify`. Only the way
   it is sent changes. Remove any `console.error("WebtritLoginChannel not found")` branch, which
   is the case the parent window now covers.

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

5. **Stay on one origin.** In a browser the app listens only to the origin the page was opened at.
   A page that redirects to another site and sends from there has to send from the first one.
   And name who may embed the page: serve it with `Content-Security-Policy: frame-ancestors`
   listing the configurator's origin and any other host of the app (see
   [How to send](#how-to-send)).

6. **Check it in both places.** On a phone, sign in through the page as before. In a browser, open
   the theme in the configurator, choose the page as the embedded login and sign in through the
   Realtime preview; the browser console must show no `WebtritLoginChannel is not defined`.

7. **Keep the check.** It is what lets the page work with app versions already installed and send
   before the page has finished loading; see [How to send](#how-to-send).

---

## Example Implementation

Below is a minimal HTML structure demonstrating how to collect an email and send it to the Flutter
app. It works on a phone and in a browser: it sends through `sendToApp` and takes its locale from
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
    function sendToApp(message) {
      if (window.WebtritLoginChannel) {
        WebtritLoginChannel.postMessage(message);
      } else {
        window.parent.postMessage({ channel: "WebtritLoginChannel", message: message }, "*");
      }
    }

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
  
      sendToApp(JSON.stringify(payload));
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

