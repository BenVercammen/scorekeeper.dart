# scorekeeper_flutter

Generic Flutter UI for the Scorekeeper application

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://flutter.dev/docs/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://flutter.dev/docs/cookbook)

For help getting started with Flutter, view our
[online documentation](https://flutter.dev/docs), which offers tutorials,
samples, guidance on mobile development, and a full API reference.


## Development notes
Build steps
 - Android (https://flutter.dev/docs/deployment/android)
   - We're building to AAB and for testing we generate APKs which we can install on a connected machine
   - First need to sign (created a keystore with alias "key", make sure to never commit this into GIT)
      - also created a **key.properties** file with passwords, but this wasn't picked up when next to the gradle.build file
         - so also put it in the user's ".gradle" folder and then it got picked up...
      - also had to adjust the **key.jks path** to a not so logical relative path...
   - Create the ABB bundle
      - `cd C:\Workspace\dart\scorekeeper\scorekeeper_flutter`
      - `flutter build appbundle`
   - Then create the APKS file, once again using build
      - Use the `C:\Tools\bundletool-all-1.4.0.jar` to create the AAB file
      - `java -jar C:\Tools\bundletool-all-1.4.0.jar build-apks --bundle=build\app\outputs\bundle\release\app-release.aab --output=build\app\outputs\apks\scorekeeper_flutter.apks --ks=..\key.jks --ks-key-alias=key`
   - For testing, deploy on a connected device (https://developer.android.com/studio/command-line/bundletool#deploy_with_bundletool)
      - `java -jar C:\Tools\bundletool-all-1.4.0.jar install-apks --apks=build\app\outputs\apks\scorekeeper_flutter.apks`
 - Web (https://flutter.dev/docs/deployment/web)
   - generate app and assets
      - `cd C:\Workspace\dart\scorekeeper\scorekeeper_flutter`
      - `flutter build web`
   - deploy to the web
      - install firebase CLI
        - https://firebase.google.com/docs/cli#install-cli-windows
      - open firebase CLI
        - `cd \Workspace\dart\scorekeeper\scorekeeper_flutter`
        - `firebase init` (eenmalig)
        - `flutter build web`
        - `firebase deploy --only hosting`
      - https://scorekeeper-flutter-poc-v1.web.app
