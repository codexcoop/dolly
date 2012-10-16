class PdfMetadata

  def self.get_from_file(path)
    if File.exist?(path) and File.file?(path)
      metadata_array = []
      metadata_string = `pdfinfo #{path.to_s}`
      metadata_string.each_line do |line|
        metadata_array << [line.split(':')[0].strip, line.split(':')[1..-1].join(':').strip]
      end
      Hash[*metadata_array.flatten]
    else
      raise IOError, %Q{Can't find file "#{path}"}
    end

  end

end

