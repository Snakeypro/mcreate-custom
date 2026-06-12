package net.snakeypro.mcreate.registry;

import net.mcreator.element.ModElementType;
import net.mcreator.generator.GeneratorFlavor;
import net.snakeypro.mcreate.element.types.CreateBlock;
import net.snakeypro.mcreate.ui.modgui.CreateBlockGUI;

import static net.mcreator.element.ModElementTypeLoader.register;
import static net.mcreator.generator.GeneratorFlavor.BaseLanguage.JAVA;

/**
 * Registers MCreate Custom plugin element types with MCreator.
 */
public class PluginElementTypes {

    /** The Create Block element type, registered as 'C' in MCreator's element palette */
    public static ModElementType<?> CREATEBLOCK;

    public static void load() {
        CREATEBLOCK = register(
                new ModElementType<>("createblock", (Character) 'C', CreateBlockGUI::new, CreateBlock.class)
        ).coveredOn(GeneratorFlavor.baseLanguage(JAVA));
    }
}
