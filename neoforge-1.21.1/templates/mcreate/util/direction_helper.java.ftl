package com.xenrao.mcreate.util;

import net.minecraft.core.Direction;

public final class DirectionHelper {
	private DirectionHelper() {
	}

	/**
	 * Dünya yönünü, bloğun baktığı yöne göre yerel yöne çevirir.
	 */
	public static Direction toLocalDirection(Direction worldDir, Direction blockFacing) {
	    if (blockFacing == Direction.NORTH) return worldDir;
	
	    return switch (blockFacing) {
	        case SOUTH -> switch (worldDir) {
	            case NORTH -> Direction.SOUTH;
	            case SOUTH -> Direction.NORTH;
	            case EAST  -> Direction.WEST;
	            case WEST  -> Direction.EAST;
	            default    -> worldDir; 
	        };
	        case EAST -> switch (worldDir) {
	            case NORTH -> Direction.WEST;  
	            case SOUTH -> Direction.EAST;  
	            case EAST  -> Direction.NORTH;
	            case WEST  -> Direction.SOUTH; 
	            default    -> worldDir;
	        };
	        case WEST -> switch (worldDir) {
	            case NORTH -> Direction.EAST; 
	            case SOUTH -> Direction.WEST; 
	            case EAST  -> Direction.SOUTH;
	            case WEST  -> Direction.NORTH;
	            default    -> worldDir;
	        };
	        case UP -> switch (worldDir) {
	            case NORTH -> Direction.DOWN; 
	            case SOUTH -> Direction.UP;   
	            case UP    -> Direction.NORTH; 
	            case DOWN  -> Direction.SOUTH; 
	            default    -> worldDir;
	        };
	        case DOWN -> switch (worldDir) {
	            case NORTH -> Direction.UP;   
	            case SOUTH -> Direction.DOWN;  
	            case UP    -> Direction.SOUTH; 
	            case DOWN  -> Direction.NORTH; 
	            default    -> worldDir;
	        };
	        default -> worldDir;
	    };
	}

	/**
	 * Yerel yönü dünya yönüne çevirir (toLocalDirection'ın tersi).
	 * Renderer'da "local shaft direction → dünya yönü" için kullanılır.
	 */
	public static Direction toWorldDirection(Direction localDir, Direction blockFacing) {
	    if (blockFacing == Direction.NORTH) return localDir;
	
	    return switch (blockFacing) {
	        case SOUTH -> switch (localDir) {
	            case NORTH -> Direction.SOUTH;
	            case SOUTH -> Direction.NORTH;
	            case EAST  -> Direction.WEST;
	            case WEST  -> Direction.EAST;
	            default    -> localDir;
	        };
	        case EAST -> switch (localDir) {
	            case NORTH -> Direction.EAST; 
	            case SOUTH -> Direction.WEST; 
	            case EAST  -> Direction.SOUTH;
	            case WEST  -> Direction.NORTH;
	            default    -> localDir;
	        };
	        case WEST -> switch (localDir) {
	            case NORTH -> Direction.WEST;  
	            case SOUTH -> Direction.EAST; 
	            case EAST  -> Direction.NORTH;
	            case WEST  -> Direction.SOUTH; 
	            default    -> localDir;
	        };
	        case UP -> switch (localDir) {
	            case NORTH -> Direction.UP;   
	            case SOUTH -> Direction.DOWN;  
	            case UP    -> Direction.SOUTH; 
	            case DOWN  -> Direction.NORTH; 
	            default    -> localDir;
	        };
	        case DOWN -> switch (localDir) {
	            case NORTH -> Direction.DOWN;  
	            case SOUTH -> Direction.UP;   
	            case UP    -> Direction.NORTH; 
	            case DOWN  -> Direction.SOUTH; 
	            default    -> localDir;
	        };
	        default -> localDir;
	    };
	}
}