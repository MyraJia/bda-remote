class ApplicationController < ActionController::Base

  rescue_from ActionController::UnknownFormat, with: :sorry_dave

  def duplicate_record
    attr = duplicate_record_attribute
    result = { error: attr.to_s.humanize + " must be unique" }
    respond_to do |format|
      format.json { render json: result, status: :unprocessable_entity }
      format.xml { render xml: result, status: :unprocessable_entity }
    end
  end

  def bad_request
    result = { error: "Bad request" }
    respond_to do |format|
      format.json { render json: result, status: :bad_request }
      format.xml { render xml: result, status: :bad_request }
      format.csv { head :bad_request }
    end
  end

  def sorry_dave
    head :not_found
  end

end
