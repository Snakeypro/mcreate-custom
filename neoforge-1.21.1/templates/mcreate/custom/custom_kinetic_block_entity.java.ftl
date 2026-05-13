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

import com.google.common.collect.ImmutableList;

import com.simibubi.create.content.kinetics.base.KineticBlockEntity;
import com.simibubi.create.content.kinetics.KineticNetwork;
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
	/** Comma-split option labels for discrete "option selector" mode. Null = numeric mode. */
	private String[] scrollValueOptions = null;
	/** Comma-split icon field names for icon+text selector mode. Null = text-only mode. */
	private String[] scrollValueIconNames = null;
	/** Icon class name used to resolve scrollValueIconNames. Defaults to AllIcons for compatibility. */
	private String scrollValueIconClass = AllIcons.class.getSimpleName();
	/** Label shown in the value box. Persisted so it survives world reload and client sync. */
	private String scrollLabel = "Value";
	/** Numeric mode min/max — persisted so they survive world reload and client sync. */
	private int scrollMin = -256;
	private int scrollMax = 256;
	/** Custom transform for the scroll value box. Disabled by default to preserve legacy behavior. */
	private boolean scrollValueTransformCustom = false;
	private double scrollValueBoxX = 8;
	private double scrollValueBoxY = 15.5;
	private double scrollValueBoxZ = 8;
	private float scrollValueRotationX = 90f;
	private float scrollValueRotationY = 0f;
	private float scrollValueRotationZ = 0f;
	/** Cached icon resolution map (icon class + field name → AllIcons instance). */
	private static final java.util.Map<String, AllIcons> ICON_CACHE = new java.util.HashMap<>();
	/** Cached icon class resolution map (requested class name → resolved icon class). */
	private static final java.util.Map<String, Class<? extends AllIcons>> ICON_CLASS_CACHE = new java.util.HashMap<>();

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

	/**
	 * Sets a custom value box transform in voxel coordinates and degrees.
	 * Once set, this overrides the default auto-facing placement until changed again.
	 */
	public void setScrollValueTransform(double boxX, double boxY, double boxZ, float rotationX, float rotationY, float rotationZ) {
		scrollValueTransformCustom = true;
		scrollValueBoxX = boxX;
		scrollValueBoxY = boxY;
		scrollValueBoxZ = boxZ;
		scrollValueRotationX = rotationX;
		scrollValueRotationY = rotationY;
		scrollValueRotationZ = rotationZ;
		setChanged();
		if (level != null && !level.isClientSide) sendData();
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
		scrollLabel = label;
		scrollMin = min;
		scrollMax = max;
		scrollValueOptions = null;
		scrollValueIconNames = null;
		scrollValueIconClass = AllIcons.class.getSimpleName();
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
		this.scrollValueIconClass = AllIcons.class.getSimpleName();
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
	 * @param icons        Comma-separated list of icon field names, e.g. "I_ROTATE_PLACE,I_NONE,I_ROTATE_PLACE_RETURNED"
	 *                     Use "" or "I_NONE" for options without a specific icon.
	 *                     Supported icon names: I_ACTIVE, I_PASSIVE, I_PLAY, I_PAUSE, I_STOP,
	 *                     I_ROTATE_PLACE, I_ROTATE_PLACE_RETURNED, I_ROTATE_NEVER_PLACE,
	 *                     I_MOVE_PLACE, I_MOVE_PLACE_RETURNED, I_MOVE_NEVER_PLACE,
	 *                     I_CART_ROTATE, I_CART_ROTATE_PAUSED, I_CART_ROTATE_LOCKED,
	 *                     I_NONE, and all other AllIcons/custom icon class field names.
	 * @param defaultIndex Index of the option that is selected by default (0-based)
	 *
	 * Example (from a procedure):
	 *   enableScrollValueOptionsWithIcons("Direction", "Clockwise,Stopped,Counter-Clockwise",
	 *       "I_ROTATE_PLACE,I_NONE,I_ROTATE_PLACE_RETURNED", 1)
	 *   → interaction UI shows the "Stopped" icon + label; cycling changes to adjacent options
	 */
	public void enableScrollValueOptionsWithIcons(String label, String options, String icons, int defaultIndex) {
		enableScrollValueOptionsWithIcons(label, options, icons, AllIcons.class.getSimpleName(), defaultIndex);
	}

	/**
	 * Enables the scroll value box as a Create-style icon + text discrete selector.
	 * Behaves like the Mechanical Bearing mode selector: each option shows its icon
	 * in the interaction UI cursor together with the option name.
	 *
	 * @param iconClass    Icon class name, e.g. "AllIcons", "SimIcons", or a fully qualified class name
	 */
	public void enableScrollValueOptionsWithIcons(String label, String options, String icons, String iconClass, int defaultIndex) {
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
		this.scrollValueIconClass = normalizeIconClassName(iconClass);
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
	 * Returns the configured icon field name for the currently selected option when using icon+text mode.
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
	 * Icons are resolved from the configured icon class; unknown classes/fields fall back safely.
	 */
	private INamedIconOptions[] buildNamedIconOptions() {
		final String[] opts = scrollValueOptions;
		final String[] iconNames = scrollValueIconNames;
		final String iconClassName = scrollValueIconClass;
		INamedIconOptions[] result = new INamedIconOptions[opts.length];
		for (int i = 0; i < opts.length; i++) {
			final String optLabel = opts[i];
			final String iconName = (iconNames != null && i < iconNames.length) ? iconNames[i] : "I_NONE";
			final AllIcons icon = resolveIcon(iconClassName, iconName);
			result[i] = new INamedIconOptions() {
				@Override public AllIcons getIcon() { return icon; }
				/** Return the option label as the "translation key"; MC renders it literally when no translation exists. */
				@Override public String getTranslationKey() { return optLabel; }
			};
		}
		return result;
	}

	/**
	 * Resolves an AllIcons instance from the requested icon class and field name.
	 * Supports Create's AllIcons plus custom subclasses like SimIcons. Unknown classes/fields
	 * fall back to AllIcons and finally AllIcons.I_NONE.
	 */
	private static AllIcons resolveIcon(String iconClassName, String iconName) {
		if (iconName == null || iconName.isBlank()) return AllIcons.I_NONE;
		final String normalizedClassName = normalizeIconClassName(iconClassName);
		final String normalizedIconName = iconName.trim();
		return ICON_CACHE.computeIfAbsent(normalizedClassName + "#" + normalizedIconName, k -> {
			AllIcons resolved = resolveIconFromClass(resolveIconClass(normalizedClassName), normalizedIconName);
			if (resolved != AllIcons.I_NONE || isAllIconsClassName(normalizedClassName))
				return resolved;
			return resolveIconFromClass(AllIcons.class, normalizedIconName);
		});
	}

	private static AllIcons resolveIconFromClass(Class<? extends AllIcons> iconClass, String iconName) {
		try {
			Object icon = iconClass.getField(iconName).get(null);
			return icon instanceof AllIcons ? (AllIcons) icon : AllIcons.I_NONE;
		} catch (NoSuchFieldException | IllegalAccessException | SecurityException ignored) {
			return AllIcons.I_NONE;
		}
	}

	private static Class<? extends AllIcons> resolveIconClass(String iconClassName) {
		final String normalizedClassName = normalizeIconClassName(iconClassName);
		if (isAllIconsClassName(normalizedClassName))
			return AllIcons.class;
		return ICON_CLASS_CACHE.computeIfAbsent(normalizedClassName, CustomKineticBlockEntity::findIconClass);
	}

	private static Class<? extends AllIcons> findIconClass(String iconClassName) {
		for (String candidate : getIconClassCandidates(iconClassName)) {
			try {
				Class<?> clazz = Class.forName(candidate, false, CustomKineticBlockEntity.class.getClassLoader());
				if (AllIcons.class.isAssignableFrom(clazz))
					return clazz.asSubclass(AllIcons.class);
			} catch (ClassNotFoundException ignored) {
			} catch (LinkageError ignored) {
			}
		}
		return AllIcons.class;
	}

	private static java.util.List<String> getIconClassCandidates(String iconClassName) {
		java.util.LinkedHashSet<String> candidates = new java.util.LinkedHashSet<>();
		candidates.add(iconClassName);
		if (!iconClassName.contains(".")) {
			candidates.add(AllIcons.class.getPackageName() + "." + iconClassName);
			for (Package pkg : Package.getPackages()) {
				candidates.add(pkg.getName() + "." + iconClassName);
			}
		}
		return new java.util.ArrayList<>(candidates);
	}

	private static boolean isAllIconsClassName(String iconClassName) {
		return AllIcons.class.getSimpleName().equals(iconClassName) || AllIcons.class.getName().equals(iconClassName);
	}

	private static String normalizeIconClassName(String iconClassName) {
		return iconClassName == null || iconClassName.isBlank() ? AllIcons.class.getSimpleName() : iconClassName.trim();
	}

	// ============== Initialize
	/**
	 * Called by Create after the block entity is fully loaded into the world.
	 * Used here to push any scroll-value configuration (set during "block placed"
	 * procedures, when level was still null) to clients via sendData().
	 */
	@Override
	public void initialize() {
		super.initialize();
		if (level != null && !level.isClientSide && scrollValueEnabled)
			sendData();
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
		tag.putString("ScrollLabel", scrollLabel);
		tag.putInt("ScrollMin", scrollMin);
		tag.putInt("ScrollMax", scrollMax);
		tag.putBoolean("ScrollValueTransformCustom", scrollValueTransformCustom);
		tag.putDouble("ScrollValueBoxX", scrollValueBoxX);
		tag.putDouble("ScrollValueBoxY", scrollValueBoxY);
		tag.putDouble("ScrollValueBoxZ", scrollValueBoxZ);
		tag.putFloat("ScrollValueRotationX", scrollValueRotationX);
		tag.putFloat("ScrollValueRotationY", scrollValueRotationY);
		tag.putFloat("ScrollValueRotationZ", scrollValueRotationZ);
		if (scrollValueOptions != null)
			tag.putString("ScrollValueOptions", String.join(",", scrollValueOptions));
		if (scrollValueIconNames != null)
			tag.putString("ScrollValueIconNames", String.join(",", scrollValueIconNames));
		tag.putString("ScrollValueIconClass", normalizeIconClassName(scrollValueIconClass));
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
		if (tag.contains("ScrollLabel"))
			scrollLabel = tag.getString("ScrollLabel");
		if (tag.contains("ScrollMin"))
			scrollMin = tag.getInt("ScrollMin");
		if (tag.contains("ScrollMax"))
			scrollMax = tag.getInt("ScrollMax");
		if (tag.contains("ScrollValueTransformCustom"))
			scrollValueTransformCustom = tag.getBoolean("ScrollValueTransformCustom");
		if (tag.contains("ScrollValueBoxX"))
			scrollValueBoxX = tag.getDouble("ScrollValueBoxX");
		if (tag.contains("ScrollValueBoxY"))
			scrollValueBoxY = tag.getDouble("ScrollValueBoxY");
		if (tag.contains("ScrollValueBoxZ"))
			scrollValueBoxZ = tag.getDouble("ScrollValueBoxZ");
		if (tag.contains("ScrollValueRotationX"))
			scrollValueRotationX = tag.getFloat("ScrollValueRotationX");
		if (tag.contains("ScrollValueRotationY"))
			scrollValueRotationY = tag.getFloat("ScrollValueRotationY");
		if (tag.contains("ScrollValueRotationZ"))
			scrollValueRotationZ = tag.getFloat("ScrollValueRotationZ");
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
		if (tag.contains("ScrollValueIconClass"))
			scrollValueIconClass = normalizeIconClassName(tag.getString("ScrollValueIconClass"));
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
			if (scrollValueTransformCustom) {
				return VecHelper.voxelSpace((float) scrollValueBoxX, (float) scrollValueBoxY, (float) scrollValueBoxZ);
			}
			if (state.hasProperty(BlockStateProperties.HORIZONTAL_FACING)) {
				// Front face center, automatically rotated with block facing
				return rotateHorizontally(state, VecHelper.voxelSpace(8, 8, 15.5f));
			}
			// Default: top face center
			return VecHelper.voxelSpace(8, 15.5f, 8);
		}

		@Override
		public void rotate(LevelAccessor level, BlockPos pos, BlockState state, PoseStack ms) {
			if (scrollValueTransformCustom) {
				TransformStack.of(ms)
					.rotateXDegrees(scrollValueRotationX)
					.rotateYDegrees(scrollValueRotationY)
					.rotateZDegrees(scrollValueRotationZ);
				return;
			}
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
