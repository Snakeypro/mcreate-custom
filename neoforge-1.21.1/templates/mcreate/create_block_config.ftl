<#--
 Shared Create block detection/config helpers.
 This allows Create behavior to be driven by explicit custom properties
 while keeping legacy CKB/CKBG naming compatibility.
-->

<#function _findCustomProperty propertyName>
	<#list data.customProperties as prop>
		<#if prop.property().getName() == propertyName>
			<#return prop>
		</#if>
	</#list>
	<#return "">
</#function>

<#function createPropValue propertyName defaultValue="">
	<#assign prop = _findCustomProperty(propertyName)>
	<#if prop?has_content>
		<#return prop.value()>
	</#if>
	<#return defaultValue>
</#function>

<#function createPropBoolean propertyName defaultValue=false>
	<#assign prop = _findCustomProperty(propertyName)>
	<#if prop?has_content>
		<#return prop.value()?string?lower_case == "true">
	</#if>
	<#return defaultValue>
</#function>

<#assign createElementVariable = (mcreate_element!"false")?string?lower_case == "true">
<#assign createRole = createPropValue("CUSTOM:MCREATE_ROLE", (mcreate_role!"CONSUMER"))?upper_case>
<#assign createElementFlag = createPropBoolean("CUSTOM:MCREATE_MOD_BLOCK", false)>
<#assign legacyCreateBlock = name?starts_with("CKB")>
<#assign legacyCreateGenerator = name?starts_with("CKBG")>

<#assign isCreateModBlock = createElementVariable || createElementFlag || legacyCreateBlock>
<#assign isCreateGeneratorBlock = isCreateModBlock && (createRole == "GENERATOR" || legacyCreateGenerator)>
