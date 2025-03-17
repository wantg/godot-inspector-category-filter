@tool
extends EditorPlugin

var editor_inspector: EditorInspector
var category_filter_container: ScrollContainer
var activated_category_color = Color("#70bafa")
var category_dict = {}
var state = {}

func _enter_tree():
	var inspector_container = get_editor_interface().get_inspector().get_parent()

	editor_inspector = (inspector_container.get_child(6) as EditorInspector)
	editor_inspector.edited_object_changed.connect(on_editor_inspector_edited_object_changed)

	category_filter_container = ScrollContainer.new()
	category_filter_container.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	var category_filter = HBoxContainer.new()
	category_filter.size_flags_horizontal = Control.SIZE_SHRINK_END | Control.SIZE_EXPAND
	category_filter.alignment = BoxContainer.ALIGNMENT_END
	category_filter_container.add_child(category_filter)
	(inspector_container.get_child(2) as HBoxContainer).add_sibling(category_filter_container)
	category_filter_container.set_custom_minimum_size(Vector2(0, 38.5))

func _exit_tree():
	category_filter_container.queue_free()

func on_editor_inspector_edited_object_changed():
	var category_filter = category_filter_container.get_child(0)
	for i in category_filter.get_children(): category_filter.remove_child(i)
	category_dict.clear()

	var editor_inspector_categories = editor_inspector.find_children("*", "EditorInspectorCategory", true, false)
	for category_node in editor_inspector_categories:
		if (category_node.get("tooltip_text") as String).contains("|"):
			var cls_name = (category_node.get("tooltip_text") as String).split("|")[1].split("|")[0]
			category_node.set_meta("category", cls_name)

			var button = Button.new()
			button.set_meta("category", cls_name)
			button.set_meta("activated", false)
			button.text = cls_name
			button.auto_translate = false
			button.focus_mode = Control.FocusMode.FOCUS_NONE
			button.pressed.connect(on_category_filter_button_pressed.bind(button))
			category_filter.add_child(button)

			category_dict[category_node] = []
			for sibling in category_node.get_parent().get_children():
				if sibling.get_index() <= category_node.get_index():
					continue
				if sibling.is_class("EditorInspectorCategory"):
					break
				category_dict[category_node].append(sibling)

	show_filtered_category()

func on_category_filter_button_pressed(button: Button):
	var category_filter = category_filter_container.get_child(0)
	var editor_inspector_edited_object = editor_inspector.get_edited_object()
	for i in category_filter.get_children():
		if i.get_meta("category") == button.get_meta("category"):
			if i.get_meta("activated"):
				state[editor_inspector_edited_object] = {"activated": null}
			else:
				state[editor_inspector_edited_object] = {"activated": button.get_meta("category")}
	show_filtered_category()

func show_filtered_category():
	var category_filter = category_filter_container.get_child(0)
	var editor_inspector_edited_object = editor_inspector.get_edited_object()
	if !state.has(editor_inspector_edited_object): return

	var activated_category_name = state[editor_inspector_edited_object]["activated"]
	for button in category_filter.get_children():
		if button.get_meta("category") == activated_category_name:
			button.set_meta("activated", true)
			button.add_theme_color_override("font_color", activated_category_color)
			button.add_theme_color_override("font_hover_color", activated_category_color)
		else:
			button.set_meta("activated", false)
			button.remove_theme_color_override("font_color")
			button.remove_theme_color_override("font_hover_color")

	for category_node in category_dict:
		var visible = activated_category_name == null || category_node.get_meta("category") == activated_category_name
		category_node.visible = visible
		for section_node in category_dict[category_node]:
			section_node.visible = visible
