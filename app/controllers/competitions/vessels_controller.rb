class Competitions::VesselsController < AuthenticatedController

  require "open-uri"
  include Craft

  before_action :require_session
  before_action :assign_competition

  def index
    @vessels = current_user.player.vessels rescue []
  end

  def manifest
    respond_to do |format|
      format.json { render json: @competition.vessels, status: :ok }
      format.xml { render xml: @competition.vessels, status: :ok }
      format.csv { headers['Content-type'] ||= 'text/csv' }
    end
  end

  def create
    redirect_to competition_vessels_path(@competition) and return unless @competition.status == 0

    # fetch and validate craft
    @vessel = Vessel.find(params[:vessel_assignment][:vessel_id])
    craft = URI::open(@vessel.craft_url).read
    unless is_craft_valid?(craft)
      redirect_to competition_vessels_path(@competition) and return
    end

    @vessel_assignment = VesselAssignment.where(
        competition_id: params[:competition_id],
        vessel_id: params[:vessel_assignment][:vessel_id]).first_or_create
    redirect_to competition_vessels_path(@competition)
  end

  def destroy
    redirect_to competition_vessels_path(@competition) and return unless @competition.status == 0
    @vessel_assignment = VesselAssignment.find(params[:id])
    @vessel_assignment.destroy
    redirect_to competition_vessels_path(@competition)
  end

  def assign_competition
    @competition = Competition.find(params[:competition_id])
  end
end
