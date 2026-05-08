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
 *   calculateAddedStressCapacity() — SU this generator PROVIDES. Must be POSITIVE.
 *   calculateStressApplied()       — SU this block CONSUMES. Should be 0 for generators.
 *
 * IMPORTANT — timing:
 *   setGeneratedSpeed/setGeneratedCapacity are often called from "block placed" procedures,
 *   which fire during Block.onPlace() BEFORE the block entity's level field is injected.
 *   updateGeneratedRotation() returns early when level == null, so the network is never
 *   created. initialize() is the correct hook — Create calls it after the BE is fully
 *   loaded with level set, both on fresh placement and on chunk load.
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

	// ============== Initialize
	/**
	 * Called by Create after the block entity is fully loaded into the world (level set).
	 * This fires both on fresh placement and on chunk load — it is the correct place to
	 * start the kinetic network for a generator.
	 *
	 * "Block placed" procedures fire during Block.onPlace(), before level is injected,
	 * so updateGeneratedRotation() called there is silently ignored. The values are saved
	 * to NBT fields, and this method picks them up at the right time.
	 */
	@Override
	public void initialize() {
		super.initialize();
		if (level != null && !level.isClientSide) {
			updateGeneratedRotation();
		}
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
	 * Sets the RPM this generator produces.
	 * If called after placement (level is set), immediately propagates to the network.
	 * If called during Block.onPlace() (level is null), the value is stored and
	 * initialize() will apply it once the BE is fully loaded.
	 */
	public void setGeneratedSpeed(float speed) {
		this.generatedSpeed = speed;
		if (level != null && !level.isClientSide) {
			updateGeneratedRotation();
		}
	}

	/**
	 * Sets the SU capacity this generator provides.
	 * If the network already exists, notifies it immediately.
	 * If called during Block.onPlace() (level is null), the value is stored and
	 * initialize() will apply it once the BE is fully loaded.
	 */
	public void setGeneratedCapacity(double capacity) {
		this.generatedCapacity = capacity;
		if (level != null && !level.isClientSide) {
			if (hasNetwork()) {
				notifyStressCapacityChange(calculateAddedStressCapacity());
			}
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
	 * Must be POSITIVE. Called by updateGeneratedRotation() via:
	 *   notifyStressCapacityChange(calculateAddedStressCapacity())
	 */
	@Override
	public float calculateAddedStressCapacity() {
		this.lastCapacityProvided = (float) generatedCapacity;
		return (float) generatedCapacity;
	}

	/**
	 * Returns how much stress this block CONSUMES — 0 for generators.
	 * Called by updateGeneratedRotation() via:
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
