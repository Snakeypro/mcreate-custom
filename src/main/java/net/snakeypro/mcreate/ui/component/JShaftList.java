package net.snakeypro.mcreate.ui.component;

import net.mcreator.ui.MCreator;
import net.mcreator.ui.component.entries.JSimpleEntriesList;
import net.mcreator.ui.component.util.ComponentUtils;
import net.mcreator.ui.help.IHelpContext;
import net.snakeypro.mcreate.element.parts.ShaftEntry;

import javax.swing.*;
import java.util.List;

/**
 * List editor for Create block shaft connections.
 * Allows adding/removing/reordering shaft entries with per-entry controls.
 */
public class JShaftList extends JSimpleEntriesList<JShaftListEntry, ShaftEntry> {

    public JShaftList(MCreator mcreator, IHelpContext gui) {
        super(mcreator, gui);
        ComponentUtils.deriveFont(add, 12);
        add.setText("+ Add Shaft");
    }

    @Override
    protected JShaftListEntry newEntry(JPanel parent, List<JShaftListEntry> entryList, boolean userAction) {
        return new JShaftListEntry(parent, entryList);
    }
}
