extends Control

# Node references
@onready var noise_rect:NoiseTexture2D = $VSplitContainer/Noise.texture
@onready var noise:TextureRect = $VSplitContainer/Noise

@onready var blend_box:SpinBox = $VSplitContainer/Menu/HBoxContainer/Blend
@onready var seamless_toggle:CheckButton = $VSplitContainer/Menu/HBoxContainer/Seamless

@onready var width_box:SpinBox = $VSplitContainer/Menu/Resolution/Width
@onready var height_box:SpinBox = $VSplitContainer/Menu/Resolution/Height

@onready var ntype_label:Label = $VSplitContainer/Menu/Type
@onready var noise_menu:MenuButton = $"VSplitContainer/Menu/Noise Types"

@onready var export_button:Button = $VSplitContainer/Menu/Dock/Export

# Configuration
@export var default_size:int = 512
var is_exporting:bool = false

func _ready() -> void:
	_setup_noise_menu()

func _setup_noise_menu() -> void:
	var popup = noise_menu.get_popup()
	popup.id_pressed.connect(_on_menu_item_selected)
	popup.add_item("Simplex", FastNoiseLite.TYPE_SIMPLEX)
	popup.add_item("Simplex Smooth", FastNoiseLite.TYPE_SIMPLEX_SMOOTH)
	popup.add_item("Cellular", FastNoiseLite.TYPE_CELLULAR)
	popup.add_item("Perlin", FastNoiseLite.TYPE_PERLIN)
	popup.add_item("Value", FastNoiseLite.TYPE_VALUE)
	popup.add_item("Value Cubic", FastNoiseLite.TYPE_VALUE_CUBIC)

# Export UI handlers
func _on_export_pressed() -> void:
	is_exporting = true
	
	# Store current state
	var was_normal_map = noise_rect.as_normal_map
	
	# Export regular texture
	noise_rect.as_normal_map = false
	var base_path = await _get_save_path()
	if base_path:
		# Get the texture data
		var image = noise_rect.get_image()
		# Save regular texture
		image.save_png(base_path)
		
		# Create normal map from height data
		var normal_image = create_normal_map(image)
		# Add _normal suffix before the extension
		var normal_path = base_path.get_basename() + "_normal" + ".png"
		normal_image.save_png(normal_path)
	
	# Restore previous state
	noise_rect.as_normal_map = was_normal_map
	is_exporting = false

func create_normal_map(height_map: Image) -> Image:
	var width = height_map.get_width()
	var height = height_map.get_height()
	var normal_map = Image.create(width, height, false, Image.FORMAT_RGB8)
	var bump_intensity = 8.0
	
	height_map.convert(Image.FORMAT_RGB8)
	
	for y in height:
		for x in width:
			# Sample heights using wrapped coordinates
			var left = height_map.get_pixel(posmod(x - 1, width), y).r
			var right = height_map.get_pixel(posmod(x + 1, width), y).r
			var up = height_map.get_pixel(x, posmod(y - 1, height)).r
			var down = height_map.get_pixel(x, posmod(y + 1, height)).r
			
			# Calculate normal with increased intensity
			var normal_x = (left - right) * 0.5 * bump_intensity
			var normal_y = (up - down) * 0.5 * bump_intensity
			var normal_z = 1.0
			
			# Normalize
			var length = sqrt(normal_x * normal_x + normal_y * normal_y + normal_z * normal_z)
			normal_x /= length
			normal_y /= length
			normal_z /= length
			
			# Convert from -1,1 range to 0,1 range
			normal_x = (normal_x * 0.5) + 0.5
			normal_y = (normal_y * 0.5) + 0.5
			normal_z = (normal_z * 0.5) + 0.5
			
			# Set pixel
			normal_map.set_pixel(x, y, Color(normal_x, normal_y, normal_z))
	
	return normal_map

func _get_save_path() -> String:
	var file_dialog = FileDialog.new()
	add_child(file_dialog)
	
	file_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	file_dialog.filters = PackedStringArray(["*.png ; PNG Images"])
	file_dialog.current_dir = OS.get_system_dir(OS.SYSTEM_DIR_DESKTOP)
	
	file_dialog.popup_centered(Vector2(800, 600))
	
	# Wait for dialog response
	var path = await file_dialog.file_selected
	file_dialog.queue_free()
	
	return path
# Toolbar functions
func _on_normalize_toggled(toggled_on: bool) -> void:
	noise_rect.normalize = toggled_on

func _on_invert_pressed() -> void:
	noise_rect.invert = !noise_rect.invert

func _on_seed_value_changed(value: float) -> void:
	noise_rect.noise.seed = value

# Seamless options
func _on_seamless_toggled(toggled_on: bool) -> void:
	blend_box.visible = toggled_on
	noise_rect.seamless = toggled_on

func _on_blend_value_changed(value: float) -> void:
	noise_rect.seamless_blend_skirt = value

func _on_h_slider_value_changed(value: float) -> void:
	noise_rect.noise.frequency = value

# Resolution handlers
func _on_width_value_changed(value: float) -> void:
	noise_rect.width = value

func _on_height_value_changed(value: float) -> void:
	noise_rect.height = value

func _on_reset_pressed() -> void:
	width_box.value = default_size
	height_box.value = default_size
	noise_rect.height = default_size
	noise_rect.width = default_size

# Noise type handlers
func _on_menu_item_selected(id: int):
	var popup = noise_menu.get_popup()
	ntype_label.text = popup.get_item_text(id)
	noise_rect.noise.noise_type = id

# Fractal type handlers
func _on_none_pressed() -> void:
	noise_rect.noise.fractal_type = FastNoiseLite.FRACTAL_NONE

func _on_fbm_pressed() -> void:
	noise_rect.noise.fractal_type = FastNoiseLite.FRACTAL_FBM

func _on_ridged_pressed() -> void:
	noise_rect.noise.fractal_type = FastNoiseLite.FRACTAL_RIDGED

func _on_ping_pong_pressed() -> void:
	noise_rect.noise.fractal_type = FastNoiseLite.FRACTAL_PING_PONG

# Preview normal map on hover
func _on_noise_mouse_entered() -> void:
	if not is_exporting:
		noise_rect.as_normal_map = true

func _on_noise_mouse_exited() -> void:
	if not is_exporting:
		noise_rect.as_normal_map = false
