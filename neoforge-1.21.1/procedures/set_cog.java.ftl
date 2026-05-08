<#include "mcitems.ftl">
if (${mappedBlockToBlock(input$block)} instanceof CustomDirectionalKineticBlock ckb)
	ckb.setSmallCog(${input$value});