{ var _msvo = world.getBlockEntity(new BlockPos((int) ${input$x}, (int) ${input$y}, (int) ${input$z}));
if (_msvo instanceof CustomKineticBlockEntity _ckbe) _ckbe.setScrollValueOptions((String)(${input$options}));
else if (_msvo instanceof CustomGeneratorKineticBlockEntity _ckbge) _ckbge.setScrollValueOptions((String)(${input$options})); }
