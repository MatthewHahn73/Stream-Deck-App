extends Control

@onready var DefaultScript: Control = get_parent() 	#DefaultScene Node
@onready var YoutubeScene: Control = $"."
@onready var YoutubeAnimations: AnimationPlayer = $YoutubeSelectionAnimations
@onready var FreetubeButton: Button = $YoutubeSelectionTexture/YoutubeSelectionMargins/YoutubeSelectionBox/FreeTubeButton

#Custom Functions
func ReturnButtonFromType(Type: String) -> Button: #Returns a UI button given a simple descriptor
	match Type:
		"FreeTube":
			return $YoutubeSelectionTexture/YoutubeSelectionMargins/YoutubeSelectionBox/FreeTubeButton
		"Youtube":
			return $YoutubeSelectionTexture/YoutubeSelectionMargins/YoutubeSelectionBox/YouTubeButton
		"Back":
			return $YoutubeSelectionTexture/BackMargin/BackButton
		_:
			return null

#Trigger Functions
func _on_back_button_pressed() -> void:
	YoutubeAnimations.play("Load Out")

func _on_any_button_focus_gained() -> void:
	if DefaultScript.MenuSettings["MenuSounds"] && DefaultScript.EnableUISoundsFocus:
		DefaultScript.MenuBlips.play()
		
func _on_mouse_entered_focus_toggle(Type: String, Focus: bool) -> void:
	var ServiceButtonEntered = ReturnButtonFromType(Type)
	if ServiceButtonEntered != null && !ServiceButtonEntered.disabled:
		if Focus:
			ServiceButtonEntered.grab_focus()
		else:
			ServiceButtonEntered.release_focus()

func _on_youtube_selection_animations_animation_finished(AnimationName: StringName) -> void:
	if AnimationName == "Load In":
		if Input.get_connected_joypads():	#Controller is connected
			FreetubeButton.grab_focus()
	if AnimationName == "Load Out":
		DefaultScript.ToggleMainButtonsDisabled(false)
		if Input.get_connected_joypads():	#Controller is connected
			DefaultScript.DefaultButton.grab_focus()

func _on_selection_button_pressed(YoutubeType: String) -> void:
	match YoutubeType:
		"FreeTube":
			DefaultScript.LoadOtherApplication("Freetube")
		"Youtube":
			DefaultScript.LoadWebBrowserApplication("Youtube") 
