class RulesController < AuthenticatedController

  # before_action :require_session
  before_action :assign_ruleset

  def assign_ruleset
    @ruleset = Ruleset.find(params[:ruleset_id])
  end

  def new
    @rule = Rule.new
  end

  def index
    @rules = @competition.rules
  end

  def create
    @rule = Rule.new
    strategy = params[:rule][:strategy].to_sym
    @rule.strategy = Rule::strategies[strategy]
    @rule.params = build_params(strategy)
    @rule.ruleset_id = @ruleset.id
    @rule.save
    if @rule.errors.any?
      flash[:error] = @rule.errors.messages
      redirect_to new_ruleset_rule_path(@ruleset)
    else
      redirect_to ruleset_path(@ruleset)
    end
  end

  def destroy
    @rule = Rule.find(params[:id])
    ruleset_id = @rule.ruleset_id
    @rule.destroy
    redirect_to ruleset_path(@ruleset)
  end

  def build_params(strategy)
    properties = lambda do |params|
      {
          part: params[:rule][:properties][:part].cleanup,
          mod: params[:rule][:properties][:name].cleanup,
          key: params[:rule][:properties][:key].cleanup,
          op: params[:rule][:properties][:op].cleanup,
          value: params[:rule][:properties][:value].cleanup
      }
    end
    case strategy.to_sym
    when :part_count
      return {
          op: params[:rule][:part_count][:op],
          value: params[:rule][:part_count][:value]
      }
    when :part_exists
      return {
          part: params[:rule][:part_exists][:part].cleanup
      }
    when :part_not_exists
      return {
          part: params[:rule][:part_exists][:part].cleanup
      }
    when :part_set_count
      return {
          parts: params[:rule][:part_set_count][:parts],
          op: params[:rule][:part_set_count][:op],
          value: params[:rule][:part_set_count][:value]
      }
    when :part_set_contains
      return {
          parts: params[:rule][:part_set_contains][:parts],
          matcher: params[:rule][:part_set_contains][:matcher]
      }
    when :float_module_property, :int_module_property, :string_module_property
      return {
          part: params[:rule][:properties][:part].cleanup,
          mod: params[:rule][:properties][:name].cleanup,
          key: params[:rule][:properties][:key].cleanup,
          op: params[:rule][:properties][:op].cleanup,
          value: params[:rule][:properties][:value].cleanup
      }
    when :resource_property
      return {
          part: params[:rule][:properties][:part].cleanup,
          res: params[:rule][:properties][:name].cleanup,
          key: params[:rule][:properties][:key].cleanup,
          op: params[:rule][:properties][:op].cleanup,
          value: params[:rule][:properties][:value].cleanup
      }
    when :ship_cost
      return {
          op: params[:rule][:ship_cost][:op],
          value: params[:rule][:ship_cost][:value]
      }
    when :ship_mass
      return {
          op: params[:rule][:ship_mass][:op],
          value: params[:rule][:ship_mass][:value]
      }
    when :ship_points
      return {
          op: params[:rule][:ship_points][:op],
          value: params[:rule][:ship_points][:value]
      }
    when :ship_size
      return {
          opx: params[:rule][:ship_size][:opx],
          x: params[:rule][:ship_size][:x],
          opy: params[:rule][:ship_size][:opy],
          y: params[:rule][:ship_size][:y],
          opz: params[:rule][:ship_size][:opz],
          z: params[:rule][:ship_size][:z]
      }
    when :ship_type
      return {
          type: params[:rule][:ship_type][:type]
      }
    else
      puts "UNK: #{strategy}"
      return {}
    end
  end
end

class String
  def cleanup
    self.to_s.gsub(/[^0-9a-zA-Z\.\-]+/, "")
  end
end