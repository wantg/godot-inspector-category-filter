class_name SimpleInspectorPlugin extends EditorInspectorPlugin

var inspector = EditorInterface.get_inspector()
var categories = []

func _can_handle(object):
	return object == inspector.get_edited_object()

func _parse_begin(object: Object) -> void:
	categories = []

func _parse_category(object: Object, category: String) -> void:
	categories.append(category)
