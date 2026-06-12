<#include "mcitems.ftl">
if (${mappedBlockToBlock(input$block)} instanceof ${package}.mcreate.custom.CustomDirectionalKineticBlock ckb)
	ckb.addRotatingVisual(${input$partial}, ${input$direction}, (float) ${input$speedMultiplier});
