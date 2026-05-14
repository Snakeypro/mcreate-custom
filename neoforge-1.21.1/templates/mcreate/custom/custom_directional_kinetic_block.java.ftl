package com.xenrao.mcreate.custom;

import net.minecraft.world.level.block.state.StateDefinition;
import net.minecraft.world.level.block.state.BlockState;
import net.minecraft.world.level.block.Block;
import net.minecraft.world.level.LevelReader;
import net.minecraft.world.level.LevelAccessor;
import net.minecraft.world.item.context.BlockPlaceContext;
import net.minecraft.world.level.block.Mirror;
import net.minecraft.world.level.block.Rotation;
import net.minecraft.core.Direction;
import net.minecraft.core.BlockPos;
import net.minecraft.world.level.block.state.properties.BlockStateProperties;
import net.minecraft.world.level.block.state.properties.DirectionProperty;

import net.createmod.catnip.data.Iterate;

import java.util.Properties;
import java.util.Map;
import java.util.EnumMap;

import com.xenrao.mcreate.util.DirectionHelper;

import com.simibubi.create.content.kinetics.simpleRelays.ICogWheel;
import com.simibubi.create.content.kinetics.base.IRotate;
import com.simibubi.create.content.kinetics.base.DirectionalKineticBlock;

public abstract class CustomDirectionalKineticBlock extends DirectionalKineticBlock implements ICogWheel {
	private final Map<Direction, Boolean> shaftDirections = new EnumMap<>(Direction.class);
	private boolean smallCog = false;

	public CustomDirectionalKineticBlock(Properties properties) {
		super(properties);
		// false direction
		for (Direction dir : Direction.values()) {
			shaftDirections.put(dir, false);
		}
	}

	@Override
	public boolean hasShaftTowards(LevelReader world, BlockPos pos, BlockState state, Direction face) {
		Direction facing = getFacing(state);
		Direction localFace = DirectionHelper.toLocalDirection(face, facing);
		return hasShaft(localFace);
	}

	@Override
	public Direction.Axis getRotationAxis(BlockState state) {
		return getFacing(state).getAxis();
	}

	// ============== Getters
	public boolean hasShaft(Direction direction) {
		return shaftDirections.getOrDefault(direction, false);
	}

	public boolean hasSmallCog() {
		return smallCog;
	}

	// ============== Setters
	public void setSmallCog(boolean value) {
		this.smallCog = value;
	}

	public void setShaft(Direction direction, boolean value) {
		shaftDirections.put(direction, value);
	}

	@Override
	public boolean isSmallCog() {
		return smallCog;
	}

	// ============== Utils
	@Override
	protected void createBlockStateDefinition(StateDefinition.Builder<Block, BlockState> builder) {
	}

	protected DirectionProperty getFacingProperty(BlockState state) {
		if (state.hasProperty(BlockStateProperties.HORIZONTAL_FACING))
			return BlockStateProperties.HORIZONTAL_FACING;
		if (state.hasProperty(FACING))
			return FACING;
		throw new IllegalStateException("CustomDirectionalKineticBlock requires a facing property");
	}

	public Direction getFacing(BlockState state) {
		return state.getValue(getFacingProperty(state));
	}

	protected boolean hasHorizontalFacing(BlockState state) {
		return state.hasProperty(BlockStateProperties.HORIZONTAL_FACING);
	}

	@Override
	public BlockState getStateForPlacement(BlockPlaceContext context) {
		BlockState defaultState = defaultBlockState();
		DirectionProperty facingProperty = getFacingProperty(defaultState);
		Direction preferred = getPreferredFacing(context);
		boolean sneaking = context.getPlayer() != null && context.getPlayer().isShiftKeyDown();
		if (preferred == null || sneaking) {
			if (hasHorizontalFacing(defaultState))
				return defaultState.setValue(facingProperty, context.getHorizontalDirection().getOpposite());
			Direction nearestLookingDirection = context.getNearestLookingDirection();
			return defaultState.setValue(facingProperty, sneaking
				? nearestLookingDirection
				: nearestLookingDirection.getOpposite());
		}
		return defaultState.setValue(facingProperty, preferred.getOpposite());
	}

	@Override
	public Direction getPreferredFacing(BlockPlaceContext context) {
		BlockState defaultState = defaultBlockState();
		Direction preferredFacing = null;
		for (Direction side : hasHorizontalFacing(defaultState) ? Iterate.horizontalDirections : Iterate.directions) {
			BlockPos neighborPos = context.getClickedPos().relative(side);
			BlockState neighborState = context.getLevel().getBlockState(neighborPos);
			if (!(neighborState.getBlock() instanceof IRotate neighbor))
				continue;
			if (!neighbor.hasShaftTowards(context.getLevel(), neighborPos, neighborState, side.getOpposite()))
				continue;
			Direction neededFacing = findFacingForShaftOnSide(side);
			if (neededFacing == null)
				continue;
			if (preferredFacing == null) {
				preferredFacing = neededFacing;
				continue;
			}
			if (preferredFacing == neededFacing)
				continue;
			if (preferredFacing.getAxis() == neededFacing.getAxis())
				continue;
			return null;
		}
		return preferredFacing != null ? preferredFacing.getOpposite() : null;
	}

	private Direction findFacingForShaftOnSide(Direction worldSide) {
		BlockState defaultState = defaultBlockState();
		for (Direction facing : hasHorizontalFacing(defaultState) ? Iterate.horizontalDirections : Direction.values()) {
			Direction localDir = DirectionHelper.toLocalDirection(worldSide, facing);
			if (hasShaft(localDir)) {
				return facing;
			}
		}
		return null;
	}

	@Override
	public BlockState rotate(BlockState state, Rotation rot) {
		DirectionProperty facingProperty = getFacingProperty(state);
		return state.setValue(facingProperty, rot.rotate(state.getValue(facingProperty)));
	}

	@Override
	public BlockState mirror(BlockState state, Mirror mirrorIn) {
		DirectionProperty facingProperty = getFacingProperty(state);
		return state.setValue(facingProperty, mirrorIn.mirror(state.getValue(facingProperty)));
	}
}
