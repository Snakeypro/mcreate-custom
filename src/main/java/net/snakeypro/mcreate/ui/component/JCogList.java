package net.snakeypro.mcreate.ui.component;

import net.mcreator.ui.MCreator;
import net.mcreator.ui.component.entries.JSimpleEntriesList;
import net.mcreator.ui.component.util.ComponentUtils;
import net.mcreator.ui.help.IHelpContext;
import net.snakeypro.mcreate.element.parts.CogEntry;

import javax.swing.*;
import java.util.List;

/**
 * List editor for Create block cog/gear connections.
 */
public class JCogList extends JSimpleEntriesList<JCogListEntry, CogEntry> {

    public JCogList(MCreator mcreator, IHelpContext gui) {
        super(mcreator, gui);
        ComponentUtils.deriveFont(add, 12);
        add.setText("+ Add Cog");
    }

    @Override
    protected JCogListEntry newEntry(JPanel parent, List<JCogListEntry> entryList, boolean userAction) {
        return new JCogListEntry(parent, entryList);
    }
}
