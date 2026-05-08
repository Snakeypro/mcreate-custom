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
 * These blocks PRODUCE rotational power rather than consuming it.
 *
 * GeneratingKineticBlockEntity is the correct Create base for power sources —
 * it provides getGeneratedSpeed(), updateGeneratedRotation(), and handles
 * stress capacity automatically (negative stress impact = SU provided).
 *
 * Set generatedSpeed to control RPM output.
 * Set generatedCapacity to control how many SU this block contributes.
 */
public abstract class CustomGeneratorKineticBlockEntity extends GeneratingKineticBlockEntity {
	/** RPM this generator produces. Positive = clockwise, negative = counter-clockwise. */
	protected float generatedSpeed = 32.0f;
	/** Stress Units (SU) capacity this generator adds to the network. */
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
	 * Sets the RPM this generator produces and propagates the change through
	 * the kinetic network via updateGeneratedRotation().
	 */
	public void setGeneratedSpeed(float speed) {
		this.generatedSpeed = speed;
		if (level != null && !level.isClientSide) {
			updateGeneratedRotation();
		}
	}

	/**
	 * Sets the SU capacity this generator provides.
	 * The network is notified via notifyStressCapacityChange().
	 */
	public void setGeneratedCapacity(double capacity) {
		this.generatedCapacity = capacity;
		if (level != null && !level.isClientSide) {
			notifyStressCapacityChange();
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
	 * Returns the speed this block generates.
	 * This is what Create checks to treat the block as a rotation source.
	 */
	@Override
	public float getGeneratedSpeed() {
		return generatedSpeed;
	}

	/**
	 * Negative stress impact = adds SU capacity to the network.
	 */
	@Override
	public float calculateStressApplied() {
		this.lastStressApplied = -(float) generatedCapacity;
		return -(float) generatedCapacity;
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
