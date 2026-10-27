extends SceneTree
## Zips build/web into build/unbroken_sky_web.zip for upload to itch.io.
##   godot --headless --path . --script res://tools/zip_web.gd

func _init() -> void:
	var source := ProjectSettings.globalize_path("res://build/web/")
	var target := ProjectSettings.globalize_path("res://build/unbroken_sky_web.zip")
	var zip := ZIPPacker.new()
	if zip.open(target) != OK:
		push_error("Cannot write %s" % target)
		quit(1)
		return
	var count := 0
	for file_name in DirAccess.get_files_at(source):
		zip.start_file(file_name)
		zip.write_file(FileAccess.get_file_as_bytes(source + file_name))
		zip.close_file()
		count += 1
	zip.close()
	print("zipped %d files into %s" % [count, target])
	quit(0 if count > 0 else 1)
