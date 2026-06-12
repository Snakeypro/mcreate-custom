package net.snakeypro.mcreate.element.parts;

/**
 * Represents a single kinetic shaft connection entry on a Create block.
 * Each shaft can be independently controlled with its own direction, type, speed multiplier, and visibility.
 */
public class ShaftEntry {

    /** Face/direction this shaft connects on. One of: NORTH, SOUTH, EAST, WEST, UP, DOWN */
    public String direction = "NORTH";

    /** Shaft type: INPUT (consumes rotation), OUTPUT (provides rotation), or BOTH */
    public String type = "BOTH";

    /** When true, this shaft operates independently of the block's main kinetic source */
    public boolean independent = false;

    /** Speed multiplier applied to rotation passing through this shaft */
    public double speedMultiplier = 1.0;

    /** Whether this shaft is rendered in the world */
    public boolean visible = true;

    public ShaftEntry() {}

    public ShaftEntry(String direction, String type, boolean independent, double speedMultiplier, boolean visible) {
        this.direction = direction;
        this.type = type;
        this.independent = independent;
        this.speedMultiplier = speedMultiplier;
        this.visible = visible;
    }
}
