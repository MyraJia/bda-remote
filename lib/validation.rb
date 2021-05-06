module Validation

  class Strategy
    def apply(craft)
      return true
    end
    def error_message
      return ""
    end
  end

  class NotCondition < Strategy
    def initialize(strategy)
      @strategy = strategy
    end
    def apply(craft)
      return !strategy(craft)
    end
  end

  class OrCondition < Strategy
    def initialize(a, b)
      @a = a
      @b = b
    end
    def apply(craft)
      return a(craft) || b(craft)
    end
  end

  class AndCondition < Strategy
    def initialize(a, b)
      @a = a
      @b = b
    end
    def apply(craft)
      return a(craft) && b(craft)
    end
  end

  class XorCondition < Strategy
    def initialize(a, b)
      @a = a
      @b = b
    end
    def apply(craft)
      ar = a(craft)
      br = b(craft)
      return (ar && !br) || (!ar && br)
    end
  end

  class ShipTypeCondition < Strategy
    def initialize(options)
      @type = options[:type]
    end
    def apply(craft)
      case @type.to_sym
      when :sph
        return craft.ship_type == "SPH"
      when :vab
        return craft.ship_type == "VAB"
      else
        return false
      end
    end
    def error_message
      case @type.to_sym
      when :sph
        return "Craft must be saved in the SPH"
      when :vab
        return "Craft must be saved in the VAB"
      else
        return "Unknown wrong ship type"
      end
    end
  end

  class ShipSizeCondition < Strategy
    def initialize(options)
      @x = options[:x]
      @opx = options[:opx]
      @y = options[:y]
      @opy = options[:opy]
      @z = options[:z]
      @opz = options[:opz]
    end
    def apply(craft)
      size = craft.ship_size
      return false unless condition_result(size[0], @x.to_f, @opx)
      return false unless condition_result(size[1], @y.to_f, @opy)
      return false unless condition_result(size[2], @z.to_f, @opz)
      return true
    end
    def condition_result(value, ref, op)
      case op.to_sym
      when :lt
        return value < ref
      when :lte
        return value <= ref
      when :gt
        return value > ref
      when :gte
        return value >= ref
      when :eq
        return value == ref
      when :neq
        return value != ref
      else
        return true
      end
    end
    def error_message
      "Craft size out of bounds"
    end
  end

  class PartCount < Strategy
    def initialize(options)
      @op = options[:op]
      @value = options[:value].to_i
    end
    def apply(craft)
      case @op.to_sym
      when :lt
        return craft.parts.count < @value
      when :lte
        return craft.parts.count <= @value
      when :gt
        return craft.parts.count > @value
      when :gte
        return craft.parts.count >= @value
      when :eq
        return craft.parts.count == @value
      when :neq
        return craft.parts.count != @value
      else
        return true
      end
    end
    def error_message
      case @op.to_sym
      when :lt
        "too many parts! (< #{@value})"
      when :lte
        "too many parts! (≤ #{@value})"
      when :gt
        "not enough parts! (> #{@value})"
      when :gte
        "not enough parts! (≥ #{@value})"
      when :eq
        "wrong number of parts! (= #{@value})"
      when :neq
        "wrong number of parts! (!= #{@value})"
      else
        "PartCount unknown op #{@op}"
      end
    end
  end

  class PartExists < Strategy
    def initialize(options)
      @part = options[:part]
    end
    def apply(craft)
      # search craft parts for at least one matching the given name
      found_parts = craft.parts.any? { |e| e["part"] =~ /#{@part}_.+/ }
      return found_parts
    end
    def error_message
      "part must exist! (#{@part})"
    end
  end

  class PartNotExists < Strategy
    def initialize(options)
      @part = options[:part]
    end
    def apply(craft)
      # search craft parts for at least one matching the given name
      found_parts = craft.parts.any? { |e| e["part"] =~ /#{@part}_.+/ }
      return !found_parts
    end
    def error_message
      "part must not exist! (#{@part})"
    end
  end

  class PartSetContains < Strategy
    def initialize(options)
      @parts = options[:parts].gsub(/\s+/, "").split(",")
      puts "parts: #{@parts.join(", ")}"
      @matcher = options[:matcher]
    end
    def apply(craft)
      puts "PartSetContains #{@matcher} #{@parts.join(", ")}"
      case @matcher.to_sym
      when :none
        # search craft parts for any matching the given names, O(m+n)
        part_map = craft.part_map
        puts "part map: #{part_map}"
        puts @parts.map { |p| "#{p} => #{part_map.key?(p)}" }.join(", ")
        return !@parts.any? { |p| part_map.key?(p) }
      when :any
        # search craft parts for any matching the given names, O(m+n)
        part_map = craft.part_map
        puts "part map: #{part_map}"
        puts @parts.map { |p| "#{p} => #{part_map.key?(p)}" }.join(", ")
        return @parts.any? { |p| part_map.key?(p)  }
      when :all
        # search craft parts for all matching the given names, O(m+n)
        part_map = craft.part_map
        return @parts.all? { |p| part_map.key?(p)  }
      else
        return true
      end
    end
    def error_message
      case @matcher.to_sym
      when :none
        "parts must not exist! (#{@parts.join(", ")})"
      when :any
        "parts must contain at least one of (#{@parts.join(", ")})"
      when :all
        "parts must exist! (#{@parts.join(", ")})"
      else
        "PartSetExists unknown matcher #{@matcher}"
      end
    end
  end

  class PartSetCount < Strategy
    # validates the total count of parts matching a named set using an operator condition
    def initialize(options)
      @parts = options[:parts].gsub(/\s+/, "").split(",")
      @op = options[:op]
      @value = options[:value].to_i
      @comparator = lambda do |craft|
        # look through part map for counts and sum them
        total_count = @parts.map { |p| craft.part_map[p] }.reduce(0, :+)
        case @op.to_sym
        when :lt
          return total_count < @value
        when :lte
          return total_count <= @value
        when :gt
          return total_count > @value
        when :gte
          return total_count >= @value
        when :eq
          return total_count == @value
        when :neq
          return total_count != @value
        else
          return true
        end
      end
    end
    def apply(craft)
      @comparator.call(craft)
    end
    def error_message
      case @op.to_sym
      when :lt
        "too many parts! (< #{@value}) from set (#{@parts.join(", ")})"
      when :lte
        "too many parts! (≤ #{@value}) from set (#{@parts.join(", ")})"
      when :gt
        "not enough parts! (> #{@value}) from set (#{@parts.join(", ")})"
      when :gte
        "not enough parts! (≥ #{@value}) from set (#{@parts.join(", ")})"
      when :eq
        "wrong number of parts! (= #{@value}) from set (#{@parts.join(", ")})"
      when :neq
        "wrong number of parts! (!= #{@value}) from set (#{@parts.join(", ")})"
      else
        "PartSetCount unknown op #{@op} for set (#{@parts.join(", ")})"
      end
    end
  end

  class PropertyCondition < Strategy
    @@operations = [:lt, :gt, :lte, :gte, :eq, :neq]
    def initialize(options, before_compare)
      @options = options
      @key = options[:key]
      @op = options[:op]
      @value = options[:value]
      @comparator = create_comparator(options[:op], options[:value], before_compare)
    end
    def create_comparator(op, value, transform)
      op_lambda = build_operator(op)
      return lambda { |e| op_lambda.call(transform.call(e), transform.call(value)) }
    end
    def build_operator(op)
      case op.to_sym
      when :lt
        return lambda { |a,b| a < b }
      when :lte
        return lambda { |a,b| a <= b }
      when :gt
        return lambda { |a,b| a > b }
      when :gte
        return lambda { |a,b| a >= b }
      when :eq
        return lambda { |a,b| a == b }
      when :neq
        return lambda { |a,b| a != b }
      else
        return lambda { |a,b| false }
      end
    end
  end

  class ModulePropertyCondition < PropertyCondition
    def initialize(options, before_compare)
      puts "initialize(#{options})"
      @options = options
      @part = options[:part]
      @mod = options[:mod]
      @key = options[:key]
      @op = options[:op]
      @value = options[:value]
      @comparator = create_comparator(options[:op], options[:value], before_compare)
    end
    def apply(craft)
      # search craft parts for one with a module matching the given name
      # and containing a property whose key/value matches the given operation
      puts "searching for part #{@part} with module #{@mod}"
      found_parts = craft.parts.filter { |e| e["part"] =~ /#{@part}_.+/ }
      puts "parts: #{found_parts.map { |e| e["part"] }.join(", ") }"
      # only apply the condition if the part exists
      return true if found_parts.empty?
      found_modules = found_parts.map { |e| e[:modules] }.flatten.filter { |e| e["name"] =~ /#{@mod}/ }
      puts "modules: #{found_modules.map { |e| e["name"] }.join(", ") }"
      # only apply the condition if the module exists
      return true if found_modules.empty?
      found_modules.each do |m|
        has_prop = m.keys.include?(@key)
        if has_prop
          v = m[@key]
          puts "found #{@key} => #{v}"
          outcome = @comparator.call(v)
          if outcome
            puts "true"
          else
            puts "false"
          end
        end
      end
      result = found_modules.map { |e| e[@options[:key]] }.any? @comparator
      return result
    end
    def error_message
      puts "options: #{@options}"
      "part (#{@part}) with module (#{@mod}) must have property (#{@key}) with value #{@op} #{@value}"
    end
  end

  class FloatModulePropertyCondition < ModulePropertyCondition
    def initialize(options)
      super(options, lambda { |e| e.to_f })
    end
  end

  class StringModulePropertyCondition < ModulePropertyCondition
    def initialize(options)
      super(options, lambda { |e| e.to_s })
    end
  end

  class IntModulePropertyCondition < ModulePropertyCondition
    def initialize(options)
      super(options, lambda { |e| e.to_i })
    end
  end

  class ResourcePropertyCondition < PropertyCondition
    def initialize(options)
      @options = options
      @part = options[:part]
      @res = options[:res]
      @key = options[:key]
      @op = options[:op]
      @value = options[:value]
      @comparator = create_comparator(options[:op], options[:value], lambda { |e| e.to_f })
    end
    def apply(craft)
      # search craft parts for one with a module matching the given name
      # and containing a property whose key/value matches the given operation
      puts "searching for part #{@options["part"]} with module #{@options[:mod]}"
      found_parts = craft.parts.filter { |e| e["part"] =~ /#{@options[:part]}_.+/ }
      # only apply the condition if the part exists
      return true if found_parts.empty?
      puts "parts: #{found_parts.map { |e| e["part"] }.join(", ") }"
      found_resources = found_parts.map { |e| e[:resources] }.flatten.filter { |e| e["name"] =~ /#{@options[:res]}/ }
      puts "resources: #{found_resources.map { |e| e["name"] }.join(", ") }"
      # only apply the condition if the resource exists
      return true if found_resources.empty?
      result = found_resources.map { |e| e[@options[:key]].to_f }.any? @comparator
      return result
    end
    def error_message
      puts "options: #{@options}"
      "part (#{@part}) with resource (#{@res}) must have property (#{@key}) with value #{@op} #{@value}"
    end
  end

  class ShipCostCondition < ResourcePropertyCondition
    def apply(craft)
      cost = craft.cost
      [cost].any? @comparator
    end
    def error_message
      "craft must cost #{@op} #{@value}"
    end
  end

  class ShipMassCondition < ResourcePropertyCondition
    def apply(craft)
      mass = craft.mass
      [mass].any? @comparator
    end
    def error_message
      "craft must have mass #{@op} #{@value}"
    end
  end

  class ShipPointsCondition < ResourcePropertyCondition
    def apply(craft)
      points = craft.points
      [points].any? @comparator
    end
    def error_message
      "craft must have points #{@op} #{@value}"
    end
  end
end
