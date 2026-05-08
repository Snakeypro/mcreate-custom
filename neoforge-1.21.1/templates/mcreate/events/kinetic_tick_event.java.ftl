package com.xenrao.mcreate.events;

import net.neoforged.bus.api.Event;

import net.minecraft.world.level.block.state.BlockState;
import net.minecraft.world.level.Level;
import net.minecraft.core.BlockPos;

public class KineticTickEvent extends Event {
	private final Level level;
	private final BlockPos pos;
	private final BlockState blockState;
	private final boolean isLazy;

	public KineticTickEvent(Level level, BlockPos pos, BlockState blockState, boolean isLazy) {
		this.level = level;
		this.pos = pos;
		this.blockState = blockState;
		this.isLazy = isLazy;
	}

	public Level getLevel() {
		return level;
	}

	public BlockPos getPos() {
		return pos;
	}

	public BlockState getBlockState() {
		return blockState;
	}

	public boolean isLazy() {
		return isLazy;
	}
}