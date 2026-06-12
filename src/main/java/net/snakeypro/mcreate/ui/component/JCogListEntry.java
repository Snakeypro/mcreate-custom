package net.snakeypro.mcreate.ui.component;

import net.mcreator.ui.component.entries.JSimpleListEntry;
import net.snakeypro.mcreate.element.parts.CogEntry;

import javax.swing.*;
import java.util.List;

/**
 * A single cog/gear entry row in the cog list editor.
 */
public class JCogListEntry extends JSimpleListEntry<CogEntry> {

    private static final String[] AXES = { "X", "Y", "Z" };
    private static final String[] COG_TYPES = { "SMALL", "LARGE" };

    private final JComboBox<String> axis = new JComboBox<>(AXES);
    private final JComboBox<String> cogType = new JComboBox<>(COG_TYPES);
    private final JCheckBox positiveFacing = new JCheckBox("Positive facing");

    public JCogListEntry(JPanel parent, List<JCogListEntry> entryList) {
        super(parent, entryList);

        axis.setToolTipText("Rotation axis for this cog");
        cogType.setToolTipText("SMALL cog is 1:1, LARGE is 1:2 gear ratio");
        positiveFacing.setSelected(true);
        positiveFacing.setToolTipText("Facing direction along the axis");

        line.add(new JLabel("Axis:"));
        line.add(axis);
        line.add(new JLabel("Type:"));
        line.add(cogType);
        line.add(positiveFacing);
    }

    @Override
    protected void setEntryEnabled(boolean enabled) {
        axis.setEnabled(enabled);
        cogType.setEnabled(enabled);
        positiveFacing.setEnabled(enabled);
    }

    @Override
    public CogEntry getEntry() {
        CogEntry entry = new CogEntry();
        entry.axis = (String) axis.getSelectedItem();
        entry.cogType = (String) cogType.getSelectedItem();
        entry.positiveFacing = positiveFacing.isSelected();
        return entry;
    }

    @Override
    public void setEntry(CogEntry e) {
        axis.setSelectedItem(e.axis);
        cogType.setSelectedItem(e.cogType);
        positiveFacing.setSelected(e.positiveFacing);
    }
}
