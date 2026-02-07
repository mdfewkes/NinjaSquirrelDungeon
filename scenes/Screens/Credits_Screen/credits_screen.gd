extends Control

## Pixels/second, normal auto-scroll
@export var scroll_speed := 50.0
## Pixels/second when holding up/down
@export var nudge_scale := 500.0

@export_file("*.md", "*.txt", "*.bbcode") var credits_file_path : String

@onready var scrolling_container: VBoxContainer = $ScrollingContainer
@onready var title_text: Node = $ScrollingContainer/Title
@onready var final_text: RichTextLabel = $ScrollingContainer/FinalWords
@onready var spacing: Node = $ScrollingContainer/Spacing
@onready var credits: RichTextLabel = $ScrollingContainer/Credits
@onready var title_button: ChangeSceneButton = $ToTitle

var fading_tween: Tween

func _ready() -> void:
	scrolling_container.position.y = size.y
	if credits_file_path:
		credits.text = _load_from_file()


func _process(delta: float) -> void:
	var nudge := Input.get_axis("move_up", "move_down")
	var speed := scroll_speed + nudge * nudge_scale
	var total_height: float = title_text.size.y + credits.size.y + spacing.size.y
	if scrolling_container.position.y > -total_height:
		scrolling_container.position.y -= speed * delta
	elif not fading_tween:
		fading_tween = GameManager.fade_out(5.0)
		fading_tween.finished.connect(_on_fade_complete)


func _on_fade_complete():
	GameManager.change_scene(title_button.path_to_scene)


func _load_from_file():
	var file = FileAccess.open(credits_file_path, FileAccess.READ)
	var content = file.get_as_text()
	return content
