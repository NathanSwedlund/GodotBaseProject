extends Label

export var char_per_second = 30 # set equal to -1 to make the text instantly appear
export (Array, int) var char_per_second_overrides
export (Array, String, MULTILINE) var dialogue_strings
export (Array, String, "Replace", "Append", "Replace W/O Acknowledgement", "Append W/O Acknowledgement") var dialogue_behavior_overrides
export var current_char = 0
export var current_dialogue_string = 0

export var acknowledge_input = "ui_accept"
export var speed_up_input = "ui_accept"
export var play_sound_on_whitespace = false
export var slow_on_periods = true
export var slowness_scale_on_periods = 6.0

export (AudioStream) var typing_sound
export (float, -80.0, 24.0, 0.0) var typing_vol_db
export (float, 0.0, 4.0, 0.0) var typing_pitch = 1.0
export (Array, float, -80.0, 24.0, 0.0) var typing_vol_db_overrides
export (Array, float, 0.0, 4.0, 0.0) var typing_pitch_overrides
export (Array, AudioStream) var typing_sounds_override

signal dialogue_complete()

# Called when the node enters the scene tree for the first time.
func _ready():
	$TypingSound.stream = typing_sound
	$TypingSound.volume_db = typing_vol_db
	$TypingSound.pitch_scale = typing_pitch

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if(current_dialogue_string >= len(dialogue_strings)):
		emit_signal("dialogue_complete")
		return
	
	type_dialogue(delta)
	if(current_char == len(dialogue_strings[current_dialogue_string])):
		if(Input.is_action_just_pressed(acknowledge_input)):
			continue_to_next_dialogue()
		else:	
			var behavior = get_override_if_exists(dialogue_behavior_overrides, "", current_dialogue_string+1)
			if(behavior != null and "W/O Acknowledgement" in behavior):
				continue_to_next_dialogue()
				
			

func continue_to_next_dialogue():
	current_dialogue_string += 1
	current_char = 0
	
	var behavior = get_override_if_exists(dialogue_behavior_overrides, "")
	if(behavior == null or "Replace" in behavior):
		text = ""
		
var time_since_last_char = 0.0
func type_dialogue(delta):
	if(current_dialogue_string >= len(dialogue_strings) or current_char == len(dialogue_strings[current_dialogue_string])):
		return
		
	time_since_last_char += delta
	var time_limit_denom = get_override_if_exists(char_per_second_overrides, 0)
	if(time_limit_denom == null):
		time_limit_denom = char_per_second
	
	var next_char = dialogue_strings[current_dialogue_string][current_char]
	
	if( (next_char != "." and time_since_last_char > 1.0/time_limit_denom) or
		(next_char == "." and time_since_last_char > slowness_scale_on_periods/time_limit_denom)):
		time_since_last_char = 0.0
		type_character()
			
func type_character():
	var next_char = dialogue_strings[current_dialogue_string][current_char]
	text += next_char
	current_char += 1
	
	# Prints 2 chars at a time when sped up
	if(Input.is_action_pressed(speed_up_input) and text != dialogue_strings[current_dialogue_string]):
		next_char = dialogue_strings[current_dialogue_string][current_char]
		text += next_char
		current_char += 1
	
	var pitch_override = get_override_if_exists(typing_pitch_overrides, 0)
	if(pitch_override != null):
		$TypingSound.pitch_scale = pitch_override
	elif($TypingSound.pitch_scale != typing_pitch):
		$TypingSound.pitch_scale = typing_pitch
		
	var volume_override = get_override_if_exists(typing_vol_db_overrides, 0)
	if(volume_override != null):
		$TypingSound.volume_db = volume_override
	elif($TypingSound.volume_db != typing_vol_db):
		$TypingSound.volume_db = typing_vol_db
		
	var sound_override = get_override_if_exists(typing_sounds_override, null)
	print(sound_override)
	print($TypingSound.stream)
	
	if(sound_override != null):
		if($TypingSound.stream != sound_override):
			$TypingSound.stream = sound_override
	elif($TypingSound.stream != typing_sound):
		$TypingSound.stream = typing_sound
		
	if(play_sound_on_whitespace == true or (next_char in [" ", "\t", "\n"]) == false):
		$TypingSound.play()

func get_override_if_exists(override_array, default_val=0, index=-1):
	# default value for index is current_dialogue_string
	if(index == -1):
		index = current_dialogue_string
		
	if(index >= len(override_array)):
		return null
	if(override_array[index] == default_val):
		return null
	
	return override_array[index]
