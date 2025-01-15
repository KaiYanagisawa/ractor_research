require 'rubocop'
require_relative './ractor_checker'

module RuboCop
  module Cop
    module Style
      class RactorSharingVariables < Base
        MSG = 'This may be referencing variables outside of the ractor block.' \
              'External references within a ractor will result in an error.'.freeze

        def_node_search :ractor_new?, <<~PATTERN
          (lvasgn $_ractor_name
            (block
              (send (const nil? :Ractor) :new)
              ...
            )
          )
        PATTERN

        def on_lvasgn(node)
          return unless ractor_new?(node)

          p node

          p node.children[0]

          file_path = processed_source.file_path
          checker = RactorChecker.new(file_path)
          checker.check

          return if checker.receive_paired_with_send?(node)

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
