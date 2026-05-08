{ var _msvo = world.getBlockEntity(new BlockPos((int) ${input$x}, (int) ${input$y}, (int) ${input$z}));
if (_msvo instanceof CustomKineticBlockEntity _ckbe) _ckbe.enableScrollValueOptions((String)(${input$label}), (String)(${input$options}), (int)(${input$defaultIndex}));
else if (_msvo instanceof CustomGeneratorKineticBlockEntity _ckbge) _ckbge.enableScrollValueOptions((String)(${input$label}), (String)(${input$options}), (int)(${input$defaultIndex})); }
