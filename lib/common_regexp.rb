module CommonRegexp

  def self.included(klass)
    klass.extend(ClassMethods)
  end

  module ClassMethods
    def simple_email_regexp
      part_1 = /^[A-Z0-9._+-]+/i # any combination of letters, digits, dot, plus, underscore, hyphen
      part_2 = /@(?:[A-Z0-9-]+\.)+/i
      part_3 = /[A-Z]{2,4}$/i
      /\A(?:#{part_1}#{part_2}#{part_3})\z/
    end

    def simple_url_regexp
      part_1 = /^(http|https):\/\/[a-z0-9]+/ix
      part_2 = /([-.]{1}[a-z0-9]+)*/ix
      part_3 = /.[a-z]{2,5}/ix
      part_4 = /(([0-9]{1,5})?\/.*)?$/ix
      /\A(?:#{part_1}#{part_2}#{part_3}#{part_4})\z/
    end

  end


end

