extends Control

#Node Variables
@onready var SettingsMenu: Control = $MainGUI/SettingsScene
@onready var ErrorMenu: Control = $ErrorScene
@onready var FetchLatestGithubReleaseRequest: HTTPRequest = $FetchLatestGithubRelease
@onready var DownloadLatestGithubReleaseRequest: HTTPRequest = $DownloadLatestGithubRelease
@onready var AppVersion: Label = $MainGUI/OptionsBackground/OptionsBox/TopMargin/TitleBox/AppVersion
@onready var ClockLabel: Label = $ClockMarginContainer/ClockLabel
@onready var ServicesBox: VBoxContainer = $MainGUI/OptionsBackground/OptionsBox/ServicesBox
@onready var ConfigBox: HBoxContainer = $MainGUI/OptionsBackground/OptionsBox/BottomMargin/ConfigBox
@onready var MenuBlips: AudioStreamPlayer = $MenuSounds
@onready var MenuClicks: AudioStreamPlayer = $MenuClicks
@onready var SettingsAnimations: AnimationPlayer = $SettingsAnimations
@onready var LogoAnimations: AnimationPlayer = $LogoAnimations
@onready var PreviewImage: TextureRect = $PreviewImage
@onready var BackgroundImages: ResourcePreloader = $PreloadedImages
@onready var DefaultButton: Button = $MainGUI/OptionsBackground/OptionsBox/ServicesBox/Amazon
@onready var PowerButton: TextureButton = $MainGUI/OptionsBackground/OptionsBox/BottomMargin/ConfigBox/Power
@onready var SettingButton: TextureButton = $MainGUI/OptionsBackground/OptionsBox/BottomMargin/ConfigBox/Settings
@onready var UpdateButton: TextureButton = $MainGUI/OptionsBackground/OptionsBox/BottomMargin/ConfigBox/UpdateControl/Update

#Static Variables
var GithubLink = "https://api.github.com/repos/MatthewHahn73/Stream-Deck-App/releases/latest"
var BuildType = DetermineDebugging()
var ConfBlueprintLocation = BuildType + "://Streaming/Config/StreamingBlueprint.conf"
var ScriptSettingsLocation = BuildType + "://Streaming/Config/Streaming.conf"
var SettingsLocation = BuildType + "://Streaming/Config/Settings.json"
var ExecutableDirectory = "res://"
var StreamingLinksLocation = ExecutableDirectory + "Assets/JSON/StreamingLinks.json"
var VersionFileLocation = ExecutableDirectory + "Assets/JSON/Version.json"
var UpdateFile = ExecutableDirectory + "LatestBuild.zip"

#Instance Variables
var StreamingLinks = {}
var CMDArguments = {}
var MenuSettings = {}
var DownloadLink = ""
var NewReleaseVersion = ""
var EnableUISoundsFocus = true

#Custom Functions	
func DetermineDebugging() -> String:	#Determines if the project is compiled and sets paths depending on whether it is or not for debugging purposes
	if OS.has_feature("editor"):
		return "res"
	return "user"

func MoveUserFilesIfApplicable() -> void: 	#Move the streaming folder to an accessable user directory in .local, if necessary
	if BuildType == "user":
		var ExecutableAbsolutePath = ProjectSettings.globalize_path(ExecutableDirectory + "Streaming/")
		var UserFilesAbsolutePath = ProjectSettings.globalize_path(BuildType + "://Streaming/")
		CopyDirectory(ExecutableAbsolutePath, UserFilesAbsolutePath)
			
func CopyDirectory(Source: String, Destination: String) -> void:	#Copies the 'Streaming' directory to the accessable user directory in .local
	DirAccess.make_dir_recursive_absolute(Destination)
	var SourceDir = DirAccess.open(Source)
	for Directory in SourceDir.get_directories():
		CopyDirectory(Source + Directory + "/", Destination + Directory + "/")	
	for Filename in SourceDir.get_files():
		SourceDir.copy(Source + Filename, Destination + Filename)
				
func LoadArguments() -> void:	#Load arguments, if any
	for Arg in OS.get_cmdline_args():
		if Arg.contains("="):
			var KeyValue = Arg.split("=")
			CMDArguments[KeyValue[0].trim_prefix("--")] = KeyValue[1]
			
func LoadStreamingLinks() -> void:	#Loads the website links and flatpak ids into a usable variable
	var StreamingLinksFile = FileAccess.open(StreamingLinksLocation, FileAccess.READ)
	if StreamingLinksFile != null:
		var StreamingLinksJSON = JSON.new() 
		if StreamingLinksJSON.parse(StreamingLinksFile.get_as_text()) == 0: 
			StreamingLinks = StreamingLinksJSON.data 
			
func LoadBashScriptSettings() -> int:	#Loads the user and application defined settings into the 'Streaming.conf' file using the 'StreamingBlueprint.conf' file as a blueprint
	var BlueprintFile = FileAccess.open(ConfBlueprintLocation, FileAccess.READ)
	if BlueprintFile != null:
		if SettingsMenu.BrowserOption.selected != -1:
			var BrowserFlatpakLink = SettingsMenu.BrowserTable[str(SettingsMenu.BrowserOption.get_selected_id())]["Flatpak"]
			if SettingsMenu.FlatpakIsInstalled(BrowserFlatpakLink) == 0:
				var BlueprintText = BlueprintFile.get_as_text()
				if BlueprintText:	#Load the resolution/browser settings
					var ResolutionSize = get_viewport().get_visible_rect().size		#Set browser resolution to resolution of the application
					var ResolutionString = str(int(ResolutionSize.x)) + "," + str(int(ResolutionSize.y))
					var BlueprintTextFilled = BlueprintText.replace("<WindowSize>", ResolutionString).replace("<Browser>", BrowserFlatpakLink)
					var ConfFile = FileAccess.open(ScriptSettingsLocation, FileAccess.WRITE)
					if ConfFile:
						ConfFile.store_string(BlueprintTextFilled)
						ConfFile.close()
						return 0
					else:
						ShowErrorMessage("IO Error", "Unable to load the conf file at " + ScriptSettingsLocation)
				else:
					ShowErrorMessage("IO Error", "Unable to load the blueprint conf file at " + ConfBlueprintLocation)
			else:
				ShowErrorMessage("Flatpak Error", "Unable to find selected flatpak " + BrowserFlatpakLink)
		else:
			ShowErrorMessage("No Browser Error", "A browser must be selected from the drop down in the settings menu. If there are no options available in the drop down, then one needs to be installed.")
	BlueprintFile.close()
	return 1
	
func LoadVersion() -> void: #Loads the application version and sets it as the subtitle
	var VersionFile = FileAccess.open(VersionFileLocation, FileAccess.READ)
	if VersionFile != null:
		var VersionJSON = JSON.new() 
		if VersionJSON.parse(VersionFile.get_as_text()) == 0: 
			AppVersion.text = VersionJSON.data["Version"]
		else:
			ShowErrorMessage("IO Error", "Unable to load data from '" + VersionFileLocation + "'")
	else:
		ShowErrorMessage("IO Error", "Unable to open '" + VersionFileLocation + "'")

func ToggleMainButtonsDisabled(Toggle: bool) -> void: 	#Toggles the website links, settings, and power buttons
	for StreamingButton in ServicesBox.get_children():
		StreamingButton.disabled = Toggle
		StreamingButton.focus_mode = FOCUS_NONE if Toggle else FOCUS_ALL
	for ConfigButton in [PowerButton, UpdateButton, SettingButton]:
		ConfigButton.disabled = Toggle
		ConfigButton.focus_mode = FOCUS_NONE if Toggle else FOCUS_ALL
				
func FindAndKillAnyActiveSessions() -> void:	#Kills any active flatpak sessions of the currently set web browser (eg. kills all firefox instances)
	var TerminalOutput = [] 
	OS.execute("flatpak", ["ps"], TerminalOutput) 
	var RunningApplications = Array(TerminalOutput[0].split("\n"))
	RunningApplications.pop_back()	#Remove the last empty string
	for CurrentApp in RunningApplications:
		var CurrentAppStats = CurrentApp.split("\t")
		var CurrentApplicationType = CurrentAppStats.get(2)
		if CurrentApplicationType == SettingsMenu.BrowserTable[str(SettingsMenu.BrowserOption.selected)]["Flatpak"]:		
			OS.execute_with_pipe("flatpak", ["kill", CurrentAppStats[0]])		#If open browser session is matched with currently selected browser then close it
		
func UpdateClock() -> void:		#Setter function that updates the clock in the right of the application
	var CurrentTime = Time.get_time_dict_from_system()
	var Meridiem = ("AM" if CurrentTime.hour < 12 else "PM")
	var CurrentHour = CurrentTime.hour % 12 if (CurrentTime.hour % 12 != 0) else 12
	ClockLabel.text = "%2d:%02d %s" % [CurrentHour, CurrentTime.minute, Meridiem]
	
func DownloadLatestRelease() -> void:	#Sets the download file/location and makes an http request to download the file
	DownloadLatestGithubReleaseRequest.download_file = UpdateFile
	DownloadLatestGithubReleaseRequest.request(DownloadLink)
	await DownloadLatestGithubReleaseRequest.request_completed
	
func DownloadLatestReleaseCompleted(Result: int, ResponseCode: int, _Headers: PackedStringArray, _Body: PackedByteArray) -> void:
	if Result == FetchLatestGithubReleaseRequest.RESULT_SUCCESS && ResponseCode == 200: 
		ShowErrorMessage("Info", "Installing update ...")	
		var UpdateFileAbsolute = ProjectSettings.globalize_path(UpdateFile)
		OS.execute("unzip", ["-q", UpdateFileAbsolute])														#Use unzip package to unzip contents to the current directory
		OS.execute("rm", [UpdateFileAbsolute]) 																#Delete the zip file
		MoveUserFilesIfApplicable()
		ShowErrorMessage("Info", "Update complete. Please restart the application")		
	else:
		ShowErrorMessage("Error", "Update failed. Error code: " + str(ResponseCode))
	ErrorMenu.ToggleErrorMessageAcknowledge(false)

func FetchLatestRelease() -> void:
	FetchLatestGithubReleaseRequest.request(GithubLink)
	await FetchLatestGithubReleaseRequest.request_completed
		
func FetchLatestReleaseCompleted(Result: int, ResponseCode: int, _Headers: PackedStringArray, Body: PackedByteArray) -> void:
	if Result == FetchLatestGithubReleaseRequest.RESULT_SUCCESS && ResponseCode == 200: 
		var JSONDataObject = JSON.new()
		var DecodedBody = Body.get_string_from_utf8()
		if JSONDataObject.parse(DecodedBody) == 0:
			var JSONData = JSONDataObject.data
			DownloadLink = JSONData["assets"][0]["browser_download_url"]
			NewReleaseVersion = JSONData["tag_name"]
	else:
		ShowErrorMessage("Error", "Attempt to get latest update version failed. Error code: " + str(ResponseCode))
		ErrorMenu.ToggleErrorMessageAcknowledge(false)

func ShowSettingsMenu() -> void: 	#Toggles the settings menu 
	ToggleMainButtonsDisabled(true) 
	if PreviewImage.visible:
		LogoAnimations.play("Preview Fade Out")		
	SettingsAnimations.play("Settings Load")

func ShowErrorMessage(ErrorMessageType: String, ErrorMessageLabel: String) -> void:							#Toggle function for the error message pop up
	if ErrorMessageType != "Info":
		print(ErrorMessageType + " - " + ErrorMessageLabel)													#Log errors to console
	if !ErrorMenu.visible:	#Check if menu is already open
		if PreviewImage.visible:
			LogoAnimations.play("Preview Fade Out")	
		ToggleMainButtonsDisabled(true)
		ErrorMenu.UpdateErrorMessage(ErrorMessageType, ErrorMessageLabel)
		ErrorMenu.ErrorAnimations.play("Load In")
	else:
		ErrorMenu.UpdateErrorMessage(ErrorMessageType, ErrorMessageLabel)
		
func LoadWebBrowserApplication(ServiceType: String) -> void: 	#Loads a web browser and navigates to a given URL
	if LoadBashScriptSettings() == 0:	#If script settings successfully loaded, launch the browser
		FindAndKillAnyActiveSessions()
		var BrowserInstance = OS.execute_with_pipe("bash", [ProjectSettings.globalize_path(BuildType + "://Streaming/LaunchBrowser.sh"), StreamingLinks["Web Links"][ServiceType]])
		if BrowserInstance:
			if MenuSettings["AutoClose"]:
				_on_power_pressed()
		else:
			ShowErrorMessage("Program Error", "Unable to launch " + StreamingLinks["Web Links"][ServiceType])
					
func ReturnButtonFromType(Type: String) -> Button:	#Returns a UI button given a simple descriptor
	match Type:
		"AppleTV":
			return $MainGUI/OptionsBackground/OptionsBox/ServicesBox/AppleTV
		"Disney":
			return $MainGUI/OptionsBackground/OptionsBox/ServicesBox/Disney
		"HBOMax":
			return $MainGUI/OptionsBackground/OptionsBox/ServicesBox/HBOMax
		"Netflix":
			return $MainGUI/OptionsBackground/OptionsBox/ServicesBox/Netflix
		"Paramount":
			return $MainGUI/OptionsBackground/OptionsBox/ServicesBox/Paramount
		"PrimeVideo":
			return $MainGUI/OptionsBackground/OptionsBox/ServicesBox/Amazon
		"Youtube":
			return $MainGUI/OptionsBackground/OptionsBox/ServicesBox/Youtube
		"PeacockTV":
			return $MainGUI/OptionsBackground/OptionsBox/ServicesBox/Peacock
		"Tubi":
			return $MainGUI/OptionsBackground/OptionsBox/ServicesBox/Tubi
		"Power":
			return $MainGUI/OptionsBackground/OptionsBox/BottomMargin/ConfigBox/Power
		"Update":
			return $MainGUI/OptionsBackground/OptionsBox/BottomMargin/ConfigBox/UpdateControl/Update
		"Settings":
			return $MainGUI/OptionsBackground/OptionsBox/BottomMargin/ConfigBox/Settings
		_:
			return null
			
#Trigger Functions
func _ready() -> void:
	LoadArguments()
	LoadVersion()
	LoadStreamingLinks()
	MoveUserFilesIfApplicable()
	SettingsMenu.LoadSettings()
	FetchLatestGithubReleaseRequest.request_completed.connect(FetchLatestReleaseCompleted) 
	DownloadLatestGithubReleaseRequest.request_completed.connect(DownloadLatestReleaseCompleted)
	get_viewport().focus_entered.connect(_on_window_focus_in)
	get_viewport().focus_exited.connect(_on_window_focus_out)
	if Input.get_connected_joypads():													#Controller is connected
		DefaultButton.grab_focus()														#Grab focus on the first available option
	if CMDArguments.has("AutoLaunch") && CMDArguments["AutoLaunch"] != null:			#If a command line argument for autolaunch was loaded, load that service 
		_on_any_service_button_pressed(CMDArguments["AutoLaunch"])

func _on_window_focus_in() -> void:
	EnableUISoundsFocus = true
		
func _on_window_focus_out() -> void:
	EnableUISoundsFocus = false
			
func _on_button_focus_gained(ServiceType: String) -> void:
	var ServiceButtonEntered = ReturnButtonFromType(ServiceType)
	if ServiceButtonEntered != null && !ServiceButtonEntered.disabled:
		if MenuSettings["MenuSounds"] && EnableUISoundsFocus:
			MenuBlips.play()
		PreviewImage.texture = BackgroundImages.get_resource(ServiceType) 
		LogoAnimations.play("Preview Fade In")		
		
func _on_button_focus_lost(ServiceType: String) -> void:
	var ServiceButtonEntered = ReturnButtonFromType(ServiceType)
	if ServiceButtonEntered != null && !ServiceButtonEntered.disabled:
		LogoAnimations.play("Preview Fade Out")		
		
func _on_other_buttons_focus_gained() -> void:
	if MenuSettings["MenuSounds"] && EnableUISoundsFocus:
		MenuBlips.play()
				
func _on_mouse_entered_focus_toggle(ServiceType: String, Focus: bool) -> void:
	var ServiceButtonEntered = ReturnButtonFromType(ServiceType)
	if ServiceButtonEntered != null && !ServiceButtonEntered.disabled:
		if Focus:
			ServiceButtonEntered.grab_focus()
		else:
			ServiceButtonEntered.release_focus()
			
func _on_any_service_button_pressed(ServiceType: String) -> void:
	LoadWebBrowserApplication(ServiceType)

func _on_settings_pressed() -> void:
	ShowSettingsMenu()
	SettingsMenu.ToggleAllElementsFocusDisabled(false)
	SettingsMenu.ToggleSaveButton()
	if Input.get_connected_joypads():	#Controller is connected
		SettingsMenu.BackButton.grab_focus()

func _on_update_pressed() -> void:
	if !UpdateButton.disabled:
		ToggleMainButtonsDisabled(true) 
		await FetchLatestRelease()
		if NewReleaseVersion > AppVersion.text:		#Update found, download and install update
			ShowErrorMessage("Info", "Update " + NewReleaseVersion + " found. Downloading ...")
			ErrorMenu.ToggleErrorMessageAcknowledge(true)
			await DownloadLatestRelease()
		elif NewReleaseVersion == AppVersion.text:	#Update version is the same, no update necessary
			ShowErrorMessage("Info", "Application is up to date")
		else:
			ShowErrorMessage("Error", "Version is newer than latest release")
		
func _on_clock_updates_timeout() -> void:
	UpdateClock()

func _on_power_pressed() -> void:
	get_tree().quit()
