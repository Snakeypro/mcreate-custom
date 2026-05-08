package com.xenrao.mcreate.custom;

import net.neoforged.neoforge.common.NeoForge;

import net.minecraft.world.level.block.state.BlockState;
import net.minecraft.world.level.block.entity.BlockEntityType;
import net.minecraft.nbt.CompoundTag;
import net.minecraft.core.HolderLookup;
import net.minecraft.core.BlockPos;

import com.xenrao.mcreate.events.KineticTickEvent;

import com.simibubi.create.content.kinetics.base.GeneratingKineticBlockEntity;

/**
 * Base class for custom generator kinetic block entities.
 * Extends GeneratingKineticBlockEntity — the correct Create base for power SOURCES.
 *
 * Create's GeneratingKineticBlockEntity uses TWO separate methods for stress:
 *
 *   calculateAddedStressCapacity() — how many SU this generator PROVIDES to the network.
 *                                    Must return a POSITIVE value.
 *                                    This is what goggles show as "Generator Stats: Capacity"
 *
 *   calculateStressApplied()       — how much stress this block CONSUMES from the network.
 *                                    For a generator this should be 0.
 *
 * Inside updateGeneratedRotation(), Create calls BOTH:
 *   notifyStressCapacityChange(calculateAddedStressCapacity());
 *   network.updateStressFor(this, calculateStressApplied());
 *
 * The previous implementation incorrectly overrode calculateStressApplied() with
 * a negative value — this consumed negative stress rather than providing capacity.
 */
public abstract class CustomGeneratorKineticBlockEntity extends GeneratingKineticBlockEntity {

	/** RPM this generator produces. Positive = clockwise, negative = counter-clockwise. */
	protected float generatedSpeed = 32.0f;

	/** Stress Units (SU) capacity this generator adds to the network. Must be positive. */
	protected double generatedCapacity = 128.0;

	// ============== Events
	protected boolean disableTickEvent = false;
	protected boolean disableLazyTickEvent = false;

	public CustomGeneratorKineticBlockEntity(BlockEntityType<?> type, BlockPos pos, BlockState state) {
		super(type, pos, state);
	}

	// ============== Getters
	public float getGeneratedSpeedValue() {
		return generatedSpeed;
	}

	public double getGeneratedCapacityValue() {
		return generatedCapacity;
	}

	// ============== Setters

	/**
	 * Sets the RPM this generator produces and propagates it through the kinetic network.
	 * updateGeneratedRotation() re-evaluates getGeneratedSpeed() and also calls
	 * calculateAddedStressCapacity() + calculateStressApplied() internally.
	 */
	public void setGeneratedSpeed(float speed) {
		this.generatedSpeed = speed;
		if (level != null && !level.isClientSide) {
			updateGeneratedRotation();
		}
	}

	/**
	 * Sets the SU capacity this generator provides.
	 * Calls updateGeneratedRotation() which internally calls
	 * notifyStressCapacityChange(calculateAddedStressCapacity()) — the correct path.
	 */
	public void setGeneratedCapacity(double capacity) {
		this.generatedCapacity = capacity;
		if (level != null && !level.isClientSide) {
			updateGeneratedRotation();
		}
	}

	public void setTickEvent(boolean value) {
		disableTickEvent = value;
	}

	public void setLazyTickEvent(boolean value) {
		disableLazyTickEvent = value;
	}

	// ============== Generator overrides

	/**
	 * Returns the speed this generator produces.
	 * Any non-zero value makes Create treat this as a rotation source.
	 */
	@Override
	public float getGeneratedSpeed() {
		return generatedSpeed;
	}

	/**
	 * Returns the SU capacity this generator PROVIDES to the network.
	 * Must be a POSITIVE value. Create multiplies this by speed internally
	 * when displaying in goggles.
	 *
	 * This is called by updateGeneratedRotation() via:
	 *   notifyStressCapacityChange(calculateAddedStressCapacity())
	 */
	@Override
	public float calculateAddedStressCapacity() {
		this.lastCapacityProvided = (float) generatedCapacity;
		return (float) generatedCapacity;
	}

	/**
	 * Returns how much stress this block CONSUMES.
	 * For a generator this is 0 — generators provide capacity, they don't consume stress.
	 *
	 * This is called by updateGeneratedRotation() via:
	 *   network.updateStressFor(this, calculateStressApplied())
	 */
	@Override
	public float calculateStressApplied() {
		this.lastStressApplied = 0;
		return 0;
	}

	// ============== Ticks
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

	// ============== NBT
	@Override
	public void write(CompoundTag tag, HolderLookup.Provider registries, boolean clientPacket) {
		super.write(tag, registries, clientPacket);
		tag.putBoolean("disableTickEvent", disableTickEvent);
		tag.putBoolean("disableLazyTickEvent", disableLazyTickEvent);
		tag.putInt("LazyTickRate", lazyTickRate);
		tag.putFloat("GeneratedSpeed", generatedSpeed);
		tag.putDouble("GeneratedCapacity", generatedCapacity);
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
		if (tag.contains("GeneratedSpeed"))
			generatedSpeed = tag.getFloat("GeneratedSpeed");
		if (tag.contains("GeneratedCapacity"))
			generatedCapacity = tag.getDouble("GeneratedCapacity");
	}
}
