require 'pdf/reader'

class PdfMetadataReceiver
  attr_accessor :technical_metadata

  def metadata(data)
    @technical_metadata = data
  end

end

#receiver = PdfMetadataReceiver.new
#pdf = PDF::Reader.file(ARGV.shift, receiver, :pages => false, :metadata => true)
#puts receiver.regular.inspect
#puts receiver.xml.inspect

