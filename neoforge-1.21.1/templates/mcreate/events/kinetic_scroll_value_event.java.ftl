package com.xenrao.mcreate.events;

import net.neoforged.bus.api.Event;

import net.minecraft.world.level.LevelAccessor;
import net.minecraft.world.level.block.state.BlockState;
import net.minecraft.core.BlockPos;

/**
 * Fired on the NeoForge event bus when a ScrollValueBehaviour value changes
 * on a CustomKineticBlockEntity or CustomGeneratorKineticBlockEntity.
 *
 * Fired server-side only, both when a player scrolls the value box AND when
 * setScrollValue() is called from code (e.g. a procedure).
 *
 * Usage in MCreator procedure:
 *   Subscribe to KineticScrollValueEvent, read getNewValue() to react.
 *
 * Example uses:
 *   - Change generator speed/direction based on value
 *   - Switch operating mode
 *   - Set stress impact dynamically
 *   - Any other per-block configurable integer
 */
public class KineticScrollValueEvent extends Event {

	private final LevelAccessor level;
	private final BlockPos pos;
	private final BlockState state;
	private final int newValue;
	private final int oldValue;

	public KineticScrollValueEvent(LevelAccessor level, BlockPos pos, BlockState state, int newValue, int oldValue) {
		this.level = level;
		this.pos = pos;
		this.state = state;
		this.newValue = newValue;
		this.oldValue = oldValue;
	}

	/** The world the block is in. */
	public LevelAccessor getLevel() {
		return level;
	}

	/** The position of the block. */
	public BlockPos getPos() {
		return pos;
	}

	/** The block state of the block. */
	public BlockState getState() {
		return state;
	}

	/**
	 * The value after the change.
	 * This is the value you should act on in your procedure.
	 */
	public int getNewValue() {
		return newValue;
	}

	/** The value before the change. */
	public int getOldValue() {
		return oldValue;
	}
}
