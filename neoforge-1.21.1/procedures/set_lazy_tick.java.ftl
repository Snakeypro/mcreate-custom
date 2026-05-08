if (world.getBlockEntity(new BlockPos((int) ${input$x}, (int) ${input$y}, (int) ${input$z})) instanceof SmartBlockEntity ckbe)
	ckbe.setLazyTickRate(${input$lazyTick});