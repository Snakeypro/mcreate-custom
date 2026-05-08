if (world.getBlockEntity(BlockPos.containing(${input$x}, ${input$y}, ${input$z})) instanceof KineticBlockEntity kbe)
	kbe.detachKinetics();