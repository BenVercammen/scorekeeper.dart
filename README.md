
# Start local development...

 - We use mono_repo, so to get started, activate that package globally
   - `pub global activate mono_repo`
 - Load all dependencies using "pub get"
   - `pub global run mono_repo pub get`
 - Generate the necessary classes (these are also checked into GIT normally)
    - `pub global run mono_repo generate`
    - generates/updates Travis CI configuration...
 - Build example_domain classes
    - `cd scorekeeper_example_domain`
    - `pub run build_runner build`






GENERATE PROTOC CLASSES:
pub global activate protoc_plugin
cd \Workspace\score\gdl\lib\src\scorable
mkdir generated\io\scorable
# NOTE: moet relatief tov root source??? anders proto_path meegeven
cd ..
mkdir scorable\generated\score\scorable
protoc --dart_out=./scorable/generated/score/scorable --proto_path=scorable\proto identifiers.proto
protoc --dart_out=./scorable/generated/score/scorable --proto_path=scorable\proto --proto_path=. commands.proto
protoc --dart_out=./scorable/generated/score/scorable --proto_path=scorable\proto --proto_path=. events.proto
protoc --dart_out=./scorable --proto_path=scorable\proto --proto_path=. scorable\proto\identifiers.proto
protoc --dart_out=./scorable/generated/score/scorable --proto_path=scorable\proto --proto_path=. scorable\proto\commands.proto
protoc --dart_out=./scorable/generated/score/scorable --proto_path=scorable\proto --proto_path=. scorable\proto\events.proto



FLUTTER BUILD STEPS
-------------------
- https://flutter.dev/docs/deployment/android
- AAB ipv APK
- eerst signen (keystore gemaakt, private houden
    - key.properties gemaakt: ook private houden, staan paswoorden in
- C:\Tools\bundletool-all-1.4.0.jar gebruiken om AAB te maken
  cd C:\Workspace\dart\scorekeeper\scorekeeper_flutter
  flutter build appbundle

  	=> gradle.properties in user folder moeten zetten (C:\Users\benve\.gradle), lokaal naast de build pikt em het niet op :/
  	=> key.jks path moeten aanpassen

  java -jar C:\Tools\bundletool-all-1.4.0.jar build-apks --bundle=build\app\outputs\bundle\release\app-release.aab --output=build\app\outputs\apks\scorekeeper_flutter.apks --ks=..\key.jks --ks-key-alias=key
  => alias is dus blijkbaar key, belangrijk om te onthouden dus...

  https://developer.android.com/studio/command-line/bundletool#deploy_with_bundletool

  java -jar C:\Tools\bundletool-all-1.4.0.jar install-apks --apks=build\app\outputs\apks\scorekeeper_flutter.apks



# Trouble shooting
 - The command "tool/ci.sh test_1" exited with 1
   - This is caused by the "ensure_build" test that fails, probably because the newest generated code was not commited
   - To check this locally:
     
        `cd scorekeeper_example_domain`
     
        `pub run test --run-skipped -t presubmit-only test/ensure_build_test.dart`
    - To solve this, try re-building the code and check again
