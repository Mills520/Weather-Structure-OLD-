package io.github.mills520.weatherrythme;

import net.fabricmc.api.ModInitializer;
import net.fabricmc.fabric.api.event.lifecycle.v1.ServerTickEvents;
import net.minecraft.resources.ResourceKey;
import net.minecraft.server.MinecraftServer;
import net.minecraft.server.level.ServerLevel;
import net.minecraft.util.RandomSource;
import net.minecraft.world.level.Level;

import java.util.HashMap;
import java.util.Map;

public final class WeatherRythmeFabricMod implements ModInitializer {
    public static final String MOD_ID = "weatherrythme";
    private static final int MIN_INTERVAL_TICKS = 5 * 60 * 20;
    private static final int MAX_INTERVAL_TICKS = 15 * 60 * 20;

    private final Map<ResourceKey<Level>, Integer> ticksUntilNextChange = new HashMap<>();

    @Override
    public void onInitialize() {
        ServerTickEvents.END_SERVER_TICK.register(this::onServerTick);
    }

    private void onServerTick(MinecraftServer server) {
        for (ServerLevel level : server.getAllLevels()) {
            ResourceKey<Level> key = level.dimension();
            if (!Level.OVERWORLD.equals(key)) {
                continue;
            }

            int remaining = ticksUntilNextChange.getOrDefault(key, 0);
            if (remaining > 0) {
                ticksUntilNextChange.put(key, remaining - 1);
                continue;
            }

            // The roll decides how long the new weather lasts, and that same span is
            // when we next roll, so the two can never drift apart.
            ticksUntilNextChange.put(key, applyRandomWeather(level));
        }
    }

    /** Rolls new weather for the level and returns how many ticks it will last. */
    private int applyRandomWeather(ServerLevel level) {
        RandomSource random = level.getRandom();
        int duration = nextInterval(random);
        boolean makeRain = random.nextBoolean();
        boolean makeThunder = makeRain && random.nextBoolean();

        // Vanilla derives the thunder duration from the rain duration, so passing the
        // rain span here covers both.
        level.setWeatherParameters(
            makeRain ? 0 : duration,
            makeRain ? duration : 0,
            makeRain,
            makeThunder
        );
        return duration;
    }

    private int nextInterval(RandomSource random) {
        return MIN_INTERVAL_TICKS + random.nextInt(MAX_INTERVAL_TICKS - MIN_INTERVAL_TICKS + 1);
    }
}
