extends Control

@onready var YoutubeScene: Control = $"."
@onready var DefaultScript: Control = get_parent() 	#DefaultScene Node
@onready var MenuSounds: AudioStreamPlayer = $MenuSounds
@onready var YoutubeAnimations: AnimationPlayer = $YoutubeSelectionAnimations

func _on_back_button_pressed() -> void:
	YoutubeAnimations.play("Load Out")

func _on_any_button_mouse_entered() -> void:
	if DefaultScript.MenuSettings["MenuSounds"]:
		MenuSounds.play()

func _on_youtube_selection_animations_animation_finished(AnimationName: StringName) -> void:
	if AnimationName == "Load Out":
		YoutubeScene.visible = false 

func _on_selection_button_pressed(YoutubeType: String) -> void:
	match YoutubeType:
		"Freetube":
			DefaultScript.LoadOtherApplication("Freetube")
		"Youtube":
			DefaultScript.LoadWebBrowserApplication("Youtube") 
