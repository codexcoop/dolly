class DigitalFilesController < ApplicationController

  before_filter :require_user

  # FIXME: tutti gli utenti possono accedere a qualunque elenco di digital_files.
  def index
    @digital_files = digital_object.digital_files.find(
      :all,
      :select => "id, digital_object_id, derivative_filename, original_filename, width_small, height_small, position, key_image",
      # :include => {:digital_object => {:digital_collection => {:project => :institution}}}
      :include => :digital_object
    )

    respond_to do |format|
      format.html
      format.xml  { render :xml => @digital_files }
    end
  end

  def move
    digital_file = DigitalFile.find(params[:id])

    movement = false
    digital_file.transaction { movement = digital_file.insert_at(params[:position]) }

    respond_to do |format|
      if movement
        format.json { render :json => {:status => "ok"} }
      else
        format.json { render :json => {:status => nil} }
      end
    end
  end

  def toggle_key_image
    @digital_file = DigitalFile.find(params[:id])

    DigitalFile.update_all({:key_image => false}, {:digital_object_id => @digital_file.digital_object_id})
    @digital_file.toggle!(:key_image)

    # NB: se non si vuole aggiornare updated_at usare:
    # DigitalFile.update_all({:key_image => true}, {:id => @digital_file.id})
    # In Rails3 lo stesso risultato si ottiene più concisamente con:
    # @digital_file.update_column(:key_image, true)

    redirect_to(request.referrer, :notice => t(:updated_successfully, :scope => default_i18n_controllers_scope))
  end

  def destroy
    @digital_file = digital_object.digital_files.find(params[:id])
    @digital_file.destroy

    respond_to do |format|
      flash[:notice] = 'DigitalFile was successfully deleted'
      format.html { redirect_to digital_object_digital_files_url(digital_object)  }
      format.xml  { head :ok }
    end
  end

  private

  def digital_object
    @digital_object ||= DigitalObject.find(params[:digital_object_id])
  end

end

