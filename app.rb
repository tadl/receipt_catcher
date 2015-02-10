require 'sinatra'
require 'sinatra/multi_route'
require 'json'
require 'cupsffi'
require 'imgkit'
require 'fastimage'

route :get, :post, '/' do
	content_type :json
	if params[:title] && params[:shelving_location] && params[:call_number]
		printers = CupsPrinter.get_all_printer_names
		# Need way to map OPAC location to priner perhaps by name or device-uri but for now hard coding
		receipt_printer = CupsPrinter.new(printers[1])
		title = '<span class="title">'+ params[:title] +'</span><br>'
		if params[:author]
			author = '<span class="author">-'+ params[:author] +'</span></br>'
		else
			author = ''
		end
		shelving_location = '<span class="location">'+ params[:shelving_location] +' '+ params[:call_number] +'</span>'
		working_directory = Dir.pwd 
		item = title + author + shelving_location
		html_content = '<html><body><head><link rel="stylesheet" type="text/css" href="'+ working_directory +'/style.css"></head><center><img src="'+ working_directory +'/logo.png" width="170px"></center>' + item + '</body></html>'
		html_file = Tempfile.new(['html_content', '.html'])
		image_file = Tempfile.new(['image', '.jpg'])
		File.open(html_file.path, 'w') { |file| file.write(html_content) }
		image = IMGKit.new(File.new(html_file.path), :quality => 100, :width => 210)
		file = image.to_file(image_file.path)
		dimensions = FastImage.size(image_file.path)
		pagesize = 'Custom.300x' + dimensions[1].to_s
		job = receipt_printer.print_file(image_file.path,{'PageSize' => pagesize})
		message = {:message => 'Correct parameters'}	
	else
		message = {:message => 'Error. Incomplete parameters'}
	end
	html_file.unlink
	image_file.unlink
	return message.to_json

end