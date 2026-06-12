package net.snakeypro.mcreate.ui.component;

import net.mcreator.ui.component.entries.JSimpleListEntry;
import net.snakeypro.mcreate.element.parts.RotatingVisualEntry;

import javax.swing.*;
import java.util.List;

/**
 * A single rotating visual entry row.
 * Controls: partial model identifier, local direction, speed multiplier, counter-clockwise, offset.
 */
public class JRotatingVisualListEntry extends JSimpleListEntry<RotatingVisualEntry> {

    private static final String[] PARTIAL_MODELS = {
            "shaft", "small_cog", "large_cog", "belt_shaft",
            "fan_blade", "mixer_head", "encased_shaft",
            "custom" // user can type in the field
    };
    private static final String[] DIRECTIONS = { "NORTH", "SOUTH", "EAST", "WEST", "UP", "DOWN" };

    private final JComboBox<String> partialModel = new JComboBox<>(PARTIAL_MODELS);
    private final JTextField customModelKey = new JTextField(12);
    private final JComboBox<String> localDirection = new JComboBox<>(DIRECTIONS);
    private final JSpinner speedMultiplier = new JSpinner(new SpinnerNumberModel(1.0, -100.0, 100.0, 0.1));
    private final JCheckBox counterClockwise = new JCheckBox("Reverse");
    private final JSpinner xOffset = new JSpinner(new SpinnerNumberModel(0.0, -2.0, 2.0, 0.0625));
    private final JSpinner yOffset = new JSpinner(new SpinnerNumberModel(0.0, -2.0, 2.0, 0.0625));
    private final JSpinner zOffset = new JSpinner(new SpinnerNumberModel(0.0, -2.0, 2.0, 0.0625));

    public JRotatingVisualListEntry(JPanel parent, List<JRotatingVisualListEntry> entryList) {
        super(parent, entryList);

        partialModel.setEditable(true);
        partialModel.setToolTipText("Create partial model to rotate. Select a preset or type a custom key.");
        localDirection.setToolTipText("Local direction/axis to rotate around");
        speedMultiplier.setToolTipText("Speed multiplier (negative = counter direction)");
        counterClockwise.setToolTipText("Reverse rotation direction");
        xOffset.setToolTipText("X offset in blocks");
        yOffset.setToolTipText("Y offset in blocks");
        zOffset.setToolTipText("Z offset in blocks");

        line.add(new JLabel("Model:"));
        line.add(partialModel);
        line.add(new JLabel("Dir:"));
        line.add(localDirection);
        line.add(new JLabel("Speed×:"));
        line.add(speedMultiplier);
        line.add(counterClockwise);
        line.add(new JLabel("  Offset X:"));
        line.add(xOffset);
        line.add(new JLabel("Y:"));
        line.add(yOffset);
        line.add(new JLabel("Z:"));
        line.add(zOffset);
    }

    @Override
    protected void setEntryEnabled(boolean enabled) {
        partialModel.setEnabled(enabled);
        localDirection.setEnabled(enabled);
        speedMultiplier.setEnabled(enabled);
        counterClockwise.setEnabled(enabled);
        xOffset.setEnabled(enabled);
        yOffset.setEnabled(enabled);
        zOffset.setEnabled(enabled);
    }

    @Override
    public RotatingVisualEntry getEntry() {
        RotatingVisualEntry e = new RotatingVisualEntry();
        Object modelSelected = partialModel.getSelectedItem();
        e.partialModel = modelSelected != null ? modelSelected.toString() : "shaft";
        e.localDirection = (String) localDirection.getSelectedItem();
        e.speedMultiplier = ((Number) speedMultiplier.getValue()).doubleValue();
        e.counterClockwise = counterClockwise.isSelected();
        e.xOffset = ((Number) xOffset.getValue()).doubleValue();
        e.yOffset = ((Number) yOffset.getValue()).doubleValue();
        e.zOffset = ((Number) zOffset.getValue()).doubleValue();
        return e;
    }

    @Override
    public void setEntry(RotatingVisualEntry e) {
        partialModel.setSelectedItem(e.partialModel);
        localDirection.setSelectedItem(e.localDirection);
        speedMultiplier.setValue(e.speedMultiplier);
        counterClockwise.setSelected(e.counterClockwise);
        xOffset.setValue(e.xOffset);
        yOffset.setValue(e.yOffset);
        zOffset.setValue(e.zOffset);
    }
}
