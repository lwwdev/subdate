# subdate

tracks your subscriptions so you stop getting surprised by charges. flutter, runs on ios / android / web.

<img src="docs/screenshot.jpg" width="320" alt="screenshot">

## what it does

- "coming up" stack for the next 7 / 14 / 30 days, total converted to your home currency
- calendar view of the month with the service icons on renewal days
- add / edit / delete subs, weekly / monthly / quarterly / yearly (or every N of those)
- a bunch of built-in brand icons, or use your own image
- mixed currencies, converted with ECB rates from [frankfurter](https://frankfurter.dev)
- local reminders before something renews (ios + android)
- free trials (reminds you before the first real charge) and pausing subs
- spending breakdown per month / year
- backup + restore as json through the clipboard
- everything stays on your device (hive), no account

## run it

```
flutter pub get
flutter run            # pick a device
flutter run -d chrome  # web
flutter test
```

android needs the SDK, ios needs xcode + cocoapods, the usual

## stack

riverpod, hive_ce, flutter_local_notifications, simple_icons, intl

brand icons come from [simple icons](https://simpleicons.org) (CC0), the logos belong to their owners obviously

## license

MIT
