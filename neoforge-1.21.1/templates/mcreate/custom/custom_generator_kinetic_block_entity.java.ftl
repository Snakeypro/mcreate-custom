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

import com.google.common.collect.ImmutableList;

import com.simibubi.create.content.kinetics.base.GeneratingKineticBlockEntity;
import com.simibubi.create.foundation.blockEntity.behaviour.BlockEntityBehaviour;
import com.simibubi.create.foundation.blockEntity.behaviour.ValueBoxTransform;
import com.simibubi.create.foundation.blockEntity.behaviour.ValueSettingsBoard;
import com.simibubi.create.foundation.blockEntity.behaviour.ValueSettingsFormatter;
import com.simibubi.create.foundation.blockEntity.behaviour.ValueSettingsFormatter.ScrollOptionSettingsFormatter;
import com.simibubi.create.foundation.blockEntity.behaviour.scrollValue.INamedIconOptions;
import com.simibubi.create.foundation.blockEntity.behaviour.scrollValue.ScrollValueBehaviour;
import com.simibubi.create.foundation.gui.AllIcons;

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
	/** Comma-split option labels for discrete "option selector" mode. Null = numeric mode. */
	private String[] scrollValueOptions = null;
	/** Comma-split Create AllIcons field names for icon+text selector mode. Null = text-only mode. */
	private String[] scrollValueIconNames = null;
	/** Label shown in the value box. Persisted so it survives world reload and client sync. */
	private String scrollLabel = "Value";
	/** Numeric mode min/max — persisted so they survive world reload and client sync. */
	private int scrollMin = -256;
	private int scrollMax = 256;
	/** Cached icon resolution map (field name → AllIcons instance). */
	private static final java.util.Map<String, AllIcons> ICON_CACHE = new java.util.HashMap<>();

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
		) {
			@Override
			public ValueSettingsBoard createBoard(net.minecraft.world.entity.player.Player player, net.minecraft.world.phys.BlockHitResult hitResult) {
				if (scrollValueOptions != null && scrollValueOptions.length > 0) {
					if (scrollValueIconNames != null && scrollValueIconNames.length > 0) {
						// Icon + text mode: mirrors Create's ScrollOptionBehaviour
						INamedIconOptions[] namedOpts = buildNamedIconOptions();
						return new ValueSettingsBoard(label, Math.max(0, namedOpts.length - 1), 1,
							ImmutableList.of(Component.literal("Select")),
							new ScrollOptionSettingsFormatter(namedOpts));
					} else {
						// Text-only label mode
						final String[] opts = scrollValueOptions;
						return new ValueSettingsBoard(label, Math.max(0, opts.length - 1), 1,
							ImmutableList.of(Component.literal("Select")),
							new ValueSettingsFormatter(v -> Component.literal(
								opts[Math.max(0, Math.min(v.value(), opts.length - 1))])));
					}
				}
				return super.createBoard(player, hitResult);
			}
		}
		.between(-256, 256)
		.withFormatter(v -> {
			if (scrollValueOptions != null && scrollValueOptions.length > 0) {
				int i = Math.max(0, Math.min(v, scrollValueOptions.length - 1));
				return scrollValueOptions[i];
			}
			return String.valueOf(v);
		})
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
	 *
	 * Any scroll-value configuration applied during "block placed" (when level
	 * was still null) is pushed to clients here via sendData().
	 */
	@Override
	public void initialize() {
		super.initialize();
		if (level != null && !level.isClientSide) {
			updateGeneratedRotation();
			if (scrollValueEnabled) sendData();
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
		setChanged();
		if (level != null && !level.isClientSide) sendData();
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
		scrollLabel = label;
		scrollMin = min;
		scrollMax = max;
		scrollValueOptions = null;
		scrollValueEnabled = true;
		setChanged();
		if (level != null && !level.isClientSide) sendData();
	}

	/**
	 * Hides the scroll value box. The stored value is kept.
	 * Re-enable with enableScrollValue() to show it again.
	 */
	public void disableScrollValue() {
		scrollValueEnabled = false;
		setChanged();
		if (level != null && !level.isClientSide) sendData();
	}

	/**
	 * Enables the scroll value box as a discrete option selector.
	 * The player scrolls through a fixed list of named options instead of a raw number.
	 * The interaction UI displays the actual option name for the current selection instead
	 * of a raw integer, and scrolling is constrained to the valid index range (0 to N-1).
	 *
	 * @param label        Text shown at the top of the value picker (e.g. "Direction", "Mode")
	 * @param options      Comma-separated list of option names, e.g. "Clockwise,Stopped,Counter-Clockwise"
	 * @param defaultIndex Index of the option that is selected by default (0-based)
	 *
	 * Example (from a procedure):
	 *   enableScrollValueOptions("Direction", "Clockwise,Stopped,Counter-Clockwise", 1)
	 *   → interaction UI shows "Stopped"; scrolling cycles through the named options
	 *   → KineticScrollValueEvent fires with newValue = 0, 1, or 2
	 *   → call getScrollValueOptionLabel() to read the current option name as a String
	 */
	public void enableScrollValueOptions(String label, String options, int defaultIndex) {
		String[] opts = options.split(",");
		for (int i = 0; i < opts.length; i++) {
			opts[i] = opts[i].trim();
		}
		this.scrollValueOptions = opts;
		this.scrollValueIconNames = null;
		this.scrollLabel = label;
		this.scrollMin = 0;
		this.scrollMax = Math.max(0, opts.length - 1);
		if (scrollValue != null) {
			scrollValue.setLabel(Component.literal(label));
			scrollValue.between(0, Math.max(0, opts.length - 1));
			scrollValue.setValue(Math.max(0, Math.min(defaultIndex, opts.length - 1)));
		}
		scrollValueEnabled = true;
		setChanged();
		if (level != null && !level.isClientSide) sendData();
	}

	/**
	 * Enables the scroll value box as a Create-style icon + text discrete selector.
	 * Behaves like the Mechanical Bearing mode selector: each option shows its icon
	 * in the interaction UI cursor together with the option name.
	 *
	 * @param label        Text shown at the top of the value picker (e.g. "Direction", "Mode")
	 * @param options      Comma-separated list of option names, e.g. "Clockwise,Stopped,Counter-Clockwise"
	 * @param icons        Comma-separated list of Create AllIcons field names, e.g. "I_ROTATE_PLACE,I_NONE,I_ROTATE_PLACE_RETURNED"
	 *                     Use "" or "I_NONE" for options without a specific icon.
	 *                     Supported icon names: I_ACTIVE, I_PASSIVE, I_PLAY, I_PAUSE, I_STOP,
	 *                     I_ROTATE_PLACE, I_ROTATE_PLACE_RETURNED, I_ROTATE_NEVER_PLACE,
	 *                     I_MOVE_PLACE, I_MOVE_PLACE_RETURNED, I_MOVE_NEVER_PLACE,
	 *                     I_CART_ROTATE, I_CART_ROTATE_PAUSED, I_CART_ROTATE_LOCKED,
	 *                     I_NONE, and all other AllIcons field names from the Create mod.
	 * @param defaultIndex Index of the option that is selected by default (0-based)
	 *
	 * Example (from a procedure):
	 *   enableScrollValueOptionsWithIcons("Direction", "Clockwise,Stopped,Counter-Clockwise",
	 *       "I_ROTATE_PLACE,I_NONE,I_ROTATE_PLACE_RETURNED", 1)
	 *   → interaction UI shows the "Stopped" icon + label; cycling changes to adjacent options
	 */
	public void enableScrollValueOptionsWithIcons(String label, String options, String icons, int defaultIndex) {
		String[] opts = options.split(",");
		for (int i = 0; i < opts.length; i++) {
			opts[i] = opts[i].trim();
		}
		String[] iconNames = icons.split(",");
		for (int i = 0; i < iconNames.length; i++) {
			iconNames[i] = iconNames[i].trim();
		}
		this.scrollValueOptions = opts;
		this.scrollValueIconNames = iconNames;
		this.scrollLabel = label;
		this.scrollMin = 0;
		this.scrollMax = Math.max(0, opts.length - 1);
		if (scrollValue != null) {
			scrollValue.setLabel(Component.literal(label));
			scrollValue.between(0, Math.max(0, opts.length - 1));
			scrollValue.setValue(Math.max(0, Math.min(defaultIndex, opts.length - 1)));
		}
		scrollValueEnabled = true;
		setChanged();
		if (level != null && !level.isClientSide) sendData();
	}

	/**
	 * Updates the option list for an already-enabled option selector without changing the label.
	 * Useful when the available choices depend on game state.
	 * Clamps the current index into the new list if it is out of range.
	 *
	 * @param options Comma-separated list of option names
	 */
	public void setScrollValueOptions(String options) {
		String[] opts = options.split(",");
		for (int i = 0; i < opts.length; i++) {
			opts[i] = opts[i].trim();
		}
		this.scrollValueOptions = opts;
		if (scrollValue != null) {
			int maxIdx = Math.max(0, opts.length - 1);
			scrollValue.between(0, maxIdx);
			if (scrollValue.getValue() > maxIdx) {
				scrollValue.setValue(maxIdx);
			}
		}
		setChanged();
		if (level != null && !level.isClientSide) sendData();
	}

	/**
	 * Returns the label of the currently selected option when using the option selector mode.
	 * Returns an empty string if the scroll value box is not in option-selector mode.
	 */
	public String getScrollValueOptionLabel() {
		if (scrollValue == null || scrollValueOptions == null || scrollValueOptions.length == 0)
			return "";
		int idx = Math.max(0, Math.min(scrollValue.getValue(), scrollValueOptions.length - 1));
		return scrollValueOptions[idx];
	}

	/**
	 * Returns the AllIcons field name for the currently selected option when using icon+text mode.
	 * Returns an empty string if not in icon mode or no icon is configured for the current option.
	 */
	public String getScrollValueIconName() {
		if (scrollValue == null || scrollValueIconNames == null || scrollValueIconNames.length == 0)
			return "";
		int idx = Math.max(0, Math.min(scrollValue.getValue(), scrollValueIconNames.length - 1));
		return scrollValueIconNames[idx];
	}

	/**
	 * Builds an INamedIconOptions array from the current scrollValueOptions and scrollValueIconNames.
	 * Option names are used directly as display text (not as translation keys).
	 * Icons are resolved by AllIcons field name; unknown names fall back to AllIcons.I_NONE.
	 */
	private INamedIconOptions[] buildNamedIconOptions() {
		final String[] opts = scrollValueOptions;
		final String[] iconNames = scrollValueIconNames;
		INamedIconOptions[] result = new INamedIconOptions[opts.length];
		for (int i = 0; i < opts.length; i++) {
			final String optLabel = opts[i];
			final String iconName = (iconNames != null && i < iconNames.length) ? iconNames[i] : "I_NONE";
			final AllIcons icon = resolveIcon(iconName);
			result[i] = new INamedIconOptions() {
				@Override public AllIcons getIcon() { return icon; }
				/** Return the option label as the "translation key"; MC renders it literally when no translation exists. */
				@Override public String getTranslationKey() { return optLabel; }
			};
		}
		return result;
	}

	/**
	 * Resolves an AllIcons instance from its field name (e.g. "I_ACTIVE").
	 * Results are cached. Unknown names return AllIcons.I_NONE.
	 */
	private static AllIcons resolveIcon(String name) {
		if (name == null || name.isBlank()) return AllIcons.I_NONE;
		return ICON_CACHE.computeIfAbsent(name.trim(), k -> {
			try {
				return (AllIcons) AllIcons.class.getField(k).get(null);
			} catch (NoSuchFieldException | IllegalAccessException | ClassCastException ignored) {
				// Unknown icon name or inaccessible field — fall back to the blank icon.
				return AllIcons.I_NONE;
			}
		});
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
		tag.putString("ScrollLabel", scrollLabel);
		tag.putInt("ScrollMin", scrollMin);
		tag.putInt("ScrollMax", scrollMax);
		if (scrollValueOptions != null)
			tag.putString("ScrollValueOptions", String.join(",", scrollValueOptions));
		if (scrollValueIconNames != null)
			tag.putString("ScrollValueIconNames", String.join(",", scrollValueIconNames));
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
		if (tag.contains("ScrollLabel"))
			scrollLabel = tag.getString("ScrollLabel");
		if (tag.contains("ScrollMin"))
			scrollMin = tag.getInt("ScrollMin");
		if (tag.contains("ScrollMax"))
			scrollMax = tag.getInt("ScrollMax");
		if (tag.contains("ScrollValueOptions")) {
			String opts = tag.getString("ScrollValueOptions");
			if (!opts.isEmpty()) {
				String[] raw = opts.split(",");
				for (int i = 0; i < raw.length; i++) raw[i] = raw[i].trim();
				scrollValueOptions = raw;
			}
		}
		if (tag.contains("ScrollValueIconNames")) {
			String icons = tag.getString("ScrollValueIconNames");
			if (!icons.isEmpty()) {
				String[] raw = icons.split(",");
				for (int i = 0; i < raw.length; i++) raw[i] = raw[i].trim();
				scrollValueIconNames = raw;
			}
		}
		// Re-apply label and range to the ScrollValueBehaviour so both server (world
		// reload) and client (sync packet) stay consistent with the stored configuration.
		if (scrollValue != null) {
			scrollValue.setLabel(Component.literal(scrollLabel));
			if (scrollValueOptions != null && scrollValueOptions.length > 0)
				scrollValue.between(0, scrollValueOptions.length - 1);
			else
				scrollValue.between(scrollMin, scrollMax);
		}
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
