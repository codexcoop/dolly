require 'pp'

# TODO: use namespaces
module UnimarcParsing

  # TODO: memoize
  # TODO: some methods should be class-methods
  # TODO: some rescues in UnimarcParsing maybe could be removed

  def get_leader_from_unimarc_text(unimarc_text)
    unimarc_text.gsub(/.*leader(\s*)/im, '').custom_to_lines.first
  rescue Exception => e
    raise Unimarc::ParsingException, e.inspect
  end

  def decode_unimarc_leader(opts={})
    opts.assert_valid_keys :position, :language, :leader
    opts.assert_required_keys :position, :language, :leader

    given_code  = opts[:leader][opts[:position].to_i, 1].to_s
    Unimarc::UNIMARC_LEADER_POSITIONS[opts[:position].to_i][:code][given_code][opts[:language].to_sym]
  rescue Exception => e
    raise Unimarc::ParsingException, e.inspect
  end

  def unimarc_record_id_index(unimarc_text)
    unimarc_text.custom_to_lines.index{|line| line.strip =~ /^001/ }
  rescue Exception => e
    raise Unimarc::ParsingException, e.inspect
  end

  def unimarc_to_lines(unimarc_text)
    begin
      collected_unimarc_lines = unimarc_text.custom_to_lines
      raise unless unimarc_record_id_index(unimarc_text)
    rescue Exception => e
      raise Unimarc::ParsingException, e.inspect
    end
    collected_unimarc_lines.values_at((unimarc_record_id_index(unimarc_text)-1)..-1).
                            each_with_index.
                            map{ |line, index|
                             line.gsub(/.*leader(\s*)/im){|match| '' if index == 0}.
                                  gsub(/\e(.)/, '').strip #.squeeze("\s+")
                            }
  rescue Exception => e
    raise Unimarc::ParsingException, e.inspect
  end

  def scan_unimarc_line(line)
    line.scan(/\$.*/).first.split('$')[1..-1].map{|subfield|
      ["$#{subfield[0,1].strip}", subfield[1..-1].gsub(/\s*,/, ", ").strip] # ).strip.squeeze("\s+")
    }
  rescue Exception => e
    raise Unimarc::ParsingException, e.inspect
  end

  # TODO: write as Hash.new{|h,k|...} see intellectual_responsability_to_sub_hash method
  def add_to_hash_key(hash, key, value)
    if hash[key]
      hash[key] << value
    else
      hash[key] = [value]
    end
    hash
  rescue Exception => e
    raise Unimarc::ParsingException, e.inspect
  end

  def initialize_sub_hash_with_indicators(line)
    sub_hash = ActiveSupport::OrderedHash.new
    sub_hash[:indicator_1] = line[4,1] if line[4,1].strip.size > 0
    sub_hash[:indicator_2] = line[5,1] if line[5,1].strip.size > 0
    sub_hash
  rescue Exception => e
    raise Unimarc::ParsingException, e.inspect
  end

  def unimarc_line_to_generic_sub_hash(line)
    sub_hash = initialize_sub_hash_with_indicators(line)
    content = scan_unimarc_line(line)
    content.each do |fragment|
      sub_hash = add_to_hash_key(sub_hash, fragment[0], fragment[1])
    end
    sub_hash
  rescue Exception => e
    raise Unimarc::ParsingException, e.inspect
  end

  def build_dewey_code(generic_sub_hash)
    code = ""
    code << generic_sub_hash['$a'].first if generic_sub_hash['$a'] && generic_sub_hash['$a'].any?
    code << " (#{generic_sub_hash['$v'].first}.)" if generic_sub_hash['$v'] && generic_sub_hash['$v'].any?
    code.strip
  rescue Exception => e
    raise Unimarc::ParsingException, e.inspect
  end

  def build_dewey_full_description(generic_sub_hash)
    full_description = ""
    full_description << build_dewey_code(generic_sub_hash)
    full_description << " #{generic_sub_hash['$1'].first}"  if generic_sub_hash['$1'] && generic_sub_hash['$1'].any?
    full_description.strip
  rescue Exception => e
    raise Unimarc::ParsingException, e.inspect
  end

  def unimarc_dewey_to_sub_hash(line)
    generic_sub_hash = unimarc_line_to_generic_sub_hash(line)
    dewey_sub_hash = ActiveSupport::OrderedHash.new
    dewey_sub_hash = add_to_hash_key(dewey_sub_hash, '$av', build_dewey_code(generic_sub_hash))
    dewey_sub_hash = add_to_hash_key(dewey_sub_hash, '$av1', build_dewey_full_description(generic_sub_hash))
    dewey_sub_hash
  rescue Exception => e
    raise Unimarc::ParsingException, e.inspect
  end

  def build_intellectual_responsability_term(generic_sub_hash)
    "".tap do |str|
      str << generic_sub_hash['$a'].first if generic_sub_hash['$a'] && generic_sub_hash['$a'].any?(&:present?)
      str << " #{generic_sub_hash['$b'].first}" if generic_sub_hash['$b'] && generic_sub_hash['$b'].any?(&:present?)
    end.squish.gsub(/\s*,\s+/,",\s")
  end

  def intellectual_responsability_to_sub_hash(line)
    generic_sub_hash = unimarc_line_to_generic_sub_hash(line)
    ActiveSupport::OrderedHash.new{|h,k| h[k] = []}.tap do |subhash|
      subhash['$ab'] << build_intellectual_responsability_term(generic_sub_hash)
      subhash['$3'] << generic_sub_hash['$3'] if generic_sub_hash['$3'].present?
      subhash['$4'] << generic_sub_hash['$4'] if generic_sub_hash['$4'].present?
      subhash[:indicator_2] << generic_sub_hash[:indicator_2] if generic_sub_hash[:indicator_2].present?
    end
  end

  # TODO: use Hash.new{|h,k|...} and instance variables for the unimarc_hash
  def add_content_to_unimarc_hash(content, unimarc_hash, main_field)
    if unimarc_hash[main_field]
      unimarc_hash[main_field] << content
    else
      unimarc_hash[main_field] = [content]
    end
    unimarc_hash
  rescue Exception => e
    raise Unimarc::ParsingException, e.inspect
  end

  def unimarc_link_to_sub_hash(line)
    sublines = line.scan(/\$.*/).
                    first.
                    split("$1").
                    map(&:strip).
                    reject(&:blank?).
                    map{|subline| subline.to_s.sub(/(...).*?\$/){|match| match[0..2] + "$"} }.
                    grep(/^001|^200/)

    fields = Hash[*sublines.map{|field| [field[0..2], field[3..-1]]}.flatten]
    fields.update({'200' => title_with_punctuation(fields['200'])})
  end

  # TODO: memoize Unimarc hash, and make it an instance_variable
  def unimarc_to_hash(unimarc_text)
    unimarc_hash = ActiveSupport::OrderedHash.new

    unimarc_to_lines(unimarc_text)[1..-1].each do |line|
      main_field  = line[0..2]
      if main_field == '676' # subjects in Dewey classification
        content = unimarc_dewey_to_sub_hash(line)
      elsif main_field.match(/7\d\d/) # sometimes the full name is splitted in subfields, as for Biblioteca Mai
        content = intellectual_responsability_to_sub_hash(line)
      elsif Unimarc::UNIMARC_LINK_FIELDS.keys.include?(main_field)
        content = unimarc_link_to_sub_hash(line)
      elsif line =~ /\$.+/
        content = unimarc_line_to_generic_sub_hash(line)
      else
        content = line[3..-1].strip.gsub(/\e(.)/, '') if line[3..-1] # .squeeze("\s+")
      end
      unimarc_hash = add_content_to_unimarc_hash(content, unimarc_hash, main_field)
    end

    unimarc_hash
  rescue Exception => e
    raise Unimarc::ParsingException, e.inspect
  end

  def unimarc_to_simple_hash(unimarc_text)
    unimarc_hash = ActiveSupport::OrderedHash.new{|hash, key| hash[key] = []}

    unimarc_to_lines(unimarc_text).each do |line|
      if line.size > 0
        unimarc_hash[line[0..2]]
        if line[3..-1].scan(/\$.+/).first
          unimarc_hash[line[0..2]] << line[3..-1].scan(/\$.+/).first.strip #.squeeze("\s+")
        else
          unimarc_hash[line[0..2]] << line[3..-1].strip #.squeeze("\s+")
        end
      end
    end
    unimarc_hash
  rescue Exception => e
    raise Unimarc::ParsingException, e.inspect
  end

  def scan_unimarc_field_occurrence(field_occurrence_hash, join_char, *subfields)
    field_occurrence_hash.values_at(*[subfields].flatten.map(&:to_s)).compact.map(&:first).join(join_char)
  end

end

