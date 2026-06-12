package net.snakeypro.mcreate.element.types;

import net.mcreator.element.parts.procedure.NumberProcedure;
import net.mcreator.element.parts.procedure.Procedure;
import net.mcreator.element.types.Block;
import net.mcreator.workspace.elements.ModElement;
import net.snakeypro.mcreate.element.parts.CogEntry;
import net.snakeypro.mcreate.element.parts.RotatingVisualEntry;
import net.snakeypro.mcreate.element.parts.ShaftEntry;
import net.snakeypro.mcreate.element.parts.VisualBoxEntry;

import java.util.ArrayList;
import java.util.List;

/**
 * Data model for the Create Mod Block custom element type.
 * Extends MCreator's standard Block to inherit all block properties,
 * and adds Create-specific kinetic/shaft/cog/visual features.
 */
@SuppressWarnings({ "unused", "NotNullFieldNotInitialized" })
public class CreateBlock extends Block {

    // ── Kinetics ──────────────────────────────────────────────────────────────

    /**
     * Kinetic role of this block:
     * CONSUMER   - consumes rotational force (stress impact)
     * GENERATOR  - produces rotational force (capacity + generated speed)
     * NEUTRAL    - passes through rotation without stress
     * CONFIGURABLE - role can be changed at runtime via procedure
     */
    public String kineticRole = "CONSUMER";

    /**
     * Facing/rotation type for the kinetic block:
     * HORIZONTAL_FACING - only rotates on horizontal plane (N/S/E/W)
     * ALL_FACES         - can face any direction (includes up/down)
     * AXIS              - uses an axis property (X/Y/Z) instead of facing
     */
    public String createFacingType = "HORIZONTAL_FACING";

    /** Default stress impact (SU consumed) when role is CONSUMER */
    public double defaultStressImpact = 4.0;

    /**
     * Return-value procedure for dynamic stress impact.
     * If set, overrides defaultStressImpact at runtime.
     * Procedure should return a number (SU impact).
     */
    public NumberProcedure stressImpactProcedure;

    /** Default stress capacity (SU generated) when role is GENERATOR */
    public double defaultCapacity = 256.0;

    /**
     * Return-value procedure for dynamic stress capacity.
     * If set, overrides defaultCapacity at runtime.
     * Procedure should return a number (SU capacity).
     */
    public NumberProcedure capacityProcedure;

    /** Default rotation speed (RPM) generated when role is GENERATOR */
    public double defaultGeneratedSpeed = 16.0;

    /**
     * Return-value procedure for dynamic generated speed.
     * If set, overrides defaultGeneratedSpeed at runtime.
     * Procedure should return a number (RPM).
     */
    public NumberProcedure generatedSpeedProcedure;

    /** Whether kinetic tick events are fired for this block */
    public boolean enableKineticTick = true;

    /**
     * Procedure called on every kinetic tick (same rate as block tick).
     * Context: x, y, z, world, blockstate
     */
    public Procedure onKineticTick;

    /**
     * Procedure called on lazy kinetic tick (roughly every 20 ticks).
     * Context: x, y, z, world, blockstate
     */
    public Procedure onKineticLazyTick;

    // ── Shafts ────────────────────────────────────────────────────────────────

    /** List of shaft connections on this block. Each shaft can be independently controlled. */
    public List<ShaftEntry> shafts = new ArrayList<>();

    // ── Cogs ──────────────────────────────────────────────────────────────────

    /** List of cog/gear connections on this block */
    public List<CogEntry> cogs = new ArrayList<>();

    // ── Rotating Visuals ──────────────────────────────────────────────────────

    /**
     * List of rotating visual parts (shafts, fans, paddles, etc.).
     * Each entry renders a model partial that spins at the block's kinetic speed.
     */
    public List<RotatingVisualEntry> rotatingVisuals = new ArrayList<>();

    // ── Visual/Scroll Value Boxes ─────────────────────────────────────────────

    /**
     * List of scroll-value / interaction boxes displayed above this block.
     * Used for mode selectors, RPM readouts, enum selectors, etc.
     */
    public List<VisualBoxEntry> visualBoxes = new ArrayList<>();

    // ── Goggle Overlay ────────────────────────────────────────────────────────

    /** Whether this block provides custom goggle (engineer's goggles) tooltip information */
    public boolean enableGoggles = false;

    /**
     * Procedure called to add lines to the goggle tooltip.
     * Context: x, y, z, world, blockstate, player
     */
    public Procedure onGoggleTooltip;

    // ── Redstone & Create Links ───────────────────────────────────────────────

    /** Whether this block acts as a Create redstone link (can send/receive wireless redstone signals) */
    public boolean enableRedstoneLink = false;

    /**
     * Redstone link behavior:
     * RECEIVER  - receives and stores redstone signal from links
     * TRANSMITTER - transmits its powered state to links
     * BOTH      - acts as both receiver and transmitter
     */
    public String redstoneLinkBehavior = "RECEIVER";

    /**
     * Procedure called when this block receives a redstone link signal.
     * Context: x, y, z, world, blockstate, signalStrength
     */
    public Procedure onRedstoneLinkReceive;

    /**
     * Return-value procedure for the redstone link output signal.
     * Procedure should return a number 0-15.
     */
    public NumberProcedure redstoneLinkOutputProcedure;

    // ── Constructor ───────────────────────────────────────────────────────────

    public CreateBlock(ModElement element) {
        super(element);

        // Create-specific defaults
        this.kineticRole = "CONSUMER";
        this.createFacingType = "HORIZONTAL_FACING";
        this.defaultStressImpact = 4.0;
        this.defaultCapacity = 256.0;
        this.defaultGeneratedSpeed = 16.0;
        this.enableKineticTick = true;
        this.enableGoggles = false;
        this.enableRedstoneLink = false;
        this.redstoneLinkBehavior = "RECEIVER";

        this.shafts = new ArrayList<>();
        this.cogs = new ArrayList<>();
        this.rotatingVisuals = new ArrayList<>();
        this.visualBoxes = new ArrayList<>();
    }
}
