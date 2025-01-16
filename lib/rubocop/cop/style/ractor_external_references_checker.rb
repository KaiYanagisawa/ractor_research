require 'parser/current'

class RactorExternalReferencesChecker
  attr_reader :variables_in_ractor, :ractor_external_variables

  def initialize(file_path)
    @file_path = file_path
    @variables_in_ractor = []
    @ractor_external_variables = []
  end

  def check
    buffer = Parser::Source::Buffer.new(@file_path)
    buffer.source = File.read(@file_path)

    parser = Parser::CurrentRuby.new
    ast = parser.parse(buffer)

    analyze_ast(ast)
  end

  def reference_external_variables?(variable_name)
    @ractor_external_variables.any? { |var| var[:name] == variable_name }
  end

  private

  def analyze_ast(node)
    return unless node.is_a?(Parser::AST::Node)

    case node.type
    when :lvasgn
      if node.to_json.include?('(const nil :Ractor) :new')
        find_lvar(node)
      else
        @ractor_external_variables << { name: node.children[0] } unless @ractor_external_variables.any? { |var| var[:name] == node.children[0] }
      end
    else
      node.children.each { |child| analyze_ast(child) }
    end
  end

  def find_lvar(node)
    return unless node.is_a?(Parser::AST::Node)

    case node.type
    when :lvar
      @variables_in_ractor << { name: node.children[0] } unless @variables_in_ractor.any? { |var| var[:name] == node.children[0] }
    else
      node.children.each { |child| find_lvar(child) }
    end
  end
end
