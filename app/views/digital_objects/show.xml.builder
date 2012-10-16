require 'exifr'

xml.instruct! :xml, :version=>"1.0", :encoding=>"UTF-8"
# All namespaces have to be declared
xml.mets :mets,
         'xmlns:mets'         => "http://www.loc.gov/METS/",
         'xmlns:mods'         => "http://www.loc.gov/mods/v3",
         'xmlns:rts'          => "http://cosimo.stanford.edu/sdr/metsrights/",
         'xmlns:mix'          => "http://www.loc.gov/mix/v10",
         'xmlns:xlink'        => "http://www.w3.org/1999/xlink",
         'xmlns:xsi'          => "http://www.w3.org/2001/XMLSchema-instance",
         'xmlns:dcterms'      => "http://purl.org/dc/terms/",
         'xmlns:dc'           => "http://purl.org/dc/elements/1.1/",
         'xmlns:europeana'    => "http://www.europeana.eu/schemas/ese/",
         'xsi:schemaLocation' => "http://www.loc.gov/METS/ http://www.loc.gov/standards/mets/mets.xsd",
         'OBJID'              => request.protocol + request.host_with_port + @digital_object.is_shown_by.absolute_path,
         'LABEL'              => @digital_object.original_object.title do
          #,
         # "PROFILE"            => "http://www.loc.gov/mets/profiles/00000013.xml"

  xml.mets :metsHdr, 'CREATEDATE' => Time.now.iso8601, 'LASTMODDATE' => Time.now.iso8601 do
    xml.mets :agent, 'ROLE' => 'CREATOR', 'TYPE' => 'ORGANIZATION' do
     xml.mets :name, @digital_object.institution.name
    end
  end

  # <mets:dmdSec ID="DMR1">
  #   <mets:mdRef xlink:href="http://www.oac.cdlib.org/findaid/ark:/13030/tf967nb619"
  #    XPTR="xpointer(id('m164505'))"
  #    LOCTYPE="URL"
  #    MDTYPE="EAD"
  #    LABEL="Pleasants family papers" />
  # </mets:dmdSec>

  # DIGITAL OBJECT METADATA (Europeana, Dublin Core)
  xml.mets :dmdSec, 'ID' => "DM1" do
    xml.mets :mdWrap, 'MDTYPE' => "Europeana - Dublin Core", 'LABEL' => @digital_object.original_object.title do
      xml.mets :xmlData do

        xml.dc :dc do
          xml_metadata_helper :entity_object => @digital_object.original_object,
                              :namespace => 'dc',
                              :metadata_standard_name => 'Dublin Core',
                              :xml => xml

          xml_metadata_helper :entity_object => @digital_object,
                              :namespace => 'dc',
                              :metadata_standard_name => 'Dublin Core',
                              :xml => xml
        end

        xml.europeana :europeana do
          xml_metadata_helper :entity_object => @digital_object.original_object,
                              :namespace => 'europeana',
                              :metadata_standard_name => 'Europeana',
                              :xml => xml

          xml_metadata_helper :entity_object => @digital_object,
                              :namespace => 'europeana',
                              :metadata_standard_name => 'Europeana',
                              :xml => xml
        end

      end
    end
  end

  # GENERAL TECHNICAL METADATA
  # @digital_files.each do |digital_file|
  #   xml.mets :admSec do
  #     xml.mets :techMD, 'ID' => "ADM#{digital_file.id}" do
  #       xml.mets :mdWrap, 'MDTYPE' => "NISOIMG" do
  #         xml.mets :xmlData do
  #           xml.mix :mix do
  # 
  #             xml.mix :BasicDigitalObjectInformation do
  #               xml.mix :ObjectIdentifier do
  #                 xml.mix :objectIdentifierType, 'url' # "ark"
  #                 xml.mix :objectIdentifierValue, @digital_object.is_shown_by.absolute_path
  #               end
  #               xml.mix :FormatDesignation do
  #                 xml.mix :formatName, digital_file.original_content_type # "image/tiff"
  #               end
  #             end
  # 
  #             xml.mix :ImageCaptureMetadata do
  #               xml.mix :GeneralCaptureInformation do
  #                 xml.mix :imageProducer, @digital_object.institution.name
  #                 # xml.mix :captureDevice, "digital still camera"
  #               end
  #               xml.mix :ScannerCapture do
  #                 xml.mix :ScannerModel do
  #                   xml.mix :scannerModelNumber
  #                   xml.mix :scannerModelSerialNo
  #                 end
  #                 xml.mix :maximumOpticalResolution
  #                 xml.mix :scannerSensor
  #                 xml.mix :ScanningSystemSoftware do
  #                   xml.mix :scanningSoftwareVersionNo
  #                 end
  #               end
  #               # xml.mix :DigitalCameraCapture do
  #               #   xml.mix :digitalCameraManufacturer, "PhaseOne"
  #               #   xml.mix :DigitalCameraModel do
  #               #     xml.mix :digitalCameraModelName, "PowerPhase"
  #               #     xml.mix :digitalCameraModelSerialNo, "AK001022"
  #               #   end
  #               #   xml.mix :CameraCaptureSettings do
  #               #     xml.mix :ImageData do
  #               #       xml.mix :lightSource, "Tungsten (incandescent light)"
  #               #     end
  #               #   end
  #               # end
  #               # xml.mix :SourceInformation do
  #               #   xml.mix :sourceType, "text/cover"
  #               #   xml.mix :SourceID do
  #               #     xml.mix :sourceIDType, "Local identifier"
  #               #     xml.mix :sourceIDValue, "cui-ms-r44-234-001"
  #               #   end
  #               # end
  #             end
  # 
  #             xml.mix :ImageAssessmentMetadata do
  #               xml.mix :SpatialMetrics do
  #                 xml.mix :xSamplingFrequency do
  #                   # => :x_resolution: !ruby/object:Rational denominator: 1 numerator: 300
  #                 end
  #                 xml.mix :ySamplingFrequency do
  #                 end
  #               end
  #               xml.mix :ImageColorEncoding do
  #                 xml.mix :bitsPerSample do
  #                   xml.mix :bitsPerSampleUnit, "integer"
  #                 end
  #               end
  #             end
  # 
  #             xml.mix :ChangeHistory do
  #               xml.mix :ImageProcessing do
  #                 xml.mix :processingAgency, @digital_object.institution.name
  #                 # xml.mix :ProcessingSoftware do
  #                 #   xml.mix :processingSoftwareName, "Photoshop" => "imagemagick"
  #                 # end
  #               end
  #             end
  # 
  #           end
  #         end
  #       end
  #     end
  #   end
  # end

  # LIST DIGITAL FILES
  DigitalFile::VARIANTS.each do |variant_name, variant|
    xml.mets :fileSec do
      xml.mets :fileGrp, "USE" => variant[:usage] do
        @digital_files.each do |digital_file|
          xml.mets :file,
                   "ID" => "FID-#{variant[:dir]}-#{digital_file.id}",
                   # OPTIMIZE: digital_file.original_content_type non è corretto né per derivate jpeg né per PDF
                   "MIMETYPE" => "image/jpeg",
                   "ADMID" => "ADM#{digital_file.id}",
                   "SEQ" => digital_file.position,
                   "GROUPID" => "GID#{digital_file.id}" do
            xml.mets :FLocat, "xlink:href" => request.protocol + request.host_with_port + digital_file.absolute_path(:variant => variant[:dir]), "LOCTYPE" => "URL"
          end
        end
      end
    end
  end

  # REPRESENT THE TREE OF THE TOC
  # xml_structmap_helper METHOD IS IN digital_objects_helper.rb
  xml.mets :structMap, "TYPE" => "logical", "LABEL" => "TOC" do
    xml.mets :div, "TYPE" => "text", "LABEL" => @digital_object.original_object.title do
    # not applicable # => , "ADMID" => "<fill the blanks!>", "DMDID" => "<fill the blanks!>"
      xml_structmap_helper(@toc, xml)
    end
  end

end

