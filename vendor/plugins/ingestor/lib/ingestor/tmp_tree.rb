module Ingestor
  # Usage example:
  #
  #    tmp_ingest_dir = TmpIngestDir.find_by_dirname('Iria-Ridet-1906')
  #    tmp_ingest_dir.create_tmp_ingest_nodes_tree do
  #      describe_level 0 do |node|
  #        tmp_ingest_dir.original_object.title # "L'eco dell'Iria"
  #      end
  #      describe_level 1 do |node|
  #        "Annata #{node.formatted_date[:year]}"
  #      end
  #      describe_level 2 do |node|
  #        desc = "N. #{node.issue}, #{node.formatted_date[:long]}"
  #        desc << " (Seconda edizione)" if node.edition == 2
  #        desc
  #      end
  #      describe_level 3 do |node|
  #        desc = "Pagina #{node.page}"
  #        desc << " (Supplemento)" if node.supplement > 0
  #        desc
  #      end
  #      level_rule do |node|
  #        [node.date.year, node.issue, node.supplement]
  #      end
  #      level_rule do |node|
  #        node.date.year
  #      end
  #      node_sorting do |node|
  #        [node.date.year, node.issue, node.edition, node.supplement, node.page]
  #      end
  #    end
  #    tree.generate_missing_nodes
  #    root = tree.live_root
  #    binding.pry

  class TmpTree
    attr_accessor :attributes_collection, :nodes, :nodes_already_generated, :tree

    def initialize(*attributes_collection, &block)
      raise ArgumentError, "No filenames given" if attributes_collection.empty?
      self.attributes_collection = [attributes_collection].flatten
      configure(&block)
    end

    def configure(&block)
      if block.arity < 1
        self.instance_eval &block
      else
        yield self
      end
    end

    def nodes
      @nodes ||= attributes_collection.map do |attributes|
        TmpNode.new(attributes)
      end
    end

    def level_rule(&block)
      level_rules << block
    end

    def describe_level(level, &block)
      descriptions[level.to_i] = block
    end

    def node_sorting(&block)
      return @sorting_rule unless block_given?
      @sorting_rule = block
    end

    def generate_missing_nodes
      return nodes if nodes_already_generated
      reset_leaves
      apply_sorting
      level_rules.each do |rule|
        nodes.unshift(create_preceding(nodes.first))
        nodes.each_cons(2) do |a, b|
          next if rule.call(b) == rule.call(a)
          i = nodes.index(b)
          nodes.insert(i, create_preceding(b))
        end
      end
      finalize_nodes
      self.nodes_already_generated = true
      nodes
    end

    def live_root(remaining_nodes=nodes.clone)
      remaining_nodes.shift.tap do |current_node|
        subtree               = remaining_nodes.take_while{|node| node.level > current_node.level}
        current_node.children = subtree.select{|node| node.level == current_node.level+1}
        live_root(remaining_nodes) while remaining_nodes.size > 0
      end
    end

    private

    def set_description(node)
      raise ArgumentError, "No description given for level #{node.level}" unless descriptions[node.level]
      node.description = descriptions[node.level].call(node)
    end

    def level_rules
      @level_rules ||= []
    end

    def descriptions
      @descriptions ||= {}
    end

    def reset_leaves
      nodes.each do |node|
        node.level = 0
        node.leaf = true
      end
    end

    def apply_sorting
      self.nodes = nodes.sort_by(&node_sorting)
    end

    def create_preceding(node, make_root=false)
      node.clone.tap do |new_node|
        new_node.level = make_root ? 0 : (new_node.level - 1)
        new_node.leaf = false
        new_node.original_filename = nil
      end
    end

    def update_max_level
      @max_level = - nodes.map{|node|node.level}.min
    end

    def max_level
      @max_level ||= update_max_level
    end

    def nodes_with_root
      if nodes.first.root?
        nodes
      else
        # TODO: brutto, scrivere in modo decente
        new_root = create_preceding(nodes.first, make_root=true)
        set_description(new_root)
        nodes.unshift new_root
      end
    end

    def finalize_nodes
      nodes.each do |node|
        node.level += (max_level+1)
        set_description(node)
      end
      nodes_with_root
    end

  end # class TmpTree

end

