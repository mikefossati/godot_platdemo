## SafeResourceLoader - Utility for safe asset loading
## Prevents silent failures when assets are missing

class_name SafeResourceLoader


## Safely load a scene with validation
## Returns null if scene doesn't exist, logs error for debugging
static func load_scene(path: String) -> PackedScene:
	if not ResourceLoader.exists(path):
		push_error("Scene file not found: '%s'" % path)
		return null
	
	var result = ResourceLoader.load(path)
	if not result:
		push_error("Failed to load scene: '%s'" % path)
		return result
	
	if not result is PackedScene:
		push_error("Resource at '%s' is not a PackedScene" % path)
		return null
	
	return result


## Safely load a texture with validation
## Returns null if texture doesn't exist, logs error for debugging
static func load_texture(path: String) -> Texture2D:
	if not ResourceLoader.exists(path):
		push_error("Texture file not found: '%s'" % path)
		return null
	
	var result = ResourceLoader.load(path)
	if not result:
		push_error("Failed to load texture: '%s'" % path)
		return result
	
	if not result is Texture2D:
		push_error("Resource at '%s' is not a Texture2D" % path)
		return null
	
	return result


## Safely load a material with validation
## Returns null if material doesn't exist, logs error for debugging
static func load_material(path: String) -> Material:
	if not ResourceLoader.exists(path):
		push_error("Material file not found: '%s'" % path)
		return null
	
	var result = ResourceLoader.load(path)
	if not result:
		push_error("Failed to load material: '%s'" % path)
		return result
	
	if not result is Material:
		push_error("Resource at '%s' is not a Material" % path)
		return null
	
	return result


## Safely load any resource with type checking
## Generic loader for any resource type
static func load_resource(path: String, expected_type: GDScript) -> Resource:
	if not ResourceLoader.exists(path):
		push_error("Resource file not found: '%s'" % path)
		return null
	
	var result = ResourceLoader.load(path)
	if not result:
		push_error("Failed to load resource: '%s'" % path)
		return result
	
	if not result.get_script() == expected_type:
		push_error("Resource at '%s' is not of expected type" % path)
		return null
	
	return result


## Load scene with fallback to default
## Returns fallback_scene if target fails to load
static func load_scene_with_fallback(path: String, fallback_scene: PackedScene) -> PackedScene:
	var result = load_scene(path)
	if not result:
		push_warning("Using fallback scene for missing: '%s'" % path)
		return fallback_scene
	return result
