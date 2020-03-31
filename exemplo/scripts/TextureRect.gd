tool
extends TextureRect

var http = HTTPRequest.new()
var progress_texture = TextureProgress.new()
var file_name = ""
var file_ext = ""

export(bool) var previewImage = false setget _setPreviewImage
export(bool) var progressbar = true setget _setProgressbar
export(Rect2) var progressbarRect = Rect2(0,0,0,0)
export var textureUrl = "http://" setget _setTextureUrl
export(Color) var progressbarColor = Color.red

signal loaded(image)
signal progress(percent)

func _setProgressbar(newValue):
	progressbar = newValue

func _setTextureUrl(newValue):
	textureUrl = newValue
	if previewImage:
		setFileName()
	
func _setPreviewImage(newValue):
	previewImage = newValue
	if previewImage:
		
		if !has_node("http"):
			http.connect("request_completed", self, "_on_HTTPRequest_request_completed")
			add_child(http)
		
		setFileName()

func setFileName():
	var spl = textureUrl.split("/")
	file_name = spl[spl.size()-1]
	
	var file_name_stripped = file_name.split("?")[0]
	var ext = file_name_stripped.split(".")
	file_ext = ext[ext.size()-1].to_lower()
	
	if file_ext != "":
		_downloadImage()
	
func _downloadImage():
	if textureUrl != "":
		http.request(textureUrl)

func _ready():
	_adjustProgress()
	
	http.connect("request_completed", self, "_on_HTTPRequest_request_completed")
	add_child(http)
	
	set_process(true)
	setFileName()

func _adjustProgress():
	if progressbar:
		add_child(progress_texture)
		progress_texture.texture_progress = load("res://addon/textureRectUrl/rect.png")
		progress_texture.tint_progress = progressbarColor
		progress_texture.set("visible", progressbar)
		progress_texture.value = 0
		
		if progressbarRect.size.x == 0:
			progress_texture.rect_size.x = rect_size.x
		else:
			progress_texture.rect_size.x = progressbarRect.size.x
			
		if progressbarRect.size.y == 0:
			progress_texture.rect_size.y = rect_size.y
		else:
			progress_texture.rect_size.y = progressbarRect.size.y
			
		if progressbarRect.position.x == 0:
			progress_texture.rect_position.x = 0
		else:
			progress_texture.rect_position.x = progressbarRect.position.x
			
		if progressbarRect.position.y == 0:
			progress_texture.rect_position.y = 0
		else:
			progress_texture.rect_position.y = progressbarRect.position.y

func _on_HTTPRequest_request_completed(result, response_code, headers, body):
	if response_code == 200:
		var image = Image.new()
		var image_error = null
		
		if file_ext == "png":
			image_error = image.load_png_from_buffer(body)
		elif file_ext == "jpg" or file_ext == "jpeg":
			image_error = image.load_jpg_from_buffer(body)
		elif file_ext == "webp":
			image_error = image.load_webp_from_buffer(body)
			
		if image_error != OK:
			set_process(false)
			# An error occurred while trying to display the image
			return
	
		var _texture = ImageTexture.new()
		_texture.create_from_image(image)
		
		emit_signal("loaded", image)
	
		# Assign a downloaded texture
		texture = _texture

func _process(delta):
	# show progressbar
	var bodySize = http.get_body_size()
	var downloadedBytes = http.get_downloaded_bytes()
	var percent = int(downloadedBytes * 100 / bodySize)
	
	emit_signal("progress", percent)
	
	if progressbar:
		progress_texture.value = percent
		
	if percent == 100:
		if progressbar:
			progress_texture.hide()
		set_process(false)
