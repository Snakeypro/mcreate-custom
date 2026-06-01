{ var _mcsv = world.getBlockEntity(new BlockPos((int) ${input$x}, (int) ${input$y}, (int) ${input$z}));
if (_mcsv instanceof ${package}.mcreate.custom.CustomKineticBlockEntity _ckbe) _ckbe.enableScrollValue((String)(${input$label}), (int)(${input$min}), (int)(${input$max}), (int)(${input$defaultValue}));
else if (_mcsv instanceof ${package}.mcreate.custom.CustomGeneratorKineticBlockEntity _ckbge) _ckbge.enableScrollValue((String)(${input$label}), (int)(${input$min}), (int)(${input$max}), (int)(${input$defaultValue})); }
