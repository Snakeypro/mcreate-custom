{ var _msvoi = world.getBlockEntity(new BlockPos((int) ${input$x}, (int) ${input$y}, (int) ${input$z}));
if (_msvoi instanceof CustomKineticBlockEntity _ckbe) _ckbe.enableScrollValueOptionsWithIcons((String)(${input$label}), (String)(${input$options}), (String)(${input$icons}), (int)(${input$defaultIndex}));
else if (_msvoi instanceof CustomGeneratorKineticBlockEntity _ckbge) _ckbge.enableScrollValueOptionsWithIcons((String)(${input$label}), (String)(${input$options}), (String)(${input$icons}), (int)(${input$defaultIndex})); }
