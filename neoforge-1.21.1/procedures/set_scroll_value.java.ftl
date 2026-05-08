{ var _mcsv = world.getBlockEntity(new BlockPos((int) ${input$x}, (int) ${input$y}, (int) ${input$z}));
if (_mcsv instanceof CustomKineticBlockEntity _ckbe) _ckbe.setScrollValue((int)(${input$value}));
else if (_mcsv instanceof CustomGeneratorKineticBlockEntity _ckbge) _ckbge.setScrollValue((int)(${input$value})); }
