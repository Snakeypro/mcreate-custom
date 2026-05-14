<#-- @formatter:off -->
package com.xenrao.mcreate.client;

import net.neoforged.fml.event.lifecycle.FMLClientSetupEvent;
import net.neoforged.fml.common.EventBusSubscriber;
import net.neoforged.bus.api.SubscribeEvent;
import net.neoforged.bus.api.IEventBus;
import net.neoforged.bus.api.EventPriority;
import net.neoforged.api.distmarker.Dist;
import net.neoforged.neoforge.client.event.ClientTickEvent;

import net.minecraft.world.level.block.entity.BlockEntityType;
import net.minecraft.world.level.block.entity.BlockEntity;
import net.minecraft.world.level.block.EntityBlock;
import net.minecraft.world.level.block.Block;
import net.minecraft.core.BlockPos;
import net.minecraft.core.Direction;
import net.minecraft.client.Minecraft;
import net.minecraft.client.multiplayer.ClientLevel;
import net.minecraft.client.renderer.blockentity.BlockEntityRenderers;
import net.minecraft.world.InteractionHand;
import net.minecraft.world.item.ItemStack;
import net.minecraft.world.phys.AABB;
import net.minecraft.world.phys.BlockHitResult;
import net.minecraft.world.phys.HitResult;
import net.minecraft.world.phys.Vec3;
import net.minecraft.network.chat.Component;

import java.util.List;
import java.util.ArrayList;

import com.xenrao.mcreate.custom.CustomKineticBlockEntity;
import com.xenrao.mcreate.custom.CustomGeneratorKineticBlockEntity;
import com.simibubi.create.AllItems;
import com.simibubi.create.foundation.blockEntity.SmartBlockEntity;
import com.simibubi.create.foundation.blockEntity.behaviour.BlockEntityBehaviour;
import com.simibubi.create.foundation.blockEntity.behaviour.ValueBox;
import com.simibubi.create.foundation.blockEntity.behaviour.ValueBox.IconValueBox;
import com.simibubi.create.foundation.blockEntity.behaviour.scrollValue.ScrollValueBehaviour;
import com.simibubi.create.foundation.gui.AllIcons;

import net.createmod.catnip.outliner.Outliner;

@EventBusSubscriber(modid = "${modid}", value = Dist.CLIENT)
public class McreateClientHandler {
	private static final List<BlockEntityType<? extends CustomKineticBlockEntity>> TO_REGISTER = new ArrayList<>();
	private static final List<BlockEntityType<? extends CustomGeneratorKineticBlockEntity>> TO_REGISTER_GENERATOR = new ArrayList<>();

	public static void addRenderer(Block block) {
		if (block instanceof EntityBlock entityBlock) {
			BlockEntity be = entityBlock.newBlockEntity(BlockPos.ZERO, block.defaultBlockState());
			if (be instanceof CustomGeneratorKineticBlockEntity) {
				@SuppressWarnings("unchecked")
				BlockEntityType<? extends CustomGeneratorKineticBlockEntity> type =
					(BlockEntityType<? extends CustomGeneratorKineticBlockEntity>) be.getType();
				TO_REGISTER_GENERATOR.add(type);
			} else if (be instanceof CustomKineticBlockEntity) {
				@SuppressWarnings("unchecked")
				BlockEntityType<? extends CustomKineticBlockEntity> type =
					(BlockEntityType<? extends CustomKineticBlockEntity>) be.getType();
				TO_REGISTER.add(type);
			}
		}
	}

	public static void register(IEventBus modEventBus) {
		modEventBus.addListener(McreateClientHandler::onClientSetup);
	}

	@SubscribeEvent(priority = EventPriority.LOWEST)
	public static void onClientSetup(FMLClientSetupEvent event) {
		event.enqueueWork(() -> {
			TO_REGISTER.forEach(McreateClientHandler::registerConsumerRenderer);
			TO_REGISTER_GENERATOR.forEach(McreateClientHandler::registerGeneratorRenderer);
		});
	}

	@SubscribeEvent(priority = EventPriority.LOWEST)
	public static void onClientTickPost(ClientTickEvent.Post event) {
		overrideIconModeScrollValueBoxes();
	}

	private static <T extends CustomKineticBlockEntity> void registerConsumerRenderer(BlockEntityType<T> type) {
		BlockEntityRenderers.register(type, McreateClientRenderer::new);
	}

	private static <T extends CustomGeneratorKineticBlockEntity> void registerGeneratorRenderer(BlockEntityType<T> type) {
		BlockEntityRenderers.register(type, McreateGeneratorClientRenderer::new);
	}

	/**
	 * Override Create's default text box for our icon-mode selectors with an icon box,
	 * matching ScrollOptionBehaviour rendering while preserving board/editor text labels.
	 */
	private static void overrideIconModeScrollValueBoxes() {
		Minecraft mc = Minecraft.getInstance();
		HitResult target = mc.hitResult;
		if (!(target instanceof BlockHitResult result) || mc.level == null || mc.player == null)
			return;

		ClientLevel world = mc.level;
		BlockPos pos = result.getBlockPos();
		Direction face = result.getDirection();
		if (!(world.getBlockEntity(pos) instanceof SmartBlockEntity sbe))
			return;

		boolean highlightFound = false;
		for (BlockEntityBehaviour blockEntityBehaviour : sbe.getAllBehaviours()) {
			if (!(blockEntityBehaviour instanceof ScrollValueBehaviour behaviour))
				continue;
			if (!behaviour.isActive())
				continue;

			ItemStack mainhandItem = mc.player.getItemInHand(InteractionHand.MAIN_HAND);
			boolean clipboard = behaviour.bypassesInput(mainhandItem);
			if (behaviour.onlyVisibleWithWrench() && !AllItems.WRENCH.isIn(mainhandItem) && !clipboard)
				continue;

			AllIcons selectedIcon = getSelectedIconFor(sbe);
			if (selectedIcon == null)
				continue;

			boolean highlight = behaviour.testHit(target.getLocation()) && !clipboard && !highlightFound;
			addIconBox(pos, face, behaviour, selectedIcon, highlight);
			if (highlight)
				highlightFound = true;
		}
	}

	private static AllIcons getSelectedIconFor(BlockEntity blockEntity) {
		if (blockEntity instanceof CustomKineticBlockEntity customKinetic) {
			if (customKinetic.isScrollValueIconModeEnabled())
				return customKinetic.getSelectedScrollValueIcon();
			return null;
		}
		if (blockEntity instanceof CustomGeneratorKineticBlockEntity customGenerator) {
			if (customGenerator.isScrollValueIconModeEnabled())
				return customGenerator.getSelectedScrollValueIcon();
			return null;
		}
		return null;
	}

	private static void addIconBox(BlockPos pos, Direction face, ScrollValueBehaviour behaviour, AllIcons icon, boolean highlight) {
		AABB bb = new AABB(Vec3.ZERO, Vec3.ZERO).inflate(.5f)
			.contract(0, 0, -.5f)
			.move(0, 0, -.125f);
		Component label = behaviour.label;
		ValueBox box = new IconValueBox(label, icon, bb, pos);
		box.passive(!highlight)
			.wideOutline();
		Outliner.getInstance().showOutline(behaviour, box.transform(behaviour.getSlotPositioning()))
			.highlightFace(face);
	}
}
<#-- @formatter:on -->
