<#include "mcitems.ftl">
(com.simibubi.create.Create.REDSTONE_LINK_NETWORK_HANDLER.networksIn(world).getOrDefault(
	net.createmod.catnip.data.Couple.create(
		com.simibubi.create.content.redstone.link.RedstoneLinkNetworkHandler.Frequency.of(new net.minecraft.world.item.ItemStack(${mappedBlockToBlock(input$freq1)}.asItem())),
		com.simibubi.create.content.redstone.link.RedstoneLinkNetworkHandler.Frequency.of(new net.minecraft.world.item.ItemStack(${mappedBlockToBlock(input$freq2)}.asItem()))
	),
	java.util.Collections.emptySet()
).stream().filter(l -> l.isAlive() && !l.isListening())
	.mapToInt(com.simibubi.create.content.redstone.link.IRedstoneLinkable::getTransmittedStrength)
	.max().orElse(0))
