# Sample Native App

This is a sample iOS app that your coding agent in Linux can build and test using
Limrun with remote XCode & iOS simulator.

## Setup

First, you need to get an API key from [Limrun Console](https://console.limrun.com).

```bash
export LIM_API_KEY=lim_....
```

Install `lim` CLI.

```bash
npm install --global lim
```

That's it! Now, make sure to recognize the skills stored in `.agents/skills` folder
so you know how to use the `lim` CLI to build and test iOS apps.

## Local Builds

If you're on macOS with access to XCode, you can get a simulator build of this
project and upload to Limrun Asset Storage so that you can get simulators
with this app pre-installed.

Build with the following command:
```bash
xcodebuild -project sample-native-app.xcodeproj \
  -scheme sample-native-app \
  -sdk iphonesimulator \
  -configuration Debug \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath build \
  build
```

Once completed, archive the `.app` folder.
```bash
tar -czf sample-native-app.app.tar.gz \
  -C build/Build/Products/Debug-iphonesimulator \
  sample-native-app.app
```

Push to Limrun Asset Storage.
```bash
lim push sample-native-app.app.tar.gz
```

Now you can use it in your iOS instances!

```bash
lim run ios --install-asset=sample-native-app.app.tar.gz
```

## Branch pull request browser

Branch is a SwiftUI pull request browser with a demo workspace and a public GitHub repository loader.
Search by title, author, repository, or number; filter Open, Closed, Draft, or All;
open descriptions and bookmark pull requests for later. Bookmarks persist locally across launches
and repository changes. The GitHub button opens the original pull request in the browser.

Choose the repository menu, enter `owner/repository`, and load up to 50 recent public pull
requests. No token is needed. Private repositories, posting reviews, and merging are outside
this version. GitHub may rate-limit anonymous requests; errors are shown in the app.
Demo review states and diff counts are examples; live results do not invent these values.

Build with `ns mobile build branch` or `lim xcode build . --scheme sample-native-app --configuration Debug`.
