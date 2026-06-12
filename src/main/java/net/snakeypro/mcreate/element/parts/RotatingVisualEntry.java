package net.snakeypro.mcreate.element.parts;

/**
 * Represents a rotating visual part on a Create block.
 * Used for things like spinning shafts, mixer paddles, fan blades, etc.
 * Each entry renders a model partial that rotates at the block's kinetic speed.
 */
public class RotatingVisualEntry {

    /**
     * The model partial/key to use for this rotating visual.
     * This references a model registered via Create's KineticBlockEntityRenderer system.
     * Examples: "shaft", "cog", "small_cog", "large_cog"
     */
    public String partialModel = "shaft";

    /** Local direction/axis this visual rotates around: NORTH, SOUTH, EAST, WEST, UP, DOWN */
    public String localDirection = "NORTH";

    /** Speed multiplier relative to the block's own rotation speed (negative = reverse) */
    public double speedMultiplier = 1.0;

    /** Whether to reverse the rotation direction */
    public boolean counterClockwise = false;

    /** X offset of the visual part relative to the block center */
    public double xOffset = 0;
    /** Y offset */
    public double yOffset = 0;
    /** Z offset */
    public double zOffset = 0;

    public RotatingVisualEntry() {}

    public RotatingVisualEntry(String partialModel, String localDirection, double speedMultiplier) {
        this.partialModel = partialModel;
        this.localDirection = localDirection;
        this.speedMultiplier = speedMultiplier;
    }
}
