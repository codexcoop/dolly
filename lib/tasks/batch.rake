namespace :batch do

  desc "Create associations between the digital_objects (specified in a static hash)"
  task :create_associations => :environment do
    exit # Comment me to execute the task
    # Sample query: SELECT o.id, d.master_dirpath FROM original_objects o, digital_objects d
    # WHERE o.id = d.original_object_id AND d.master_dirpath LIKE 'bergamo_3%' ORDER BY o.id;
    h = {
    697 => 492,
    698 => 492,
    699 => 492,
    700 => 492,
    701 => 492,
    702 => 489,
    703 => 493,
    704 => 490,
    705 => 490,
    706 => 490,
    707 => 490,
    708 => 490,
    709 => 490,
    710 => 490,
    711 => 490,
    712 => 490,
    713 => 490,
    714 => 490,
    715 => 490,
    716 => 490,
    717 => 490,
    718 => 490,
    719 => 490,
    720 => 490,
    721 => 490,
    722 => 490,
    723 => 490,
    724 => 490,
    725 => 490,
    726 => 490,
    727 => 490,
    728 => 490,
    729 => 491,
    730 => 491,
    731 => 491,
    732 => 491,
    733 => 491,
    734 => 491,
    735 => 557,
    736 => 494,
    737 => 494,
    738 => 494
    }

    h.each_pair do |current_object_id, parent_object_id|
      current_object = OriginalObject.find(current_object_id)
      parent_object = OriginalObject.find(parent_object_id)

      current_object.associations_to.create(
        :related_original_object_id => parent_object_id, :qualifier => '461')
      parent_object.associations_to.create(
        :related_original_object_id => current_object_id, :qualifier => '463')
    end

  end

end
