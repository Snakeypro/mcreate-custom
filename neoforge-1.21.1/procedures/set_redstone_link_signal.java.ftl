<#include "mcitems.ftl">
{
	net.createmod.catnip.data.Couple<com.simibubi.create.content.redstone.link.RedstoneLinkNetworkHandler.Frequency> _rlKey =
		net.createmod.catnip.data.Couple.create(
			com.simibubi.create.content.redstone.link.RedstoneLinkNetworkHandler.Frequency.of(new net.minecraft.world.item.ItemStack(${mappedBlockToBlock(input$freq1)}.asItem())),
			com.simibubi.create.content.redstone.link.RedstoneLinkNetworkHandler.Frequency.of(new net.minecraft.world.item.ItemStack(${mappedBlockToBlock(input$freq2)}.asItem()))
		);
	java.util.Set<com.simibubi.create.content.redstone.link.IRedstoneLinkable> _rlNet =
		com.simibubi.create.Create.REDSTONE_LINK_NETWORK_HANDLER.networksIn(world).get(_rlKey);
	if (_rlNet != null) {
		int _rlStrength = Math.max(0, Math.min(15, (int) ${input$strength}));
		for (com.simibubi.create.content.redstone.link.IRedstoneLinkable _rl : new java.util.ArrayList<>(_rlNet)) {
			if (_rl.isAlive() && !_rl.isListening()
				&& _rl instanceof com.simibubi.create.content.redstone.link.LinkBehaviour _rlLb
				&& _rlLb.blockEntity instanceof com.simibubi.create.content.redstone.link.RedstoneLinkBlockEntity _rlbe) {
				_rlbe.transmit(_rlStrength);
			}
		}
	}
}
