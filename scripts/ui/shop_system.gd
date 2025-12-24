extends Control
class_name ShopSystem

## Shop System - Purchase unlockables with coins
## Part of Phase 3: Collectibles & Economy System

# Shop item data structure
class ShopItem:
	var id: String
	var name: String
	var description: String
	var cost: int
	var category: String  # "ability", "costume", "trail", "upgrade"
	var purchased: bool = false

	func _init(item_id: String, item_name: String, desc: String, price: int, cat: String):
		id = item_id
		name = item_name
		description = desc
		cost = price
		category = cat

# Shop inventory
var shop_items: Dictionary = {}

# UI references
@onready var items_container: VBoxContainer = $Panel/VBoxContainer/ScrollContainer/ItemsContainer if has_node("Panel/VBoxContainer/ScrollContainer/ItemsContainer") else null
@onready var coin_label: Label = $Panel/VBoxContainer/CoinCounter/CoinLabel if has_node("Panel/VBoxContainer/CoinCounter/CoinLabel") else null
@onready var close_button: Button = $Panel/VBoxContainer/Header/CloseButton if has_node("Panel/VBoxContainer/Header/CloseButton") else null

# Signals
signal item_purchased(item_id: String)
signal shop_closed


func _ready() -> void:
	# Initialize shop items
	_initialize_shop_items()

	# Load purchased items from save
	_load_purchased_items()

	# Populate UI
	_populate_shop_ui()

	# Update coin display
	_update_coin_display()

	# Connect close button
	if close_button:
		close_button.pressed.connect(_on_close_pressed)


func _initialize_shop_items() -> void:
	# Abilities
	_add_item("ground_pound", "Ground Pound", "Slam down from the air to defeat enemies and break blocks", 150, "ability")
	_add_item("spin_attack", "Spin Attack", "Spinning attack that damages nearby enemies", 150, "ability")
	_add_item("air_dash", "Air Dash", "Dash through the air for extended mobility", 200, "ability")

	# Upgrades
	_add_item("extra_heart", "Extra Heart Container", "Increases maximum health by 1", 200, "upgrade")
	_add_item("faster_respawn", "Faster Respawn", "Reduce respawn time by 50%", 100, "upgrade")

	# Costumes
	_add_item("costume_blue", "Blue Pip Costume", "Dress your character in blue", 100, "costume")
	_add_item("costume_red", "Red Pip Costume", "Dress your character in red", 100, "costume")
	_add_item("costume_gold", "Gold Pip Costume", "Dress your character in shiny gold", 150, "costume")

	# Trail Effects
	_add_item("trail_sparkles", "Sparkle Trail", "Leave a trail of sparkles when you move", 50, "trail")
	_add_item("trail_stars", "Star Trail", "Leave a trail of stars when you move", 75, "trail")


func _add_item(id: String, name: String, desc: String, cost: int, category: String) -> void:
	shop_items[id] = ShopItem.new(id, name, desc, cost, category)


func _populate_shop_ui() -> void:
	if not items_container:
		push_warning("ShopSystem: ItemsContainer not found!")
		return

	# Clear existing items
	for child in items_container.get_children():
		child.queue_free()

	# Group items by category
	var categories = ["ability", "upgrade", "costume", "trail"]

	for category in categories:
		# Add category header
		var header = Label.new()
		header.text = category.capitalize() + "s"
		header.add_theme_font_size_override("font_size", 20)
		items_container.add_child(header)

		# Add items in category
		for item_id in shop_items.keys():
			var item: ShopItem = shop_items[item_id]
			if item.category == category:
				_create_shop_item_ui(item)


func _create_shop_item_ui(item: ShopItem) -> void:
	if not items_container:
		return

	# Create item panel
	var item_panel = PanelContainer.new()
	item_panel.custom_minimum_size = Vector2(400, 80)

	var hbox = HBoxContainer.new()
	item_panel.add_child(hbox)

	# Item info (left side)
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(vbox)

	# Item name
	var name_label = Label.new()
	name_label.text = item.name
	name_label.add_theme_font_size_override("font_size", 16)
	vbox.add_child(name_label)

	# Item description
	var desc_label = Label.new()
	desc_label.text = item.description
	desc_label.add_theme_font_size_override("font_size", 12)
	desc_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	vbox.add_child(desc_label)

	# Purchase button (right side)
	var buy_button = Button.new()
	if item.purchased:
		buy_button.text = "OWNED"
		buy_button.disabled = true
	else:
		buy_button.text = "%d Coins" % item.cost
		buy_button.pressed.connect(_on_purchase_pressed.bind(item.id))
	hbox.add_child(buy_button)

	items_container.add_child(item_panel)


func _on_purchase_pressed(item_id: String) -> void:
	if not shop_items.has(item_id):
		push_error("ShopSystem: Unknown item: %s" % item_id)
		return

	var item: ShopItem = shop_items[item_id]

	# Check if already purchased
	if item.purchased:
		print("ShopSystem: Item already purchased: %s" % item_id)
		return

	# Check if player has enough coins
	var player_coins = GameManager.score  # Using score as coins for now
	if player_coins < item.cost:
		print("ShopSystem: Not enough coins! Need %d, have %d" % [item.cost, player_coins])
		# TODO: Show error message in UI
		return

	# Purchase the item
	_purchase_item(item_id)


func _purchase_item(item_id: String) -> void:
	var item: ShopItem = shop_items[item_id]

	# Deduct coins
	GameManager.score -= item.cost
	GameManager.score_changed.emit(GameManager.score)

	# Mark as purchased
	item.purchased = true

	# Apply the unlock
	_apply_unlock(item_id)

	# Save purchase
	_save_purchase(item_id)

	# Update UI
	_populate_shop_ui()
	_update_coin_display()

	# Emit signal
	item_purchased.emit(item_id)

	print("ShopSystem: Purchased %s for %d coins" % [item.name, item.cost])


func _apply_unlock(item_id: String) -> void:
	match item_id:
		"extra_heart":
			# TODO: Implement in GameManager
			print("ShopSystem: Extra heart unlocked!")

		"ground_pound":
			GameManager.unlock_ability("ground_pound")

		"spin_attack":
			# TODO: Implement spin attack
			print("ShopSystem: Spin attack unlocked!")

		"air_dash":
			GameManager.unlock_ability("air_dash")

		"faster_respawn":
			# TODO: Implement respawn speed modifier
			print("ShopSystem: Faster respawn unlocked!")

		"costume_blue", "costume_red", "costume_gold":
			# TODO: Implement costume system in Phase 5
			print("ShopSystem: Costume unlocked: %s" % item_id)

		"trail_sparkles", "trail_stars":
			# TODO: Implement trail effects in Phase 5
			print("ShopSystem: Trail effect unlocked: %s" % item_id)

		_:
			push_warning("ShopSystem: Unknown unlock: %s" % item_id)


func _save_purchase(item_id: String) -> void:
	# TODO: Implement proper save system in GameManager
	# For now, purchases are saved through GameManager.save_game()
	GameManager.save_game()


func _load_purchased_items() -> void:
	# TODO: Load purchased items from GameManager save data
	# For now, items reset each session
	pass


func _update_coin_display() -> void:
	if coin_label:
		coin_label.text = "Coins: %d" % GameManager.score


func _on_close_pressed() -> void:
	shop_closed.emit()
	queue_free()  # Close the shop


## Public API to open shop
static func open_shop(parent: Node) -> ShopSystem:
	var shop_scene = load("res://scenes/ui/shop_menu.tscn")
	if shop_scene:
		var shop = shop_scene.instantiate()
		parent.add_child(shop)
		return shop
	else:
		push_error("ShopSystem: Failed to load shop_menu.tscn")
		return null
