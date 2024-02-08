extends Node

signal send_event_successful
signal send_event_failed

var API_KEY := ""

const ENDPOINT := "https://app.posthog.com/capture/"
enum SendType { SINGLE, BATCH }

var sender: HTTPRequest

var request_queue = []

const API_KEY_NAME := "api_key"
const EVENT_KEY := "event"
const TYPE_KEY := "type"
const TIMESTAMP_KEY := "timestamp"
const DISTINCT_ID_KEY := "distinct_id"
const PROPERTIES_KEY := "properties"
const BATCH_KEY := "batch"

var SINGLE_EVENT_BODY = {
	API_KEY_NAME : "",
	EVENT_KEY : "",
	PROPERTIES_KEY : {
		DISTINCT_ID_KEY : ""
	   },
	TIMESTAMP_KEY : null
   }

var BATCH_EVENT_BODY = {
	API_KEY_NAME : "",
	BATCH_KEY : []
   }

func _ready() -> void:
	sender = HTTPRequest.new()
	add_child(sender)
	sender.request_completed.connect(_on_send_event_request_complete)
	
	if ProjectSettings.has_setting("global/posthog_api_key"):
		API_KEY = ProjectSettings.get_setting("global/posthog_api_key")
		SINGLE_EVENT_BODY[API_KEY_NAME] = API_KEY
		BATCH_EVENT_BODY[API_KEY_NAME] = API_KEY
	

# Send a single event to the Mixpanel service
func send_event(event : PostHogEvent) -> void:
	var json := JSON.new()
	var dupe := JSON.stringify(get_formatted_single_event(event))
	
	if sender.get_http_client_status() == HTTPClient.STATUS_DISCONNECTED:
		sender.request(ENDPOINT, PackedStringArray(), HTTPClient.METHOD_POST, dupe)
	else:
		request_queue.push_back({EVENT_KEY: event, TYPE_KEY: SendType.SINGLE})

# Ensure everything in batched_events is of type PostHogEvent
func send_event_batch(batched_events : Array) -> void:
	var dupe := BATCH_EVENT_BODY.duplicate(true)
	for event in batched_events:
		var formatted_event = get_formatted_batch_event(event)
		dupe.batch.push_back(formatted_event)
	
	var json := JSON.new()
	var to_push = JSON.stringify(dupe)
	
	if sender.get_http_client_status() == HTTPClient.STATUS_DISCONNECTED:
		sender.request(ENDPOINT, PackedStringArray(), HTTPClient.METHOD_POST, to_push)
	else:
		request_queue.push_back({EVENT_KEY: batched_events, TYPE_KEY: SendType.BATCH})

func get_formatted_single_event(event : PostHogEvent) -> Dictionary:
	var dupe = SINGLE_EVENT_BODY.duplicate(true)
	dupe.event = event.event_name
	dupe.properties = event.properties
	dupe.properties[DISTINCT_ID_KEY] = event.distinct_id
	
	if !event.timestamp:
		dupe.erase(TIMESTAMP_KEY)
	
	return dupe
	
func get_formatted_batch_event(event : PostHogEvent) -> String:
	var result = get_formatted_single_event(event)
	result.erase(API_KEY_NAME)
	return result
	
func _on_send_event_request_complete(result, response_code, headers, body):
	if response_code == HTTPClient.RESPONSE_OK:
		send_event_successful.emit()
	else:
		send_event_failed.emit()
	
	if request_queue.size() > 0:
		var request = request_queue[0]
		var event = request[EVENT_KEY]
		var type = request[TYPE_KEY]
		if type == SendType.SINGLE:
			send_event(event)
		elif type == SendType.BATCH: # Since we can't be sure what type is, ensure it's something correct rather than blanket else
			send_event_batch(event)
			
		request_queue.remove_at(0)
