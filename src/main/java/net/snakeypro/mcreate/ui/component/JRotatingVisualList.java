package net.snakeypro.mcreate.ui.component;

import net.mcreator.ui.MCreator;
import net.mcreator.ui.component.entries.JSimpleEntriesList;
import net.mcreator.ui.component.util.ComponentUtils;
import net.mcreator.ui.help.IHelpContext;
import net.snakeypro.mcreate.element.parts.RotatingVisualEntry;

import javax.swing.*;
import java.util.List;

/**
 * List editor for Create rotating visual parts (shafts, fans, paddles, etc.)
 */
public class JRotatingVisualList extends JSimpleEntriesList<JRotatingVisualListEntry, RotatingVisualEntry> {

    public JRotatingVisualList(MCreator mcreator, IHelpContext gui) {
        super(mcreator, gui);
        ComponentUtils.deriveFont(add, 12);
        add.setText("+ Add Rotating Visual");
    }

    @Override
    protected JRotatingVisualListEntry newEntry(JPanel parent, List<JRotatingVisualListEntry> entryList,
            boolean userAction) {
        return new JRotatingVisualListEntry(parent, entryList);
    }
}
