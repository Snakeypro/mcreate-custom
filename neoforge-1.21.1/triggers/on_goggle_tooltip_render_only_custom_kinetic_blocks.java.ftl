<#include "procedures.java.ftl">
@EventBusSubscriber(value = {Dist.CLIENT})
public class ${name}Procedure {
    @OnlyIn(Dist.CLIENT)
    @SubscribeEvent
    public static void onEventTriggered(GoggleTooltipEvent event) {
        <#assign dependenciesCode><#compress>
            <@procedureDependenciesCode dependencies, {
            "x": "event.getPos().getX()",
            "y": "event.getPos().getY()",
            "z": "event.getPos().getZ()",
            "world": "event.getLevel()",
            "blockstate": "event.getBlockState()",
            "isPlayerSneaking": "event.isPlayerSneaking()",
            "event": "event"
            }/>
        </#compress></#assign>
        execute(event<#if dependenciesCode?has_content>,</#if>${dependenciesCode});
    }