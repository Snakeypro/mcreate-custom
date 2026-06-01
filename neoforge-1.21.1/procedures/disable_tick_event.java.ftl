{ var _mckbe = world.getBlockEntity(new BlockPos((int) ${input$x}, (int) ${input$y}, (int) ${input$z}));
if (_mckbe instanceof ${package}.mcreate.custom.CustomKineticBlockEntity ckbe) ckbe.setTickEvent(${input$value});
else if (_mckbe instanceof ${package}.mcreate.custom.CustomGeneratorKineticBlockEntity ckbge) ckbge.setTickEvent(${input$value}); }
