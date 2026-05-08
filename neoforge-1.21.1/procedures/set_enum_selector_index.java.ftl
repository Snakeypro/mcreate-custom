{ var _msesi = world.getBlockEntity(new BlockPos((int) ${input$x}, (int) ${input$y}, (int) ${input$z}));
if (_msesi instanceof CustomKineticBlockEntity _ckbe) _ckbe.setScrollValue((int)(${input$index}));
else if (_msesi instanceof CustomGeneratorKineticBlockEntity _ckbge) _ckbge.setScrollValue((int)(${input$index})); }
