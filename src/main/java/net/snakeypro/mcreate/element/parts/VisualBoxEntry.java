package net.snakeypro.mcreate.element.parts;

/**
 * Represents a Create scroll-value / interaction box rendered above a block.
 * Visual boxes display information (like RPM, mode selector, etc.) in the goggle overlay
 * or as a floating UI element.
 */
public class VisualBoxEntry {

    /** Display label shown in the box */
    public String label = "Value";

    /** X offset of the box relative to the block center (in pixels, 1/16 of a block) */
    public double xPos = 0;
    /** Y offset */
    public double yPos = 0;
    /** Z offset */
    public double zPos = 0;

    /** X rotation of the box (degrees) */
    public double xRot = 0;
    /** Y rotation */
    public double yRot = 0;
    /** Z rotation */
    public double zRot = 0;

    /**
     * Box type/mode:
     * NUMERIC - shows a numeric value (min/max/default)
     * OPTIONS - shows a list of text options
     * ICON_OPTIONS - shows icon+text options (enum selector)
     */
    public String boxType = "NUMERIC";

    /** Comma-separated list of option labels (for OPTIONS / ICON_OPTIONS types) */
    public String options = "";

    /** Comma-separated list of icon resource paths (for ICON_OPTIONS type) */
    public String icons = "";

    /** Icon sprite class name (for ICON_OPTIONS type), e.g. "AllIcons" */
    public String iconClass = "";

    /** Minimum numeric value (for NUMERIC type) */
    public double minValue = 0;

    /** Maximum numeric value (for NUMERIC type) */
    public double maxValue = 100;

    /** Default value index or numeric default */
    public double defaultValue = 0;

    public VisualBoxEntry() {}
}
