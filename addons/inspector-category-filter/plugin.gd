@tool
extends EditorPlugin

var simple_inspector_plugin = SimpleInspectorPlugin.new()
var category_filter = CategoryFilter.new()

func _enter_tree():
	add_inspector_plugin(simple_inspector_plugin)
	category_filter.init(simple_inspector_plugin)

func _exit_tree():
	category_filter.exit()
