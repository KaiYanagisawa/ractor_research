require 'rubocop'
require_relative 'ractor_yield_take_checker'

module RuboCop
  module Cop
    module Style
      class RactorYieldTake < Base
        MSG = 'No take found that corresponds to yield'.freeze

        def_node_search :ractor_yield?, <<~PATTERN
          (send (const nil? :Ractor) :yield ...)
        PATTERN

        def_node_search :ractor_new_block?, <<~PATTERN
          (lvasgn $_ractor_name
            (block
              (send (const nil? :Ractor) :new)
              ...
            )
          )
        PATTERN

        def on_send(node)
          return unless ractor_yield?(node)

          file_path = processed_source.file_path
          checker = RactorYieldTakeChecker.new(file_path)
          checker.check

          ractor_name = node.each_ancestor.find { |ancestor| ractor_new_block?(ancestor) }.children[0]

          return if checker.yield_paired_with_take?(ractor_name)

          message = message(node)
          add_offense(node, message: message)
        end

        private

        def message(node)
          format(MSG, ractor: node.children[0].children[0])
        end
      end
    end
  end
end
