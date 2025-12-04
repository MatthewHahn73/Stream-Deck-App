extends Control

@onready var YoutubeScene: Control = $"."
@onready var DefaultScript: Control = get_parent() 	#DefaultScene Node
@onready var MenuSounds: AudioStreamPlayer = $MenuSounds
@onready var YoutubeAnimations: AnimationPlayer = $YoutubeSelectionAnimations
@onready var FreetubeButton: Button = $YoutubeSelectionTexture/YoutubeSelectionMargins/YoutubeSelectionBox/FreeTubeButton

#Custom Functions
func ReturnButtonFromType(Type: String) -> Button:
	match Type:
		"FreeTube":
			return $YoutubeSelectionTexture/YoutubeSelectionMargins/YoutubeSelectionBox/FreeTubeButton
		"Youtube":
			return $YoutubeSelectionTexture/YoutubeSelectionMargins/YoutubeSelectionBox/YouTubeButton
		_:
			return null

#Trigger Functions
func _on_back_button_pressed() -> void:
	YoutubeAnimations.play("Load Out")

func _on_any_button_focus_gained() -> void:
	if DefaultScript.MenuSettings["MenuSounds"]:
		MenuSounds.play()
		
func _on_mouse_entered_focus_toggle(ServiceType: String, Focus: bool) -> void:
	var ServiceButtonEntered = ReturnButtonFromType(ServiceType)
	if ServiceButtonEntered != null && !ServiceButtonEntered.disabled:
		if Focus:
			ServiceButtonEntered.grab_focus()
		else:
			ServiceButtonEntered.release_focus()

func _on_youtube_selection_animations_animation_finished(AnimationName: StringName) -> void:
	if AnimationName == "Load In":
		FreetubeButton.grab_focus()
	if AnimationName == "Load Out":
		YoutubeScene.visible = false 
		DefaultScript.ToggleMainButtonsDisabled(false)
		if Input.get_connected_joypads():												#Controller is connected
			DefaultScript.DefaultButton.grab_focus()

func _on_selection_button_pressed(YoutubeType: String) -> void:
	match YoutubeType:
		"FreeTube":
			DefaultScript.LoadOtherApplication("Freetube")
		"Youtube":
			DefaultScript.LoadWebBrowserApplication("Youtube") 
