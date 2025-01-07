require 'parser/current'

class RactorChecker
  attr_reader :ractor_receives, :ractor_sends

  def initialize(file_path)
    @file_path = file_path
    @ractor_receives = []
    @ractor_sends = []
  end

  def check
    buffer = Parser::Source::Buffer.new(@file_path)
    buffer.source = File.read(@file_path)

    parser = Parser::CurrentRuby.new
    ast = parser.parse(buffer)

    analyze_ast(ast)
  end

  def receive_paired_with_send?(node)
    exist_receive = false

    @ractor_receives.each do |receive|
      next unless node.children[0] == receive[:ractor]

      exist_receive = true
      @ractor_sends.each do |send|
        return true if receive[:ractor] == send[:ractor]
      end
    end

    return false if exist_receive

    true
  end

  def send_paired_with_receive?(node)
    @ractor_sends.each do |send|
      next unless node.children[0].children[0] == send[:ractor]

      @ractor_receives.each do |receive|
        return true if send[:ractor] == receive[:ractor]
      end
    end

    false
  end

  private

  def analyze_ast(node, current_ractor = nil)
    return unless node.is_a?(Parser::AST::Node)

    case node.type
    when :lvasgn
      return unless node.to_json.include?('(const nil :Ractor) :receive') && node.to_json.include?('(const nil :Ractor) :new')

      current_ractor = node.children[0]
      @ractor_receives << { ractor: current_ractor, node: node }
    when :send
      return unless node.children[1] == :send

      @ractor_sends << { ractor: node.to_json.scan(/\(lvar :(\w+)\) :send/)[0]&.first&.to_sym, node: node }
    else
      node.children.each { |child| analyze_ast(child, current_ractor) }
    end
  end

  def report_warnings
    unmatched_receives = @ractor_receives.reject do |receive|
      @ractor_sends.any? { |send| send[:ractor] == receive[:ractor] }
    end

    unmatched_receives.each do |receive|
      ractor_name = receive[:ractor]
      location = receive[:node].location.expression
      puts "Warning: Ractor.receive in #{ractor_name} has no matching .send (#{location})"
    end
  end
end
