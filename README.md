# WeatherRythme (archived)

> **This repository is archived and will not receive any further updates.**
> This was the final change made to it. It is kept online for reference only.
> Check out the new **Weather Structure** project, which integrates this one!

A small Minecraft mod that randomly changes overworld weather every 5-15 minutes,
built for both the Fabric and Forge loaders.

## Status

This mod is no longer supported. The source code used to be broken and would not
compile; that has now been fixed, so the project builds and runs as a working
snapshot of where it was left. No further fixes, features, or version bumps are
planned.

## Supported versions

| Loader | Minecraft | Loader version   | Java |
| ------ | --------- | ---------------- | ---- |
| Fabric | 1.21.1    | Fabric Loader 0.16.10 | 21 |
| Forge  | 1.20.1    | Forge 47.3.0     | 17   |

Forge stops at 1.20.1 because that is the last Minecraft version with a stable
MinecraftForge release line; newer versions moved to NeoForge. Fabric targets
1.21.1, which requires Java 21.

## Building

Build both loaders at once:

```bash
./scripts/build_all.sh
```

Finished jars are written to `dist/`. The script uses your system Gradle if it is
version 8 or newer, and otherwise downloads Gradle 8.14.3 into `.tools/`.

To build a single loader:

```bash
gradle -p fabric clean build   # -> fabric/build/libs
gradle -p forge  clean build   # -> forge/build/libs
```

Each module builds independently and needs the matching JDK from the table above.

## Credits

Made by Mills520. Thanks to all contributors on GitHub under the contributors tag.

## License

MIT - see [LICENSE](LICENSE).
