extends VBoxContainer

#Node Variables
@onready var BrowserOption: OptionButton = $BrowserRow/BrowserOption
@onready var MenuSoundsCheckbox: CheckBox = $MenuSoundsRow/CheckboxContainer/MenuSoundsButton
@onready var AutoCloseCheckbox: CheckBox = $AutoCloseRow/CheckboxContainer/AutoCloseButton
@onready var BackButton: Button = $SettingsMargins/SettingsButtonContainer/BackButton
@onready var SaveButton: Button = $SettingsMargins/SettingsButtonContainer/SaveButton
@onready var SettingsMenu: VBoxContainer = $"."
@onready var SettingSounds: AudioStreamPlayer = $MenuSounds
@onready var MenuClicks: AudioStreamPlayer = $MenuClicks
@onready var DefaultScript: Control = get_parent().get_parent() 	#DefaultScene Node

#General Variables
var BrowserTableLocation = "res://Assets/JSON/BrowserFlatpaks.json"
var BrowserTable = {}

#Custom Functions
func LoadAvailableBrowserData() -> void: 
	var BrowserTableFile = FileAccess.open(BrowserTableLocation, FileAccess.READ)
	if BrowserTableFile != null:
		var BrowserTableJSON = JSON.new() 
		if BrowserTableJSON.parse(BrowserTableFile.get_as_text()) == 0: 
			BrowserTable = BrowserTableJSON.data 
	for Key in BrowserTable: 
		if FlatpakIsInstalled(BrowserTable[Key]["Flatpak"]) == 0:
			BrowserOption.add_item(BrowserTable[Key]["Name"], int(Key)) 
	
func LoadSettings() -> void: 
	#Check if file exists, if it doesn't create one
	var SettingsDataLocal = LoadSettingsData()
	BrowserOption.selected = SettingsDataLocal["Browser"]
	MenuSoundsCheckbox.button_pressed = SettingsDataLocal["MenuSounds"]
	AutoCloseCheckbox.button_pressed = SettingsDataLocal["AutoClose"]
	SetMenuValues()
		
func LoadSettingsData() -> Dictionary:
	var SettingsFile = FileAccess.open(DefaultScript.SettingsLocation, FileAccess.READ)
	if SettingsFile != null:
		var SettingsJSON = JSON.new() 
		if SettingsJSON.parse(SettingsFile.get_as_text()) == 0: 
			return SettingsJSON.data 
		else:
			DefaultScript.UpdateErrorLabel("IOError", "Unable to load settings from '" + DefaultScript.SettingsLocation + "'")
		SettingsFile.close()
	else:
		SaveSettings()
		LoadSettings()
	return {}
		
func SetMenuValues() -> void:
	DefaultScript.MenuSettings["MenuSounds"] = MenuSoundsCheckbox.button_pressed
	DefaultScript.MenuSettings["AutoClose"] = AutoCloseCheckbox.button_pressed
		
func SaveSettings() -> void: 
	#Check if file exists, if it does, write to it, if not create a new one
	var SettingsFile = FileAccess.open(DefaultScript.SettingsLocation, FileAccess.WRITE)
	var SettingsJSON = JSON.new() 
	SettingsJSON = {
		"Browser" : BrowserOption.selected, 
		"MenuSounds" : MenuSoundsCheckbox.button_pressed, 
		"AutoClose" : AutoCloseCheckbox.button_pressed
	}
	SettingsFile.store_string(JSON.stringify(SettingsJSON))
	SettingsFile.close()
	
func ToggleSettingsButtonsDisabledIfRequired() -> void:
	var FileSettingsData = LoadSettingsData()
	var CurrentSettingsData = {
		"Browser" : float(BrowserOption.selected), 
		"MenuSounds" : MenuSoundsCheckbox.button_pressed, 
		"AutoClose" : AutoCloseCheckbox.button_pressed
	}
	var ButtonToggleBool = (CurrentSettingsData == FileSettingsData)
	SaveButton.disabled = ButtonToggleBool
	SaveButton.focus_mode = FOCUS_NONE if ButtonToggleBool else FOCUS_ALL
	
func ToggleAllElementsFocusDisabled(Toggle: bool) -> void:
	for Element in [BrowserOption, MenuSoundsCheckbox, AutoCloseCheckbox, BackButton, SaveButton]:
		Element.focus_mode = FOCUS_NONE if Toggle else FOCUS_ALL
		
func FlatpakIsInstalled(Program: String) -> int: 
	var TerminalOutput = [] 
	OS.execute("flatpak", ["list", "--app"], TerminalOutput) 
	if Program in TerminalOutput[0]:
		return 0 
	return 1
	
func ReturnButtonFromType(Type: String) -> Button:
	match Type:
		"Back":
			return $SettingsMargins/SettingsButtonContainer/BackButton
		"Save":
			return $SettingsMargins/SettingsButtonContainer/SaveButton
		"MenuSounds":
			return $MenuSoundsRow/CheckboxContainer/MenuSoundsButton
		"AutoClose":
			return $AutoCloseRow/CheckboxContainer/AutoCloseButton
		_:
			return null
	
#Trigger Functions
func _ready() -> void:
	LoadAvailableBrowserData()

func _on_button_focus_gained(ButtonType: String) -> void:
	var ButtonEntered = ReturnButtonFromType(ButtonType)
	if ButtonEntered != null && !ButtonEntered.disabled:
		if DefaultScript.MenuSettings["MenuSounds"]:
			SettingSounds.play()

func _on_mouse_entered_focus_toggle(ServiceType: String, Focus: bool) -> void:
	var ServiceButtonEntered = ReturnButtonFromType(ServiceType)
	if ServiceButtonEntered != null && !ServiceButtonEntered.disabled:
		if Focus:
			ServiceButtonEntered.grab_focus()
		else:
			ServiceButtonEntered.release_focus()
						
func _on_resolution_option_item_selected(_index: int) -> void:
	if DefaultScript.MenuSettings["MenuSounds"]:
		MenuClicks.play()
	ToggleSettingsButtonsDisabledIfRequired()

func _on_browser_option_pressed() -> void:
	if DefaultScript.MenuSettings["MenuSounds"]:
		MenuClicks.play()
			
func _on_settings_save_button_pressed() -> void:
	SaveSettings()
	SetMenuValues()
	ToggleSettingsButtonsDisabledIfRequired()
	BackButton.grab_focus()
	
func _on_back_button_pressed() -> void:
	DefaultScript.ToggleMainButtonsDisabled(DefaultScript.SettingsToggle) 
	DefaultScript.ToggleSettingsMenu(!DefaultScript.SettingsToggle)
	ToggleAllElementsFocusDisabled(DefaultScript.SettingsToggle)
	if Input.get_connected_joypads():												#Controller is connected
		DefaultScript.DefaultButtonBack.grab_focus()
