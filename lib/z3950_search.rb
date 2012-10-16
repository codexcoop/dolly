require 'zoom'

class Z3950Search

  def self.perform(params)
    server_name       = params[:z3950_server] || 'opac.sbn.it'
    selected_server   = servers[server_name]
    pqf_query_array   = build_pqf_array(params, mapping)
    pqf_query_string  = build_pqf_query_string(pqf_query_array)
    results           = []

    if pqf_query_array.size > 0
      ZOOM::Connection.open(server_name, selected_server[:port]) do |conn|
        conn.database_name = selected_server[:database]
        conn.preferred_record_syntax = selected_server[:format]
        conn.element_set_name = 'F' # F => full, B => brief (from SBN OPAC docs)
        # conn.set_option('from', 1) #  => like all other options it is ignored
        # conn.set_option('nentries', 10) # => like all other options it is ignored
        results_set = conn.search(pqf_query_string)
        results = results_set.records[0..19]
      end
    end

    results
  end

  def self.build_pqf_array(params, mapping={})
    pqf_query_array = []

    mapping.each_pair do |param_name, bib_1|
      value = params[:search][param_name.to_sym]
      pqf_query_array <<  [ bib_1['structure'], bib_1['attribute'], params[:search][param_name.to_sym] ] if value.present?
    end

    pqf_query_array
  end

  def self.build_pqf_query_string(pqf_query_array)
    pqf_and_rules = "@and " * (pqf_query_array.size - 1)
    pqf_attributes = ""
    pqf_query_array.each do |structure, attribute, param|
      pqf_attributes << %Q{@attr #{structure}=#{attribute} @attr 4=2 "#{param}" }
    end
    pqf_query_string = ("@attrset bib-1 "  +
                         pqf_and_rules      +
                         pqf_attributes).
                         strip.
                         gsub(/\\/, "\\\\\\\\")
    # pqf_query_string = %Q{@attrset bib-1 @and @attr 1=4 @attr 4=2 "Cesare Egitto" @attr 1=1003 @attr 4=2 "Pacini Giovanni"}
  end

  class << self
    attr_reader :servers, :mapping
  end

  @servers =  {
    'z3950.loc.gov' => {:port => 7090, :database => 'Voyager',  :format => 'MARC21' },
    'opac.sbn.it'   => {:port => 3950, :database => 'nopac',    :format => 'UNIMARC' } # :format => SUTRS
  }

  @mapping = {
    'author'                   => {'attribute' => '1003', 'structure' => '1' },
    'title'                    => {'attribute' => '4'   , 'structure' => '1' },
    'date_publication'         => {'attribute' => '31'  , 'structure' => '1' },
    'publisher'                => {'attribute' => '1018', 'structure' => '1' },
    'institution_directory_id' => {'attribute' => '1044', 'structure' => '1' },
    'isbn'                     => {'attribute' => '7'   , 'structure' => '1' },
    'issn'                     => {'attribute' => '8'   , 'structure' => '1' },
    'bid'                      => {'attribute' => '1032', 'structure' => '1' }
  }

end

