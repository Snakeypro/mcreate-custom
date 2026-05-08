<#include "mcitems.ftl">
if (${mappedBlockToBlock(input$block)} instanceof CustomDirectionalKineticBlock ckb)
	ckb.setShaft(${input$direction}, ${input$value});