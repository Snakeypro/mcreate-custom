package net.snakeypro.mcreate;

import net.mcreator.plugin.JavaPlugin;
import net.mcreator.plugin.Plugin;
import net.mcreator.plugin.events.PreGeneratorsLoadingEvent;
import net.snakeypro.mcreate.registry.PluginElementTypes;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

/**
 * Entry point for the MCreate Custom Java plugin.
 * Registers the Create Block custom element type on startup.
 */
public class McreatePlugin extends JavaPlugin {

    public static final Logger LOG = LogManager.getLogger("MCreate Custom Plugin");

    public McreatePlugin(Plugin plugin) {
        super(plugin);
        addListener(PreGeneratorsLoadingEvent.class, event -> PluginElementTypes.load());
        LOG.info("MCreate Custom plugin loaded");
    }
}
