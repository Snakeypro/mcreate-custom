package com.xenrao.mcreate.custom;

import net.neoforged.neoforge.common.NeoForge;

import net.minecraft.world.level.LevelAccessor;
import net.minecraft.world.level.block.state.BlockState;
import net.minecraft.world.level.block.state.properties.BlockStateProperties;
import net.minecraft.world.level.block.entity.BlockEntityType;
import net.minecraft.network.chat.Component;
import net.minecraft.nbt.CompoundTag;
import net.minecraft.core.HolderLookup;
import net.minecraft.core.BlockPos;
import net.minecraft.core.Direction;
import net.minecraft.world.phys.Vec3;

import com.mojang.blaze3d.vertex.PoseStack;

import java.util.List;

import com.xenrao.mcreate.events.KineticTickEvent;
import com.xenrao.mcreate.events.KineticScrollValueEvent;

import com.simibubi.create.content.kinetics.base.GeneratingKineticBlockEntity;
import com.simibubi.create.foundation.blockEntity.behaviour.BlockEntityBehaviour;
import com.simibubi.create.foundation.blockEntity.behaviour.ValueBoxTransform;
import com.simibubi.create.foundation.blockEntity.behaviour.scrollValue.ScrollValueBehaviour;

import net.createmod.catnip.math.VecHelper;
import net.createmod.catnip.math.AngleHelper;
import dev.engine_room.flywheel.lib.transform.TransformStack;

/**
 * Base class for custom generator kinetic block entities.
 * Extends GeneratingKineticBlockEntity — the correct Create base for power SOURCES.
 *
 * === Stress ===
 * calculateAddedStressCapacity() — SU this generator PROVIDES. Must be POSITIVE.
 * calculateStressApplied()       — SU this block CONSUMES. 0 for generators.
 *
 * === Scroll Value Box (optional) ===
 * A general-purpose scrollable value box (the white UI box from Create) is built in
 * but hidden by default. Enable it from a procedure with enableScrollValue().
 *
 * When the player scrolls the value, KineticScrollValueEvent fires. Subscribe to it
 * in a MCreator procedure and react however you like — change speed, direction, mode, etc.
 *
 * Quick setup example (in "block placed" or "block loaded" procedure):
 *   1. enableScrollValue()              — shows the box with defaults (-256 to 256, label "Value")
 *   2. OR enableScrollValue("RPM", 1, 256, 32)   — custom label, range, and starting value
 *   3. Subscribe to KineticScrollValueEvent and call setGeneratedSpeed((float) event.getNewValue())
 */
public abstract class CustomGeneratorKineticBlockEntity extends GeneratingKineticBlockEntity {

	/** RPM this generator produces. Positive = clockwise, negative = counter-clockwise. */
	protected float generatedSpeed = 32.0f;

	/** Stress Units (SU) capacity this generator adds to the network. Must be positive. */
	protected double generatedCapacity = 128.0;

	// ============== Events
	protected boolean disableTickEvent = false;
	protected boolean disableLazyTickEvent = false;

	// ============== Scroll Value
	protected ScrollValueBehaviour scrollValue;
	private boolean scrollValueEnabled = false;
	private int scrollPrevValue = 0;

	public CustomGeneratorKineticBlockEntity(BlockEntityType<?> type, BlockPos pos, BlockState state) {
		super(type, pos, state);
	}

	// ============== Behaviours
	@Override
	public void addBehaviours(List<BlockEntityBehaviour> behaviours) {
		scrollValue = new ScrollValueBehaviour(
			Component.literal("Value"),
			this,
			new KineticScrollBoxTransform()
		)
		.between(-256, 256)
		.withFormatter(v -> String.valueOf(v))
		.onlyActiveWhen(() -> scrollValueEnabled)
		.withCallback(newVal -> {
			if (level != null && !level.isClientSide) {
				NeoForge.EVENT_BUS.post(new KineticScrollValueEvent(
					level, getBlockPos(), getBlockState(), newVal, scrollPrevValue
				));
				scrollPrevValue = newVal;
			}
		});
		behaviours.add(scrollValue);
	}

	// ============== Initialize
	/**
	 * Called by Create after the block entity is fully loaded into the world.
	 * Fires both on fresh placement and chunk load — this is where the kinetic
	 * network is started, since level is guaranteed to be non-null here.
	 *
	 * "Block placed" procedures fire during Block.onPlace() before level is
	 * injected, so updateGeneratedRotation() called there is silently ignored.
	 * Values set by procedures are saved to fields and picked up here.
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

	/**
	 * Returns the current scroll value box value.
	 * Returns 0 if the scroll value box has not been enabled.
	 */
	public int getScrollValue() {
		return scrollValue != null ? scrollValue.getValue() : 0;
	}

	// ============== Setters

	/**
	 * Sets the RPM this generator produces.
	 * If level is set, immediately propagates to the kinetic network.
	 * If called during Block.onPlace() (level is null), stored and applied in initialize().
	 */
	public void setGeneratedSpeed(float speed) {
		this.generatedSpeed = speed;
		if (level != null && !level.isClientSide) {
			updateGeneratedRotation();
		}
	}

	/**
	 * Sets the SU capacity this generator provides.
	 * If the network exists, notifies it immediately.
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

	/**
	 * Sets the scroll value box value from code (e.g. a procedure).
	 * Also fires KineticScrollValueEvent so your procedure listener is notified.
	 * Has no effect if the scroll value box is not enabled.
	 */
	public void setScrollValue(int value) {
		if (scrollValue != null) {
			scrollValue.setValue(value);
		}
	}

	// ============== Scroll Value Box control

	/**
	 * Enables the scroll value box with default settings:
	 *   label = "Value", range = -256 to 256, starting value = 0
	 *
	 * Call this from a "block placed" or "block loaded" procedure to show the box.
	 * Subscribe to KineticScrollValueEvent to react when the player changes the value.
	 */
	public void enableScrollValue() {
		scrollValueEnabled = true;
	}

	/**
	 * Enables the scroll value box with custom settings.
	 *
	 * @param label        Text shown at the top of the value picker (e.g. "Speed", "Mode")
	 * @param min          Minimum selectable value (can be negative for direction control)
	 * @param max          Maximum selectable value
	 * @param defaultValue The starting value
	 */
	public void enableScrollValue(String label, int min, int max, int defaultValue) {
		if (scrollValue != null) {
			scrollValue.setLabel(Component.literal(label));
			scrollValue.between(min, max);
			scrollValue.setValue(defaultValue);
		}
		scrollValueEnabled = true;
	}

	/**
	 * Hides the scroll value box. The stored value is kept.
	 * Re-enable with enableScrollValue() to show it again.
	 */
	public void disableScrollValue() {
		scrollValueEnabled = false;
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
	 * Returns the SU capacity this generator PROVIDES to the network (positive).
	 * Called by updateGeneratedRotation() via notifyStressCapacityChange().
	 */
	@Override
	public float calculateAddedStressCapacity() {
		this.lastCapacityProvided = (float) generatedCapacity;
		return (float) generatedCapacity;
	}

	/**
	 * Returns how much stress this block CONSUMES — 0 for generators.
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
		tag.putBoolean("ScrollValueEnabled", scrollValueEnabled);
		tag.putInt("ScrollPrevValue", scrollPrevValue);
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
		if (tag.contains("ScrollValueEnabled"))
			scrollValueEnabled = tag.getBoolean("ScrollValueEnabled");
		if (tag.contains("ScrollPrevValue"))
			scrollPrevValue = tag.getInt("ScrollPrevValue");
		// Note: the ScrollValueBehaviour value itself is saved/loaded automatically by Create
	}

	// ============== Scroll box position
	/**
	 * Positions the white value box in 3D space relative to the block.
	 *
	 * If the block has a HORIZONTAL_FACING property, the box appears on the front face
	 * and rotates with the block. Otherwise it appears on the top face.
	 *
	 * Override this inner class in your block entity to customise the position.
	 */
	public class KineticScrollBoxTransform extends ValueBoxTransform {

		@Override
		public Vec3 getLocalOffset(LevelAccessor level, BlockPos pos, BlockState state) {
			if (state.hasProperty(BlockStateProperties.HORIZONTAL_FACING)) {
				// Front face center, automatically rotated with block facing
				return rotateHorizontally(state, VecHelper.voxelSpace(8, 8, 15.5f));
			}
			// Default: top face center
			return VecHelper.voxelSpace(8, 15.5f, 8);
		}

		@Override
		public void rotate(LevelAccessor level, BlockPos pos, BlockState state, PoseStack ms) {
			if (state.hasProperty(BlockStateProperties.HORIZONTAL_FACING)) {
				float yRot = AngleHelper.horizontalAngle(
					state.getValue(BlockStateProperties.HORIZONTAL_FACING)
				);
				TransformStack.of(ms).rotateYDegrees(yRot);
			} else {
				TransformStack.of(ms).rotateXDegrees(90);
			}
		}
	}
}
