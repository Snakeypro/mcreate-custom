package com.xenrao.mcreate.client;

import net.minecraft.world.level.block.state.BlockState;
import net.minecraft.world.level.block.Block;
import net.minecraft.core.Direction.Axis;
import net.minecraft.core.Direction;
import net.minecraft.client.renderer.blockentity.BlockEntityRendererProvider;
import net.minecraft.client.renderer.RenderType;
import net.minecraft.client.renderer.MultiBufferSource;

import net.createmod.catnip.render.SuperByteBuffer;
import net.createmod.catnip.render.CachedBuffers;
import net.createmod.catnip.animation.AnimationTickHolder;

import java.util.Map;
import java.util.EnumMap;

import com.xenrao.mcreate.util.DirectionHelper;
import com.xenrao.mcreate.custom.CustomGeneratorKineticBlockEntity;
import com.xenrao.mcreate.custom.CustomDirectionalKineticBlock;

import com.simibubi.create.content.kinetics.base.KineticBlockEntityRenderer;
import com.simibubi.create.AllPartialModels;

import com.mojang.blaze3d.vertex.PoseStack;


public class McreateGeneratorClientRenderer extends KineticBlockEntityRenderer<CustomGeneratorKineticBlockEntity> {
    public McreateGeneratorClientRenderer(BlockEntityRendererProvider.Context context) {
        super(context);
    }

    private static final Map<Direction, Axis> DIRECTION_AXIS = new EnumMap<>(Map.of(
        Direction.NORTH, Axis.Z,
        Direction.SOUTH, Axis.Z,
        Direction.EAST,  Axis.X,
        Direction.WEST,  Axis.X,
        Direction.UP,    Axis.Y,
        Direction.DOWN,  Axis.Y
    ));

    @Override
    protected void renderSafe(CustomGeneratorKineticBlockEntity be, float partialTicks, PoseStack ms,
                              MultiBufferSource buffer, int light, int overlay) {

        BlockState state = be.getBlockState();
        RenderType type = getRenderType(be, state);
        Block block = state.getBlock();

        if (!(block instanceof CustomDirectionalKineticBlock ckb)) return;

        float time = AnimationTickHolder.getRenderTime(be.getLevel());

        // Shaft rendering loop
        for (Direction localDir : Direction.values()) {
            if (!ckb.hasShaft(localDir)) continue;

            Direction facing = ckb.getFacing(state);
            Direction worldDir = DirectionHelper.toWorldDirection(localDir, facing);

            Axis axis = DIRECTION_AXIS.get(worldDir);
            float offset = getRotationOffsetForPosition(be, be.getBlockPos(), axis);
            float angle = ((time * be.getSpeed() * 3f / 10 + offset) % 360) / 180f * (float) Math.PI;

            SuperByteBuffer shaftBuf = CachedBuffers.partialFacing(AllPartialModels.SHAFT_HALF, state, worldDir);
            kineticRotationTransform(shaftBuf, be, axis, angle, light);
            shaftBuf.renderInto(ms, buffer.getBuffer(type));
        }

        // Cog rendering
        if (!ckb.hasSmallCog()) return;

        Direction facing = ckb.getFacing(state);

        Axis cogAxis = switch (facing) {
            case EAST, WEST   -> Axis.X;
            case UP, DOWN     -> Axis.Y;
            default           -> Axis.Z;
        };

        float rotX = 0f, rotY = 0f, rotZ = 0f;

        switch (facing) {
            case NORTH -> { rotX = 90f; rotY =   0f; rotZ = 0f; }
            case SOUTH -> { rotX = 90f; rotY = 180f; rotZ = 0f; }
            case EAST  -> { rotX =  0f; rotY =   0f; rotZ = 90f; }
            case WEST  -> { rotX =  0f; rotY =   0f; rotZ = 90f; }
            case UP    -> { rotX =  0f; rotY =   0f; rotZ = 0f; }
            case DOWN  -> { rotX = 180f; rotY =  0f; rotZ = 0f; }
        }

        SuperByteBuffer cogBuf = CachedBuffers.partial(AllPartialModels.SHAFTLESS_COGWHEEL, state);
        KineticBlockEntityRenderer.standardKineticRotationTransform(cogBuf, be, light);

        cogBuf.translate(0.5f, 0.5f, 0.5f);
        if (rotX != 0) cogBuf.rotateX((float) Math.toRadians(rotX));
        if (rotY != 0) cogBuf.rotateY((float) Math.toRadians(rotY));
        if (rotZ != 0) cogBuf.rotateZ((float) Math.toRadians(rotZ));
        cogBuf.translate(-0.5f, -0.5f, -0.5f);

        cogBuf.renderInto(ms, buffer.getBuffer(type));
    }
}
