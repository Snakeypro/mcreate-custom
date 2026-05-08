package com.xenrao.mcreate.custom;

import net.neoforged.neoforge.common.NeoForge;

import net.minecraft.world.level.block.state.BlockState;
import net.minecraft.world.level.block.entity.BlockEntityType;
import net.minecraft.world.level.Level;
import net.minecraft.network.chat.Component;
import net.minecraft.nbt.CompoundTag;
import net.minecraft.core.HolderLookup;
import net.minecraft.core.BlockPos;

import java.util.List;

import com.xenrao.mcreate.events.KineticTickEvent;
import com.xenrao.mcreate.events.GoggleTooltipEvent;

import com.simibubi.create.content.kinetics.base.KineticBlockEntity;
import com.simibubi.create.content.kinetics.KineticNetwork;

public abstract class CustomKineticBlockEntity extends KineticBlockEntity {
	protected double impactValue = 2.0;
	// ============== Events
	protected boolean disableTickEvent = false;
	protected boolean disableLazyTickEvent = false;

	public CustomKineticBlockEntity(BlockEntityType<?> type, BlockPos pos, BlockState state) {
		super(type, pos, state);
	}

	// ============== Getters
	public double getImpactValue() {
		return impactValue;
	}

	// ============== Setters
	public void setImpactValue(double value) {
		impactValue = value;
		if (level != null && !level.isClientSide) {
			if (hasNetwork()) {
				KineticNetwork network = getOrCreateNetwork();
				network.updateStressFor(this, calculateStressApplied());
				network.updateStress();
			}
		}
	}

	public void setTickEvent(boolean value) {
		disableTickEvent = value;
	}

	public void setLazyTickEvent(boolean value) {
		disableLazyTickEvent = value;
	}

	// ============== Others
	@Override
	public float calculateStressApplied() {
		this.lastStressApplied = (float) impactValue;
		return (float) impactValue;
	}

	@Override
	public void lazyTick() {
		super.lazyTick();
		if (!disableLazyTickEvent)
			NeoForge.EVENT_BUS.post(new KineticTickEvent(level, getBlockPos(), getBlockState(), true));
	}

	@Override
	public void tick() {
		super.tick();
		if (!disableTickEvent)
			NeoForge.EVENT_BUS.post(new KineticTickEvent(level, getBlockPos(), getBlockState(), false));
	}

	@Override
	public boolean addToGoggleTooltip(List<Component> tooltip, boolean isPlayerSneaking) {
		super.addToGoggleTooltip(tooltip, isPlayerSneaking);
		GoggleTooltipEvent event = new GoggleTooltipEvent(level, getBlockPos(), getBlockState(), isPlayerSneaking);
		NeoForge.EVENT_BUS.post(event);
		// Event cancel
		if (event.isCanceled())
			return false;
		// clearGoggleTooltip
		if (event.shouldClearDefault())
			tooltip.clear();
		// write
		for (String line : event.getLines()) {
			if (!line.isEmpty())
				tooltip.add(Component.literal(line));
		}
		return true;
	}

	// ============== NBT
	@Override
	public void write(CompoundTag tag, HolderLookup.Provider registries, boolean clientPacket) {
		super.write(tag, registries, clientPacket);
		tag.putBoolean("disableTickEvent", disableTickEvent);
		tag.putBoolean("disableLazyTickEvent", disableLazyTickEvent);
		tag.putInt("LazyTickRate", lazyTickRate);
		tag.putDouble("ImpactValue", impactValue);
	}

	@Override
	protected void read(CompoundTag tag, HolderLookup.Provider registries, boolean clientPacket) {
		super.read(tag, registries, clientPacket);

		if (tag.contains("disableTickEvent"))
			disableTickEvent = tag.getBoolean("disableTickEvent");
		if (tag.contains("disableLazyTickEvent"))
			disableLazyTickEvent = tag.getBoolean("disableLazyTickEvent");

		if (tag.contains("LazyTickRate"))
			lazyTickRate = tag.getInt("LazyTickRate");
		if (tag.contains("ImpactValue"))
			impactValue = tag.getDouble("ImpactValue");
	}
}