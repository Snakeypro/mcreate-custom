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
import com.xenrao.mcreate.custom.CustomGeneratorKineticBlockEntity;

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

	private static <T extends CustomKineticBlockEntity> void registerConsumerRenderer(BlockEntityType<T> type) {
		BlockEntityRenderers.register(type, McreateClientRenderer::new);
	}

	private static <T extends CustomGeneratorKineticBlockEntity> void registerGeneratorRenderer(BlockEntityType<T> type) {
		BlockEntityRenderers.register(type, McreateGeneratorClientRenderer::new);
	}
}
<#-- @formatter:on -->
