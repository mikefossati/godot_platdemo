# Object Pooling System Guide

## Overview

The object pooling system reduces memory allocation and garbage collection overhead by reusing objects instead of constantly creating and destroying them. This is particularly beneficial for collectibles that spawn and despawn frequently.

## Benefits

- **Reduced GC Pressure**: No need to constantly allocate/deallocate memory
- **Better Performance**: Faster spawning since objects are pre-allocated
- **Predictable Memory**: Fixed pool size prevents memory spikes
- **Easy to Use**: Drop-in replacement for traditional instantiate/queue_free pattern

## How It Works

1. **ObjectPool** - Generic pooling system that manages a pool of reusable nodes
2. **Poolable Objects** - Implement `reset_pooled_object()` method to reset state when reused
3. **Pool Manager** - Game-specific manager that handles spawning/despawning using the pool

## Using Collectible Pooling in Levels

### Option 1: Use CollectibleManager (Recommended for New Levels)

1. Add a `CollectibleManager` node to your level scene
2. Configure the manager:
   ```
   - collectible_scene: res://scenes/collectible/collectible.tscn
   - spawn_positions: [Vector3(0, 1, 0), Vector3(5, 1, 0), ...]
   - enable_pooling: true
   ```
3. Remove individual Collectible nodes from the scene
4. The manager will spawn them automatically using the pool

**Example Level Structure:**
```
MainLevel (Node3D)
├── Player
├── Ground
├── Platforms
└── CollectibleManager
    └── ObjectPool (created automatically)
```

### Option 2: Keep Existing Collectibles (Backward Compatible)

The collectible code automatically detects if a pool manager exists:
- If `collectible_pool` group exists → uses pooling
- If not → uses traditional queue_free()

This means existing levels continue to work without changes.

### Option 3: Hybrid Approach

You can have some collectibles in the scene tree (for fixed positions) and use the manager for dynamic spawning. Both will work together seamlessly.

## Creating Custom Poolable Objects

To make any object poolable:

1. Add a `reset_pooled_object()` method:
```gdscript
func reset_pooled_object() -> void:
    # Reset all state variables
    time_passed = 0.0
    velocity = Vector3.ZERO

    # Re-enable collision/visibility
    monitoring = true
    show()

    # Reset position (will be set by spawner)
```

2. When destroying, check for pool manager:
```gdscript
func destroy() -> void:
    var pool = get_tree().get_first_node_in_group("my_object_pool")
    if pool and pool.has_method("release_object"):
        pool.release_object(self)
    else:
        queue_free()
```

3. Create a manager similar to CollectibleManager for your object type

## Performance Monitoring

To check pool statistics:

```gdscript
var manager = get_tree().get_first_node_in_group("collectible_pool")
if manager:
    var stats = manager.get_pool_stats()
    print("Pool Stats:")
    print("  Available: ", stats.available)
    print("  Active: ", stats.active)
    print("  Total: ", stats.total)
```

## Configuration

### ObjectPool Parameters

- **pooled_scene**: The PackedScene to instantiate
- **initial_pool_size**: Number of objects pre-allocated (default: 10)
- **max_pool_size**: Maximum pool size, 0 = unlimited (default: 50)

### CollectibleManager Parameters

- **collectible_scene**: The collectible PackedScene
- **spawn_positions**: Array of Vector3 positions
- **enable_pooling**: Enable/disable pooling (default: true)

## Best Practices

1. **Size the pool appropriately**: Set `initial_pool_size` to your typical max count
2. **Set a max_pool_size**: Prevents unbounded memory growth
3. **Reset thoroughly**: Make sure `reset_pooled_object()` clears all state
4. **Test both modes**: Ensure your objects work with and without pooling
5. **Use for frequently spawned objects**: Best for collectibles, projectiles, particles

## Migration Path

### Minimal Changes (Keep Current Behavior)
- No changes needed! Existing levels work as-is.

### Gradual Adoption (Per-Level Opt-In)
1. Add CollectibleManager to one level
2. Test thoroughly
3. Migrate other levels one at a time

### Full Migration (Maximum Performance)
1. Update all levels to use CollectibleManager
2. Remove individual Collectible nodes from scenes
3. Define spawn positions in manager
4. Enjoy performance benefits!

## Troubleshooting

**Collectibles increment total_collectibles twice**
- This happens because `_ready()` increments the count, and we haven't adjusted for pooling
- Solution: The manager decrements the count when releasing to pool

**Collectibles don't reset properly**
- Check that `reset_pooled_object()` resets ALL state variables
- Use debug prints to verify the method is being called

**Pool runs out of objects**
- Increase `max_pool_size` or set to 0 for unlimited
- Check for leaks (objects not being released back to pool)

**Performance not improved**
- Verify pooling is enabled with `enable_pooling = true`
- Check pool stats to ensure objects are being reused
- Profile before/after to measure actual impact
