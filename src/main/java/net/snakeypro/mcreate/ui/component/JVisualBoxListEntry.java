package net.snakeypro.mcreate.ui.component;

import net.mcreator.ui.component.entries.JSimpleListEntry;
import net.mcreator.ui.component.util.PanelUtils;
import net.snakeypro.mcreate.element.parts.VisualBoxEntry;

import javax.swing.*;
import javax.swing.border.TitledBorder;
import java.awt.*;
import java.util.List;

/**
 * A single visual/scroll-value box entry with position, rotation, type and options controls.
 */
public class JVisualBoxListEntry extends JSimpleListEntry<VisualBoxEntry> {

    private static final String[] BOX_TYPES = { "NUMERIC", "OPTIONS", "ICON_OPTIONS" };

    private final JTextField label = new JTextField("Value", 10);
    private final JComboBox<String> boxType = new JComboBox<>(BOX_TYPES);

    // Position
    private final JSpinner xPos = new JSpinner(new SpinnerNumberModel(0.0, -16.0, 16.0, 0.1));
    private final JSpinner yPos = new JSpinner(new SpinnerNumberModel(0.0, -16.0, 16.0, 0.1));
    private final JSpinner zPos = new JSpinner(new SpinnerNumberModel(0.0, -16.0, 16.0, 0.1));

    // Rotation
    private final JSpinner xRot = new JSpinner(new SpinnerNumberModel(0.0, -360.0, 360.0, 1.0));
    private final JSpinner yRot = new JSpinner(new SpinnerNumberModel(0.0, -360.0, 360.0, 1.0));
    private final JSpinner zRot = new JSpinner(new SpinnerNumberModel(0.0, -360.0, 360.0, 1.0));

    // Numeric settings
    private final JSpinner minValue = new JSpinner(new SpinnerNumberModel(0.0, -1e9, 1e9, 1.0));
    private final JSpinner maxValue = new JSpinner(new SpinnerNumberModel(100.0, -1e9, 1e9, 1.0));
    private final JSpinner defaultValue = new JSpinner(new SpinnerNumberModel(0.0, -1e9, 1e9, 1.0));

    // Options settings
    private final JTextField options = new JTextField(20);
    private final JTextField icons = new JTextField(20);
    private final JTextField iconClass = new JTextField(15);

    private final JPanel numericPanel = new JPanel(new FlowLayout(FlowLayout.LEFT));
    private final JPanel optionsPanel = new JPanel(new FlowLayout(FlowLayout.LEFT));

    public JVisualBoxListEntry(JPanel parent, List<JVisualBoxListEntry> entryList) {
        super(parent, entryList);

        // Type selection changes visible sub-panels
        boxType.addActionListener(e -> updateVisibility());

        // Build row 1: label + type
        JPanel row1 = new JPanel(new FlowLayout(FlowLayout.LEFT));
        row1.setOpaque(false);
        row1.add(new JLabel("Label:"));
        row1.add(label);
        row1.add(new JLabel("  Type:"));
        row1.add(boxType);

        // Build position/rotation row
        JPanel row2 = new JPanel(new FlowLayout(FlowLayout.LEFT));
        row2.setOpaque(false);
        row2.add(new JLabel("Pos X:"));
        row2.add(xPos);
        row2.add(new JLabel("Y:"));
        row2.add(yPos);
        row2.add(new JLabel("Z:"));
        row2.add(zPos);
        row2.add(new JLabel("  Rot X:"));
        row2.add(xRot);
        row2.add(new JLabel("Y:"));
        row2.add(yRot);
        row2.add(new JLabel("Z:"));
        row2.add(zRot);

        // Numeric panel
        numericPanel.setOpaque(false);
        numericPanel.add(new JLabel("Min:"));
        numericPanel.add(minValue);
        numericPanel.add(new JLabel("Max:"));
        numericPanel.add(maxValue);
        numericPanel.add(new JLabel("Default:"));
        numericPanel.add(defaultValue);

        // Options panel
        optionsPanel.setOpaque(false);
        options.setToolTipText("Comma-separated option labels, e.g.: Slow,Medium,Fast");
        icons.setToolTipText("Comma-separated icon names (for ICON_OPTIONS), e.g.: AllIcons.I_ARROW_LEFT,AllIcons.I_ARROW_RIGHT");
        iconClass.setToolTipText("Icon sprite class (for ICON_OPTIONS), e.g.: AllIcons");
        optionsPanel.add(new JLabel("Options:"));
        optionsPanel.add(options);
        optionsPanel.add(new JLabel("Icons:"));
        optionsPanel.add(icons);
        optionsPanel.add(new JLabel("Icon class:"));
        optionsPanel.add(iconClass);

        line.setLayout(new BoxLayout(line, BoxLayout.PAGE_AXIS));
        line.add(row1);
        line.add(row2);
        line.add(numericPanel);
        line.add(optionsPanel);

        updateVisibility();
    }

    private void updateVisibility() {
        String selected = (String) boxType.getSelectedItem();
        numericPanel.setVisible("NUMERIC".equals(selected));
        optionsPanel.setVisible("OPTIONS".equals(selected) || "ICON_OPTIONS".equals(selected));
        line.revalidate();
        line.repaint();
    }

    @Override
    protected void setEntryEnabled(boolean enabled) {
        label.setEnabled(enabled);
        boxType.setEnabled(enabled);
        xPos.setEnabled(enabled);
        yPos.setEnabled(enabled);
        zPos.setEnabled(enabled);
        xRot.setEnabled(enabled);
        yRot.setEnabled(enabled);
        zRot.setEnabled(enabled);
        minValue.setEnabled(enabled);
        maxValue.setEnabled(enabled);
        defaultValue.setEnabled(enabled);
        options.setEnabled(enabled);
        icons.setEnabled(enabled);
        iconClass.setEnabled(enabled);
    }

    @Override
    public VisualBoxEntry getEntry() {
        VisualBoxEntry e = new VisualBoxEntry();
        e.label = label.getText();
        e.boxType = (String) boxType.getSelectedItem();
        e.xPos = ((Number) xPos.getValue()).doubleValue();
        e.yPos = ((Number) yPos.getValue()).doubleValue();
        e.zPos = ((Number) zPos.getValue()).doubleValue();
        e.xRot = ((Number) xRot.getValue()).doubleValue();
        e.yRot = ((Number) yRot.getValue()).doubleValue();
        e.zRot = ((Number) zRot.getValue()).doubleValue();
        e.minValue = ((Number) minValue.getValue()).doubleValue();
        e.maxValue = ((Number) maxValue.getValue()).doubleValue();
        e.defaultValue = ((Number) defaultValue.getValue()).doubleValue();
        e.options = options.getText();
        e.icons = icons.getText();
        e.iconClass = iconClass.getText();
        return e;
    }

    @Override
    public void setEntry(VisualBoxEntry e) {
        label.setText(e.label);
        boxType.setSelectedItem(e.boxType);
        xPos.setValue(e.xPos);
        yPos.setValue(e.yPos);
        zPos.setValue(e.zPos);
        xRot.setValue(e.xRot);
        yRot.setValue(e.yRot);
        zRot.setValue(e.zRot);
        minValue.setValue(e.minValue);
        maxValue.setValue(e.maxValue);
        defaultValue.setValue(e.defaultValue);
        options.setText(e.options);
        icons.setText(e.icons);
        iconClass.setText(e.iconClass);
        updateVisibility();
    }
}
