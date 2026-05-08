package com.xenrao.mcreate.events;

import net.neoforged.bus.api.ICancellableEvent;
import net.neoforged.bus.api.Event;

import net.minecraft.world.level.block.state.BlockState;
import net.minecraft.world.level.Level;
import net.minecraft.core.BlockPos;

import java.util.List;
import java.util.ArrayList;

public class GoggleTooltipEvent extends Event implements ICancellableEvent {
	private final Level level;
	private final BlockPos pos;
	private final BlockState blockState;
	private final boolean isPlayerSneaking;
	private final List<String> lines = new ArrayList<>();
	private boolean clearDefault = false;

	public GoggleTooltipEvent(Level level, BlockPos pos, BlockState blockState, boolean isPlayerSneaking) {
		this.level = level;
		this.pos = pos;
		this.blockState = blockState;
		this.isPlayerSneaking = isPlayerSneaking;
	}

	public void addLine(String text) {
		lines.add(text);
	}

	// clear create's tooltip
	public void clearGoggleTooltip() {
		clearDefault = true;
	}

	public boolean shouldClearDefault() {
		return clearDefault;
	}

	public List<String> getLines() {
		return lines;
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

	public boolean isPlayerSneaking() {
		return isPlayerSneaking;
	}
}