class TermsController < ApplicationController
  before_filter :require_user

  def vocabulary
    @vocabulary = Vocabulary.find params[:vocabulary_id]
  end

  def list
    @terms = Term.autocomplete_search(params)

    respond_to do |format|
      format.json  { render :json => @terms.map{|t|t.attributes} }
      format.html do
        render  :partial => "shared/relations/livesearch/results",
                :locals =>  {
                  :results => @terms,
                  :opts => {
                    :excluded_ids => [],
                    :selected_label_short => lambda{|term| h term.code }, # just an example
                    :selected_label_full  => lambda{|term, builder| h term.send(I18n.locale) }
                  }
                }
      end
    end
  end

  def index
    @terms = vocabulary.terms.find(:all, :order => 'position')

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @terms }
    end
  end

  # GET /terms/1
  # GET /terms/1.xml
  def show
    @term = vocabulary.terms.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @term }
    end
  end

  # GET /terms/new
  # GET /terms/new.xml
  def new
    @term = vocabulary.terms.build

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @term }
    end
  end

  # GET /terms/1/edit
  def edit
    @term = vocabulary.terms.find(params[:id])
  end

  # POST /terms
  # POST /terms.xml
  def create(updating = true)
    vocabulary_id = params[:id].present? ? params[:id] : params[:term][:vocabulary_id]
    vocabulary  = Vocabulary.find(vocabulary_id)

    @term = Term.new(params[:term])
    @term.user_id = current_user.id

    respond_to do |format|
      if @term.save
        flash[:notice] = t :created_successfully, :scope => [:controllers, :terms]
        format.html { redirect_to vocabulary_term_url(vocabulary, @term) }
        format.xml  { render :xml => @term, :status => :created, :location => @term }
        format.json { render :json => @term.attributes }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @term.errors, :status => :unprocessable_entity }
        format.json { render :json => {:errors => Hash[*@term.errors.map.flatten]} }
      end
    end
  end

  # PUT /terms/1
  # PUT /terms/1.xml
  def update
    @term = vocabulary.terms.find(params[:id])
    sanitized_params = params[:term].delete_if{|k,v| k == 'uuid'}
    @term.user_id = current_user.id

    respond_to do |format|
      if @term.update_attributes(sanitized_params)
        flash[:notice] = t :updated_successfully, :scope => [:controllers, :terms]
        format.html { redirect_to vocabulary_term_url(vocabulary, @term) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @term.errors, :status => :unprocessable_entity }
      end
    end
  end

  def move
    @term = Term.find(params[:id])

    respond_to do |format|
      if @term.insert_at(params[:position].to_i)
        @hash_for_json_response = {:status => "success", :term => @term.attributes.delete_if{|k,v|k.included_in?(['position',:position])}}
        format.json { render :json => @hash_for_json_response }
      else
        @hash_for_json_response = {:status => nil}
        format.json { render :json => @hash_for_json_response }
      end
    end
  end

  # DELETE /terms/1
  # DELETE /terms/1.xml
  def destroy
    @term = vocabulary.terms.find(params[:id])
    @term.destroy
    flash[:notice] = t :deleted_successfully, :scope => [:controllers, :terms]

    respond_to do |format|
      format.html { redirect_to url_for(:action => 'index') }
      format.xml  { head :ok }
    end
  end
end

