require 'parser/current'

class RactorYieldTakeChecker
  attr_reader :ractor_takes

  def initialize(file_path)
    @file_path = file_path
    @ractor_takes = []
  end

  def check
    buffer = Parser::Source::Buffer.new(@file_path)
    buffer.source = File.read(@file_path)

    parser = Parser::CurrentRuby.new
    ast = parser.parse(buffer)

    analyze_ast(ast)
  end

  def paired_with_take?(ractor_name)
    return false if @ractor_takes.empty?

    @ractor_takes.each { |ractor_take| return true if ractor_take[:ractor] == ractor_name }

    false
  end

  private

  def analyze_ast(node, current_ractor = nil)
    return unless node.is_a?(Parser::AST::Node)

    case node.type
    when :send
      return unless node.to_json.scan(/\(lvar :(\w+)\) :take\)/).any?

      @ractor_takes << { ractor: node.to_json.scan(/\(lvar :(\w+)\) :take\)/)[0]&.first&.to_sym, node: node }
    else
      node.children.each { |child| analyze_ast(child, current_ractor) }
    end
  end
end
