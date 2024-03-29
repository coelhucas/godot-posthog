# Godot PostHog

Integration of PostHog API for Godot 4.X
Made on top of [@WolfgangSenff](https://github.com/WolfgangSenff)'s [PostHogPlugin](https://github.com/WolfgangSenff/KylesGodotPlugins/blob/master/PostHogPlugin/)

## Usage

Put `posthog/` folder inside `res://addons/`

Once the plugin is added, your project will get a new global setting, `Posthog API Key`
![image](https://github.com/WolfgangSenff/KylesGodotPlugins/assets/28108272/e5a277dd-9490-49ec-b2f5-8e4d6e16737f)

Set it to your API Key and then you'll be able to send your events as follows:
```gdscript
var _ev := PostHogEvent.new()
_ev.event_name = "Your event name"
_ev.distinct_id = "an unique identifier"
_ev.properties = { "some_key": "a value", "another_key": "value" }

PostHog.send_event(_ev)
```

A `timestamp` is optional, will be set to the server one if none is sent.

An example of a custom event send to their analytics dashboard:

![image](https://github.com/coelhucas/godot-posthog/assets/28108272/98da1a88-159a-46b3-a04c-a633226922aa)

