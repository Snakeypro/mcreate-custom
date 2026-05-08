if (world.getBlockEntity(new BlockPos((int) ${input$x}, (int) ${input$y}, (int) ${input$z})) instanceof CustomKineticBlockEntity ckbe)
	ckbe.setLazyTickEvent(${input$value});