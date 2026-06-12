<#include "mcitems.ftl">
if (${mappedBlockToBlock(input$block)} instanceof ${package}.mcreate.custom.CustomDirectionalKineticBlock ckb)
	ckb.configureShaft(${input$direction}, ${input$mode}, ${input$independent}, (float) ${input$speedMultiplier}, ${input$visible});
