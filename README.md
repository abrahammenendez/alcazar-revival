# alcazar-revival

Alcazar for current Android phones, with every book unlocked.

Alcazar is Jérôme Morin-Drouin's
[amazing path-drawing puzzle game](https://web.archive.org/web/20160918211350/http://www.theincrediblecompany.com/alcazar-1).
I played it about twelve years ago and fell in love with it.

Unfortunately, it's abandonware now. It left Google Play years ago, and nobody
sells or updates it anymore. The latest version I could find, 1.2.13 from
2016, targets Android 4.4 (API 19), and Android 14 and later refuse to install
it. Only the first of its 23 books was free. The rest were in-app purchases,
and there's no way to buy them anymore.

## Download

The [releases](https://github.com/abrahammenendez/alcazar-revival/releases)
have two APKs:

- `alcazar-1.2.13-original.apk`, the game exactly as the developer released it.
- `alcazar-1.2.13-revival.apk`, the same game with the changes below. This is
  the one to install.

The revival APK is signed with my key. `apksigner verify --print-certs` shows
the signer `CN=Alcazar revival` with this certificate SHA-256:

```
b447f393399ffed0ae672fe530ee009a3a46f967c16482e2625d85e531888114
```

Uninstall any other copy of Alcazar first, since it's signed with a different
key. That also deletes its progress. Then:

- **From the phone:** open the APK. Play Protect blocks it because it hasn't
  seen an app from this key before. Tap **More details**, then
  **Install anyway**.
- **With adb:** `adb install alcazar-1.2.13-revival.apk`.

Later releases are signed with the same key, so they install as updates and
keep your progress.

## What changes

| Change | Why |
| --- | --- |
| `targetSdkVersion` 19 → 34 | Android 14 blocks installing apps that target very old versions, and Play Protect warns when the target is more than two versions behind the phone. 34 is the newest target before edge-to-edge (35) and predictive back (36) change how the game behaves. |
| `android:exported="true"` on the activity | Required for apps that target API 31 or later. |
| `storage.isUnlocked` in the game's JavaScript always returns `true` | Unlocks the books that were in-app purchases. |

Apktool also recompiles `resources.arsc`, `res/xml/config.xml`, and the app icon
on the way. Everything else, `classes.dex` included, stays exactly as it was.

## Build it yourself

You need:

- [Apktool](https://apktool.org/) (tested with 3.0.3).
- `zipalign` and `apksigner` from the Android SDK build-tools (tested with
  36.0.0), on your `PATH` or found through `ANDROID_HOME`.
- Java, which Apktool and `apksigner` run on, and Perl.

1. Download the original APK from the releases. `build.sh` only accepts the
   file with this SHA-256:

   ```
   50621158ef2e37ad0b0d04633cb11dbfc5ac00531844e3ce918a8154082391b8
   ```

   It's signed by the developer: `apksigner verify --print-certs` shows
   `CN=Jerome Morin-Drouin, OU=The Incredible Company`.

2. Create a signing key once and keep it somewhere safe, such as a password
   manager. Android only installs an update over an app signed with the same
   key, so your builds can't update the release APK, and the other way round.

   ```sh
   keytool -genkeypair -keystore alcazar.jks -alias alcazar -keyalg RSA -keysize 3072 -validity 36500 -dname "CN=Alcazar"
   ```

3. Build:

   ```sh
   ./build.sh alcazar-1.2.13-original.apk alcazar.jks
   ```

   It asks for the keystore password and writes
   `build/alcazar-1.2.13-revival.apk`.

If an Apktool update changes the unpacked files so that an edit no longer
matches, `build.sh` stops instead of building an APK with a change missing.

## Known issues

- The Daily Alcazar shipped with 486 puzzles, which ran out on 10 April 2017.
  Since then it asks you to update the game, and there's no update to get.
- "Recommend it and rate it" and "Order the Alcazar book" on the About screen
  do nothing. They never did: the original build lacks the Cordova plugin that
  lets a link open outside the app.
- On phones with API 37 or later, target 34 is more than two versions behind,
  so Play Protect shows the same "built for an older version of Android"
  warning as for the original APK.

## Development

There are no automated tests. After changing `build.sh`, run
`shellcheck build.sh`, install the build on a phone, and check the tutorial, a
puzzle in a formerly paid book, the padlock and ✕ buttons, the back button,
and that progress survives force-stopping the app.

Tested on a POCO X6 Pro with Android 16 and on an API 37 emulator.

## Legal

Alcazar, its puzzles, and its artwork belong to Jérôme Morin-Drouin and The
Incredible Company. Abandonware is still under copyright, and this project
isn't affiliated with them. If you hold the rights and would like this
repository removed, let me know and I'll do it.

## License

The script and documentation are under the [MIT License](LICENSE). It doesn't
cover the game or the APKs in the releases.
