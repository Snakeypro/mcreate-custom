{ var _msesi = world.getBlockEntity(new BlockPos((int) ${input$x}, (int) ${input$y}, (int) ${input$z}));
if (_msesi instanceof ${package}.mcreate.custom.CustomKineticBlockEntity _ckbe) _ckbe.setScrollValue((int)(${input$index}));
else if (_msesi instanceof ${package}.mcreate.custom.CustomGeneratorKineticBlockEntity _ckbge) _ckbge.setScrollValue((int)(${input$index})); }
