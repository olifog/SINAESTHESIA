extends ColorRect

@onready var wrath_progress = $WrathItem/WrathProgress
@onready var greed_progress = $GreedItem/GreedProgress
@onready var sloth_progress = $SlothItem/SlothProgress

@onready var wrath_level = $WrathItem/Level
@onready var greed_level = $GreedItem/Level
@onready var sloth_level = $SlothItem/Level

@onready var wrath_button = $WrathItem/UpgradeButton
@onready var greed_button = $GreedItem/UpgradeButton
@onready var sloth_button = $SlothItem/UpgradeButton

@onready var souls_label = $SoulsLabel

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	get_node("%ShopUI").visible = false
	
	# Connect button signals
	wrath_button.pressed.connect(_on_wrath_upgrade_pressed)
	greed_button.pressed.connect(_on_greed_upgrade_pressed)
	sloth_button.pressed.connect(_on_sloth_upgrade_pressed)
	
	# Connect to GlobalSettings signals
	GlobalSettings.souls_changed.connect(_on_souls_changed)
	GlobalSettings.sin_level_changed.connect(_on_sin_level_changed)
	
	# Initial UI update
	_update_all_ui()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _update_all_ui() -> void:
	_update_souls_label()
	_update_sin_ui(GlobalSettings.Sin.WRATH)
	_update_sin_ui(GlobalSettings.Sin.GREED)
	_update_sin_ui(GlobalSettings.Sin.SLOTH)

func _update_souls_label() -> void:
	souls_label.text = "Souls: %d" % GlobalSettings.souls

func _update_sin_ui(sin: GlobalSettings.Sin) -> void:
	var level = GlobalSettings.get_sin_level(sin)
	var cost = GlobalSettings.get_sin_upgrade_cost(sin)
	var can_upgrade = GlobalSettings.can_upgrade_sin(sin)
	
	match sin:
		GlobalSettings.Sin.WRATH:
			wrath_level.text = "Level %d" % level
			wrath_progress.value = level * 10
			wrath_button.text = "Upgrade (%d)" % cost
			wrath_button.disabled = !can_upgrade
		GlobalSettings.Sin.GREED:
			greed_level.text = "Level %d" % level
			greed_progress.value = level * 10
			greed_button.text = "Upgrade (%d)" % cost
			greed_button.disabled = !can_upgrade
		GlobalSettings.Sin.SLOTH:
			sloth_level.text = "Level %d" % level
			sloth_progress.value = level * 10
			sloth_button.text = "Upgrade (%d)" % cost
			sloth_button.disabled = !can_upgrade

func _on_souls_changed(_new_souls: int) -> void:
	_update_all_ui()

func _on_sin_level_changed(sin: int, _new_level: int) -> void:
	_update_sin_ui(sin)

func _on_wrath_upgrade_pressed() -> void:
	if GlobalSettings.upgrade_sin(GlobalSettings.Sin.WRATH):
		GlobalSettings.save_game()

func _on_greed_upgrade_pressed() -> void:
	if GlobalSettings.upgrade_sin(GlobalSettings.Sin.GREED):
		GlobalSettings.save_game()

func _on_sloth_upgrade_pressed() -> void:
	if GlobalSettings.upgrade_sin(GlobalSettings.Sin.SLOTH):
		GlobalSettings.save_game()
