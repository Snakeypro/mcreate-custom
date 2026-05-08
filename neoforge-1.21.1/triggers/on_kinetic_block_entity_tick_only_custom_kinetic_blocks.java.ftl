<#include "procedures.java.ftl">
@EventBusSubscriber
public class ${name}Procedure {
    @SubscribeEvent
    public static void onEventTriggered(KineticTickEvent event) {
        <#assign dependenciesCode><#compress>
            <@procedureDependenciesCode dependencies, {
            "x": "event.getPos().getX()",
            "y": "event.getPos().getY()",
            "z": "event.getPos().getZ()",
            "world": "event.getLevel()",
            "blockstate": "event.getBlockState()",
            "isLazy": "event.isLazy()",
            "event": "event"
            }/>
        </#compress></#assign>
        execute(event<#if dependenciesCode?has_content>,</#if>${dependenciesCode});
    }