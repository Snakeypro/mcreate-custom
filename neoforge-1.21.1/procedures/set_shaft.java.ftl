<#include "mcitems.ftl">
if (${mappedBlockToBlock(input$block)} instanceof ${package}.mcreate.custom.CustomDirectionalKineticBlock ckb)
	ckb.setShaft(${input$direction}, ${input$value});