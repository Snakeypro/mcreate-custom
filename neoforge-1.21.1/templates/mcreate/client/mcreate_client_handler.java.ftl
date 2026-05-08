<#-- @formatter:off -->
package com.xenrao.mcreate.client;

import net.neoforged.fml.event.lifecycle.FMLClientSetupEvent;
import net.neoforged.fml.common.EventBusSubscriber;
import net.neoforged.bus.api.SubscribeEvent;
import net.neoforged.bus.api.IEventBus;
import net.neoforged.bus.api.EventPriority;
import net.neoforged.api.distmarker.Dist;

import net.minecraft.world.level.block.entity.BlockEntityType;
import net.minecraft.world.level.block.entity.BlockEntity;
import net.minecraft.world.level.block.EntityBlock;
import net.minecraft.world.level.block.Block;
import net.minecraft.core.BlockPos;
import net.minecraft.client.renderer.blockentity.BlockEntityRenderers;

import java.util.List;
import java.util.ArrayList;

import com.xenrao.mcreate.custom.CustomKineticBlockEntity;

@EventBusSubscriber(modid = "${modid}", value = Dist.CLIENT)
public class McreateClientHandler {
	private static final List<BlockEntityType<? extends CustomKineticBlockEntity>> TO_REGISTER = new ArrayList<>();

	/*
		public static void addRenderer(BlockEntityType<? extends CustomKineticBlockEntity> type) {
			TO_REGISTER.add(type);
		}
	*/
	public static void addRenderer(Block block) {
		if (block instanceof EntityBlock entityBlock) {
			// Dummy BlockPos ve BlockState ile entity oluştur
			BlockEntity be = entityBlock.newBlockEntity(BlockPos.ZERO, block.defaultBlockState());
			if (be instanceof CustomKineticBlockEntity) {
				@SuppressWarnings("unchecked")
				BlockEntityType<? extends CustomKineticBlockEntity> type = (BlockEntityType<? extends CustomKineticBlockEntity>) be.getType();
				TO_REGISTER.add(type);
			}
		}
	}

	public static void register(IEventBus modEventBus) {
		modEventBus.addListener(McreateClientHandler::onClientSetup);
	}

	@SubscribeEvent(priority = EventPriority.LOWEST)
	public static void onClientSetup(FMLClientSetupEvent event) {
		event.enqueueWork(() -> TO_REGISTER.forEach(McreateClientHandler::registerRenderer));
	}

	private static <T extends CustomKineticBlockEntity> void registerRenderer(BlockEntityType<T> type) {
		BlockEntityRenderers.register(type, McreateClientRenderer::new);
	}
}
<#-- @formatter:on -->