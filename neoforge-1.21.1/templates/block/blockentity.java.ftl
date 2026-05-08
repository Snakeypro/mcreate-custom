<#--
 # MCreator (https://mcreator.net/)
 # Copyright (C) 2012-2020, Pylo
 # Copyright (C) 2020-2023, Pylo, opensource contributors
 #
 # This program is free software: you can redistribute it and/or modify
 # it under the terms of the GNU General Public License as published by
 # the Free Software Foundation, either version 3 of the License, or
 # (at your option) any later version.
 #
 # This program is distributed in the hope that it will be useful,
 # but WITHOUT ANY WARRANTY; without even the implied warranty of
 # MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 # GNU General Public License for more details.
 #
 # You should have received a copy of the GNU General Public License
 # along with this program.  If not, see <https://www.gnu.org/licenses/>.
 #
 # Additional permission for code generator templates (*.ftl files)
 #
 # As a special exception, you may create a larger work that contains part or
 # all of the MCreator code generator templates (*.ftl files) and distribute
 # that work under terms of your choice, so long as that work isn't itself a
 # template for code generation. Alternatively, if you modify or redistribute
 # the template itself, you may (at your option) remove this special exception,
 # which will cause the template and the resulting code generator output files
 # to be licensed under the GNU General Public License without this special
 # exception.
-->

<#-- @formatter:off -->
<#include "../procedures.java.ftl">

<#assign isGeneratorBlock = name?starts_with("CKBG")>
<#assign isKineticBlock = name?starts_with("CKB") && !isGeneratorBlock>
<#assign kineticBaseClass = isGeneratorBlock?then("CustomGeneratorKineticBlockEntity", "CustomKineticBlockEntity")>

package ${package}.block.entity;

<@javacompress>

<#-- ================================================================ -->
<#--   KINETIC BLOCK ENTITY                                           -->
<#-- ================================================================ -->
<#if isKineticBlock || isGeneratorBlock>
public class ${name}BlockEntity extends ${kineticBaseClass} implements WorldlyContainer
    <#if data.sensitiveToVibration>, GameEventListener.Provider<VibrationSystem.Listener>, VibrationSystem</#if> {

    <#-- ── Kinetic'e özel ── -->
    <#if data.renderType() == 4>
        <#list data.animations as animation>
    public final AnimationState animationState${animation?index} = new AnimationState();
        </#list>
    </#if>

    <#-- ── Ortak: inventory ── -->
    private NonNullList<ItemStack> stacks = NonNullList.withSize(${data.inventorySize}, ItemStack.EMPTY);

    <#-- ── Ortak: vibration ── -->
    <#if data.sensitiveToVibration>
    private final VibrationSystem.Listener vibrationListener = new VibrationSystem.Listener(this);
    private final VibrationSystem.User vibrationUser = new VibrationUser(this.getBlockPos());
    private VibrationSystem.Data vibrationData = new VibrationSystem.Data();
    </#if>

    public ${name}BlockEntity(BlockEntityType<?> type, BlockPos pos, BlockState state) {
        super(type != null ? type : ${JavaModName}BlockEntities.${REGISTRYNAME}.get(), pos, state);
    }

    <#-- ── Kinetic: write/read (Create sistemi, saveAdditional final!) ── -->
    @Override
    public void write(CompoundTag tag, HolderLookup.Provider registries, boolean clientPacket) {
        super.write(tag, registries, clientPacket);
        ContainerHelper.saveAllItems(tag, this.stacks, registries);
        <#if data.hasEnergyStorage>
        tag.put("energyStorage", energyStorage.serializeNBT(registries));
        </#if>
        <#if data.isFluidTank>
        tag.put("fluidTank", fluidTank.writeToNBT(registries, new CompoundTag()));
        </#if>
        <#if data.sensitiveToVibration>
        VibrationSystem.Data.CODEC.encodeStart(registries.createSerializationContext(NbtOps.INSTANCE), this.vibrationData)
            .resultOrPartial(e -> ${JavaModName}.LOGGER.error("Failed to encode vibration listener for ${data.name}: '{}'", e))
            .ifPresent(listener -> tag.put("listener", listener));
        </#if>
    }

    @Override
    protected void read(CompoundTag tag, HolderLookup.Provider registries, boolean clientPacket) {
        super.read(tag, registries, clientPacket);
        this.stacks = NonNullList.withSize(this.getContainerSize(), ItemStack.EMPTY);
        ContainerHelper.loadAllItems(tag, this.stacks, registries);
        <#if data.hasEnergyStorage>
        if (tag.get("energyStorage") instanceof IntTag intTag)
            energyStorage.deserializeNBT(registries, intTag);
        </#if>
        <#if data.isFluidTank>
        if (tag.get("fluidTank") instanceof CompoundTag compoundTag)
            fluidTank.readFromNBT(registries, compoundTag);
        </#if>
        <#if data.sensitiveToVibration>
        if (tag.contains("listener", 10)) {
            VibrationSystem.Data.CODEC.parse(registries.createSerializationContext(NbtOps.INSTANCE), tag.getCompound("listener"))
                .resultOrPartial(e -> ${JavaModName}.LOGGER.error("Failed to parse vibration listener for ${data.name}: '{}'", e))
                .ifPresent(data -> this.vibrationData = data);
        }
        </#if>
    }

<#-- ================================================================ -->
<#--   NORMAL BLOCK ENTITY                                            -->
<#-- ================================================================ -->
<#else>
public class ${name}BlockEntity extends RandomizableContainerBlockEntity implements WorldlyContainer
    <#if data.sensitiveToVibration>, GameEventListener.Provider<VibrationSystem.Listener>, VibrationSystem</#if> {

    <#-- ── Normal'e özel ── -->
    <#if data.renderType() == 4>
        <#list data.animations as animation>
    public final AnimationState animationState${animation?index} = new AnimationState();
        </#list>
    </#if>

    <#-- ── Ortak: inventory ── -->
    private NonNullList<ItemStack> stacks = NonNullList.withSize(${data.inventorySize}, ItemStack.EMPTY);

    <#-- ── Ortak: vibration ── -->
    <#if data.sensitiveToVibration>
    private final VibrationSystem.Listener vibrationListener = new VibrationSystem.Listener(this);
    private final VibrationSystem.User vibrationUser = new VibrationUser(this.getBlockPos());
    private VibrationSystem.Data vibrationData = new VibrationSystem.Data();
    </#if>

    public ${name}BlockEntity(BlockPos position, BlockState state) {
        super(${JavaModName}BlockEntities.${REGISTRYNAME}.get(), position, state);
    }

    <#-- ── Normal: loadAdditional/saveAdditional ── -->
    @Override
    public void loadAdditional(CompoundTag compound, HolderLookup.Provider lookupProvider) {
        super.loadAdditional(compound, lookupProvider);
        if (!this.tryLoadLootTable(compound))
            this.stacks = NonNullList.withSize(this.getContainerSize(), ItemStack.EMPTY);
        ContainerHelper.loadAllItems(compound, this.stacks, lookupProvider);
        <#if data.hasEnergyStorage>
        if (compound.get("energyStorage") instanceof IntTag intTag)
            energyStorage.deserializeNBT(lookupProvider, intTag);
        </#if>
        <#if data.isFluidTank>
        if (compound.get("fluidTank") instanceof CompoundTag compoundTag)
            fluidTank.readFromNBT(lookupProvider, compoundTag);
        </#if>
        <#if data.sensitiveToVibration>
        if (compound.contains("listener", 10)) {
            VibrationSystem.Data.CODEC.parse(lookupProvider.createSerializationContext(NbtOps.INSTANCE), compound.getCompound("listener"))
                .resultOrPartial(e -> ${JavaModName}.LOGGER.error("Failed to parse vibration listener for ${data.name}: '{}'", e))
                .ifPresent(data -> this.vibrationData = data);
        }
        </#if>
    }

    @Override
    public void saveAdditional(CompoundTag compound, HolderLookup.Provider lookupProvider) {
        super.saveAdditional(compound, lookupProvider);
        if (!this.trySaveLootTable(compound))
            ContainerHelper.saveAllItems(compound, this.stacks, lookupProvider);
        <#if data.hasEnergyStorage>
        compound.put("energyStorage", energyStorage.serializeNBT(lookupProvider));
        </#if>
        <#if data.isFluidTank>
        compound.put("fluidTank", fluidTank.writeToNBT(lookupProvider, new CompoundTag()));
        </#if>
        <#if data.sensitiveToVibration>
        VibrationSystem.Data.CODEC.encodeStart(lookupProvider.createSerializationContext(NbtOps.INSTANCE), this.vibrationData)
            .resultOrPartial(e -> ${JavaModName}.LOGGER.error("Failed to encode vibration listener for ${data.name}: '{}'", e))
            .ifPresent(listener -> compound.put("listener", listener));
        </#if>
    }

    <#-- ── Normal'e özel: RandomizableContainer metodları ── -->
    @Override
    public Component getDefaultName() {
        return Component.literal("${registryname}");
    }

    <#if data.inventoryStackSize != 99>
    @Override
    public int getMaxStackSize() {
        return ${data.inventoryStackSize};
    }
    </#if>

    @Override
    public AbstractContainerMenu createMenu(int id, Inventory inventory) {
        <#if !data.guiBoundTo?has_content>
        return ChestMenu.threeRows(id, inventory);
        <#else>
        return new ${data.guiBoundTo}Menu(id, inventory, new FriendlyByteBuf(Unpooled.buffer()).writeBlockPos(this.worldPosition));
        </#if>
    }

    @Override
    public Component getDisplayName() {
        return Component.literal("${data.name}");
    }

    @Override
    protected NonNullList<ItemStack> getItems() {
        return this.stacks;
    }

    @Override
    protected void setItems(NonNullList<ItemStack> stacks) {
        this.stacks = stacks;
    }

</#if>
<#-- ================================================================ -->
<#--   ORTAK: Her iki BlockEntity için aynı olan kısımlar            -->
<#-- ================================================================ -->

    @Override
    public ClientboundBlockEntityDataPacket getUpdatePacket() {
        return ClientboundBlockEntityDataPacket.create(this);
    }

    @Override
    public CompoundTag getUpdateTag(HolderLookup.Provider lookupProvider) {
        return this.saveWithFullMetadata(lookupProvider);
    }

    <#-- ── Ortak: Container metodları ── -->
    @Override
    public int getContainerSize() {
        return stacks.size();
    }

    @Override
    public boolean isEmpty() {
        for (ItemStack stack : this.stacks)
            if (!stack.isEmpty())
                return false;
        return true;
    }

    @Override
    public ItemStack getItem(int slot) {
        return this.stacks.get(slot);
    }

    @Override
    public ItemStack removeItem(int slot, int amount) {
        ItemStack result = ContainerHelper.removeItem(this.stacks, slot, amount);
        if (!result.isEmpty())
            this.setChanged();
        return result;
    }

    @Override
    public ItemStack removeItemNoUpdate(int slot) {
        return ContainerHelper.takeItem(this.stacks, slot);
    }

    @Override
    public void setItem(int slot, ItemStack stack) {
        this.stacks.set(slot, stack);
        if (stack.getCount() > this.getMaxStackSize())
            stack.setCount(this.getMaxStackSize());
        this.setChanged();
    }

    @Override
    public boolean stillValid(Player player) {
        return Container.stillValidBlockEntity(this, player);
    }

    @Override
    public void clearContent() {
        this.stacks.clear();
    }

    <#-- ── Ortak: WorldlyContainer metodları ── -->
    @Override
    public boolean canPlaceItem(int index, ItemStack stack) {
        <#list data.inventoryOutSlotIDs as id>
        if (index == ${id})
            return false;
        </#list>
        return true;
    }

    @Override
    public int[] getSlotsForFace(Direction side) {
        return IntStream.range(0, this.getContainerSize()).toArray();
    }

    @Override
    public boolean canPlaceItemThroughFace(int index, ItemStack itemstack, @Nullable Direction direction) {
        return this.canPlaceItem(index, itemstack)
        <#if hasProcedure(data.inventoryAutomationPlaceCondition)>&& <@procedureCode data.inventoryAutomationPlaceCondition, {
            "index": "index",
            "itemstack": "itemstack",
            "direction": "direction"
        }, false/>
        </#if>;
    }

    @Override
    public boolean canTakeItemThroughFace(int index, ItemStack itemstack, Direction direction) {
        <#list data.inventoryInSlotIDs as id>
        if (index == ${id})
            return false;
        </#list>
        <#if hasProcedure(data.inventoryAutomationTakeCondition)>
        return <@procedureCode data.inventoryAutomationTakeCondition, {
            "index": "index",
            "itemstack": "itemstack",
            "direction": "direction"
        }, false/>;
        <#else>
        return true;
        </#if>
    }

    <#-- ── Ortak: Energy Storage ── -->
    <#if data.hasEnergyStorage>
    private final EnergyStorage energyStorage = new EnergyStorage(
        ${data.energyCapacity}, ${data.energyMaxReceive}, ${data.energyMaxExtract}, ${data.energyInitial}
    ) {
        @Override
        public int receiveEnergy(int maxReceive, boolean simulate) {
            int retval = super.receiveEnergy(maxReceive, simulate);
            if (!simulate) {
                setChanged();
                level.sendBlockUpdated(worldPosition, level.getBlockState(worldPosition), level.getBlockState(worldPosition), 2);
            }
            return retval;
        }

        @Override
        public int extractEnergy(int maxExtract, boolean simulate) {
            int retval = super.extractEnergy(maxExtract, simulate);
            if (!simulate) {
                setChanged();
                level.sendBlockUpdated(worldPosition, level.getBlockState(worldPosition), level.getBlockState(worldPosition), 2);
            }
            return retval;
        }
    };

    public EnergyStorage getEnergyStorage() {
        return energyStorage;
    }
    </#if>

    <#-- ── Ortak: Fluid Tank ── -->
    <#if data.isFluidTank>
    private final FluidTank fluidTank = new FluidTank(${data.fluidCapacity}
        <#if data.fluidRestrictions?has_content>, fs -> {
        <#list data.fluidRestrictions as fluidRestriction>
            if (fs.getFluid() == ${fluidRestriction}) return true;
        </#list>
            return false;
        }</#if>
    ) {
        @Override
        protected void onContentsChanged() {
            super.onContentsChanged();
            setChanged();
            level.sendBlockUpdated(worldPosition, level.getBlockState(worldPosition), level.getBlockState(worldPosition), 2);
        }
    };

    public FluidTank getFluidTank() {
        return fluidTank;
    }
    </#if>

    <#-- ── Ortak: Vibration ── -->
    <#if data.sensitiveToVibration>
    @Override
    public VibrationSystem.Data getVibrationData() {
        return this.vibrationData;
    }

    @Override
    public VibrationSystem.User getVibrationUser() {
        return this.vibrationUser;
    }

    @Override
    public VibrationSystem.Listener getListener() {
        return this.vibrationListener;
    }

    private class VibrationUser implements VibrationSystem.User {

        private final int x;
        private final int y;
        private final int z;
        private final PositionSource positionSource;

        public VibrationUser(BlockPos blockPos) {
            this.x = blockPos.getX();
            this.y = blockPos.getY();
            this.z = blockPos.getZ();
            this.positionSource = new BlockPositionSource(blockPos);
        }

        @Override
        public PositionSource getPositionSource() {
            return this.positionSource;
        }

        <#if data.vibrationalEvents?has_content>
        @Override
        public TagKey<GameEvent> getListenableEvents() {
            return TagKey.create(Registries.GAME_EVENT, ResourceLocation.withDefaultNamespace("${registryname}_can_listen"));
        }
        </#if>

        @Override
        public int getListenerRadius() {
            <#if hasProcedure(data.vibrationSensitivityRadius)>
            Level world = ${name}BlockEntity.this.getLevel();
            BlockState blockstate = ${name}BlockEntity.this.getBlockState();
            return (int) <@procedureOBJToNumberCode data.vibrationSensitivityRadius/>;
            <#else>
            return ${data.vibrationSensitivityRadius.getFixedValue()};
            </#if>
        }

        @Override
        public boolean canReceiveVibration(ServerLevel world, BlockPos vibrationPos, Holder<GameEvent> holder, GameEvent.Context context) {
            <#if hasProcedure(data.canReceiveVibrationCondition)>
            return <@procedureCode data.canReceiveVibrationCondition {
                "x": "x",
                "y": "y",
                "z": "z",
                "vibrationX": "vibrationPos.getX()",
                "vibrationY": "vibrationPos.getY()",
                "vibrationZ": "vibrationPos.getZ()",
                "world": "world",
                "entity": "context.sourceEntity()",
                "blockstate": "${name}BlockEntity.this.getBlockState()"
            }/>
            <#else>
            return true;
            </#if>
        }

        @Override
        public void onReceiveVibration(ServerLevel world, BlockPos vibrationPos, Holder<GameEvent> holder, Entity entity, Entity projectileShooter, float distance) {
            <#if hasProcedure(data.onReceivedVibration)>
            <@procedureCode data.onReceivedVibration {
                "x": "x",
                "y": "y",
                "z": "z",
                "vibrationX": "vibrationPos.getX()",
                "vibrationY": "vibrationPos.getY()",
                "vibrationZ": "vibrationPos.getZ()",
                "world": "world",
                "blockstate": "${name}BlockEntity.this.getBlockState()",
                "entity": "entity",
                "sourceentity": "projectileShooter"
            }/>
            </#if>
        }

        @Override
        public void onDataChanged() {
            ${name}BlockEntity.this.setChanged();
        }

        @Override
        public boolean requiresAdjacentChunksToBeTicking() {
            return true;
        }
    }
    </#if>

}
</@javacompress>
<#-- @formatter:on -->
