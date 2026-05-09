if (world.getBlockEntity(new BlockPos((int) ${input$x}, (int) ${input$y}, (int) ${input$z})) instanceof com.simibubi.create.content.redstone.link.RedstoneLinkBlockEntity _rlbe)
	_rlbe.transmit(Math.max(0, Math.min(15, (int) ${input$strength})));
