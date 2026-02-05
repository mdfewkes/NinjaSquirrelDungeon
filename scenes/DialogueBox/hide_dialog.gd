extends RichTextLabel

func _process(delta) ->void:
	if text.is_empty():
		hide()
	else:
		show()
