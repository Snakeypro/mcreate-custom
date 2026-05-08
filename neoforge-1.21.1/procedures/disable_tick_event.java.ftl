{ var _mckbe = world.getBlockEntity(new BlockPos((int) ${input$x}, (int) ${input$y}, (int) ${input$z}));
if (_mckbe instanceof CustomKineticBlockEntity ckbe) ckbe.setTickEvent(${input$value});
else if (_mckbe instanceof CustomGeneratorKineticBlockEntity ckbge) ckbge.setTickEvent(${input$value}); }
