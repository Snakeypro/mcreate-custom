package com.xenrao.mcreate.custom;

import net.neoforged.neoforge.common.NeoForge;

import net.minecraft.world.level.LevelAccessor;
import net.minecraft.world.level.block.state.BlockState;
import net.minecraft.world.level.block.state.properties.BlockStateProperties;
import net.minecraft.world.level.block.entity.BlockEntityType;
import net.minecraft.world.level.Level;
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
import com.xenrao.mcreate.events.GoggleTooltipEvent;

import com.simibubi.create.content.kinetics.base.KineticBlockEntity;
import com.simibubi.create.content.kinetics.KineticNetwork;
import com.simibubi.create.foundation.blockEntity.behaviour.BlockEntityBehaviour;
import com.simibubi.create.foundation.blockEntity.behaviour.ValueBoxTransform;
import com.simibubi.create.foundation.blockEntity.behaviour.scrollValue.ScrollValueBehaviour;

import net.createmod.catnip.math.VecHelper;
import net.createmod.catnip.math.AngleHelper;
import dev.engine_room.flywheel.lib.transform.TransformStack;

/**
 * Base class for custom kinetic block entities that CONSUME rotational power.
 * Extends KineticBlockEntity directly.
 *
 * === Stress ===
 * calculateStressApplied() returns impactValue — a positive number of SU consumed.
 * Set via setImpactValue() from a procedure.
 *
 * === Scroll Value Box (optional) ===
 * A general-purpose scrollable value box (the white UI box from Create) is built in
 * but hidden by default. Enable it from a procedure with enableScrollValue().
 *
 * When the player scrolls the value, KineticScrollValueEvent fires. Subscribe to it
 * in a MCreator procedure and react however you like — change stress impact, mode, etc.
 *
 * Quick setup example (in "block placed" or "block loaded" procedure):
 *   1. enableScrollValue()                        — shows the box with defaults
 *   2. OR enableScrollValue("Impact", 1, 64, 2)   — custom label, range, and starting value
 *   3. Subscribe to KineticScrollValueEvent and call setImpactValue((double) event.getNewValue())
 */
public abstract class CustomKineticBlockEntity extends KineticBlockEntity {

	protected double impactValue = 2.0;

	// ============== Events
	protected boolean disableTickEvent = false;
	protected boolean disableLazyTickEvent = false;

	// ============== Scroll Value
	protected ScrollValueBehaviour scrollValue;
	private boolean scrollValueEnabled = false;
	private int scrollPrevValue = 0;

	public CustomKineticBlockEntity(BlockEntityType<?> type, BlockPos pos, BlockState state) {
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

	// ============== Getters
	public double getImpactValue() {
		return impactValue;
	}

	/**
	 * Returns the current scroll value box value.
	 * Returns 0 if the scroll value box has not been enabled.
	 */
	public int getScrollValue() {
		return scrollValue != null ? scrollValue.getValue() : 0;
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
	 * @param label        Text shown at the top of the value picker (e.g. "Impact", "Mode")
	 * @param min          Minimum selectable value
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

	// ============== Stress
	@Override
	public float calculateStressApplied() {
		this.lastStressApplied = (float) impactValue;
		return (float) impactValue;
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

	@Override
	public boolean addToGoggleTooltip(List<Component> tooltip, boolean isPlayerSneaking) {
		super.addToGoggleTooltip(tooltip, isPlayerSneaking);
		GoggleTooltipEvent event = new GoggleTooltipEvent(level, getBlockPos(), getBlockState(), isPlayerSneaking);
		NeoForge.EVENT_BUS.post(event);
		if (event.isCanceled())
			return false;
		if (event.shouldClearDefault())
			tooltip.clear();
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
		if (tag.contains("ImpactValue"))
			impactValue = tag.getDouble("ImpactValue");
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
