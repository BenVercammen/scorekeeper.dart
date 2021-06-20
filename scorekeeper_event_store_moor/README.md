# scorekeeper_event_store_moor

Event store implementation using moor / sqflite


## Development
When adjusting the `@DataClassName` annotated classes, you'll need to generate the code again.
This can be done with the build_runner, like this:
``flutter pub run build_runner build``


## Troubleshooting

### Database schema outdated
At times, especially during development, it happens that the database schema gets outdated.
This might result in an exception such as this one:

`E/flutter ( 7543): [ERROR:flutter/lib/ui/ui_dart_state.cc(199)] Unhandled Exception: Null check operator used on a null value`

Pointing to generated code
```
payloadType: const StringType().mapFromDatabaseResponse(data['${effectivePrefix}payload_type'])!,
```

So, we should be able to tell moor to clear/delete the database.
 - https://stackoverflow.com/questions/6338976/how-to-find-and-clear-the-sqlite-db-file-in-android-emulator/6338994
 - One way is to uninstall the application.

In the future, we'll need to make sure that we can handle such things.
Of course, right now this is because of required metadata. Our (volatile) domain events are simply serialized and stored without any structure.

#### Local development
When running tests, the SQL structure is already set up, no?
Where to find the database file??
 - Tests by default should put it in ``C:\Users\...\AppData\Local\Temp\db.sqlite``


## Testing
 - ``pub global activate protoc_plugin`` (if not already installed)
 - ``cd C:\Workspace\dart\scorekeeper\scorekeeper_event_store_moor``
 - ``mkdir test\generated`` (if not already exists)
 - ``protoc --dart_out=test/generated -Itest/protos test/protos/events.proto``
