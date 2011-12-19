class PrintsController < ApplicationController
  before_filter :cache_index, :only => :index
  
  def index
    @print = Print.new

    respond_to do |format|
      format.html
    end
  end
  
  def create
    document = params[:print].delete(:document)
    params[:print][:copies] = 1 if params[:print][:copies].blank?
    
    @print = Print.new(params[:print])
    @print.user = $redis.srandmember("users")
    @print.filename = document.try(:original_filename)
    @print.tempfile = document.try(:tempfile).try(:path)

    respond_to do |format|
      if success = @print.save
        Resque.enqueue(PrintWorker, @print.id)
        flash[:notice] = "Your document has been successfully sent to <strong>#{@print.printer}</strong> under the pseudonym \"<strong>#{@print.user}</strong>\"."
        format.html { redirect_to root_path(success: success) }
      else
        format.html { render action: "index" }
      end
    end
  end
  
  private
  def cache_index
    unless params[:success]
      expires_in 30.minutes, :public => true
    end
  end
end