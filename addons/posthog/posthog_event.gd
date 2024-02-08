extends Resource
class_name PostHogEvent

# The name of the event you want to record
@export var event_name: String
# The user's distinct ID
@export var distinct_id: String
# The properties to record
@export var properties: Dictionary

# Optional timestamp; if not supplied, it is supplied by the server
@export var timestamp: String
