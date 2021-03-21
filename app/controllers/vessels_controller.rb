class VesselsController < AuthenticatedController
  require 'csv'
  include Craft

  before_action :require_session, except: [:detail, :evaluate]
  before_action :assign_player, except: [:detail, :evaluate]
  before_action :assign_vessel, only: [:show, :edit, :update, :destroy, :undiscard, :sensitivity]
  before_action :reject_if_needed, except: [:detail, :evaluate]

  skip_before_action :verify_authenticity_token

  def new
    @vessel = Vessel.new
  end

  def create
    s3 = Aws::S3::Resource.new(region: ENV['AWS_REGION'])
    bucket = s3.bucket(ENV['S3_BUCKET'])
    redirect_to new_vessel_path and return if bucket.nil?

    file = params[:file]

    unless file.original_filename.ends_with?(".craft")
      flash[:error] = "File must have .craft extension"
      redirect_to new_vessel_path and return
    end

    if file.size > 5242880
      flash[:error] = "File too large (max 5MB)"
      redirect_to new_vessel_path and return
    end

    filename = "players/#{@player.id}/#{file.original_filename}"
    s3obj = bucket.object(filename)
    s3obj.put(
      body: file,
      acl: "public-read"
    )

    # craft_url = "url-#{Time.now.to_f}"
    craft_url = s3obj.public_url
    @vessel = Vessel.create(player_id: @player.id, craft_url: craft_url, name: params[:vessel][:name])

    if @vessel.errors.any?
      flash[:error] = @vessel.errors
      redirect_to new_player_vessel_path(current_user.player) and return
    else
      redirect_to player_vessels_path(current_user.player)
    end
  end

  def index
    @vessels = @player.vessels.kept
    respond_to do |format|
      format.html
      format.json { render json: @vessels }
      format.xml { render xml: @vessels }
    end
  end

  def show
    redirect_to player_vessels_path(current_user.player) and return unless @vessel.player == current_user.player
  end

  def edit
  end

  def update
    @vessel.update(vessel_params)
    redirect_to player_vessel_path(@player, @vessel)
  end

  def destroy
    @vessel.discard
    redirect_to player_vessel_path(@player, @vessel)
  end

  def undiscard
    @vessel.undiscard
    redirect_to player_vessel_path(@player, @vessel)
  end

  def detail
    file = params[:file]
    @craft = Craft::KspVessel.interpret_file(file)
    if @craft.nil?
      flash[:error] = "Failed to interpret your file"
      redirect_to evaluate_path and return
    end
    if @craft.parts.nil?
      flash[:error] = "Failed to resolve parts for your file"
      redirect_to evaluate_path
    end
  end

  def evaluate
  end

  def sensitivity
    competition = Sensitivity.configure(@vessel, current_user)
    redirect_to competition_path(competition)
  end

  private

  def assign_player
    @player = Player.find(params[:player_id])
  end

  def assign_vessel
    @vessel = Vessel.find(params[:id])
  end

  def reject_if_needed
    redirect_to player_vessels_path(current_user.player) and return unless !@player.is_human or @player.user == current_user
  end

  def vessel_params
    params.require(:vessel).permit(:name)
  end
end
