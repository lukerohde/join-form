class FilesController < ApplicationController
	# this is pretty dreadful
  def get
    file_path = "#{Rails.root}/public/#{params[:filename]}.#{params[:format]}"
    send_file file_path, :filename => "#{params[:filename]}.#{params[:format]}", :disposition => 'attachment'
  end

end