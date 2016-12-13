class LogoUploader < AttachmentUploader
  include CarrierWave::MiniMagick
  # Create different versions of your uploaded files:

  # Process files as they are uploaded:
  process resize_to_limit: [400, 10000]
  process quality: 100

  version :thumb do
    process resize_and_pad: [80,80]
  end

  def filename
    if original_filename.present?
      "#{secure_token}.#{file.extension}"
    end
  end
  
  def extension_white_list
    %w(jpg jpeg gif png)
  end
end
