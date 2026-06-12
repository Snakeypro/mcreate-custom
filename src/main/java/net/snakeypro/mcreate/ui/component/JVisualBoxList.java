package net.snakeypro.mcreate.ui.component;

import net.mcreator.ui.MCreator;
import net.mcreator.ui.component.entries.JSimpleEntriesList;
import net.mcreator.ui.component.util.ComponentUtils;
import net.mcreator.ui.help.IHelpContext;
import net.snakeypro.mcreate.element.parts.VisualBoxEntry;

import javax.swing.*;
import java.util.List;

/**
 * List editor for Create scroll-value / visual interaction boxes.
 */
public class JVisualBoxList extends JSimpleEntriesList<JVisualBoxListEntry, VisualBoxEntry> {

    public JVisualBoxList(MCreator mcreator, IHelpContext gui) {
        super(mcreator, gui);
        ComponentUtils.deriveFont(add, 12);
        add.setText("+ Add Visual Box");
    }

    @Override
    protected JVisualBoxListEntry newEntry(JPanel parent, List<JVisualBoxListEntry> entryList, boolean userAction) {
        return new JVisualBoxListEntry(parent, entryList);
    }
}
