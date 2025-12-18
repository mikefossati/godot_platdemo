## NodeCache - Performance optimization for frequent node lookups
## Caches frequently accessed nodes to eliminate expensive tree searches
## Used as autoload singleton

extends Node

## Cached references for performance
var cached_player: Node
var cached_hud: CanvasLayer
var cached_level_session: Node
var cached_settings_manager: Node

## Initialize cache with current scene nodes
func _ready() -> void:
	_cache_frequent_nodes()


## Cache frequently accessed nodes once
func _cache_frequent_nodes() -> void:
	# Cache player reference
	if not cached_player or not is_instance_valid(cached_player):
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			cached_player = players[0]
	
	# Cache HUD reference
	if not cached_hud or not is_instance_valid(cached_hud):
		var huds = get_tree().get_nodes_in_group("hud")
		if huds.size() > 0:
			cached_hud = huds[0]
	
	# Cache LevelSession reference
	if not cached_level_session or not is_instance_valid(cached_level_session):
		var sessions = get_tree().get_nodes_in_group("level_session")
		if sessions.size() > 0:
			cached_level_session = sessions[0]
	
	# Cache SettingsManager reference
	if not cached_settings_manager:
		# SettingsManager is an autoload, access it directly
		cached_settings_manager = get_node_or_null("/root/SettingsManager")


## Get cached player reference
func get_player() -> Node:
	if not cached_player or not is_instance_valid(cached_player):
		_cache_frequent_nodes()
	return cached_player


## Get cached HUD reference
func get_hud() -> CanvasLayer:
	if not cached_hud or not is_instance_valid(cached_hud):
		_cache_frequent_nodes()
	return cached_hud


## Get cached LevelSession reference
func get_level_session() -> Node:
	if not cached_level_session or not is_instance_valid(cached_level_session):
		_cache_frequent_nodes()
	return cached_level_session


## Get cached SettingsManager reference
func get_settings_manager() -> Node:
	if not cached_settings_manager:
		_cache_frequent_nodes()
	return cached_settings_manager


## Invalidate all caches (call when changing scenes)
func invalidate_all() -> void:
	cached_player = null
	cached_hud = null
	cached_level_session = null
	# SettingsManager is an autoload, no need to invalidate


## Invalidate specific cache
func invalidate_player() -> void:
	cached_player = null


func invalidate_hud() -> void:
	cached_hud = null


func invalidate_level_session() -> void:
	cached_level_session = null
