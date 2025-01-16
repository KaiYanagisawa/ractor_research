require 'rubocop'
require_relative './ractor_external_references_checker'

module RuboCop
  module Cop
    module Style
      class RactorSharingVariables < Base
        MSG = 'This may be referencing variables outside of the ractor block,' \
              'which will result in an error.'.freeze

        def_node_matcher :ractor_new?, <<~PATTERN
          (block
            (send (const nil? :Ractor) :new)
            ...
          )
        PATTERN

        def on_lvar(node)
          return unless ractor_new?(node.ancestors[1])

          file_path = processed_source.file_path
          checker = RactorExternalReferencesChecker.new(file_path)
          checker.check

          return unless checker.reference_external_variables?(node.children[0])

          add_offense(node, message: MSG)
        end
      end
    end
  end
end
