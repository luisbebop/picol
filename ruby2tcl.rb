require 'rubygems'
require 'parse_tree'
require 'sexp_processor'
require 'unified_ruby'

require 'pp'

class Ruby2Tcl < SexpProcessor
  include UnifiedRuby

  XLATE_MAP = {
    :puts => :puts
  }

  def initialize
    super
    @klasses = []
    @indent = "  "

    self.auto_shift_type = true
    self.strict = true
    self.expected = String
  end

  def translate_function(fname)
    XLATE_MAP[fname] || fname
  end

  def self.process(exp)
    self.new.process(exp)
  end

  def process(exp)
    exp = Sexp.from_array(exp) if Array === exp unless Sexp === exp
    super exp
  end

  def process_block(exp)
    result = []

    exp << nil if exp.empty?
    until exp.empty? do
      code = exp.shift
      if code.nil? or code.first == :nil then
        result << "# do nothing"
      else
        result << process(code)
      end
    end

    result = result.join "\n"

    result = case self.context[1]
             when nil, :scope, :if, :iter, :resbody, :when, :while then
               result + "\n"
             else
               "(#{result})"
             end

    return result
  end

  def process_defn(exp)
    type1 = exp[1].first
    #type2 = exp[2] rescue nil #.first 

    result = []

    case type1
        when :scope, :args then
        name = exp.shift.to_s
        name.gsub!('?', '_q')
        args = process(exp.shift)
        body = process(exp.shift)
        parent = @klasses.join('.')
        unless @klasses.empty?
          result << parent
          result << "."
        end
        result << name
        # return "#{result.join} = function#{args} {\n#{indent(body)}\n}"
        return "proc #{result.join} {#{args}} {\n#{indent(body)}\n}"
      else
        raise "Unknown defn type: #{type1} for #{exp.inspect}"
    end
  end

  def process_args(exp)
    args = []
    until exp.empty?
      arg = exp.shift
      case arg
      when Symbol then
        args << arg.to_s
      end
    end
    return "#{args.join ' '}"
  end

  def process_scope(exp)
    exp.empty? ? "" : process(exp.shift)
  end

  def process_if(exp)
    c = process exp.shift
    t = process exp.shift
    f = process exp.shift

    c = "(#{c.chomp})" if c =~ /\n/

    r = "if {#{c}} {\n#{indent(t)}\n} \n"
    r << "else {\n#{indent(f)}\n" if f
    r << "}"
    r
  end
  
  def process_call(exp)
    receiver_node_type = exp.first.nil? ? nil : exp.first.first
    receiver = process exp.shift

    #receiver = "(#{receiver})" if
    #  Ruby2Ruby::ASSIGN_NODES.include? receiver_node_type

    name = exp.shift
    args_exp = exp.shift rescue nil
        
    if args_exp && args_exp.first == :array # FIX
      args = "#{process(args_exp)[1..-2]}"
    else
      args = process args_exp
      args = nil if args.empty?
    end

    case name
    when :<=>, :==, :<, :>, :<=, :>=, :-, :+, :*, :/, :%, :<<, :>>, :** then
      # "(#{receiver} #{name} #{args})"
      "#{name} #{receiver} #{args}"
    when :[] then
      "#{receiver}[#{args}]"
    when :"-@" then
      "-#{receiver}"
    when :"+@" then
      "+#{receiver}"
    else
      unless receiver.nil? then
        "#{receiver}.#{name}(#{args})"
      else
        puts "name #{name} call args: #{args} class: #{args.class}"
                
        case args[0]
          when ?=, ?<, ?>, ?-, ?+, ?*, ?/, ?%  then
            "[#{translate_function(name)} [#{args}]]"
          when ?[ then
            "#{translate_function(name)} #{args}"
          else
            "[#{translate_function(name)} #{args}]"
          end
      end
    end
  end

  def process_lvar(exp)
    "$" + exp.shift.to_s
  end

  def process_arglist(exp)
    code = []
    until exp.empty? do
      code << process(exp.shift)
    end
    code.join ' '
  end

  def process_lit(exp)
    exp.shift.inspect
  end

  def process_return(exp)
    exp = "#{process(exp.shift)}"
    case exp[0].to_sym
    when :<=>, :==, :<, :>, :<=, :>=, :-, :+, :*, :/, :%, :<<, :>>, :** then
      "#{exp}"
    else
      "return #{exp}" 
    end
  end

  private
  def indent(s)
    s.to_s.split(/\n/).map{|line| @indent + line}.join("\n")
  end
end

code =<<-SCRIPT
  def fib(x)
    if x <= 1
      return 1
    else
      return fib(x-1) + fib(x-2)
    end
  end
  
  def add(x,y)
    x + y
  end
  
  def sum_one_and_two()
    add(1,2)
  end

  puts fib(20)
SCRIPT

sexp = ParseTree.translate(code)
pp sexp
puts Ruby2Tcl.process(sexp)
