module CatalogueSearchHelper

  def label_with_hint(opts={})
    opts.assert_required_keys :input_name, :label_text, :hint_text
    opts.assert_valid_keys :input_name, :label_text, :hint_text

    content = ""
    content << content_tag(:strong, label_tag(opts[:input_name], opts[:label_text]))
    content << "&nbsp;"
    content << content_tag(:span, :class => 'hint'){opts[:hint_text]}
    content
  end

end

