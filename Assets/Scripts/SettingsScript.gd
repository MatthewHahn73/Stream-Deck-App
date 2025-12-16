extends Control

#Node Variables
@onready var BrowserOption: OptionButton = $SettingsContainer/BrowserRow/BrowserOption
@onready var MenuSoundsCheckbox: CheckBox = $SettingsContainer/MenuSoundsRow/CheckboxContainer/MenuSoundsButton
@onready var AutoCloseCheckbox: CheckBox = $SettingsContainer/AutoCloseRow/CheckboxContainer/AutoCloseButton
@onready var BackButton: Button = $SettingsContainer/SettingsMargins/SettingsButtonContainer/BackButton
@onready var SaveButton: Button = $SettingsContainer/SettingsMargins/SettingsButtonContainer/SaveButton
@onready var SettingsMenu: Control = $"."
@onready var DefaultScript: Control = get_parent().get_parent() 	#DefaultScene Node

#Static Variables
var BrowserTableLocation = "res://Assets/JSON/BrowserFlatpaks.json"

#Instance Variables
var BrowserTable = {}

#Custom Functions
func LoadAvailableBrowserData() -> void: #Searches the system for valid, installed browsers and adds them to the drop down
	var BrowserTableFile = FileAccess.open(BrowserTableLocation, FileAccess.READ)
	if BrowserTableFile != null:
		var BrowserTableJSON = JSON.new() 
		if BrowserTableJSON.parse(BrowserTableFile.get_as_text()) == 0: 
			BrowserTable = BrowserTableJSON.data 
			for Key in BrowserTable: 
				if FlatpakIsInstalled(BrowserTable[Key]["Flatpak"]) == 0:
					BrowserOption.add_item(BrowserTable[Key]["Name"], int(Key)) 
	else:
		DefaultScript.ShowErrorMessage("IOError", "Unable to get flatpak data from '" + BrowserTableLocation + "'")
	
func LoadSettings() -> void: 	#Loads the user settings and sets those values
	var SettingsDataLocal = LoadSettingsData()
	BrowserOption.selected = SettingsDataLocal["Browser"]
	MenuSoundsCheckbox.button_pressed = SettingsDataLocal["MenuSounds"]
	AutoCloseCheckbox.button_pressed = SettingsDataLocal["AutoClose"]
	SetMenuValues()
		
func LoadSettingsData() -> Dictionary:	#Grabs the user settings data from the 'Settings.json' file in .local and returns it. Returns an empty string if an error is thrown
	var SettingsFile = FileAccess.open(DefaultScript.SettingsLocation, FileAccess.READ)
	if SettingsFile != null:
		var SettingsJSON = JSON.new() 
		if SettingsJSON.parse(SettingsFile.get_as_text()) == 0: 
			return SettingsJSON.data 
		else:
			DefaultScript.ShowErrorMessage("IOError", "Unable to load settings from '" + DefaultScript.SettingsLocation + "'")
		SettingsFile.close()
	else:	#'Settings.json' file doesn't exist, create a new one
		SaveSettings()
		return {
			"Browser" : BrowserOption.selected, 
			"MenuSounds" : MenuSoundsCheckbox.button_pressed, 
			"AutoClose" : AutoCloseCheckbox.button_pressed
		}
	return {}
		
func SetMenuValues() -> void:	#Sets the values in settings to an accessable variable to be used in the main script
	DefaultScript.MenuSettings["MenuSounds"] = MenuSoundsCheckbox.button_pressed
	DefaultScript.MenuSettings["AutoClose"] = AutoCloseCheckbox.button_pressed
		
func SaveSettings() -> void: 	#Saves the settings to the 'Settings.json' file in .local, if file doesn't exist, creates one
	var SettingsFile = FileAccess.open(DefaultScript.SettingsLocation, FileAccess.WRITE)
	if SettingsFile != null:
		var SettingsJSON = JSON.new() 
		SettingsJSON = {
			"Browser" : BrowserOption.selected, 
			"MenuSounds" : MenuSoundsCheckbox.button_pressed, 
			"AutoClose" : AutoCloseCheckbox.button_pressed
		}
		SettingsFile.store_string(JSON.stringify(SettingsJSON))
	else:
		DefaultScript.ShowErrorMessage("IOError", "Unable to write to settings file at '" + DefaultScript.SettingsLocation + "'")
	SettingsFile.close()
	
func ToggleSaveButton() -> void:	#Reads in currently saved settings data and compares to see whether or not to disable the save button
	var FileSettingsData = LoadSettingsData()
	var CurrentSettingsData = {
		"Browser" : float(BrowserOption.selected), 
		"MenuSounds" : MenuSoundsCheckbox.button_pressed, 
		"AutoClose" : AutoCloseCheckbox.button_pressed
	}
	var ButtonToggleBool = (CurrentSettingsData == FileSettingsData)
	SaveButton.disabled = ButtonToggleBool
	SaveButton.focus_mode = FOCUS_NONE if ButtonToggleBool else FOCUS_ALL
	
func ToggleAllElementsFocusDisabled(Toggle: bool) -> void:	#Toggles whether or not the UI elements of the settings menu are focusable to prevent confusing behavior to the user when the menu is hidden
	for Element in [BrowserOption, MenuSoundsCheckbox, AutoCloseCheckbox, BackButton, SaveButton]:
		Element.focus_mode = FOCUS_NONE if Toggle else FOCUS_ALL
		
func FlatpakIsInstalled(Program: String) -> int: #Checks whether or not a given flatpak is installed
	var TerminalOutput = [] 
	OS.execute("flatpak", ["list", "--app"], TerminalOutput) 
	if Program in TerminalOutput[0]:
		return 0 
	return 1
	
func ReturnButtonFromType(Type: String) -> Button: #Returns a UI button given a simple descriptor
	match Type:
		"Back":
			return $SettingsContainer/SettingsMargins/SettingsButtonContainer/BackButton
		"Save":
			return $SettingsContainer/SettingsMargins/SettingsButtonContainer/SaveButton
		"MenuSounds":
			return $SettingsContainer/MenuSoundsRow/CheckboxContainer/MenuSoundsButton
		"AutoClose":
			return $SettingsContainer/AutoCloseRow/CheckboxContainer/AutoCloseButton
		_:
			return null
	
#Trigger Functions
func _ready() -> void:
	LoadAvailableBrowserData()

func _on_button_focus_gained(ButtonType: String) -> void:
	var ButtonEntered = ReturnButtonFromType(ButtonType)
	if ButtonEntered != null && !ButtonEntered.disabled:
		if DefaultScript.MenuSettings["MenuSounds"] && DefaultScript.EnableUISoundsFocus:
			DefaultScript.MenuBlips.play()

func _on_mouse_entered_focus_toggle(ServiceType: String, Focus: bool) -> void:
	var ServiceButtonEntered = ReturnButtonFromType(ServiceType)
	if ServiceButtonEntered != null && !ServiceButtonEntered.disabled:
		if Focus:
			ServiceButtonEntered.grab_focus()
		else:
			ServiceButtonEntered.release_focus()
						
func _on_resolution_option_item_selected(_index: int) -> void:
	if DefaultScript.MenuSettings["MenuSounds"] && DefaultScript.EnableUISoundsFocus:
		DefaultScript.MenuClicks.play()
	ToggleSaveButton()
			
func _on_settings_save_button_pressed() -> void:
	SaveSettings()
	SetMenuValues()
	ToggleSaveButton()
	BackButton.grab_focus()
	
func _on_back_button_pressed() -> void:
	DefaultScript.ToggleMainButtonsDisabled(false) 
	ToggleAllElementsFocusDisabled(false)
	DefaultScript.SettingsAnimations.play("Settings Load Out")
	if Input.get_connected_joypads():	#Controller is connected
		DefaultScript.SettingButton.grab_focus()
