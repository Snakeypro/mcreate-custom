package net.snakeypro.mcreate.element.parts;

/**
 * Represents a cog / large gear connection on a Create block.
 * Cogs are used to change rotation speed/direction between axes.
 */
public class CogEntry {

    /** Rotation axis for this cog: X, Y, or Z */
    public String axis = "Y";

    /** Cog size: SMALL (1:1 ratio) or LARGE (1:2 ratio) */
    public String cogType = "SMALL";

    /** Whether the cog is facing positively along its axis (true) or negatively (false) */
    public boolean positiveFacing = true;

    public CogEntry() {}

    public CogEntry(String axis, String cogType, boolean positiveFacing) {
        this.axis = axis;
        this.cogType = cogType;
        this.positiveFacing = positiveFacing;
    }
}
