if (world.getBlockEntity(new BlockPos((int) ${input$x}, (int) ${input$y}, (int) ${input$z})) instanceof CustomGeneratorKineticBlockEntity cgkbe)
	cgkbe.setGeneratedSpeed((float) (${input$speed}));
