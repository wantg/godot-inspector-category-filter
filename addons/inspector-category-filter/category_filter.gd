class_name CategoryFilter

var base_control: Control = EditorInterface.get_base_control()
var inspector: EditorInspector = EditorInterface.get_inspector()
var category_filter_container: ScrollContainer
var activated_category_color = Color("#70bafa")
var state = {}
var simple_inspector_plugin

func init(simple_inspector_plugin_: SimpleInspectorPlugin):
	self.simple_inspector_plugin = simple_inspector_plugin_
	inspector.edited_object_changed.connect(on_inspector_edited_object_changed)
	inspector.sort_children.connect(on_inspector_sort_children)

	category_filter_container = ScrollContainer.new()
	category_filter_container.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	category_filter_container.set_custom_minimum_size(Vector2(0, 38.5))
	var category_filter = HBoxContainer.new()
	category_filter.size_flags_horizontal = Control.SIZE_SHRINK_END | Control.SIZE_EXPAND
	category_filter.alignment = BoxContainer.ALIGNMENT_END
	category_filter_container.add_child(category_filter)
	inspector.get_parent().get_child(inspector.get_index() - 1).add_sibling(category_filter_container)

func exit():
	category_filter_container.queue_free()

func on_inspector_edited_object_changed():
	var category_filter = category_filter_container.get_child(0)
	for i in category_filter.get_children(): category_filter.remove_child(i)
	if inspector.get_edited_object() == null: return

	for cls_name in simple_inspector_plugin.categories:
		var icon_name = cls_name
		if cls_name.ends_with(".gd"):
			icon_name = "GDScript"
		elif !cls_name in ["CanvasItem"] && ClassDB.class_exists(cls_name) && !ClassDB.can_instantiate(cls_name):
			icon_name = "NodeDisabled"
		elif ClassDB.is_parent_class(cls_name, "Resource") || cls_name == "RefCounted":
			icon_name = "Object"
		var button = Button.new()
		button.icon = base_control.get_theme_icon(icon_name, "EditorIcons")
		button.set_meta("category", cls_name)
		button.set_meta("activated", false)
		button.text = cls_name
		button.auto_translate = false
		button.focus_mode = Control.FocusMode.FOCUS_NONE
		button.pressed.connect(on_category_filter_button_pressed.bind(button))
		category_filter.add_child(button)

	show_filtered_category()

func on_inspector_sort_children():
	show_filtered_category()

func on_category_filter_button_pressed(button: Button):
	var category_filter = category_filter_container.get_child(0)
	var inspector_edited_object = inspector.get_edited_object()
	for i in category_filter.get_children():
		if i.get_meta("category") == button.get_meta("category"):
			if i.get_meta("activated"):
				state[inspector_edited_object] = {"activated": null}
			else:
				state[inspector_edited_object] = {"activated": button.get_meta("category")}
	show_filtered_category()

func show_filtered_category():
	var category_filter = category_filter_container.get_child(0)
	var inspector_edited_object = inspector.get_edited_object()
	if !state.has(inspector_edited_object): return

	var activated_category_name = state[inspector_edited_object]["activated"]
	for button in category_filter.get_children():
		if button.get_meta("category") == activated_category_name:
			button.set_meta("activated", true)
			button.add_theme_color_override("font_color", activated_category_color)
			button.add_theme_color_override("font_hover_color", activated_category_color)
		else:
			button.set_meta("activated", false)
			button.remove_theme_color_override("font_color")
			button.remove_theme_color_override("font_hover_color")

	var category_dict = {}

	var inspector_categories = inspector.find_children("*", "EditorInspectorCategory", true, false).filter(
		func(i): return i.get("tooltip_text").length() > 0
	)
	for category_idx in inspector_categories.size():
		var category_node = inspector_categories[category_idx]
		var cls_name = simple_inspector_plugin.categories[category_idx]
		category_node.set_meta("category", cls_name)
		category_dict[category_node] = []
		for sibling in category_node.get_parent().get_children():
			if sibling.get_index() <= category_node.get_index():
				continue
			if sibling.is_class("EditorInspectorCategory"):
				break
			category_dict[category_node].append(sibling)

	for category_node in category_dict:
		var visible = activated_category_name == null || category_node.get_meta("category") == activated_category_name
		category_node.visible = visible
		for section_node in category_dict[category_node]:
			section_node.visible = visible
