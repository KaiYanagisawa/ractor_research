require 'rubocop'
require_relative './ractor_checker'

module RuboCop
  module Cop
    module Style
      class RactorReceiveSend < Base
        MSG = 'Found `%<ractor>s`.send ' \
              'but no corresponding Ractor.receive in ractor block found.'.freeze

        def_node_search :ractor_send?, <<~PATTERN
          (send (lvar _) :send ...)
        PATTERN

        def on_send(node)
          return unless ractor_send?(node)

          file_path = processed_source.file_path
          checker = RactorChecker.new(file_path)
          checker.check

          return if checker.send_paired_with_receive?(node)

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
