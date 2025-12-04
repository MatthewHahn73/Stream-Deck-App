extends Control

@onready var ErrorScene: Control = $"."
@onready var DefaultScript: Control = get_parent() 	#DefaultScene Node
@onready var MenuSounds: AudioStreamPlayer = $MenuSounds
@onready var ErrorTypeLabel: Label = $ErrorBoxTexture/ErrorMessageMargins/ErrorMessageBox/ErrorMessageType
@onready var ErrorMessageLabel: Label = $ErrorBoxTexture/ErrorMessageMargins/ErrorMessageBox/ErrorMessageText
@onready var ErrorAnimations: AnimationPlayer = $ErrorAnimations
@onready var BackButton: Button = $ErrorBoxTexture/Acknowledgement/BackButton

func UpdateErrorMessage(ErrorType: String, ErrorMessage: String) -> void:
	ErrorTypeLabel.text = ErrorType
	ErrorMessageLabel.text = ErrorMessage

func _on_back_button_pressed() -> void:
	ErrorAnimations.play("Load Out")

func _on_back_button_focus_gained() -> void:
	if DefaultScript.MenuSettings["MenuSounds"]:
		MenuSounds.play()

func _on_error_animations_animation_finished(AnimationName: StringName) -> void:
	if AnimationName == "Load In":
		BackButton.grab_focus()
	if AnimationName == "Load Out":
		ErrorScene.visible = false 
		DefaultScript.ToggleMainButtonsDisabled(false)
		DefaultScript.DefaultButton.grab_focus()
