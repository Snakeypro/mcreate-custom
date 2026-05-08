<#include "procedures.java.ftl">
@EventBusSubscriber
public class ${name}Procedure {
    @SubscribeEvent
    public static void onEventTriggered(KineticScrollValueEvent event) {
        <#assign dependenciesCode><#compress>
            <@procedureDependenciesCode dependencies, {
            "x": "event.getPos().getX()",
            "y": "event.getPos().getY()",
            "z": "event.getPos().getZ()",
            "world": "event.getLevel()",
            "blockstate": "event.getState()",
            "newValue": "event.getNewValue()",
            "oldValue": "event.getOldValue()",
            "event": "event"
            }/>
        </#compress></#assign>
        execute(event<#if dependenciesCode?has_content>,</#if>${dependenciesCode});
    }
