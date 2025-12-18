## SceneValidator - Utility for safe node access
## Prevents runtime crashes from missing nodes by validating node paths before access

class_name SceneValidator


## Safely get a node by path, with error reporting
## Returns null if node doesn't exist, logs error for debugging
static func validate_node_path(node: Node, path: String) -> Node:
	var result = node.get_node_or_null(path)
	if not result:
		push_error("Required node not found: '%s' on '%s'" % [path, node.name])
	return result


## Safely get a node by path, with optional fallback
## Returns fallback_node if target doesn't exist
static func validate_node_path_with_fallback(node: Node, path: String, fallback_node: Node) -> Node:
	var result = node.get_node_or_null(path)
	if not result:
		push_warning("Node not found: '%s' on '%s', using fallback" % [path, node.name])
		return fallback_node
	return result


## Validate that a node has all required children
## Returns array of missing child node names
static func validate_children(node: Node, required_children: Array[String]) -> Array[String]:
	var missing: Array[String] = []
	
	for child_name in required_children:
		if not node.has_node(child_name):
			missing.append(child_name)
	
	if missing.size() > 0:
		push_error("Missing required children on '%s': %s" % [node.name, ", ".join(missing)])
	
	return missing


## Check if a node exists and is of expected type
## Returns true if node exists and matches type
static func validate_node_type(node: Node, path: String, expected_type: GDScript) -> bool:
	var target_node = node.get_node_or_null(path)
	if not target_node:
		return false
	
	return target_node.get_script() == expected_type
