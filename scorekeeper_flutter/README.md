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
      - Use the `C:\Tools\bundletool-all-1.4.0.jar` to create the AAB file (pw=mm)
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


## Authentication
For authentication, we'll rely on firebase authentication.
This will require a Google Firebase project
 - Go to https://console.firebase.google.com/
 - Select the "Scorekeeper Flutter POC v1" (https://console.firebase.google.com/u/0/project/scorekeeper-flutter-poc-v1/overview)
 - Select "Authentication" under the "Build" section in the Firebase menu
 - Sign-in providers:
    - Google:
        - simpel... https://console.firebase.google.com/u/0/project/scorekeeper-flutter-poc-v1/authentication/providers
    - Facebook:
        - https://developers.facebook.com/docs/facebook-login/security#appsecret
        - get app id and secret (https://developers.facebook.com/apps/2550940618562699/settings/basic/)
        - add oauth redirect url (https://developers.facebook.com/apps/2550940618562699/fb-login/settings/)
    

# Emulating with Android SDK command line tools
 - Check 
    - https://medium.com/michael-wallace/how-to-install-android-sdk-and-setup-avd-emulator-without-android-studio-aeb55c014264
    - https://proandroiddev.com/automated-android-emulator-setup-and-configuration-23accc11a325
 - General setup:
    - Env Path "ANDROID_CLI_TOOLS" = `C:\Tools\AndroidSDK\cmdline-tools\latest`
    - `sdkmanager platform-tools emulator`
    - Env Path "ANDROID_EMULATOR" = `C:\Tools\AndroidSDK\emulator`
    - Env Path "ANDROID_PLATFORM_TOOLS" = `C:\Tools\AndroidSDK\emulator`
    - Env Path "ANDROID_TOOLS" = `C:\Tools\AndroidSDK\tools\bin`
 - API level specific setup
    - Android 7.0 on my phone, has Android API level 24...
        - `sdkmanager "platforms;android-24"`
 - Create AVD device (Android Virtual Device)
    - `sdkmanager "system-images;android-24;google_apis;x86"`
    - `sdkmanager --licenses` (accept all licenses)
    - `avdmanager create avd --name android24 --package "system-images;android-24;google_apis;x86"` (just say no to custom profile, for now)
 - Run the emulator
    - `emulator -avd android24` or `emulator @android24`
 - Set up in IntelliJ IDEA
    - `flutter doctor` to make sure everything is okay
    - restart IntelliJ and the emulator should show up in devices
 - Customize AVD:
    - Go to the (default) AVD location
        - `%USR_HOME%\.android\avd\android24.avd`
    - Check the `.config.ini` file
    - To enable keyboard, set `hw.keyboard=yes`
 - Check console.log 
    - `adb logcat browser:V *:S` (does not seem to log anything, but intelliJ actually does, after rebooting the app in the emulator)
    - Encountered issues:
        - Permission denied (missing INTERNET permission?)
            - https://stackoverflow.com/questions/17360924/securityexception-permission-denied-missing-internet-permission
            - remove maxSdkVersion...



# Testing
https://medium.com/flutter-community/automated-testing-using-atdd-in-flutter-21d4d0cf5df6

## Unit tests
Verifies the behavior of a method or class.

## Widget tests
Verifies the behavior of Flutter widgets without running the app itself.

## Integration tests
https://flutter.dev/docs/testing/integration-tests
https://github.com/flutter/flutter/tree/master/packages/integration_test#integration_test
Also called end-to-end testing or GUI testing, runs the full app.
Used for automated testing of the actual UI.
Makes use of the `flutter drive` command in order to run on physical devices, emulators or in the Firebase Test Lab.

### Running integration tests
Using the commands below, you can run the integration tests on an emulator.

 - `flutter devices` (check device id)
 - `flutter drive --driver test_driver/driver.dart --target integration_test/app_test.dart`
 - `flutter drive --driver=test_driver/driver.dart --target=integration_test/app_test.dart -d "emulator-5554"`


### Developing integration tests with 'tooling'
While developing your integration tests, you'll typically want the load time in between tests to be as low as possible.
`flutter driver` is mainly used to connect the integration test process with the flutter app running on the (emulated) device.

In order to cut down on the time to load and run integration tests, it is possible to by-pass `flutter driver` altogether.
See https://medium.com/flutter-community/hot-reload-for-flutter-integration-tests-e0478b63bd54 for more information on this.

#### IntelliJ IDEA setup (still not fully working...)
 1. Create a new "Flutter" run configuration 
    - Dart entrypoint: `C:\Workspace\dart\scorekeeper\scorekeeper_flutter\lib\main.dart`
    - Additional run args: `--observatory-port 8888 --disable-service-auth-codes`
 2. Configure the integration test run configuration to listen on the same shared port
    - Dart file: `C:\Workspace\dart\scorekeeper\scorekeeper_flutter\integration_test\app_test.dart`
    - Enable asserts: true
    - Working directory: `C:\Workspace\dart\scorekeeper\scorekeeper_flutter`
    - Environment variables: `VM_SERVICE_URL=http://127.0.0.1:8888/`
 3. Start the "Flutter" app configured in step 1. in run or debug mode
 4. Run the integration test configured in step 2. in run or debug mode

Werkt toch nog niet, nog eens kijken naar:
https://pvba04.medium.com/flutter-integration-tests-in-intellij-idea-16736df35bc7


# Troubleshooting
 
## Various
 - Because every version of flutter_driver from sdk depends on crypto 2.1.5 and uuid >=3.0.0 depends on crypto ^3.0.0, flutter_driver from sdk is incompatible with uuid >=3.0.0.
    - upgrade flutter sdk on machine, see README file in `scorekeeper_core`

 - Travis build fails for flutter package
```
    PKG: scorekeeper_flutter
    Resolving dependencies...
    Because scorekeeper_flutter depends on integration_test any from sdk which
    doesn't exist (the Flutter SDK is not available), version solving failed.
    Flutter users should run `flutter pub get` instead of `pub get`.
    PKG: scorekeeper_flutter; 'pub upgrade' - FAILED  (69)
    SUCCESS COUNT: 4
    FAILURES: 1
    scorekeeper_flutter; 'pub upgrade'
    The command "tool/ci.sh dartanalyzer" exited with 1.
    cache.2
    store build cache
``` 

TODO:
 - https://dev.to/ameysunu/travis-ci-for-flutter-apps-1ngj
 - TODO: nog verder uitvissen!

DOEL == flutter builden op travis
 
 - flutter tests: DONE
 -  integration, deploy, APK build ergens zetten?
        => beter naar codemagic overstappen... 

 - https://docs.travis-ci.com/user/build-stages/
 - https://stackoverflow.com/questions/60493958/flutter-integration-tests-with-travis-ci
 - https://medium.com/@yegorj/building-flutter-apks-and-ipas-on-travis-98d84d8e9b4
 - https://samjakob.medium.com/automatically-build-your-flutter-apps-with-travis-ci-4c1e47a5ae69


https://www.thewindowsclub.com/how-to-run-sh-or-shell-script-file-in-windows-10

TODO: 24/04/21:
 - https://blog.codemagic.io/how-to-migrate-from-any-ci-and-why-flutter-needs-dedicated-ci/
 - https://flutter.dev/docs/deployment/cd

Update: 30/04/21: 
 - https://github.com/google/mono_repo.dart/pull/318
 - for now, we'll just be content with regular tests
    - for "integration testing" and "deploying" etc, we'll try to set up a separate codemagic build...


## Persistence
### Moor, SQFLite, SQLite
As a persistence solution we're currently looking at the `moor` package.
Issues we've encountered:

 - Code generation:
    - the file containing the `@UseMoor` annotation has the following import:
        `part 'YOUR_FILENAME_HERE.g.dart';`
        - make sure that the file names match!
     - `flutter pub run build_runner build`
        ```
        [SEVERE] Failed to snapshot build script .dart_tool/build/entrypoint/build.dart.
        This is likely caused by a misconfigured builder definition.
        ```
       - Problem is that the build_runner is picking up our `scorekeeper_domain/build.yaml` file
            - Cannot prevent this from happening, but... can fix the "dependency issue"
                -> scorekeeper_codegen should be added as dev_dependency
       - Problem 2:
            - after first success, we keep getting the following:
            ```
            [SEVERE] scorekeeper_domain:aggregate_dto_factory_generator on lib/$lib$ (cached):
            FileSystemException: Cannot open file, path = 'lib/src/event_store_moor.moor.g.part' (OS Error: Het systeem kan het opgegeven bestand niet vinden.
            , errno = 2)
            ```
            - added extra check...
 - Testing:
    - `Invalid argument(s): Failed to load dynamic library 'sqlite3.dll': 126`
        - Make sure the `sqlite3.dll` file is present on the `PATH` of your local machine
    - `SqliteException(14): bad parameter or other API misuse, bad parameter or other API misuse (code 21)`
        - https://github.com/simolus3/moor/issues/731
        - Make sure your `flutter_tester.exe` process has access to the local machine's `ApplicationDocumentsDirectory` folder

