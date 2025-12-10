extends Control

#Node Variables
@onready var SettingsMenu: Control = $MainGUI/SettingsScene
@onready var YoutubeMenu: Control = $YoutubeSelectionScene
@onready var ErrorMenu: Control = $ErrorScene
@onready var FetchLatestGithubReleaseRequest: HTTPRequest = $FetchLatestGithubRelease
@onready var DownloadLatestGithubReleaseRequest: HTTPRequest = $DownloadLatestGithubRelease
@onready var AppVersion: Label = $MainGUI/OptionsBackground/OptionsBox/TopMargin/TitleBox/AppVersion
@onready var ClockLabel: Label = $ClockMarginContainer/ClockLabel
@onready var ServicesBox: VBoxContainer = $MainGUI/OptionsBackground/OptionsBox/ServicesBox
@onready var ConfigBox: HBoxContainer = $MainGUI/OptionsBackground/OptionsBox/BottomMargin/ConfigBox
@onready var MenuSounds: AudioStreamPlayer = $MenuSounds
@onready var SettingsAnimations: AnimationPlayer = $SettingsAnimations
@onready var LogoAnimations: AnimationPlayer = $LogoAnimations
@onready var PreviewImage: TextureRect = $PreviewImage
@onready var BackgroundImages: ResourcePreloader = $PreloadedImages
@onready var DefaultButton: Button = $MainGUI/OptionsBackground/OptionsBox/ServicesBox/Amazon
@onready var DefaultButtonBack: TextureButton = $MainGUI/OptionsBackground/OptionsBox/BottomMargin/ConfigBox/Settings
@onready var UpdateButton: TextureButton = $MainGUI/OptionsBackground/OptionsBox/BottomMargin/ConfigBox/Update

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
var SettingsToggle = true
var StreamingLinks = {}
var CMDArguments = {}
var MenuSettings = {}
var DownloadLink = ""
var NewReleaseVersion = ""

	
#Custom Functions	
func DetermineDebugging() -> String:	#Determines if the project is compiled and sets paths depending on whether it is or not for debugging purposes
	var CurrentPath = OS.get_executable_path().get_base_dir()
	if DirAccess.dir_exists_absolute(CurrentPath + "/Streaming/"):
		return "user"
	return "res"

func MoveUserFilesIfApplicable() -> void: 	#Move the streaming folder to an accessable user directory in .local, if necessary
	if BuildType == "user":
		CopyDirectory(ExecutableDirectory + "/Streaming/", BuildType + "://Streaming/")
			
func CopyDirectory(Source: String, Destination: String) -> void:	#Copies the 'Streaming' directory to the accessable user directory in .local
	DirAccess.make_dir_recursive_absolute(Destination)
	var SourceDir = DirAccess.open(Source)
	for Directory in SourceDir.get_directories():
		CopyDirectory(Source + Directory + "/", Destination + Directory + "/")	
	for Filename in SourceDir.get_files():
		print(Source + Filename)
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
				ShowErrorMessage("Program Error", "Unable to find selected flatpak " + BrowserFlatpakLink)
		else:
			ShowErrorMessage("Browser Error", "Unable to find one of the following browsers (Flatpak): Firefox, Google Chrome, Librewolf, Microsoft Edge, Opera")
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
	SettingsToggle = !Toggle
	for StreamingButton in ServicesBox.get_children():
		StreamingButton.disabled = Toggle
		StreamingButton.focus_mode = FOCUS_NONE if Toggle else FOCUS_ALL
	for ConfigButton in ConfigBox.get_children():
		ConfigButton.disabled = Toggle
		ConfigButton.focus_mode = FOCUS_NONE if Toggle else FOCUS_ALL
		
func ToggleSettingsMenu(Toggle: bool) -> void: 	#Toggles the settings menu 
	if Toggle:
		SettingsMenu.visible = Toggle
		SettingsAnimations.play("Settings Load")
	else:
		SettingsAnimations.play("Settings Load Out")
		
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
	
func DownloadLatestReleaseComplete(Result: int, ResponseCode: int, _Headers: PackedStringArray, _Body: PackedByteArray) -> void:
	if Result == FetchLatestGithubReleaseRequest.RESULT_SUCCESS && ResponseCode == 200: 
		var UpdateFileAbsolute = ProjectSettings.globalize_path(UpdateFile)
		OS.execute("ark", ["--batch", UpdateFileAbsolute])																			#Unzip the contents of the download to a folder in the directory
		OS.execute("rm", [UpdateFileAbsolute]) 						#Delete the zip file
		OS.execute("rm", ["-r", ProjectSettings.globalize_path("res://Streaming.Services.App") + "/"])			#Delete the Unzipped directory
		MoveUserFilesIfApplicable()

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
		 
func ShowErrorMessage(ErrorMessageType: String, ErrorMessageLabel: String) -> void:	#Toggle function for the error message pop up
	ToggleMainButtonsDisabled(true)
	#if YoutubeMenu.visible:	???
		#YoutubeMenu._on_back_button_pressed()
	ErrorMenu.visible = true
	ErrorMenu.UpdateErrorMessage(ErrorMessageType, ErrorMessageLabel)
	ErrorMenu.ErrorAnimations.play("Load In")
	
func ShowYoutubeSelection() -> void:	#Toggle function for the youtube selection pop up
	ToggleMainButtonsDisabled(true)
	YoutubeMenu.visible = true
	YoutubeMenu.YoutubeAnimations.play("Load In")
	
func LoadWebBrowserApplication(ServiceType: String) -> void: 	#Loads a web browser and navigates to a given URL
	if LoadBashScriptSettings() == 0:	#If script settings successfully loaded, launch the browser
		FindAndKillAnyActiveSessions()
		var BrowserInstance = OS.execute_with_pipe("bash", [ProjectSettings.globalize_path(BuildType + "://Streaming/LaunchBrowser.sh"), StreamingLinks["Web Links"][ServiceType]])
		if BrowserInstance:
			if MenuSettings["AutoClose"]:
				_on_power_pressed()
		else:
			ShowErrorMessage("Program Error", "Unable to launch " + StreamingLinks["Web Links"][ServiceType])
			
func LoadOtherApplication(ApplicationType) -> void:	#Loads a given flatpak application
	match ApplicationType:
		"Freetube":
			if SettingsMenu.FlatpakIsInstalled(StreamingLinks["Flatpaks"][ApplicationType]) == 0:
				var ApplicationInstance = OS.create_process("flatpak", ["run", StreamingLinks["Flatpaks"][ApplicationType]])
				if ApplicationInstance:
					if MenuSettings["AutoClose"]:
						_on_power_pressed()
				else:
					ShowErrorMessage("Program Error", "Unable to launch " + StreamingLinks["Flatpaks"][ApplicationType])
			else:
				ShowErrorMessage("Program Error", "Unable to find selected flatpak " + StreamingLinks["Flatpaks"][ApplicationType])
		_:
			pass
		
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
		"Power":
			return $MainGUI/OptionsBackground/OptionsBox/BottomMargin/ConfigBox/Power
		"Update":
			return $MainGUI/OptionsBackground/OptionsBox/BottomMargin/ConfigBox/Update
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
	if CMDArguments.has("AutoLaunch") && CMDArguments["AutoLaunch"] != null:			#If a command line argument for autolaunch was loaded, load that service 
		_on_any_service_button_pressed(CMDArguments["AutoLaunch"])
	if Input.get_connected_joypads():													#Controller is connected
		DefaultButton.grab_focus()														#Grab focus on the first available option
	FetchLatestGithubReleaseRequest.request_completed.connect(FetchLatestReleaseCompleted) 
	DownloadLatestGithubReleaseRequest.request_completed.connect(DownloadLatestReleaseComplete)
	
func _process(_delta: float):
	UpdateClock()
	await get_tree().create_timer(1.0).timeout 		#Check every second instead of every frame
		
func _on_button_focus_gained(ServiceType: String) -> void:
	var ServiceButtonEntered = ReturnButtonFromType(ServiceType)
	if ServiceButtonEntered != null && !ServiceButtonEntered.disabled:
		if MenuSettings["MenuSounds"]:
			MenuSounds.play()
		PreviewImage.texture = BackgroundImages.get_resource(ServiceType) 
		LogoAnimations.play("Preview Fade In")		
		
func _on_button_focus_lost(ServiceType: String) -> void:
	var ServiceButtonEntered = ReturnButtonFromType(ServiceType)
	if ServiceButtonEntered != null && !ServiceButtonEntered.disabled:
		LogoAnimations.play("Preview Fade Out")		
		
func _on_other_buttons_focus_gained() -> void:
	if MenuSettings["MenuSounds"]:
		MenuSounds.play()
				
func _on_mouse_entered_focus_toggle(ServiceType: String, Focus: bool) -> void:
	var ServiceButtonEntered = ReturnButtonFromType(ServiceType)
	if ServiceButtonEntered != null && !ServiceButtonEntered.disabled:
		if Focus:
			ServiceButtonEntered.grab_focus()
		else:
			ServiceButtonEntered.release_focus()
			
func _on_any_service_button_pressed(ServiceType: String) -> void:
	if ServiceType != "YoutubeSelection":
		LoadWebBrowserApplication(ServiceType)
	else:
		ShowYoutubeSelection()

func _on_settings_pressed() -> void:
	ToggleMainButtonsDisabled(SettingsToggle) 
	ToggleSettingsMenu(!SettingsToggle)
	SettingsMenu.ToggleAllElementsFocusDisabled(SettingsToggle)
	SettingsMenu.ToggleSaveButton()
	if Input.get_connected_joypads():	#Controller is connected
		SettingsMenu.BackButton.grab_focus()

func _on_update_pressed() -> void:
	if !UpdateButton.disabled:
		ToggleMainButtonsDisabled(true) 
		await FetchLatestRelease()
		if NewReleaseVersion > AppVersion.text:
			ShowErrorMessage("Info", "Update " + NewReleaseVersion + " found. Downloading ...")
			await DownloadLatestRelease()
		else:
			ShowErrorMessage("Info", "Application is up to date")
		
func _on_power_pressed() -> void:
	get_tree().quit()
