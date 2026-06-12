package net.snakeypro.mcreate.ui.component;

import net.mcreator.ui.component.entries.JSimpleListEntry;
import net.mcreator.ui.component.util.PanelUtils;
import net.snakeypro.mcreate.element.parts.ShaftEntry;

import javax.swing.*;
import java.util.List;

/**
 * A single shaft entry row in the shaft list editor.
 * Controls: direction, type (INPUT/OUTPUT/BOTH), independent toggle, speed multiplier, visible toggle.
 */
public class JShaftListEntry extends JSimpleListEntry<ShaftEntry> {

    private static final String[] DIRECTIONS = { "NORTH", "SOUTH", "EAST", "WEST", "UP", "DOWN" };
    private static final String[] TYPES = { "INPUT", "OUTPUT", "BOTH" };

    private final JComboBox<String> direction = new JComboBox<>(DIRECTIONS);
    private final JComboBox<String> type = new JComboBox<>(TYPES);
    private final JCheckBox independent = new JCheckBox("Independent");
    private final JSpinner speedMultiplier = new JSpinner(new SpinnerNumberModel(1.0, -100.0, 100.0, 0.1));
    private final JCheckBox visible = new JCheckBox("Visible", true);

    public JShaftListEntry(JPanel parent, List<JShaftListEntry> entryList) {
        super(parent, entryList);

        direction.setToolTipText("Direction/face this shaft connects on");
        type.setToolTipText("Shaft type: INPUT consumes rotation, OUTPUT provides it, BOTH does both");
        independent.setToolTipText("When checked, shaft operates independently from the block's main kinetic source");
        speedMultiplier.setToolTipText("Speed multiplier (negative reverses direction)");
        visible.setToolTipText("Whether this shaft is rendered in the world");

        JLabel dirLabel = new JLabel("Dir:");
        JLabel typeLabel = new JLabel("Type:");
        JLabel multiplierLabel = new JLabel("Speed ×:");

        // Arrange components in the entry row
        line.add(dirLabel);
        line.add(direction);
        line.add(typeLabel);
        line.add(type);
        line.add(independent);
        line.add(multiplierLabel);
        line.add(speedMultiplier);
        line.add(visible);
    }

    @Override
    protected void setEntryEnabled(boolean enabled) {
        direction.setEnabled(enabled);
        type.setEnabled(enabled);
        independent.setEnabled(enabled);
        speedMultiplier.setEnabled(enabled);
        visible.setEnabled(enabled);
    }

    @Override
    public ShaftEntry getEntry() {
        ShaftEntry entry = new ShaftEntry();
        entry.direction = (String) direction.getSelectedItem();
        entry.type = (String) type.getSelectedItem();
        entry.independent = independent.isSelected();
        entry.speedMultiplier = ((Number) speedMultiplier.getValue()).doubleValue();
        entry.visible = visible.isSelected();
        return entry;
    }

    @Override
    public void setEntry(ShaftEntry e) {
        direction.setSelectedItem(e.direction);
        type.setSelectedItem(e.type);
        independent.setSelected(e.independent);
        speedMultiplier.setValue(e.speedMultiplier);
        visible.setSelected(e.visible);
    }
}
