require 'rubocop'
require_relative './ractor_checker'

module RuboCop
  module Cop
    module Style
      class RactorSendReceive < Base
        extend AutoCorrector

        MSG = 'Ractor.receive detected in the Ractor block '\
              'but no corresponding `%<ractor>s`.send found.'.freeze

        def_node_search :ractor_new?, <<~PATTERN
          (lvasgn $_ractor_name
            (block
              (send (const nil? :Ractor) :new)
              ...
            )
          )
        PATTERN

        def_node_search :ractor_receive?, <<~PATTERN
          (send (const nil? :Ractor) :receive)
        PATTERN

        def_node_search :ractor_send?, <<~PATTERN
          (send (lvar %1) :send ...)
        PATTERN

        def on_lvasgn(node)
          return unless ractor_new?(node)

          file_path = processed_source.file_path
          checker = RactorChecker.new(file_path)
          checker.check

          return if checker.receive_paired_with_send?(node)

          message = message(node)
          add_offense(node, message: message) do |corrector|
            corrector.insert_after(node, "\n\n#{node.children[0]}.send()")
          end
        end

        private

        def message(node)
          format(MSG, ractor: node.children[0])
        end
      end
    end
  end
end
