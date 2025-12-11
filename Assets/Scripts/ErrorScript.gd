extends Control

@onready var DefaultScript: Control = get_parent() 	#DefaultScene Node
@onready var ErrorScene: Control = $"."
@onready var ErrorTypeLabel: Label = $ErrorBoxTexture/ErrorMessageMargins/ErrorMessageBox/ErrorMessageType
@onready var ErrorMessageLabel: Label = $ErrorBoxTexture/ErrorMessageMargins/ErrorMessageBox/ErrorMessageText
@onready var ErrorAnimations: AnimationPlayer = $ErrorAnimations
@onready var BackButton: Button = $ErrorBoxTexture/Acknowledgement/BackButton

#Custom Functions
func UpdateErrorMessage(ErrorType: String, ErrorMessage: String) -> void:	#Setter function for the error message type and content
	ErrorTypeLabel.text = ErrorType
	ErrorMessageLabel.text = ErrorMessage
	
func ToggleErrorMessageAcknowledge(Toggle: bool) -> void:
	BackButton.disabled = Toggle
	BackButton.focus_mode = FOCUS_NONE if Toggle else FOCUS_ALL

#Trigger Functions
func _on_back_button_pressed() -> void:
	ErrorAnimations.play("Load Out")

func _on_back_button_focus_gained() -> void:
	if DefaultScript.MenuSettings["MenuSounds"]:
		DefaultScript.MenuBlips.play()
		
func _on_mouse_entered_focus_toggle(Focus: bool) -> void:
	if Focus:
		BackButton.grab_focus()
	else:
		BackButton.release_focus()

func _on_error_animations_animation_finished(AnimationName: StringName) -> void:
	if AnimationName == "Load In":
		if Input.get_connected_joypads():	#Controller is connected
			BackButton.grab_focus()
	if AnimationName == "Load Out":
		ErrorScene.visible = false 
		DefaultScript.ToggleMainButtonsDisabled(false)
		if Input.get_connected_joypads():	#Controller is connected
			DefaultScript.DefaultButton.grab_focus()
