require 'rubocop'
require_relative 'ractor_take_checker'

module RuboCop
  module Cop
    module Style
      class RactorTake < Base
        MSG = 'No `%<ractor>s`.take found that corresponds to yield'.freeze

        def_node_search :ractor_new_block?, <<~PATTERN
          (lvasgn $_ractor_name
            (block
              (send (const nil? :Ractor) :new)
              ...
            )
          )
        PATTERN

        def on_lvasgn(node)
          return unless ractor_new_block?(node)

          file_path = processed_source.file_path
          checker = RactorYieldTakeChecker.new(file_path)
          checker.check

          return if checker.paired_with_take?(node.children[0])

          message = message(node)
          add_offense(node, message: message)
        end

        private

        def message(node)
          format(MSG, ractor: node.children[0])
        end
      end
    end
  end
end
