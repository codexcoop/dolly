class NodesController < ApplicationController

  def index
    digital_object = DigitalObject.find(params[:digital_object_id])
    @toc = digital_object.toc
    @nodes = digital_object.nodes_to_jstree_hash
    respond_to do |format|
      format.json {render :json => @nodes}
    end
  end

  def create
    @parent = Node.find(params[:node][:parent_id])
    @node = @parent.children.build(params[:node].delete_if{|k,v| k.included_in?([:parent_id, 'parent_id']) })

    respond_to do |format|
      if @node.save
        @hash_for_json_response = {:status => "success", :node => @node.attributes.delete_if{|k,v|k.included_in?(['position',:position])}}
        format.json { render :json => @hash_for_json_response }
      else
        @hash_for_json_response = {:status => nil}
        format.json { render :json => @hash_for_json_response }
      end
    end
  end

  def update
    params[:node].delete_if{|k, v| k.included_in? [:position, 'position', :parent_id, 'parent_id']}
    @node = Node.find(params[:id])

    respond_to do |format|
      if @node.update_attributes(params[:node])
        @hash_for_json_response = {:status => "success", :node => @node.attributes.delete_if{|k,v|k.included_in?(['position',:position])}}
        format.json { render :json => @hash_for_json_response }
      else
        @hash_for_json_response = {:status => nil}
        format.json { render :json => @hash_for_json_response }
      end
    end
  end

  def move
    @node = Node.find(params[:id])

    respond_to do |format|
      if @node.move_globally( :new_parent_id => params[:node][:parent_id],
                              :new_position => params[:node][:position])
        @hash_for_json_response = {:status => "success", :node => @node.attributes.delete_if{|k,v|k.included_in?(['position',:position])}}
        format.json { render :json => @hash_for_json_response }
      else
        @hash_for_json_response = {:status => nil}
        format.json { render :json => @hash_for_json_response }
      end
    end
  end

  def assign
    @node = Node.find(params[:id])

    respond_to do |format|
      if @node.update_attribute(:digital_file_id, params[:node][:digital_file_id])
        @hash_for_json_response = {
                                    :status =>  "success",
                                    :node   =>  @node.attributes.delete_if{|k,v|k.included_in?(['position',:position])}
                                   }
        format.json { render :json => @hash_for_json_response }
      else
        @hash_for_json_response = {:status => nil}
        format.json { render :json => @hash_for_json_response }
      end
    end
  end

  def description_template
    render  :partial => "digital_objects/node_description",
            :locals => {:node_id => params[:id],
                        :parent_id => Node.find(params[:id]).parent_id,
                        :text => params[:node][:description] }
  end

  def remove_assignment
    @node = Node.find(params[:id])

    respond_to do |format|
      if @node.update_attribute(:digital_file_id, nil)
        @hash_for_json_response = {
                                    :status =>  "success",
                                    :node   =>  @node.attributes.delete_if{|k,v|k.included_in?(['position',:position])}
                                   }
        format.json { render :json => @hash_for_json_response }
      else
        @hash_for_json_response = {:status => nil}
        format.json { render :json => @hash_for_json_response }
      end
    end
  end

  def destroy
    @node = Node.find(params[:id])
    @flat_sub_tree = @node.descendants.map(&:id) << @node.id

    respond_to do |format|
      if @node.parent_id? and @node.destroy
        @hash_for_json_response = {
                                    :status =>  "success",
                                    :node   =>  @node.attributes.delete_if{|k,v|k.included_in?(['position',:position])},
                                    :flat_sub_tree => @flat_sub_tree
                                   }
        format.json { render :json => @hash_for_json_response }
      else
        @hash_for_json_response = {:status => nil}
        format.json { render :json => @hash_for_json_response }
      end
    end
  end

end

