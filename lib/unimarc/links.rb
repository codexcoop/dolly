# TODO: use namespaces
module UnimarcLinks

  def missing_unimarc_links
    unimarc_links.missing
  end

  def missing_unimarc_links?
    missing_unimarc_links.present?
  end

  def related_bids
    related.map(&:bid).uniq
  end

  def linked_bids
    unimarc_links.map(&:bid).uniq
  end

  def pendent_bids
    linked_bids - related_bids
  end

  def pendent_unimarc_links
    unimarc_links.find(:all, :conditions => {:bid => pendent_bids}) - missing_unimarc_links
  end

  def pendent_unimarc_links?
    pendent_unimarc_links.present?
  end

  attr_accessor :bid_was_changed, :tmp_unimarc_links_was_changed
  alias_method :bid_was_changed?, :bid_was_changed
  alias_method :tmp_unimarc_links_was_changed?, :tmp_unimarc_links_was_changed

  def mark_changed_bid
    self.bid_was_changed = true if bid_changed?
  end

  def mark_changed_tmp_unimarc_links
    self.tmp_unimarc_links_was_changed = true if tmp_unimarc_links_changed?
  end

  def save_unimarc_links
    unimarc_links.destroy_all
    if tmp_unimarc_links
      tmp_unimarc_links.each_pair do |field, embedded_records|
        embedded_records.each do |embedded_record|
          self.unimarc_links.create(:bid => embedded_record['001'],
                                    :title => embedded_record['200'],
                                    :qualifier => field)
        end
      end
    end
  end

  def update_unimarc_links
    save_unimarc_links if tmp_unimarc_links_was_changed?
  end

  def process_pendent_unimarc_links
    if pendent_unimarc_links?
      pendent_unimarc_links.each do |link|
        related_id = link.linked_original_object.try(:id)
        if related_id
          self.associations_to.find_or_create(
            :qualifier => link.qualifier,
            :related_original_object_id => related_id
          )
        end
      end
      true
    else
      false
    end
  end

  def find_and_process_linking_records
    # OPTIMIZE: could use uniq here
    UnimarcLink.find_all_by_bid(self.bid).map(&:original_object).each do |original_object|
      original_object.process_pendent_unimarc_links
    end
  end

  def review_and_process_pendent_links
    find_and_process_linking_records if bid_was_changed?
    process_pendent_unimarc_links if tmp_unimarc_links_was_changed?
  end

  # TODO: update this method for the new implementation
  def self.flatten_unimarc_links(hash)
    hash.map{|k,vs| vs.each.map{|v|{:unimarc_field => k, :bid => v}}}.flatten
  end

end

